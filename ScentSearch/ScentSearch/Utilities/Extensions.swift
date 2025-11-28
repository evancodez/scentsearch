//
//  Extensions.swift
//  ScentSearch
//
//  Utility extensions for the app
//

import SwiftUI

// MARK: - View Extensions

extension View {
    /// Apply a shimmer loading effect
    func shimmer(when loading: Bool) -> some View {
        self
            .redacted(reason: loading ? .placeholder : [])
            .shimmering(active: loading)
    }
    
    /// Add a bounce animation on tap
    func bounceOnTap() -> some View {
        self.modifier(BounceModifier())
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    let active: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        if active {
            content
                .overlay(
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                    }
                    .mask(content)
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    func shimmering(active: Bool = true) -> some View {
        modifier(ShimmerModifier(active: active))
    }
}

// MARK: - Bounce Modifier

struct BounceModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - String Extensions

extension String {
    /// Format brand slug to display name
    var brandDisplayName: String {
        self.replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
    
    /// Truncate string with ellipsis
    func truncated(to length: Int) -> String {
        if self.count > length {
            return String(self.prefix(length - 3)) + "..."
        }
        return self
    }
}

// MARK: - Date Extensions

extension Date {
    /// Format date as relative time
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Format date as medium style
    var formattedMedium: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

// MARK: - Array Extensions

extension Array where Element: Identifiable {
    /// Find index of element by ID
    func index(of element: Element) -> Int? {
        firstIndex(where: { $0.id == element.id }) as? Int
    }
}

// MARK: - Animation Extensions

extension Animation {
    static let smoothSpring = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let quickSpring = Animation.spring(response: 0.25, dampingFraction: 0.7)
    static let bounceSpring = Animation.spring(response: 0.4, dampingFraction: 0.5)
}

