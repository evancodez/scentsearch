//
//  ContentView.swift
//  ScentSearch
//
//  Main content view with tab navigation
//

import SwiftUI

// Environment key for tab selection
struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

extension EnvironmentValues {
    var selectedTab: Binding<Int> {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}

// Tab indices
enum AppTab: Int {
    case discover = 0
    case search = 1
    case collection = 2
    case profile = 3
}

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var fragranceService = FragranceService.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "flame.fill")
                }
                .tag(AppTab.discover.rawValue)
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(AppTab.search.rawValue)
            
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "square.grid.2x2.fill")
                }
                .tag(AppTab.collection.rawValue)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(AppTab.profile.rawValue)
        }
        .tint(.scentAmber)
        .environment(\.selectedTab, $selectedTab)
        .task {
            await fragranceService.loadFragrances()
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
