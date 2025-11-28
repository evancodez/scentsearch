//
//  GenderFilterBar.swift
//  ScentSearch
//
//  Reusable gender filter component - supports single and multi-select
//

import SwiftUI

// MARK: - Single Select (Legacy)

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

// MARK: - Multi-Select Gender Filter

struct MultiSelectGenderFilter: View {
    @Binding var selectedGenders: Set<FragranceGender>
    
    // Filter options excluding "All" which is handled specially
    private let genderOptions: [FragranceGender] = [.mens, .womens, .unisex]
    
    var body: some View {
        HStack(spacing: 8) {
            // "All" button
            MultiSelectFilterButton(
                gender: .all,
                isSelected: selectedGenders.contains(.all) || selectedGenders.isEmpty
            ) {
                selectAll()
            }
            
            // Individual gender buttons
            ForEach(genderOptions, id: \.self) { gender in
                MultiSelectFilterButton(
                    gender: gender,
                    isSelected: selectedGenders.contains(gender) && !selectedGenders.contains(.all)
                ) {
                    toggleGender(gender)
                }
            }
        }
    }
    
    private func selectAll() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedGenders = [.all]
        }
    }
    
    private func toggleGender(_ gender: FragranceGender) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.2)) {
            // If "All" is currently selected, clear it and select this gender
            if selectedGenders.contains(.all) {
                selectedGenders = [gender]
            }
            // If this gender is already selected
            else if selectedGenders.contains(gender) {
                selectedGenders.remove(gender)
                // If nothing left, revert to "All"
                if selectedGenders.isEmpty {
                    selectedGenders = [.all]
                }
            }
            // Add this gender to selection
            else {
                selectedGenders.insert(gender)
                // If all three are selected, switch to "All"
                if selectedGenders.contains(.mens) && 
                   selectedGenders.contains(.womens) && 
                   selectedGenders.contains(.unisex) {
                    selectedGenders = [.all]
                }
            }
        }
    }
}

struct MultiSelectFilterButton: View {
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
                
                // Show checkmark when selected (except for All)
                if isSelected && gender != .all {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }
            .foregroundColor(isSelected ? .scentBackground : .scentTextSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.scentAmber : Color.scentSurface)
            .clipShape(Capsule())
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

#Preview("Single Select") {
    ZStack {
        Color.scentBackground
        GenderFilterBar(selected: .constant(.all))
    }
}

#Preview("Multi Select") {
    ZStack {
        Color.scentBackground
        MultiSelectGenderFilter(selectedGenders: .constant([.mens, .unisex]))
    }
}

