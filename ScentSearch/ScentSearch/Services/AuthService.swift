//
//  AuthService.swift
//  ScentSearch
//
//  Authentication service using Firebase Auth
//

import Foundation
import SwiftUI
import AuthenticationServices

@Observable
class AuthService {
    static let shared = AuthService()
    
    private(set) var currentUser: AuthUser?
    private(set) var isAuthenticated = false
    private(set) var isLoading = false
    private(set) var error: AuthError?
    
    // For Apple Sign In
    private var currentNonce: String?
    
    private init() {
        // Check for existing session
        checkExistingSession()
    }
    
    // MARK: - Session Management
    
    private func checkExistingSession() {
        // Check UserDefaults for saved session (for MVP without Firebase)
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(AuthUser.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    private func saveSession(_ user: AuthUser) {
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        self.currentUser = user
        self.isAuthenticated = true
    }
    
    // MARK: - Email Authentication
    
    func signUp(email: String, password: String, displayName: String?) async throws {
        await MainActor.run { isLoading = true }
        
        // Validate inputs
        guard isValidEmail(email) else {
            await MainActor.run { isLoading = false }
            throw AuthError.invalidEmail
        }
        
        guard password.count >= 6 else {
            await MainActor.run { isLoading = false }
            throw AuthError.weakPassword
        }
        
        // Simulate network delay for MVP
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Create user with deterministic ID based on email to preserve data
        let deterministicId = email.lowercased().data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
        
        let user = AuthUser(
            id: deterministicId,
            email: email,
            displayName: displayName,
            provider: .email
        )
        
        await MainActor.run {
            saveSession(user)
            isLoading = false
        }
        
        // Create user profile
        try await UserService.shared.createUserProfile(for: user)
    }
    
    func signIn(email: String, password: String) async throws {
        await MainActor.run { isLoading = true }
        
        guard isValidEmail(email) else {
            await MainActor.run { isLoading = false }
            throw AuthError.invalidEmail
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // For MVP, use a deterministic ID based on email to preserve data across sessions
        // This ensures the same email always gets the same user ID
        let deterministicId = email.lowercased().data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
        
        let user = AuthUser(
            id: deterministicId,
            email: email,
            displayName: nil,
            provider: .email
        )
        
        await MainActor.run {
            saveSession(user)
            isLoading = false
        }
        
        // Load or create user profile
        try await UserService.shared.loadOrCreateUserProfile(for: user)
    }
    
    // MARK: - Apple Sign In
    
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async throws {
        await MainActor.run { isLoading = true }
        
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                await MainActor.run { isLoading = false }
                throw AuthError.invalidCredential
            }
            
            let userId = appleIDCredential.user
            let email = appleIDCredential.email ?? "\(userId)@privaterelay.appleid.com"
            let fullName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            let user = AuthUser(
                id: userId,
                email: email,
                displayName: fullName.isEmpty ? nil : fullName,
                provider: .apple
            )
            
            await MainActor.run {
                saveSession(user)
                isLoading = false
            }
            
            try await UserService.shared.loadOrCreateUserProfile(for: user)
            
        case .failure(let error):
            await MainActor.run { isLoading = false }
            throw AuthError.appleSignInFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
        currentUser = nil
        isAuthenticated = false
        UserService.shared.clearCurrentProfile()
    }
    
    // MARK: - Helpers
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}

// MARK: - Models

struct AuthUser: Codable {
    let id: String
    let email: String
    var displayName: String?
    let provider: AuthProvider
}

enum AuthProvider: String, Codable {
    case email
    case apple
}

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case invalidCredential
    case userNotFound
    case networkError
    case appleSignInFailed(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 6 characters"
        case .invalidCredential:
            return "Invalid credentials"
        case .userNotFound:
            return "No account found with this email"
        case .networkError:
            return "Network error. Please try again"
        case .appleSignInFailed(let message):
            return "Apple Sign In failed: \(message)"
        case .unknown(let message):
            return message
        }
    }
}

