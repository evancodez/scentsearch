//
//  ProfileView.swift
//  ScentSearch
//
//  User profile with signature scent, top 5, and stats
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.selectedTab) var selectedTab
    @State private var authService = AuthService.shared
    @State private var userService = UserService.shared
    @State private var fragranceService = FragranceService.shared
    @State private var reviewService = ReviewService.shared
    
    @State private var showingSettings = false
    @State private var showingSignatureSelector = false
    @State private var showingTopFiveEditor = false
    @State private var showingReviews = false
    
    private var profile: UserProfile? {
        userService.currentProfile
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.scentBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Profile Header
                        ProfileHeader(
                            displayName: profile?.displayName ?? authService.currentUser?.email ?? "User",
                            email: profile?.email ?? ""
                        )
                        
                        // Stats - Now tappable
                        StatsRow(
                            collectionCount: profile?.collectionCount ?? 0,
                            wishlistCount: profile?.wishlistCount ?? 0,
                            reviewCount: reviewService.getUserReviews().count,
                            onCollectionTap: { selectedTab.wrappedValue = AppTab.collection.rawValue },
                            onWishlistTap: { selectedTab.wrappedValue = AppTab.collection.rawValue },
                            onReviewsTap: { showingReviews = true }
                        )
                        
                        // Signature Scent
                        SignatureScentSection(
                            fragrance: profile?.signatureScent.flatMap { fragranceService.fragrance(byId: $0) },
                            onSelect: { showingSignatureSelector = true }
                        )
                        
                        // Top 5
                        TopFiveSection(
                            fragrances: fragranceService.fragrances(byIds: profile?.topFive ?? []),
                            onEdit: { showingTopFiveEditor = true }
                        )
                        
                        // Recent Collection
                        RecentCollectionSection(
                            fragrances: getRecentCollection()
                        )
                        
                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.scentAmber)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingSignatureSelector) {
                SignatureSelectorView()
            }
            .sheet(isPresented: $showingTopFiveEditor) {
                TopFiveEditorView()
            }
            .sheet(isPresented: $showingReviews) {
                UserReviewsView()
            }
            .task {
                // Wait for fragrances to be loaded
                await fragranceService.loadFragrances()
            }
        }
    }
    
    private func getRecentCollection() -> [Fragrance] {
        let ids = Array((profile?.collection ?? []).suffix(6).reversed())
        return fragranceService.fragrances(byIds: ids)
    }
}

// MARK: - Profile Header

struct ProfileHeader: View {
    let displayName: String
    let email: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient.scentGoldGradient)
                    .frame(width: 90, height: 90)
                
                Text(String(displayName.prefix(1)).uppercased())
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.scentBackground)
            }
            
            VStack(spacing: 4) {
                Text(displayName)
                    .font(.scentTitle2)
                    .foregroundColor(.scentTextPrimary)
                
                Text(email)
                    .font(.scentCaption)
                    .foregroundColor(.scentTextMuted)
            }
        }
    }
}

// MARK: - Stats Row

struct StatsRow: View {
    let collectionCount: Int
    let wishlistCount: Int
    let reviewCount: Int
    var onCollectionTap: (() -> Void)?
    var onWishlistTap: (() -> Void)?
    var onReviewsTap: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 0) {
            StatItem(value: collectionCount, label: "Collection", icon: "drop.fill", action: onCollectionTap)
            
            Divider()
                .frame(height: 40)
                .background(Color.scentTextMuted.opacity(0.3))
            
            StatItem(value: wishlistCount, label: "Wishlist", icon: "heart.fill", action: onWishlistTap)
            
            Divider()
                .frame(height: 40)
                .background(Color.scentTextMuted.opacity(0.3))
            
            StatItem(value: reviewCount, label: "Reviews", icon: "star.fill", action: onReviewsTap)
        }
        .padding(.vertical, 16)
        .background(Color.scentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let value: Int
    let label: String
    let icon: String
    var action: (() -> Void)?
    
    var body: some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(.scentAmber)
                    
                    Text("\(value)")
                        .font(.scentTitle3)
                        .fontWeight(.bold)
                        .foregroundColor(.scentTextPrimary)
                }
                
                Text(label)
                    .font(.scentCaption2)
                    .foregroundColor(.scentTextMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Signature Scent Section

struct SignatureScentSection: View {
    let fragrance: Fragrance?
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.scentGold)
                    Text("Signature Scent")
                        .font(.scentTitle3)
                        .foregroundColor(.scentTextPrimary)
                }
                
                Spacer()
                
                Button {
                    onSelect()
                } label: {
                    Text(fragrance == nil ? "Choose" : "Change")
                        .font(.scentCaption)
                        .foregroundColor(.scentAmber)
                }
            }
            
            if let fragrance = fragrance {
                NavigationLink(destination: FragranceDetailView(fragrance: fragrance)) {
                    SignatureCard(fragrance: fragrance)
                }
            } else {
                Button {
                    onSelect()
                } label: {
                    EmptySignatureCard()
                }
            }
        }
        .padding(.horizontal)
    }
}

struct SignatureCard: View {
    let fragrance: Fragrance
    
    var body: some View {
        HStack(spacing: 16) {
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
            .frame(width: 100, height: 100)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(fragrance.displayBrand)
                    .font(.scentCaption)
                    .foregroundColor(.scentAmber)
                    .textCase(.uppercase)
                
                Text(fragrance.name)
                    .font(.scentHeadline)
                    .foregroundColor(.scentTextPrimary)
                    .lineLimit(2)
                
                if let notes = fragrance.notes?.allNotes.prefix(3) {
                    Text(notes.joined(separator: " · "))
                        .font(.scentCaption)
                        .foregroundColor(.scentTextSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundColor(.scentGold)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.scentGold.opacity(0.1), Color.scentCard],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.scentGold.opacity(0.3), lineWidth: 1)
        )
    }
}

struct EmptySignatureCard: View {
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.scentSurfaceLight)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(.scentTextMuted)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Choose Your Signature")
                    .font(.scentHeadline)
                    .foregroundColor(.scentTextPrimary)
                
                Text("Select a fragrance from your collection")
                    .font(.scentCaption)
                    .foregroundColor(.scentTextSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.scentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Top 5 Section

struct TopFiveSection: View {
    let fragrances: [Fragrance]
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.scentGold)
                    Text("Top 5")
                        .font(.scentTitle3)
                        .foregroundColor(.scentTextPrimary)
                }
                
                Spacer()
                
                Button {
                    onEdit()
                } label: {
                    Text("Edit")
                        .font(.scentCaption)
                        .foregroundColor(.scentAmber)
                }
            }
            .padding(.horizontal)
            
            if fragrances.isEmpty {
                EmptyTopFiveView(onAdd: onEdit)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(fragrances.enumerated()), id: \.element.id) { index, fragrance in
                            NavigationLink(destination: FragranceDetailView(fragrance: fragrance)) {
                                TopFiveCard(fragrance: fragrance, position: index + 1)
                            }
                        }
                        
                        if fragrances.count < 5 {
                            Button {
                                onEdit()
                            } label: {
                                AddTopFiveCard()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct TopFiveCard: View {
    let fragrance: Fragrance
    let position: Int
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
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
                .frame(width: 100, height: 100)
                
                // Position badge
                Text("\(position)")
                    .font(.scentCaption)
                    .fontWeight(.bold)
                    .foregroundColor(.scentBackground)
                    .frame(width: 24, height: 24)
                    .background(Color.scentGold)
                    .clipShape(Circle())
                    .offset(x: -4, y: -4)
            }
            
            VStack(spacing: 2) {
                Text(fragrance.displayBrand)
                    .font(.scentCaption2)
                    .foregroundColor(.scentAmber)
                
                Text(fragrance.name)
                    .font(.scentCaption)
                    .foregroundColor(.scentTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 110)
    }
}

struct AddTopFiveCard: View {
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.scentSurfaceLight)
                    .frame(width: 100, height: 100)
                
                VStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(.scentAmber)
                    
                    Text("Add")
                        .font(.scentCaption)
                        .foregroundColor(.scentTextMuted)
                }
            }
            
            Text(" ")
                .font(.scentCaption2)
        }
        .frame(width: 110)
    }
}

struct EmptyTopFiveView: View {
    let onAdd: () -> Void
    
    var body: some View {
        Button {
            onAdd()
        } label: {
            HStack {
                Image(systemName: "star")
                    .font(.title2)
                    .foregroundColor(.scentAmber)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Build Your Top 5")
                        .font(.scentHeadline)
                        .foregroundColor(.scentTextPrimary)
                    
                    Text("Select your favorite fragrances from your collection")
                        .font(.scentCaption)
                        .foregroundColor(.scentTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.scentTextMuted)
            }
            .padding(16)
            .background(Color.scentSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Recent Collection Section

struct RecentCollectionSection: View {
    let fragrances: [Fragrance]
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Additions")
                    .font(.scentTitle3)
                    .foregroundColor(.scentTextPrimary)
                
                Spacer()
            }
            .padding(.horizontal)
            
            if fragrances.isEmpty {
                Text("Add fragrances to your collection to see them here")
                    .font(.scentCallout)
                    .foregroundColor(.scentTextMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(fragrances) { fragrance in
                        NavigationLink(destination: FragranceDetailView(fragrance: fragrance)) {
                            MiniFragranceCard(fragrance: fragrance)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct MiniFragranceCard: View {
    let fragrance: Fragrance
    
    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: URL(string: fragrance.imageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.scentSurfaceLight)
                        .overlay(ProgressView().tint(.scentAmber))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                case .failure:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.scentSurfaceLight)
                        .overlay(
                            Image(systemName: "drop.fill")
                                .font(.caption)
                                .foregroundColor(.scentAmber.opacity(0.5))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 80)
            
            Text(fragrance.name)
                .font(.scentCaption2)
                .foregroundColor(.scentTextSecondary)
                .lineLimit(1)
        }
        .padding(8)
        .background(Color.scentCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}

