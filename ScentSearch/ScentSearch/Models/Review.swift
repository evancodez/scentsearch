//
//  Review.swift
//  ScentSearch
//
//  Review model for fragrance reviews stored in Firestore
//

import Foundation

struct Review: Codable, Identifiable {
    let id: String
    let fragranceId: String
    let userId: String
    var userDisplayName: String?
    var rating: Int // 1-5 stars
    var title: String?
    var text: String?
    var longevity: Int? // 1-10 hours
    var sillage: Int? // 1-5 (intimate to beast mode)
    var seasonalRating: SeasonalRating?
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        fragranceId: String,
        userId: String,
        userDisplayName: String? = nil,
        rating: Int,
        title: String? = nil,
        text: String? = nil,
        longevity: Int? = nil,
        sillage: Int? = nil,
        seasonalRating: SeasonalRating? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.fragranceId = fragranceId
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.rating = min(5, max(1, rating)) // Clamp to 1-5
        self.title = title
        self.text = text
        self.longevity = longevity
        self.sillage = sillage
        self.seasonalRating = seasonalRating
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct SeasonalRating: Codable {
    var spring: Int // 1-5
    var summer: Int
    var fall: Int
    var winter: Int
    
    var bestSeason: String {
        let seasons = [("Spring", spring), ("Summer", summer), ("Fall", fall), ("Winter", winter)]
        return seasons.max(by: { $0.1 < $1.1 })?.0 ?? "All Year"
    }
}

// Sample data for previews
extension Review {
    static let sample = Review(
        id: "sample-review-1",
        fragranceId: "dior-sauvage-elixir",
        userId: "sample-user-id",
        userDisplayName: "Fragrance Lover",
        rating: 5,
        title: "Incredible Beast Mode Fragrance",
        text: "This is hands down the best fragrance I've ever owned. The performance is insane - easily lasts 12+ hours. The spicy, boozy opening settles into this rich, ambery dry down that gets compliments everywhere.",
        longevity: 10,
        sillage: 5,
        seasonalRating: SeasonalRating(spring: 3, summer: 2, fall: 5, winter: 5)
    )
    
    static let samples: [Review] = [
        sample,
        Review(
            id: "sample-review-2",
            fragranceId: "dior-sauvage-elixir",
            userId: "user-2",
            userDisplayName: "Cologne Collector",
            rating: 4,
            title: "Great but Strong",
            text: "Amazing scent but be careful with the sprays. 2-3 is more than enough.",
            longevity: 8,
            sillage: 4
        )
    ]
}

