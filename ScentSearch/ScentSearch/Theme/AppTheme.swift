//
//  AppTheme.swift
//  ScentSearch
//
//  App-wide theme definitions with dark mode and amber accents
//

import SwiftUI

// MARK: - Color Palette

extension Color {
    // Primary brand colors - Amber/Gold luxury theme
    static let scentAmber = Color(hex: "D4A574")
    static let scentGold = Color(hex: "C9A962")
    static let scentBronze = Color(hex: "8B6914")
    
    // Dark theme backgrounds
    static let scentBackground = Color(hex: "0D0D0D")
    static let scentSurface = Color(hex: "1A1A1A")
    static let scentSurfaceLight = Color(hex: "252525")
    static let scentCard = Color(hex: "1E1E1E")
    
    // Text colors
    static let scentTextPrimary = Color.white
    static let scentTextSecondary = Color(hex: "A0A0A0")
    static let scentTextMuted = Color(hex: "666666")
    
    // Accent colors for actions
    static let scentWishlist = Color(hex: "E85D75") // Pink-red for wishlist/hearts
    static let scentOwned = Color(hex: "4CAF50") // Green for owned
    static let scentPass = Color(hex: "6B6B6B") // Grey for pass
    
    // Note pyramid colors
    static let noteTop = Color(hex: "FFD700") // Gold
    static let noteMiddle = Color(hex: "FF8C00") // Dark orange
    static let noteBase = Color(hex: "8B4513") // Saddle brown
    
    // Helper for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradients

extension LinearGradient {
    static let scentGoldGradient = LinearGradient(
        colors: [.scentAmber, .scentGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let scentBackgroundGradient = LinearGradient(
        colors: [.scentBackground, .scentSurface],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardGlassGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.1),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography

extension Font {
    static let scentLargeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let scentTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let scentTitle2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let scentTitle3 = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let scentHeadline = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let scentBody = Font.system(size: 16, weight: .regular)
    static let scentCallout = Font.system(size: 14, weight: .regular)
    static let scentCaption = Font.system(size: 12, weight: .regular)
    static let scentCaption2 = Font.system(size: 11, weight: .regular)
}

// MARK: - View Modifiers

struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.scentCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.scentHeadline)
            .foregroundColor(.scentBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isDisabled 
                    ? AnyShapeStyle(Color.scentTextMuted)
                    : AnyShapeStyle(LinearGradient.scentGoldGradient)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.scentHeadline)
            .foregroundColor(.scentAmber)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.scentAmber.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.scentAmber.opacity(0.5), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func glassBackground(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius))
    }
    
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

