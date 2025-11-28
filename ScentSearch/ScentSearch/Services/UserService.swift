//
//  UserService.swift
//  ScentSearch
//
//  Service for managing user profiles and collections
//

import Foundation
import SwiftUI

@Observable
class UserService {
    static let shared = UserService()
    
    private(set) var currentProfile: UserProfile?
    private(set) var isLoading = false
    
    private let profileKey = "userProfile"
    
    private init() {
        loadLocalProfile()
        // Auto-create local profile if none exists
        ensureProfileExists()
    }
    
    // MARK: - Profile Management
    
    private func loadLocalProfile() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentProfile = profile
        }
    }
    
    private func ensureProfileExists() {
        if currentProfile == nil {
            createLocalGuestProfile()
        }
    }
    
    private func createLocalGuestProfile() {
        let profile = UserProfile(
            id: "local-\(UUID().uuidString)",
            email: "guest@local",
            displayName: "Guest"
        )
        currentProfile = profile
        saveLocalProfile()
    }
    
    private func saveLocalProfile() {
        guard let profile = currentProfile else { return }
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }
    
    func createUserProfile(for user: AuthUser) async throws {
        let profile = UserProfile(
            id: user.id,
            email: user.email,
            displayName: user.displayName
        )
        
        await MainActor.run {
            self.currentProfile = profile
            self.saveLocalProfile()
        }
    }
    
    func loadOrCreateUserProfile(for user: AuthUser) async throws {
        // Check if profile exists locally
        if let profile = currentProfile, profile.id == user.id {
            return
        }
        
        // Create new profile
        try await createUserProfile(for: user)
    }
    
    func clearCurrentProfile() {
        currentProfile = nil
        UserDefaults.standard.removeObject(forKey: profileKey)
    }
    
    func updateDisplayName(_ name: String) {
        currentProfile?.displayName = name
        currentProfile?.updatedAt = Date()
        saveLocalProfile()
    }
    
    // MARK: - Collection Management
    
    func addToCollection(_ fragranceId: String) {
        guard var profile = currentProfile else { return }
        
        if !profile.collection.contains(fragranceId) {
            profile.collection.append(fragranceId)
            // Remove from wishlist if present
            profile.wishlist.removeAll { $0 == fragranceId }
            profile.updatedAt = Date()
            currentProfile = profile
            saveLocalProfile()
        }
    }
    
    func removeFromCollection(_ fragranceId: String) {
        guard var profile = currentProfile else { return }
        
        profile.collection.removeAll { $0 == fragranceId }
        // Also remove from top 5 and signature if present
        profile.topFive.removeAll { $0 == fragranceId }
        if profile.signatureScent == fragranceId {
            profile.signatureScent = nil
        }
        profile.updatedAt = Date()
        currentProfile = profile
        saveLocalProfile()
    }
    
    // MARK: - Wishlist Management
    
    func addToWishlist(_ fragranceId: String) {
        guard var profile = currentProfile else { return }
        
        // Don't add if already owned
        guard !profile.collection.contains(fragranceId) else { return }
        
        if !profile.wishlist.contains(fragranceId) {
            profile.wishlist.append(fragranceId)
            profile.updatedAt = Date()
            currentProfile = profile
            saveLocalProfile()
        }
    }
    
    func removeFromWishlist(_ fragranceId: String) {
        guard var profile = currentProfile else { return }
        
        profile.wishlist.removeAll { $0 == fragranceId }
        profile.updatedAt = Date()
        currentProfile = profile
        saveLocalProfile()
    }
    
    func clearWishlist() {
        guard var profile = currentProfile else { return }
        profile.wishlist.removeAll()
        profile.updatedAt = Date()
        currentProfile = profile
        saveLocalProfile()
    }
    
    func clearCollection() {
        guard var profile = currentProfile else { return }
        profile.collection.removeAll()
        profile.topFive.removeAll()
        profile.signatureScent = nil
        profile.updatedAt = Date()
        currentProfile = profile
        saveLocalProfile()
    }
    
    func clearPassedOn() {
        guard var profile = currentProfile else { return }
        profile.passedOn.removeAll()
        profile.updatedAt = Date()
        currentProfile = profile
        saveLocalProfile()
    }
    
    // MARK: - Discovery (Swiping)
    
    func passOnFragrance(_ fragranceId: String) {
        guard var profile = currentProfile else { return }
        
        if !profile.passedOn.contains(fragranceId) {
            profile.passedOn.append(fragranceId)
            profile.updatedAt = Date()
            currentProfile = profile
            saveLocalProfile()
        }
    }
    
    func getSeenFragranceIds() -> Set<String> {
        guard let profile = currentProfile else { return [] }
        return Set(profile.collection + profile.wishlist + profile.passedOn)
    }
    
    // MARK: - Signature & Top 5
    
    func setSignatureScent(_ fragranceId: String?) {
        guard var profile = currentProfile else { return }
        
        // Must be in collection to be signature
        if let id = fragranceId {
            guard profile.collection.contains(id) else { return }
        }
        
        profile.signatureScent = fragranceId
        profile.updatedAt = Date()
        currentProfile = profile
        saveLocalProfile()
    }
    
    func addToTopFive(_ fragranceId: String) {
        guard var profile = currentProfile else { return }
        
        // Must be in collection
        guard profile.collection.contains(fragranceId) else { return }
        
        // Can only have 5
        guard profile.topFive.count < 5 else { return }
        
        if !profile.topFive.contains(fragranceId) {
            profile.topFive.append(fragranceId)
            profile.updatedAt = Date()
            currentProfile = profile
            saveLocalProfile()
        }
    }
    
    func removeFromTopFive(_ fragranceId: String) {
        guard var profile = currentProfile else { return }
        
        profile.topFive.removeAll { $0 == fragranceId }
        profile.updatedAt = Date()
        currentProfile = profile
        saveLocalProfile()
    }
    
    func reorderTopFive(_ fragranceIds: [String]) {
        guard var profile = currentProfile else { return }
        
        // Validate all IDs are in collection and list is <= 5
        let validIds = fragranceIds.filter { profile.collection.contains($0) }.prefix(5)
        profile.topFive = Array(validIds)
        profile.updatedAt = Date()
        currentProfile = profile
        saveLocalProfile()
    }
    
    // MARK: - Helpers
    
    func isInCollection(_ fragranceId: String) -> Bool {
        currentProfile?.collection.contains(fragranceId) ?? false
    }
    
    func isInWishlist(_ fragranceId: String) -> Bool {
        currentProfile?.wishlist.contains(fragranceId) ?? false
    }
    
    func isSignatureScent(_ fragranceId: String) -> Bool {
        currentProfile?.signatureScent == fragranceId
    }
    
    func isInTopFive(_ fragranceId: String) -> Bool {
        currentProfile?.topFive.contains(fragranceId) ?? false
    }
}

