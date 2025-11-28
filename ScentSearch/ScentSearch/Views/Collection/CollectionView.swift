//
//  CollectionView.swift
//  ScentSearch
//
//  Collection and wishlist tab with segmented control
//

import SwiftUI

struct CollectionView: View {
    @State private var selectedTab = 0
    @State private var userService = UserService.shared
    @State private var fragranceService = FragranceService.shared
    @State private var showingClearAlert = false
    
    private var hasItems: Bool {
        if selectedTab == 0 {
            return (userService.currentProfile?.collection.count ?? 0) > 0
        } else {
            return (userService.currentProfile?.wishlist.count ?? 0) > 0
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.scentBackground
                    .ignoresSafeArea()
                
                if fragranceService.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.scentAmber)
                            .scaleEffect(1.5)
                        Text("Loading fragrances...")
                            .font(.scentBody)
                            .foregroundColor(.scentTextSecondary)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Segmented Control
                        HStack(spacing: 0) {
                            SegmentButton(
                                title: "Collection",
                                count: userService.currentProfile?.collection.count ?? 0,
                                isSelected: selectedTab == 0
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = 0
                                }
                            }
                            
                            SegmentButton(
                                title: "Wishlist",
                                count: userService.currentProfile?.wishlist.count ?? 0,
                                isSelected: selectedTab == 1
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = 1
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Content
                        TabView(selection: $selectedTab) {
                            CollectionGridView()
                                .tag(0)
                            
                            WishlistGridView()
                                .tag(1)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                }
            }
            .navigationTitle(selectedTab == 0 ? "My Collection" : "Wishlist")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if hasItems {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                showingClearAlert = true
                            } label: {
                                Label(
                                    selectedTab == 0 ? "Clear Collection" : "Clear Wishlist",
                                    systemImage: "trash"
                                )
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.scentAmber)
                        }
                    }
                }
            }
            .alert(
                selectedTab == 0 ? "Clear Collection?" : "Clear Wishlist?",
                isPresented: $showingClearAlert
            ) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    if selectedTab == 0 {
                        userService.clearCollection()
                    } else {
                        userService.clearWishlist()
                    }
                }
            } message: {
                Text(selectedTab == 0 
                     ? "This will remove all fragrances from your collection. This cannot be undone."
                     : "This will remove all fragrances from your wishlist. This cannot be undone.")
            }
            .task {
                // Wait for fragrances to be loaded
                await fragranceService.loadFragrances()
            }
        }
    }
}

// MARK: - Segment Button

struct SegmentButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.scentHeadline)
                    
                    Text("\(count)")
                        .font(.scentCaption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.scentAmber : Color.scentTextMuted.opacity(0.3))
                        .foregroundColor(isSelected ? .scentBackground : .scentTextMuted)
                        .clipShape(Capsule())
                }
                .foregroundColor(isSelected ? .scentTextPrimary : .scentTextMuted)
                
                Rectangle()
                    .fill(isSelected ? Color.scentAmber : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Collection Grid

struct CollectionGridView: View {
    @State private var userService = UserService.shared
    @State private var fragranceService = FragranceService.shared
    @State private var sortOption: CollectionSortOption = .recent
    @State private var showingSortSheet = false
    
    enum CollectionSortOption: String, CaseIterable {
        case recent = "Recently Added"
        case name = "Name"
        case brand = "Brand"
    }
    
    private var fragrances: [Fragrance] {
        let ids = userService.currentProfile?.collection ?? []
        let unsorted = fragranceService.fragrances(byIds: ids)
        
        switch sortOption {
        case .recent:
            // Keep original order (most recent first)
            return ids.reversed().compactMap { id in unsorted.first { $0.id == id } }
        case .name:
            return unsorted.sorted { $0.name < $1.name }
        case .brand:
            return unsorted.sorted { $0.brand < $1.brand }
        }
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            if fragrances.isEmpty {
                EmptyCollectionView(type: .collection)
            } else {
                VStack(spacing: 16) {
                    // Sort Button
                    HStack {
                        Spacer()
                        
                        Button {
                            showingSortSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.arrow.down")
                                Text(sortOption.rawValue)
                            }
                            .font(.scentCaption)
                            .foregroundColor(.scentAmber)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.scentSurface)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                    
                    // Grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(fragrances) { fragrance in
                            NavigationLink(destination: FragranceDetailView(fragrance: fragrance)) {
                                FragranceGridItem(
                                    fragrance: fragrance,
                                    showBadge: getBadge(for: fragrance)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 16)
            }
        }
        .confirmationDialog("Sort By", isPresented: $showingSortSheet) {
            ForEach(CollectionSortOption.allCases, id: \.self) { option in
                Button(option.rawValue) {
                    withAnimation {
                        sortOption = option
                    }
                }
            }
        }
    }
    
    private func getBadge(for fragrance: Fragrance) -> FragranceGridItem.BadgeType? {
        if userService.isSignatureScent(fragrance.id) {
            return .signature
        } else if let index = userService.currentProfile?.topFive.firstIndex(of: fragrance.id) {
            return .topFive(index + 1)
        }
        return nil
    }
}

// MARK: - Wishlist Grid

struct WishlistGridView: View {
    @State private var userService = UserService.shared
    @State private var fragranceService = FragranceService.shared
    
    private var fragrances: [Fragrance] {
        let ids = userService.currentProfile?.wishlist ?? []
        return ids.reversed().compactMap { id in fragranceService.fragrance(byId: id) }
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            if fragrances.isEmpty {
                EmptyCollectionView(type: .wishlist)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(fragrances) { fragrance in
                        WishlistGridItem(fragrance: fragrance)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }
        }
    }
}

// MARK: - Wishlist Grid Item

struct WishlistGridItem: View {
    let fragrance: Fragrance
    @State private var userService = UserService.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // Tappable image area that navigates
            NavigationLink(destination: FragranceDetailView(fragrance: fragrance)) {
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: fragrance.imageUrl ?? "")) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.scentSurfaceLight)
                                .overlay(ProgressView().tint(.scentAmber))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.scentSurfaceLight)
                                .overlay(
                                    Image(systemName: "drop.fill")
                                        .foregroundColor(.scentAmber.opacity(0.5))
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 140)
                    
                    // Heart badge
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.scentWishlist)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .padding(6)
                }
            }
            .buttonStyle(.plain)
            
            VStack(spacing: 2) {
                Text(fragrance.displayBrand)
                    .font(.scentCaption2)
                    .foregroundColor(.scentAmber)
                    .lineLimit(1)
                
                Text(fragrance.name)
                    .font(.scentCaption)
                    .foregroundColor(.scentTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            
            // Quick Actions (separate from navigation)
            HStack(spacing: 8) {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    userService.addToCollection(fragrance.id)
                } label: {
                    Text("Own It")
                        .font(.scentCaption2)
                        .foregroundColor(.scentOwned)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.scentOwned.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                Button {
                    userService.removeFromWishlist(fragrance.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundColor(.scentTextMuted)
                        .padding(6)
                        .background(Color.scentSurfaceLight)
                        .clipShape(Circle())
                }
            }
        }
        .padding(10)
        .background(Color.scentCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Empty State

struct EmptyCollectionView: View {
    enum EmptyType {
        case collection
        case wishlist
    }
    
    let type: EmptyType
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: type == .collection ? "square.grid.2x2" : "heart")
                .font(.system(size: 50))
                .foregroundStyle(LinearGradient.scentGoldGradient)
            
            VStack(spacing: 8) {
                Text(type == .collection ? "No Fragrances Yet" : "Wishlist Empty")
                    .font(.scentTitle3)
                    .foregroundColor(.scentTextPrimary)
                
                Text(type == .collection 
                     ? "Start building your collection by discovering new fragrances!"
                     : "Swipe right on fragrances you want to add them here!")
                    .font(.scentBody)
                    .foregroundColor(.scentTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

#Preview {
    CollectionView()
        .preferredColorScheme(.dark)
}

