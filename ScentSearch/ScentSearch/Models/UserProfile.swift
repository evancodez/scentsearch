//
//  UserProfile.swift
//  ScentSearch
//
//  User profile model for Firestore
//

import Foundation

struct UserProfile: Codable, Identifiable {
    let id: String
    var email: String
    var displayName: String?
    var avatarUrl: String?
    var signatureScent: String? // fragrance ID
    var topFive: [String] // fragrance IDs
    var collection: [String] // fragrance IDs
    var wishlist: [String] // fragrance IDs
    var passedOn: [String] // fragrances swiped left
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String,
        email: String,
        displayName: String? = nil,
        avatarUrl: String? = nil,
        signatureScent: String? = nil,
        topFive: [String] = [],
        collection: [String] = [],
        wishlist: [String] = [],
        passedOn: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.signatureScent = signatureScent
        self.topFive = topFive
        self.collection = collection
        self.wishlist = wishlist
        self.passedOn = passedOn
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Stats computed properties
    var collectionCount: Int { collection.count }
    var wishlistCount: Int { wishlist.count }
    
    // Check if a fragrance is in collection
    func ownsFragrance(_ fragranceId: String) -> Bool {
        collection.contains(fragranceId)
    }
    
    // Check if a fragrance is in wishlist
    func wantsFragrance(_ fragranceId: String) -> Bool {
        wishlist.contains(fragranceId)
    }
    
    // Check if user has already seen this fragrance
    func hasSeenFragrance(_ fragranceId: String) -> Bool {
        collection.contains(fragranceId) ||
        wishlist.contains(fragranceId) ||
        passedOn.contains(fragranceId)
    }
}

// Sample data for previews
extension UserProfile {
    static let sample = UserProfile(
        id: "sample-user-id",
        email: "user@example.com",
        displayName: "Fragrance Lover",
        signatureScent: "dior-sauvage-elixir",
        topFive: ["creed-aventus", "tom-ford-tobacco-vanille", "dior-sauvage-elixir"],
        collection: ["creed-aventus", "tom-ford-tobacco-vanille", "dior-sauvage-elixir", "bleu-de-chanel"],
        wishlist: ["roja-parfums-elysium", "parfums-de-marly-layton"]
    )
}

