//
//  ScentSearchApp.swift
//  ScentSearch
//
//  Main app entry point
//

import SwiftUI

@main
struct ScentSearchApp: App {
    @State private var authService = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                } else {
                    AuthContainerView()
                }
            }
            .preferredColorScheme(.dark)
            .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
        }
    }
}
