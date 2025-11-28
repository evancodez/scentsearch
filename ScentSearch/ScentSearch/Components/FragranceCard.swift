//
//  FragranceCard.swift
//  ScentSearch
//
//  Reusable fragrance card component
//

import SwiftUI

struct FragranceCard: View {
    let fragrance: Fragrance
    var showNotes: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            AsyncImage(url: URL(string: fragrance.imageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.scentSurfaceLight)
                        .overlay(
                            ProgressView()
                                .tint(.scentAmber)
                        )
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
                                .font(.system(size: 40))
                                .foregroundColor(.scentAmber.opacity(0.5))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 200)
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(fragrance.displayBrand)
                    .font(.scentCaption)
                    .foregroundColor(.scentAmber)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(fragrance.name)
                    .font(.scentTitle3)
                    .foregroundColor(.scentTextPrimary)
                    .lineLimit(2)
                
                if let year = fragrance.year {
                    Text(year)
                        .font(.scentCaption)
                        .foregroundColor(.scentTextMuted)
                }
                
                if showNotes, let notes = fragrance.notes {
                    NotesPreview(notes: notes)
                }
            }
        }
        .padding(16)
        .background(Color.scentCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        .contentShape(Rectangle())
    }
}

struct NotesPreview: View {
    let notes: FragranceNotes
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let topNotes = notes.top, !topNotes.isEmpty {
                NoteRow(label: "Top", notes: topNotes, color: .noteTop)
            }
            if let middleNotes = notes.middle, !middleNotes.isEmpty {
                NoteRow(label: "Heart", notes: middleNotes, color: .noteMiddle)
            }
            if let baseNotes = notes.base, !baseNotes.isEmpty {
                NoteRow(label: "Base", notes: baseNotes, color: .noteBase)
            }
        }
        .padding(.top, 8)
    }
}

struct NoteRow: View {
    let label: String
    let notes: [String]
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .padding(.top, 5)
            
            Text(notes.prefix(3).joined(separator: ", "))
                .font(.scentCaption)
                .foregroundColor(.scentTextSecondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Grid Item Version

struct FragranceGridItem: View {
    let fragrance: Fragrance
    var isSelected: Bool = false
    var showBadge: BadgeType?
    
    enum BadgeType {
        case signature
        case topFive(Int)
        case owned
        case wishlist
    }
    
    var body: some View {
        VStack(spacing: 8) {
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
                
                if let badge = showBadge {
                    BadgeView(type: badge)
                        .padding(6)
                }
            }
            
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
        }
        .padding(10)
        .background(Color.scentCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.scentAmber : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle()) // Makes entire area tappable for NavigationLink
    }
}

struct BadgeView: View {
    let type: FragranceGridItem.BadgeType
    
    var body: some View {
        Group {
            switch type {
            case .signature:
                Image(systemName: "crown.fill")
                    .foregroundColor(.scentGold)
            case .topFive(let position):
                Text("\(position)")
                    .font(.scentCaption2)
                    .fontWeight(.bold)
                    .foregroundColor(.scentBackground)
                    .frame(width: 18, height: 18)
                    .background(Color.scentGold)
                    .clipShape(Circle())
            case .owned:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.scentOwned)
            case .wishlist:
                Image(systemName: "heart.fill")
                    .foregroundColor(.scentWishlist)
            }
        }
        .font(.system(size: 14))
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
    }
}

// MARK: - Previews

#Preview("Card") {
    FragranceCard(fragrance: .sample)
        .padding()
        .background(Color.scentBackground)
}

#Preview("Grid Item") {
    HStack {
        FragranceGridItem(fragrance: .sample, showBadge: .signature)
        FragranceGridItem(fragrance: .sample, showBadge: .topFive(1))
    }
    .padding()
    .background(Color.scentBackground)
}

