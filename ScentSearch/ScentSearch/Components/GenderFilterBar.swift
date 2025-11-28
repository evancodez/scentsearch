//
//  GenderFilterBar.swift
//  ScentSearch
//
//  Reusable gender filter component
//

import SwiftUI

struct GenderFilterBar: View {
    @Binding var selected: FragranceGender
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(FragranceGender.allCases, id: \.self) { gender in
                GenderFilterButton(
                    gender: gender,
                    isSelected: selected == gender
                ) {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = gender
                    }
                }
            }
        }
    }
}

struct GenderFilterButton: View {
    let gender: FragranceGender
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: gender.icon)
                    .font(.caption)
                Text(gender.rawValue)
                    .font(.scentCaption)
            }
            .foregroundColor(isSelected ? .scentBackground : .scentTextSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.scentAmber : Color.scentSurface)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    ZStack {
        Color.scentBackground
        GenderFilterBar(selected: .constant(.all))
    }
}

