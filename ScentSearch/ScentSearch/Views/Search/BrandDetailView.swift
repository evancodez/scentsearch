//
//  BrandDetailView.swift
//  ScentSearch
//
//  Shows all fragrances from a specific brand
//

import SwiftUI

struct BrandDetailView: View {
    let brand: String
    
    @State private var fragranceService = FragranceService.shared
    @State private var sortOption: SortOption = .name
    @State private var showingSortSheet = false
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case yearNew = "Newest First"
        case yearOld = "Oldest First"
    }
    
    private var displayBrand: String {
        brand.replacingOccurrences(of: "-", with: " ").capitalized
    }
    
    private var fragrances: [Fragrance] {
        let unsorted = fragranceService.fragrances(byBrand: brand)
        
        switch sortOption {
        case .name:
            return unsorted.sorted { $0.name < $1.name }
        case .yearNew:
            return unsorted.sorted { ($0.year ?? "") > ($1.year ?? "") }
        case .yearOld:
            return unsorted.sorted { ($0.year ?? "") < ($1.year ?? "") }
        }
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            Color.scentBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient.scentGoldGradient)
                                .frame(width: 80, height: 80)
                            
                            Text(String(displayBrand.prefix(1)))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.scentBackground)
                        }
                        
                        Text(displayBrand)
                            .font(.scentTitle)
                            .foregroundColor(.scentTextPrimary)
                        
                        Text("\(fragrances.count) fragrances")
                            .font(.scentCallout)
                            .foregroundColor(.scentTextSecondary)
                    }
                    .padding(.top, 10)
                    
                    // Sort Button
                    HStack {
                        Spacer()
                        
                        Button {
                            showingSortSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Text("Sort: \(sortOption.rawValue)")
                                    .font(.scentCaption)
                                Image(systemName: "chevron.down")
                                    .font(.scentCaption2)
                            }
                            .foregroundColor(.scentAmber)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.scentSurface)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                    
                    // Fragrances Grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(fragrances) { fragrance in
                            NavigationLink(destination: FragranceDetailView(fragrance: fragrance)) {
                                FragranceGridItem(fragrance: fragrance)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle(displayBrand)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Sort By", isPresented: $showingSortSheet) {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button(option.rawValue) {
                    withAnimation {
                        sortOption = option
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BrandDetailView(brand: "dior")
    }
    .preferredColorScheme(.dark)
}

