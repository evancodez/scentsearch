//
//  FragranceDetailView.swift
//  ScentSearch
//
//  Detailed view of a fragrance with notes, actions, and reviews
//

import SwiftUI

struct FragranceDetailView: View {
    let fragrance: Fragrance
    
    @State private var userService = UserService.shared
    @State private var reviewService = ReviewService.shared
    @State private var showingReviewSheet = false
    @State private var showingActionSheet = false
    @Environment(\.dismiss) private var dismiss
    
    private var isOwned: Bool {
        userService.isInCollection(fragrance.id)
    }
    
    private var isWishlisted: Bool {
        userService.isInWishlist(fragrance.id)
    }
    
    private var averageRating: Double? {
        reviewService.getAverageRating(for: fragrance.id)
    }
    
    private var reviewCount: Int {
        reviewService.getReviewCount(for: fragrance.id)
    }
    
    var body: some View {
        ZStack {
            Color.scentBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Image
                    ZStack(alignment: .bottomTrailing) {
                        AsyncImage(url: URL(string: fragrance.imageUrl ?? "")) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.scentSurfaceLight)
                                    .overlay(ProgressView().tint(.scentAmber))
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            case .failure:
                                Rectangle()
                                    .fill(Color.scentSurfaceLight)
                                    .overlay(
                                        Image(systemName: "drop.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.scentAmber.opacity(0.3))
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 350)
                        
                        // Status badges
                        HStack(spacing: 8) {
                            if isOwned {
                                StatusBadge(icon: "checkmark.circle.fill", text: "Owned", color: .scentOwned)
                            }
                            if isWishlisted {
                                StatusBadge(icon: "heart.fill", text: "Wishlist", color: .scentWishlist)
                            }
                        }
                        .padding(16)
                    }
                    
                    // Info Section
                    VStack(spacing: 16) {
                        // Brand & Name
                        VStack(spacing: 8) {
                            NavigationLink(destination: BrandDetailView(brand: fragrance.brand)) {
                                Text(fragrance.displayBrand)
                                    .font(.scentCaption)
                                    .foregroundColor(.scentAmber)
                                    .textCase(.uppercase)
                                    .tracking(2)
                            }
                            
                            Text(fragrance.name)
                                .font(.scentTitle)
                                .foregroundColor(.scentTextPrimary)
                                .multilineTextAlignment(.center)
                            
                            if let year = fragrance.year {
                                Text("Released \(year)")
                                    .font(.scentCallout)
                                    .foregroundColor(.scentTextMuted)
                            }
                        }
                        
                        // Rating
                        if let rating = averageRating {
                            RatingBadge(rating: rating, count: reviewCount)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        // Collection Button
                        Button {
                            toggleCollection()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isOwned ? "checkmark.circle.fill" : "plus.circle")
                                Text(isOwned ? "In Collection" : "Add to Collection")
                            }
                            .font(.scentHeadline)
                            .foregroundColor(isOwned ? .scentBackground : .scentOwned)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isOwned ? Color.scentOwned : Color.scentOwned.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Wishlist Button
                        Button {
                            toggleWishlist()
                        } label: {
                            Image(systemName: isWishlisted ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(isWishlisted ? .scentWishlist : .scentTextSecondary)
                                .frame(width: 52, height: 52)
                                .background(isWishlisted ? Color.scentWishlist.opacity(0.15) : Color.scentSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                    
                    // Notes Section
                    if let notes = fragrance.notes {
                        NotesSection(notes: notes)
                    }
                    
                    // Reviews Section
                    ReviewsSection(
                        fragranceId: fragrance.id,
                        onWriteReview: { showingReviewSheet = true }
                    )
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if isOwned {
                        Button {
                            userService.setSignatureScent(fragrance.id)
                        } label: {
                            Label("Set as Signature", systemImage: "crown.fill")
                        }
                        
                        Button {
                            userService.addToTopFive(fragrance.id)
                        } label: {
                            Label("Add to Top 5", systemImage: "star.fill")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            userService.removeFromCollection(fragrance.id)
                        } label: {
                            Label("Remove from Collection", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.scentAmber)
                }
            }
        }
        .sheet(isPresented: $showingReviewSheet) {
            WriteReviewView(fragrance: fragrance)
        }
    }
    
    private func toggleCollection() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        if isOwned {
            userService.removeFromCollection(fragrance.id)
        } else {
            userService.addToCollection(fragrance.id)
        }
    }
    
    private func toggleWishlist() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        if isWishlisted {
            userService.removeFromWishlist(fragrance.id)
        } else {
            userService.addToWishlist(fragrance.id)
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.scentCaption2)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Notes Section

struct NotesSection: View {
    let notes: FragranceNotes
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fragrance Notes")
                .font(.scentTitle3)
                .foregroundColor(.scentTextPrimary)
            
            VStack(spacing: 16) {
                NoteCard(title: "Top Notes", notes: notes.top ?? [], color: .noteTop, description: "First impression, lasts 15-30 minutes")
                NoteCard(title: "Heart Notes", notes: notes.middle ?? [], color: .noteMiddle, description: "Core of the fragrance, lasts 2-4 hours")
                NoteCard(title: "Base Notes", notes: notes.base ?? [], color: .noteBase, description: "Foundation, lasts 4-8+ hours")
            }
        }
        .padding(.horizontal)
    }
}

struct NoteCard: View {
    let title: String
    let notes: [String]
    let color: Color
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(title)
                    .font(.scentHeadline)
                    .foregroundColor(.scentTextPrimary)
                
                Spacer()
            }
            
            Text(description)
                .font(.scentCaption2)
                .foregroundColor(.scentTextMuted)
            
            if notes.isEmpty {
                Text("No notes listed")
                    .font(.scentCallout)
                    .foregroundColor(.scentTextMuted)
                    .italic()
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(notes, id: \.self) { note in
                        Text(note)
                            .font(.scentCallout)
                            .foregroundColor(.scentTextPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(color.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
        .background(Color.scentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Reviews Section

struct ReviewsSection: View {
    let fragranceId: String
    let onWriteReview: () -> Void
    
    @State private var reviewService = ReviewService.shared
    
    private var reviews: [Review] {
        reviewService.getReviews(for: fragranceId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Reviews")
                    .font(.scentTitle3)
                    .foregroundColor(.scentTextPrimary)
                
                Spacer()
                
                Button {
                    onWriteReview()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.pencil")
                        Text("Write Review")
                    }
                    .font(.scentCaption)
                    .foregroundColor(.scentAmber)
                }
            }
            
            if reviews.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 30))
                        .foregroundColor(.scentTextMuted)
                    
                    Text("No reviews yet")
                        .font(.scentCallout)
                        .foregroundColor(.scentTextSecondary)
                    
                    Text("Be the first to share your thoughts!")
                        .font(.scentCaption)
                        .foregroundColor(.scentTextMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color.scentSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 12) {
                    ForEach(reviews.prefix(3)) { review in
                        ReviewCard(review: review)
                    }
                    
                    if reviews.count > 3 {
                        Button {
                            // TODO: Show all reviews
                        } label: {
                            Text("View all \(reviews.count) reviews")
                                .font(.scentCallout)
                                .foregroundColor(.scentAmber)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Avatar
                Circle()
                    .fill(LinearGradient.scentGoldGradient)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(review.userDisplayName?.prefix(1) ?? "A"))
                            .font(.scentCaption)
                            .fontWeight(.semibold)
                            .foregroundColor(.scentBackground)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.userDisplayName ?? "Anonymous")
                        .font(.scentCallout)
                        .fontWeight(.medium)
                        .foregroundColor(.scentTextPrimary)
                    
                    StarRatingDisplay(rating: Double(review.rating), size: 10)
                }
                
                Spacer()
                
                Text(review.createdAt, style: .date)
                    .font(.scentCaption2)
                    .foregroundColor(.scentTextMuted)
            }
            
            if let title = review.title, !title.isEmpty {
                Text(title)
                    .font(.scentHeadline)
                    .foregroundColor(.scentTextPrimary)
            }
            
            if let text = review.text, !text.isEmpty {
                Text(text)
                    .font(.scentCallout)
                    .foregroundColor(.scentTextSecondary)
                    .lineLimit(3)
            }
            
            // Longevity & Sillage
            if review.longevity != nil || review.sillage != nil {
                HStack(spacing: 16) {
                    if let longevity = review.longevity {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text("\(longevity)h")
                                .font(.scentCaption2)
                        }
                        .foregroundColor(.scentTextMuted)
                    }
                    
                    if let sillage = review.sillage {
                        HStack(spacing: 4) {
                            Image(systemName: "wave.3.right")
                                .font(.caption2)
                            Text("\(sillage)/5")
                                .font(.scentCaption2)
                        }
                        .foregroundColor(.scentTextMuted)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.scentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        FragranceDetailView(fragrance: .sample)
    }
    .preferredColorScheme(.dark)
}

