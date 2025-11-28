//
//  UserReviewsView.swift
//  ScentSearch
//
//  Displays user's reviews
//

import SwiftUI

struct UserReviewsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var reviewService = ReviewService.shared
    @State private var fragranceService = FragranceService.shared
    
    private var reviews: [Review] {
        reviewService.getUserReviews().sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.scentBackground
                    .ignoresSafeArea()
                
                if reviews.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "star")
                            .font(.system(size: 50))
                            .foregroundStyle(LinearGradient.scentGoldGradient)
                        
                        VStack(spacing: 8) {
                            Text("No Reviews Yet")
                                .font(.scentTitle3)
                                .foregroundColor(.scentTextPrimary)
                            
                            Text("Rate fragrances to see your reviews here")
                                .font(.scentBody)
                                .foregroundColor(.scentTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(reviews) { review in
                                UserReviewCard(review: review)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.scentAmber)
                }
            }
        }
    }
}

struct UserReviewCard: View {
    let review: Review
    @State private var fragranceService = FragranceService.shared
    
    private var fragrance: Fragrance? {
        fragranceService.fragrance(byId: review.fragranceId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Fragrance info
            if let fragrance = fragrance {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: fragrance.imageUrl ?? "")) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.scentSurfaceLight)
                                .overlay(ProgressView().tint(.scentAmber))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.scentSurfaceLight)
                                .overlay(
                                    Image(systemName: "drop.fill")
                                        .foregroundColor(.scentAmber.opacity(0.5))
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 60, height: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fragrance.displayBrand)
                            .font(.scentCaption)
                            .foregroundColor(.scentAmber)
                        
                        Text(fragrance.name)
                            .font(.scentHeadline)
                            .foregroundColor(.scentTextPrimary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
            }
            
            // Rating
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= review.rating ? "star.fill" : "star")
                        .foregroundColor(.scentGold)
                        .font(.system(size: 14))
                }
                
                Text("•")
                    .foregroundColor(.scentTextMuted)
                
                Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.scentCaption)
                    .foregroundColor(.scentTextMuted)
            }
            
            // Review title
            if let title = review.title, !title.isEmpty {
                Text(title)
                    .font(.scentHeadline)
                    .foregroundColor(.scentTextPrimary)
            }
            
            // Review text
            if let text = review.text, !text.isEmpty {
                Text(text)
                    .font(.scentBody)
                    .foregroundColor(.scentTextSecondary)
                    .lineLimit(4)
            }
            
            // Longevity & Sillage
            if review.longevity != nil || review.sillage != nil {
                HStack(spacing: 16) {
                    if let longevity = review.longevity {
                        Label("\(longevity)/10 Longevity", systemImage: "clock")
                            .font(.scentCaption)
                            .foregroundColor(.scentTextMuted)
                    }
                    
                    if let sillage = review.sillage {
                        Label("\(sillage)/10 Sillage", systemImage: "wind")
                            .font(.scentCaption)
                            .foregroundColor(.scentTextMuted)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.scentCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    UserReviewsView()
        .preferredColorScheme(.dark)
}

