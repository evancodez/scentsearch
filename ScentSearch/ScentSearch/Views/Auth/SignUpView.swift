//
//  SignUpView.swift
//  ScentSearch
//
//  Sign up screen
//

import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @Binding var showSignUp: Bool
    
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var authService = AuthService.shared
    
    init(showSignUp: Binding<Bool>) {
        self._showSignUp = showSignUp
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header
                HStack {
                    Button {
                        showSignUp = false
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.scentTextPrimary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Title
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.scentTitle)
                        .foregroundColor(.scentTextPrimary)
                    
                    Text("Join the fragrance community")
                        .font(.scentBody)
                        .foregroundColor(.scentTextSecondary)
                }
                .padding(.top, 20)
                
                // Form
                VStack(spacing: 16) {
                    // Display Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.scentCaption)
                            .foregroundColor(.scentTextSecondary)
                        
                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(.scentTextMuted)
                            
                            TextField("", text: $displayName)
                                .textContentType(.name)
                                .foregroundColor(.scentTextPrimary)
                        }
                        .padding()
                        .background(Color.scentSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.scentTextMuted.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.scentCaption)
                            .foregroundColor(.scentTextSecondary)
                        
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.scentTextMuted)
                            
                            TextField("", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .foregroundColor(.scentTextPrimary)
                        }
                        .padding()
                        .background(Color.scentSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.scentTextMuted.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.scentCaption)
                            .foregroundColor(.scentTextSecondary)
                        
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.scentTextMuted)
                            
                            SecureField("", text: $password)
                                .textContentType(.newPassword)
                                .foregroundColor(.scentTextPrimary)
                        }
                        .padding()
                        .background(Color.scentSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.scentTextMuted.opacity(0.3), lineWidth: 1)
                        )
                        
                        if !password.isEmpty && password.count < 6 {
                            Text("Password must be at least 6 characters")
                                .font(.scentCaption2)
                                .foregroundColor(.scentWishlist)
                        }
                    }
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.scentCaption)
                            .foregroundColor(.scentTextSecondary)
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.scentTextMuted)
                            
                            SecureField("", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .foregroundColor(.scentTextPrimary)
                        }
                        .padding()
                        .background(Color.scentSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(passwordsMatch ? Color.scentTextMuted.opacity(0.3) : Color.scentWishlist, lineWidth: 1)
                        )
                        
                        if !confirmPassword.isEmpty && !passwordsMatch {
                            Text("Passwords don't match")
                                .font(.scentCaption2)
                                .foregroundColor(.scentWishlist)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Buttons
                VStack(spacing: 16) {
                    // Create Account Button
                    Button {
                        signUp()
                    } label: {
                        if authService.isLoading {
                            ProgressView()
                                .tint(.scentBackground)
                        } else {
                            Text("Create Account")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(isDisabled: !isFormValid))
                    .disabled(!isFormValid || authService.isLoading)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.scentTextMuted.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.scentCaption)
                            .foregroundColor(.scentTextMuted)
                        
                        Rectangle()
                            .fill(Color.scentTextMuted.opacity(0.3))
                            .frame(height: 1)
                    }
                    
                    // Apple Sign In
                    SignInWithAppleButton(
                        onRequest: configureAppleSignIn,
                        onCompletion: handleAppleSignIn
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 50)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var passwordsMatch: Bool {
        confirmPassword.isEmpty || password == confirmPassword
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        password.count >= 6 && 
        password == confirmPassword
    }
    
    private func signUp() {
        Task {
            do {
                try await authService.signUp(
                    email: email, 
                    password: password,
                    displayName: displayName.isEmpty ? nil : displayName
                )
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func configureAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        Task {
            do {
                try await authService.handleAppleSignIn(result: result)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    SignUpView(showSignUp: .constant(true))
        .background(Color.scentBackground)
}

