//
//  LoginView.swift
//  ScentSearch
//
//  Login screen with email and Apple Sign In
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Binding var showSignUp: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var authService = AuthService.shared
    
    init(showSignUp: Binding<Bool>) {
        self._showSignUp = showSignUp
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 60)
                
                // Logo and Title
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.scentGoldGradient)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "drop.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.scentBackground)
                    }
                    
                    VStack(spacing: 8) {
                        Text("ScentSearch")
                            .font(.scentLargeTitle)
                            .foregroundColor(.scentTextPrimary)
                        
                        Text("Discover your signature scent")
                            .font(.scentBody)
                            .foregroundColor(.scentTextSecondary)
                    }
                }
                
                // Login Form
                VStack(spacing: 16) {
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
                                .textContentType(.password)
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
                    
                    // Forgot Password
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            // TODO: Implement password reset
                        }
                        .font(.scentCaption)
                        .foregroundColor(.scentAmber)
                    }
                }
                .padding(.horizontal, 24)
                
                // Buttons
                VStack(spacing: 16) {
                    // Sign In Button
                    Button {
                        signIn()
                    } label: {
                        if authService.isLoading {
                            ProgressView()
                                .tint(.scentBackground)
                        } else {
                            Text("Sign In")
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
                
                // Sign Up Link
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundColor(.scentTextSecondary)
                    
                    Button("Sign Up") {
                        showSignUp = true
                    }
                    .foregroundColor(.scentAmber)
                    .fontWeight(.semibold)
                }
                .font(.scentCallout)
                .padding(.bottom, 32)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func signIn() {
        Task {
            do {
                try await authService.signIn(email: email, password: password)
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
    AuthContainerView()
}

