//
//  AuthContainerView.swift
//  ScentSearch
//
//  Container for authentication flow
//

import SwiftUI

struct AuthContainerView: View {
    @State private var showSignUp = false
    
    var body: some View {
        ZStack {
            // Background
            Color.scentBackground
                .ignoresSafeArea()
            
            // Decorative gradient orbs
            GeometryReader { geometry in
                Circle()
                    .fill(Color.scentAmber.opacity(0.15))
                    .blur(radius: 100)
                    .frame(width: 300, height: 300)
                    .offset(x: -50, y: -100)
                
                Circle()
                    .fill(Color.scentGold.opacity(0.1))
                    .blur(radius: 80)
                    .frame(width: 200, height: 200)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height - 200)
            }
            
            if showSignUp {
                SignUpView(showSignUp: $showSignUp)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
            } else {
                LoginView(showSignUp: $showSignUp)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSignUp)
    }
}

#Preview {
    AuthContainerView()
}

