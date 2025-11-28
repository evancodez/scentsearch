//
//  Fragrance.swift
//  ScentSearch
//
//  Data model for fragrances from the local database
//

import Foundation

struct FragranceNotes: Codable, Hashable {
    let top: [String]?
    let middle: [String]?
    let base: [String]?
    
    var allNotes: [String] {
        (top ?? []) + (middle ?? []) + (base ?? [])
    }
}

// Gender categories for fragrances
enum FragranceGender: String, Codable, CaseIterable {
    case all = "All"
    case mens = "Men's"
    case womens = "Women's"
    case unisex = "Unisex"
    
    var icon: String {
        switch self {
        case .all: return "person.2.fill"
        case .mens: return "figure.stand"
        case .womens: return "figure.stand.dress"
        case .unisex: return "figure.2"
        }
    }
}

struct Fragrance: Codable, Identifiable, Hashable {
    let brand: String
    let name: String
    let notes: FragranceNotes?
    let year: String?
    let imageUrl: String?
    let gender: String? // "men", "women", "unisex" - optional in database
    
    // Computed stable ID based on brand + name + year + image URL
    // Using a deterministic approach that survives app relaunches
    var id: String {
        let brandPart = brand.lowercased().replacingOccurrences(of: " ", with: "-")
        let namePart = name.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\"", with: "")
        let yearPart = year ?? "0"
        // Use last part of image URL (the filename) for uniqueness instead of unstable hashValue
        let imagePart = imageUrl?.components(separatedBy: "/").last?.replacingOccurrences(of: ".jpg", with: "") ?? "0"
        return "\(brandPart)_\(namePart)_\(yearPart)_\(imagePart)"
    }
    
    // Display-friendly brand name
    var displayBrand: String {
        brand.replacingOccurrences(of: "-", with: " ").capitalized
    }
    
    // Get gender category - returns nil if no gender data (for proper filtering)
    var genderCategory: FragranceGender? {
        guard let g = gender?.lowercased() else { return nil }
        switch g {
        case "men", "male", "him", "homme": return .mens
        case "women", "female", "her", "femme": return .womens
        case "unisex", "shared": return .unisex
        default: return nil
        }
    }
    
    // Check if fragrance matches a single gender filter
    func matchesGender(_ filter: FragranceGender) -> Bool {
        // "All" always matches
        if filter == .all { return true }
        // If no gender data, show in all categories (don't hide fragrances)
        guard let category = genderCategory else { return true }
        return category == filter
    }
    
    // Check if fragrance matches any of the selected gender filters (multi-select)
    func matchesGenders(_ filters: Set<FragranceGender>) -> Bool {
        // Empty set or "All" selected = show everything
        if filters.isEmpty || filters.contains(.all) { return true }
        // If no gender data, show in all categories
        guard let category = genderCategory else { return true }
        // Check if fragrance's gender matches any selected filter
        return filters.contains(category)
    }
    
    enum CodingKeys: String, CodingKey {
        case brand
        case name
        case notes
        case year
        case imageUrl = "image_url"
        case gender
    }
}

// Extension for sample data in previews
extension Fragrance {
    static let sample = Fragrance(
        brand: "dior",
        name: "Sauvage Elixir",
        notes: FragranceNotes(
            top: ["cinnamon", "cardamom", "grapefruit"],
            middle: ["lavender", "nutmeg"],
            base: ["amber", "sandalwood", "licorice"]
        ),
        year: "2021",
        imageUrl: "https://fimgs.net/mdimg/perfume-thumbs/375x500.69027.jpg",
        gender: "men"
    )
    
    static let samples: [Fragrance] = [
        sample,
        Fragrance(
            brand: "creed",
            name: "Aventus",
            notes: FragranceNotes(
                top: ["pineapple", "bergamot", "apple", "blackcurrant"],
                middle: ["jasmine", "rose", "birch"],
                base: ["musk", "oakmoss", "ambergris", "vanilla"]
            ),
            year: "2010",
            imageUrl: "https://fimgs.net/mdimg/perfume-thumbs/375x500.9828.jpg",
            gender: "men"
        ),
        Fragrance(
            brand: "tom-ford",
            name: "Tobacco Vanille",
            notes: FragranceNotes(
                top: ["tobacco leaf", "spicy notes"],
                middle: ["vanilla", "cacao", "tonka bean"],
                base: ["dried fruits", "woody notes"]
            ),
            year: "2007",
            imageUrl: "https://fimgs.net/mdimg/perfume-thumbs/375x500.1825.jpg",
            gender: "unisex"
        )
    ]
}

