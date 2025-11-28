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
    
    // Index for faster lookups
    private var fragranceById: [String: Fragrance] = [:]
    private var fragrancesByBrand: [String: [Fragrance]] = [:]
    
    private init() {}
    
    // MARK: - Loading
    
    func loadFragrances() async {
        guard fragrances.isEmpty else { return }
        
        await MainActor.run { isLoading = true }
        
        do {
            guard let url = Bundle.main.url(forResource: "fragrance_database", withExtension: "json") else {
                throw FragranceServiceError.fileNotFound
            }
            
            // Load and decode on background thread
            let loadedFragrances: [Fragrance] = try await Task.detached(priority: .userInitiated) {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                return try decoder.decode([Fragrance].self, from: data)
            }.value
            
            // Build indexes on background thread
            let (idIndex, brandIndex, brandList) = await Task.detached(priority: .userInitiated) {
                let idIndex = loadedFragrances.reduce(into: [String: Fragrance]()) { dict, fragrance in
                    dict[fragrance.id] = fragrance
                }
                let brandIndex = Dictionary(grouping: loadedFragrances, by: { $0.brand })
                let brandList = brandIndex.keys.sorted()
                return (idIndex, brandIndex, brandList)
            }.value
            
            await MainActor.run {
                self.fragrances = loadedFragrances
                self.fragranceById = idIndex
                self.fragrancesByBrand = brandIndex
                self.brands = brandList
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
            print("Error loading fragrances: \(error)")
        }
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
    
    func getDiscoveryQueue(excluding seenIds: Set<String>, limit: Int = 50, gender: FragranceGender = .all) -> [Fragrance] {
        fragrances
            .filter { !seenIds.contains($0.id) }
            .filter { $0.matchesGender(gender) }
            .shuffled()
            .prefix(limit)
            .map { $0 }
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

