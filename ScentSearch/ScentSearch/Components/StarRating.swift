//
//  StarRating.swift
//  ScentSearch
//
//  Interactive and display star rating component
//

import SwiftUI

struct StarRating: View {
    @Binding var rating: Int
    var maxRating: Int = 5
    var size: CGFloat = 24
    var spacing: CGFloat = 4
    var isInteractive: Bool = true
    var filledColor: Color = .scentGold
    var emptyColor: Color = .scentTextMuted
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundColor(index <= rating ? filledColor : emptyColor)
                    .onTapGesture {
                        if isInteractive {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                // Tap same star to deselect
                                if rating == index {
                                    rating = index - 1
                                } else {
                                    rating = index
                                }
                            }
                        }
                    }
                    .scaleEffect(index == rating && isInteractive ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: rating)
            }
        }
    }
}

// Static display version
struct StarRatingDisplay: View {
    let rating: Double
    var maxRating: Int = 5
    var size: CGFloat = 14
    var spacing: CGFloat = 2
    var filledColor: Color = .scentGold
    var emptyColor: Color = .scentTextMuted
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: starType(for: index))
                    .font(.system(size: size))
                    .foregroundColor(starColor(for: index))
            }
        }
    }
    
    private func starType(for index: Int) -> String {
        let value = Double(index)
        if rating >= value {
            return "star.fill"
        } else if rating >= value - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
    
    private func starColor(for index: Int) -> Color {
        let value = Double(index)
        if rating >= value - 0.5 {
            return filledColor
        } else {
            return emptyColor
        }
    }
}

// Compact rating with count
struct RatingBadge: View {
    let rating: Double
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundColor(.scentGold)
            
            Text(String(format: "%.1f", rating))
                .font(.scentCaption)
                .fontWeight(.semibold)
                .foregroundColor(.scentTextPrimary)
            
            Text("(\(count))")
                .font(.scentCaption2)
                .foregroundColor(.scentTextMuted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.scentSurfaceLight)
        .clipShape(Capsule())
    }
}

#Preview("Interactive") {
    struct PreviewWrapper: View {
        @State private var rating = 3
        
        var body: some View {
            VStack(spacing: 20) {
                StarRating(rating: $rating)
                Text("Rating: \(rating)")
            }
            .padding()
            .background(Color.scentBackground)
        }
    }
    return PreviewWrapper()
}

#Preview("Display") {
    VStack(spacing: 20) {
        StarRatingDisplay(rating: 4.5)
        StarRatingDisplay(rating: 3.2)
        RatingBadge(rating: 4.3, count: 128)
    }
    .padding()
    .background(Color.scentBackground)
}

