//
//  DiscoverView.swift
//  ScentSearch
//
//  Main discover page with Tinder-style swipe cards
//

import SwiftUI

struct DiscoverView: View {
    @State private var fragranceService = FragranceService.shared
    @State private var userService = UserService.shared
    
    @State private var cardQueue: [Fragrance] = []
    @State private var currentIndex = 0
    @State private var showingDetail = false
    @State private var selectedFragrance: Fragrance?
    @State private var selectedGender: FragranceGender = .all
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.scentBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Gender Filter - always show
                    ScrollView(.horizontal, showsIndicators: false) {
                        GenderFilterBar(selected: $selectedGender)
                            .padding(.horizontal)
                    }
                    
                    if fragranceService.isLoading {
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.scentAmber)
                                .scaleEffect(1.5)
                            Text("Loading fragrances...")
                                .font(.scentBody)
                                .foregroundColor(.scentTextSecondary)
                        }
                        Spacer()
                    } else if cardQueue.isEmpty {
                        Spacer()
                        EmptyStateView(onReset: resetDiscovery)
                        Spacer()
                    } else {
                        // Card Stack - show top 3 cards
                        ZStack {
                            // Show cards in reverse order so first card is on top
                            ForEach(Array(cardQueue.prefix(3).enumerated().reversed()), id: \.element.id) { index, fragrance in
                                SwipeCardView(
                                    fragrance: fragrance,
                                    isTopCard: index == 0,
                                    onSwipeLeft: { handleSwipeLeft(fragrance) },
                                    onSwipeRight: { handleSwipeRight(fragrance) },
                                    onTap: {
                                        selectedFragrance = fragrance
                                        showingDetail = true
                                    }
                                )
                                .offset(y: CGFloat(index) * 8)
                                .scaleEffect(1 - CGFloat(index) * 0.03)
                                .zIndex(Double(3 - index))
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Action Buttons
                        ActionButtonsView(
                            onPass: { handleSwipeLeft(cardQueue.first!) },
                            onOwn: { handleOwn(cardQueue.first!) },
                            onWant: { handleSwipeRight(cardQueue.first!) }
                        )
                        .opacity(cardQueue.isEmpty ? 0 : 1)
                    }
                }
                .padding(.top, 10)
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            refreshQueue()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Button {
                            showingResetAlert = true
                        } label: {
                            Label("Reset All Passes", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.scentAmber)
                    }
                }
            }
            .sheet(isPresented: $showingDetail) {
                if let fragrance = selectedFragrance {
                    FragranceDetailView(fragrance: fragrance)
                }
            }
            .alert("Reset Discovery?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetDiscovery()
                }
            } message: {
                Text("This will reset all passed fragrances so you can see them again in discovery.")
            }
        }
        .onAppear {
            if cardQueue.isEmpty {
                refreshQueue()
            }
        }
        .onChange(of: selectedGender) { _, _ in
            refreshQueue()
        }
    }
    
    private func refreshQueue() {
        let seenIds = userService.getSeenFragranceIds()
        cardQueue = fragranceService.getDiscoveryQueue(excluding: seenIds, limit: 20, gender: selectedGender)
    }
    
    private func resetDiscovery() {
        userService.clearPassedOn()
        refreshQueue()
    }
    
    private func handleSwipeLeft(_ fragrance: Fragrance) {
        userService.passOnFragrance(fragrance.id)
        removeTopCard()
    }
    
    private func handleSwipeRight(_ fragrance: Fragrance) {
        userService.addToWishlist(fragrance.id)
        removeTopCard()
    }
    
    private func handleOwn(_ fragrance: Fragrance) {
        userService.addToCollection(fragrance.id)
        removeTopCard()
    }
    
    private func removeTopCard() {
        withAnimation(.spring(response: 0.3)) {
            if !cardQueue.isEmpty {
                cardQueue.removeFirst()
            }
            
            // Load more cards if running low
            if cardQueue.count < 5 {
                let seenIds = userService.getSeenFragranceIds()
                let newCards = fragranceService.getDiscoveryQueue(excluding: seenIds, limit: 10)
                cardQueue.append(contentsOf: newCards)
            }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var onReset: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient.scentGoldGradient)
            
            VStack(spacing: 8) {
                Text("All Caught Up!")
                    .font(.scentTitle2)
                    .foregroundColor(.scentTextPrimary)
                
                Text("You've seen all available fragrances.\nTap below to see them again!")
                    .font(.scentBody)
                    .foregroundColor(.scentTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let onReset = onReset {
                Button {
                    onReset()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset & Discover Again")
                    }
                    .font(.scentHeadline)
                    .foregroundColor(.scentBackground)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(LinearGradient.scentGoldGradient)
                    .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .padding(40)
    }
}

// MARK: - Action Buttons

struct ActionButtonsView: View {
    let onPass: () -> Void
    let onOwn: () -> Void
    let onWant: () -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            // Pass Button (X)
            ActionButton(
                icon: "xmark",
                color: .scentPass,
                size: 60,
                action: onPass
            )
            
            // Already Own Button (checkmark)
            ActionButton(
                icon: "checkmark",
                color: .scentOwned,
                size: 50,
                action: onOwn
            )
            
            // Want Button (heart)
            ActionButton(
                icon: "heart.fill",
                color: .scentWishlist,
                size: 60,
                action: onWant
            )
        }
        .padding(.bottom, 20)
    }
}

struct ActionButton: View {
    let icon: String
    let color: Color
    var size: CGFloat = 60
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(Color.scentSurface)
                        .shadow(color: color.opacity(0.3), radius: 10)
                )
                .overlay(
                    Circle()
                        .stroke(color.opacity(0.5), lineWidth: 2)
                )
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.2), value: isPressed)
    }
}

#Preview {
    DiscoverView()
        .preferredColorScheme(.dark)
}

