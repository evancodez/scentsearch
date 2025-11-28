//
//  SwipeCardView.swift
//  ScentSearch
//
//  Swipeable card for the discover page
//

import SwiftUI

struct SwipeCardView: View {
    let fragrance: Fragrance
    let isTopCard: Bool
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let onTap: () -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var isFlipped = false
    
    private let swipeThreshold: CGFloat = 100
    
    var body: some View {
        ZStack {
            if isFlipped {
                CardBackView(fragrance: fragrance)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                CardFrontView(fragrance: fragrance, swipeProgress: swipeProgress)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 560)
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .gesture(
            isTopCard ? dragGesture : nil
        )
        .onTapGesture {
            if isTopCard {
                withAnimation(.spring(response: 0.5)) {
                    isFlipped.toggle()
                }
            }
        }
        .animation(.interactiveSpring(response: 0.3), value: offset)
    }
    
    private var swipeProgress: Double {
        Double(offset.width / swipeThreshold)
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation
                rotation = Double(value.translation.width / 20)
            }
            .onEnded { value in
                if value.translation.width > swipeThreshold {
                    // Swipe right - add to wishlist
                    withAnimation(.easeOut(duration: 0.3)) {
                        offset = CGSize(width: 500, height: 0)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onSwipeRight()
                        resetCard()
                    }
                } else if value.translation.width < -swipeThreshold {
                    // Swipe left - pass
                    withAnimation(.easeOut(duration: 0.3)) {
                        offset = CGSize(width: -500, height: 0)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onSwipeLeft()
                        resetCard()
                    }
                } else {
                    // Return to center
                    withAnimation(.spring(response: 0.3)) {
                        offset = .zero
                        rotation = 0
                    }
                }
            }
    }
    
    private func resetCard() {
        offset = .zero
        rotation = 0
    }
}

// MARK: - Card Front

struct CardFrontView: View {
    let fragrance: Fragrance
    let swipeProgress: Double
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.scentCard)
            
            VStack(spacing: 0) {
                // Image
                ZStack(alignment: .bottom) {
                    AsyncImage(url: URL(string: fragrance.imageUrl ?? "")) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.scentSurfaceLight)
                                .overlay(
                                    ProgressView()
                                        .tint(.scentAmber)
                                        .scaleEffect(1.5)
                                )
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
                    .frame(height: 360)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 24,
                            topTrailingRadius: 24
                        )
                    )
                    
                    // Gradient overlay
                    LinearGradient(
                        colors: [.clear, Color.scentCard.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                }
                
                // Info
                VStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text(fragrance.displayBrand)
                            .font(.scentCaption)
                            .foregroundColor(.scentAmber)
                            .textCase(.uppercase)
                            .tracking(2)
                        
                        Text(fragrance.name)
                            .font(.scentTitle2)
                            .foregroundColor(.scentTextPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        if let year = fragrance.year {
                            Text(year)
                                .font(.scentCaption)
                                .foregroundColor(.scentTextMuted)
                        }
                    }
                    
                    // Notes preview
                    if let notes = fragrance.notes {
                        HStack(spacing: 8) {
                            ForEach(notes.allNotes.prefix(4), id: \.self) { note in
                                Text(note)
                                    .font(.scentCaption2)
                                    .foregroundColor(.scentTextSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.scentSurfaceLight)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    Text("Tap for details")
                        .font(.scentCaption2)
                        .foregroundColor(.scentTextMuted)
                }
                .padding(20)
            }
            
            // Swipe indicators
            SwipeIndicators(progress: swipeProgress)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.3), radius: 15, y: 10)
    }
}

// MARK: - Card Back

struct CardBackView: View {
    let fragrance: Fragrance
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.scentCard)
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(fragrance.displayBrand)
                        .font(.scentCaption)
                        .foregroundColor(.scentAmber)
                        .textCase(.uppercase)
                        .tracking(2)
                    
                    Text(fragrance.name)
                        .font(.scentTitle2)
                        .foregroundColor(.scentTextPrimary)
                        .multilineTextAlignment(.center)
                }
                
                // Note Pyramid
                if let notes = fragrance.notes {
                    VStack(spacing: 20) {
                        NoteSection(title: "Top Notes", notes: notes.top ?? [], color: .noteTop, icon: "arrow.up.circle.fill")
                        NoteSection(title: "Heart Notes", notes: notes.middle ?? [], color: .noteMiddle, icon: "heart.circle.fill")
                        NoteSection(title: "Base Notes", notes: notes.base ?? [], color: .noteBase, icon: "arrow.down.circle.fill")
                    }
                }
                
                Spacer()
                
                // Year and info
                if let year = fragrance.year {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.scentTextMuted)
                        Text("Released \(year)")
                            .font(.scentCallout)
                            .foregroundColor(.scentTextSecondary)
                    }
                }
                
                Text("Tap to flip back")
                    .font(.scentCaption2)
                    .foregroundColor(.scentTextMuted)
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.3), radius: 15, y: 10)
    }
}

struct NoteSection: View {
    let title: String
    let notes: [String]
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.scentHeadline)
                    .foregroundColor(.scentTextPrimary)
            }
            
            if notes.isEmpty {
                Text("—")
                    .font(.scentCallout)
                    .foregroundColor(.scentTextMuted)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(notes, id: \.self) { note in
                        Text(note)
                            .font(.scentCaption)
                            .foregroundColor(.scentTextSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(color.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Swipe Indicators

struct SwipeIndicators: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            // Pass indicator (left)
            HStack {
                Text("PASS")
                    .font(.scentTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.scentPass)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.scentPass, lineWidth: 3)
                    )
                    .rotationEffect(.degrees(-20))
                    .opacity(progress < -0.3 ? Double(-progress - 0.3) * 2 : 0)
                    .padding(.leading, 30)
                
                Spacer()
            }
            
            // Want indicator (right)
            HStack {
                Spacer()
                
                Text("WANT")
                    .font(.scentTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.scentWishlist)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.scentWishlist, lineWidth: 3)
                    )
                    .rotationEffect(.degrees(20))
                    .opacity(progress > 0.3 ? Double(progress - 0.3) * 2 : 0)
                    .padding(.trailing, 30)
            }
        }
        .padding(.top, 40)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

#Preview {
    ZStack {
        Color.scentBackground.ignoresSafeArea()
        SwipeCardView(
            fragrance: .sample,
            isTopCard: true,
            onSwipeLeft: {},
            onSwipeRight: {},
            onTap: {}
        )
        .padding()
    }
}

