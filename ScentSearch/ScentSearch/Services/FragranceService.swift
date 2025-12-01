//
//  FragranceService.swift
//  ScentSearch
//
//  Service for loading and searching the local fragrance database
//

import Foundation
import SwiftUI

@Observable
class FragranceService {
    static let shared = FragranceService()
    
    private(set) var fragrances: [Fragrance] = []
    private(set) var brands: [String] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    private var loadingTask: Task<Void, Never>?
    
    // Index for faster lookups
    private var fragranceById: [String: Fragrance] = [:]
    private var fragrancesByBrand: [String: [Fragrance]] = [:]
    
    private init() {}
    
    // MARK: - Loading
    
    func loadFragrances() async {
        // Already loaded
        guard fragrances.isEmpty else { 
            print("FragranceService: Already loaded \(fragrances.count) fragrances")
            return 
        }
        
        // Already loading - wait for existing task
        if let existingTask = loadingTask {
            print("FragranceService: Already loading, waiting...")
            await existingTask.value
            return
        }
        
        print("FragranceService: Starting to load fragrances...")
        
        // Start new loading task
        let task = Task { @MainActor in
            self.isLoading = true
            
            do {
                // Try multiple locations for the JSON file
                var url: URL?
                
                // Try bundle first
                if let bundleUrl = Bundle.main.url(forResource: "fragrance_database", withExtension: "json") {
                    url = bundleUrl
                    print("FragranceService: Found in bundle at \(bundleUrl)")
                }
                
                // If not in bundle, try the app's documents or source location
                if url == nil {
                    // For development, try source directory
                    let sourceUrl = URL(fileURLWithPath: #file)
                        .deletingLastPathComponent() // Services/
                        .deletingLastPathComponent() // ScentSearch/
                        .appendingPathComponent("fragrance_database.json")
                    
                    if FileManager.default.fileExists(atPath: sourceUrl.path) {
                        url = sourceUrl
                        print("FragranceService: Found at source path \(sourceUrl)")
                    }
                }
                
                guard let finalUrl = url else {
                    print("FragranceService: ERROR - fragrance_database.json not found!")
                    print("Bundle path: \(Bundle.main.bundlePath)")
                    print("Bundle resources: \(Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])")
                    throw FragranceServiceError.fileNotFound
                }
                
                // Load and decode on background thread
                let loadedFragrances: [Fragrance] = try await Task.detached(priority: .userInitiated) {
                    print("FragranceService: Loading data from \(finalUrl)")
                    let data = try Data(contentsOf: finalUrl)
                    print("FragranceService: Loaded \(data.count) bytes, decoding...")
                    let decoder = JSONDecoder()
                    return try decoder.decode([Fragrance].self, from: data)
                }.value
                
                print("FragranceService: Decoded \(loadedFragrances.count) fragrances, building indexes...")
                
                // Build indexes on background thread
                let (idIndex, brandIndex, brandList) = await Task.detached(priority: .userInitiated) {
                    let idIndex = loadedFragrances.reduce(into: [String: Fragrance]()) { dict, fragrance in
                        dict[fragrance.id] = fragrance
                    }
                    let brandIndex = Dictionary(grouping: loadedFragrances, by: { $0.brand })
                    let brandList = brandIndex.keys.sorted()
                    return (idIndex, brandIndex, brandList)
                }.value
                
                self.fragrances = loadedFragrances
                self.fragranceById = idIndex
                self.fragrancesByBrand = brandIndex
                self.brands = brandList
                self.isLoading = false
                self.loadingTask = nil
                
                print("FragranceService: SUCCESS - Loaded \(loadedFragrances.count) fragrances, \(brandList.count) brands")
            } catch {
                self.error = error
                self.isLoading = false
                self.loadingTask = nil
                print("FragranceService: ERROR - \(error)")
            }
        }
        
        loadingTask = task
        await task.value
    }
    
    private func buildIndexes() {
        // Build ID index - use reduce to handle duplicates (last one wins)
        fragranceById = fragrances.reduce(into: [:]) { dict, fragrance in
            dict[fragrance.id] = fragrance
        }
        
        // Build brand index
        fragrancesByBrand = Dictionary(grouping: fragrances, by: { $0.brand })
        
        // Extract unique brands sorted alphabetically
        brands = fragrancesByBrand.keys.sorted()
    }
    
    // MARK: - Lookups
    
    func fragrance(byId id: String) -> Fragrance? {
        fragranceById[id]
    }
    
    func fragrances(byBrand brand: String) -> [Fragrance] {
        fragrancesByBrand[brand] ?? []
    }
    
    func fragrances(byIds ids: [String]) -> [Fragrance] {
        ids.compactMap { fragranceById[$0] }
    }
    
    // MARK: - Search
    
    func search(query: String) -> [Fragrance] {
        guard !query.isEmpty else { return [] }
        
        let lowercasedQuery = query.lowercased()
        
        return fragrances.filter { fragrance in
            fragrance.name.lowercased().contains(lowercasedQuery) ||
            fragrance.brand.lowercased().contains(lowercasedQuery) ||
            fragrance.displayBrand.lowercased().contains(lowercasedQuery)
        }
    }
    
    func searchByNotes(notes: [String]) -> [Fragrance] {
        guard !notes.isEmpty else { return [] }
        
        let lowercasedNotes = notes.map { $0.lowercased() }
        
        return fragrances.filter { fragrance in
            guard let fragranceNotes = fragrance.notes else { return false }
            let allNotes = fragranceNotes.allNotes.map { $0.lowercased() }
            return lowercasedNotes.allSatisfy { note in
                allNotes.contains { $0.contains(note) }
            }
        }
    }
    
    // MARK: - Discovery Queue
    
    // Single gender filter
    func getDiscoveryQueue(excluding seenIds: Set<String>, limit: Int = 50, gender: FragranceGender = .all) -> [Fragrance] {
        fragrances
            .filter { !seenIds.contains($0.id) }
            .filter { $0.matchesGender(gender) }
            .shuffled()
            .prefix(limit)
            .map { $0 }
    }
    
    // Multi-select gender filter
    func getDiscoveryQueue(excluding seenIds: Set<String>, limit: Int = 50, genders: Set<FragranceGender>) -> [Fragrance] {
        fragrances
            .filter { !seenIds.contains($0.id) }
            .filter { $0.matchesGenders(genders) }
            .shuffled()
            .prefix(limit)
            .map { $0 }
    }
    
    // Search with gender filter
    func search(query: String, genders: Set<FragranceGender>) -> [Fragrance] {
        guard !query.isEmpty else { return [] }
        
        let lowercasedQuery = query.lowercased()
        
        return fragrances.filter { fragrance in
            let matchesQuery = fragrance.name.lowercased().contains(lowercasedQuery) ||
                fragrance.brand.lowercased().contains(lowercasedQuery) ||
                fragrance.displayBrand.lowercased().contains(lowercasedQuery)
            return matchesQuery && fragrance.matchesGenders(genders)
        }
    }
    
    // Get random fragrances for initial display
    func getRandomFragrances(count: Int = 10) -> [Fragrance] {
        Array(fragrances.shuffled().prefix(count))
    }
}

enum FragranceServiceError: LocalizedError {
    case fileNotFound
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Fragrance database file not found"
        case .decodingFailed:
            return "Failed to decode fragrance database"
        }
    }
}

