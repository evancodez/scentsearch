//
//  ReviewService.swift
//  ScentSearch
//
//  Service for managing fragrance reviews
//

import Foundation
import SwiftUI

@Observable
class ReviewService {
    static let shared = ReviewService()
    
    private(set) var reviews: [Review] = []
    private(set) var isLoading = false
    
    // Grouped by fragrance ID for quick lookup
    private var reviewsByFragrance: [String: [Review]] = [:]
    
    private let reviewsKey = "userReviews"
    
    private init() {
        loadLocalReviews()
    }
    
    // MARK: - Local Storage
    
    private func loadLocalReviews() {
        if let data = UserDefaults.standard.data(forKey: reviewsKey),
           let loadedReviews = try? JSONDecoder().decode([Review].self, from: data) {
            reviews = loadedReviews
            buildIndex()
        }
    }
    
    private func saveLocalReviews() {
        if let data = try? JSONEncoder().encode(reviews) {
            UserDefaults.standard.set(data, forKey: reviewsKey)
        }
    }
    
    private func buildIndex() {
        reviewsByFragrance = Dictionary(grouping: reviews, by: { $0.fragranceId })
    }
    
    // MARK: - CRUD Operations
    
    func createReview(
        fragranceId: String,
        rating: Int,
        title: String? = nil,
        text: String? = nil,
        longevity: Int? = nil,
        sillage: Int? = nil,
        seasonalRating: SeasonalRating? = nil
    ) async throws {
        guard let user = AuthService.shared.currentUser else {
            throw ReviewError.notAuthenticated
        }
        
        await MainActor.run { isLoading = true }
        
        // Check if user already reviewed this fragrance
        if let existingIndex = reviews.firstIndex(where: { 
            $0.fragranceId == fragranceId && $0.userId == user.id 
        }) {
            // Update existing review
            var updatedReview = reviews[existingIndex]
            updatedReview.rating = rating
            updatedReview.title = title
            updatedReview.text = text
            updatedReview.longevity = longevity
            updatedReview.sillage = sillage
            updatedReview.seasonalRating = seasonalRating
            updatedReview.updatedAt = Date()
            
            await MainActor.run {
                reviews[existingIndex] = updatedReview
                buildIndex()
                saveLocalReviews()
                isLoading = false
            }
        } else {
            // Create new review
            let review = Review(
                fragranceId: fragranceId,
                userId: user.id,
                userDisplayName: user.displayName ?? "Anonymous",
                rating: rating,
                title: title,
                text: text,
                longevity: longevity,
                sillage: sillage,
                seasonalRating: seasonalRating
            )
            
            await MainActor.run {
                reviews.append(review)
                buildIndex()
                saveLocalReviews()
                isLoading = false
            }
        }
    }
    
    func deleteReview(_ reviewId: String) async throws {
        guard let user = AuthService.shared.currentUser else {
            throw ReviewError.notAuthenticated
        }
        
        guard let index = reviews.firstIndex(where: { $0.id == reviewId }) else {
            throw ReviewError.reviewNotFound
        }
        
        // Can only delete own reviews
        guard reviews[index].userId == user.id else {
            throw ReviewError.unauthorized
        }
        
        await MainActor.run {
            reviews.remove(at: index)
            buildIndex()
            saveLocalReviews()
        }
    }
    
    // MARK: - Queries
    
    func getReviews(for fragranceId: String) -> [Review] {
        reviewsByFragrance[fragranceId] ?? []
    }
    
    func getAverageRating(for fragranceId: String) -> Double? {
        let fragranceReviews = getReviews(for: fragranceId)
        guard !fragranceReviews.isEmpty else { return nil }
        
        let sum = fragranceReviews.reduce(0) { $0 + $1.rating }
        return Double(sum) / Double(fragranceReviews.count)
    }
    
    func getUserReview(for fragranceId: String) -> Review? {
        guard let userId = AuthService.shared.currentUser?.id else { return nil }
        return reviews.first { $0.fragranceId == fragranceId && $0.userId == userId }
    }
    
    func getUserReviews() -> [Review] {
        guard let userId = AuthService.shared.currentUser?.id else { return [] }
        return reviews.filter { $0.userId == userId }
    }
    
    func getReviewCount(for fragranceId: String) -> Int {
        reviewsByFragrance[fragranceId]?.count ?? 0
    }
}

enum ReviewError: LocalizedError {
    case notAuthenticated
    case reviewNotFound
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to review"
        case .reviewNotFound:
            return "Review not found"
        case .unauthorized:
            return "You can only delete your own reviews"
        }
    }
}

