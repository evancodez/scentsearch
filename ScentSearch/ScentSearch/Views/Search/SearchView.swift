//
//  SearchView.swift
//  ScentSearch
//
//  Search page with brand browsing and fragrance search
//

import SwiftUI

struct SearchView: View {
    @State private var fragranceService = FragranceService.shared
    @State private var searchText = ""
    @State private var searchResults: [Fragrance] = []
    @State private var isSearching = false
    @State private var selectedGenders: Set<FragranceGender> = [.all]
    
    private var filteredResults: [Fragrance] {
        return searchResults.filter { $0.matchesGenders(selectedGenders) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.scentBackground
                    .ignoresSafeArea()
                
                if fragranceService.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.scentAmber)
                            .scaleEffect(1.5)
                        Text("Loading fragrances...")
                            .font(.scentBody)
                            .foregroundColor(.scentTextSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Search Bar
                            SearchBar(text: $searchText, isSearching: $isSearching)
                                .padding(.horizontal)
                            
                            // Multi-select Gender Filter
                            ScrollView(.horizontal, showsIndicators: false) {
                                MultiSelectGenderFilter(selectedGenders: $selectedGenders)
                                    .padding(.horizontal)
                            }
                            
                            if !searchText.isEmpty {
                                // Search Results
                                SearchResultsView(results: filteredResults)
                            } else {
                                // Browse by Brand
                                BrandListView()
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            // Wait for fragrances to be loaded
            await fragranceService.loadFragrances()
        }
        .onChange(of: searchText) { _, newValue in
            performSearch(query: newValue)
        }
        .onChange(of: selectedGenders) { _, _ in
            performSearch(query: searchText)
        }
    }
    
    private func performSearch(query: String) {
        if query.isEmpty {
            searchResults = []
        } else {
            searchResults = fragranceService.search(query: query, genders: selectedGenders)
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.scentTextMuted)
                
                TextField("Search fragrances or brands...", text: $text)
                    .foregroundColor(.scentTextPrimary)
                    .focused($isFocused)
                    .onTapGesture {
                        isSearching = true
                    }
                
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.scentTextMuted)
                    }
                }
            }
            .padding(14)
            .background(Color.scentSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isFocused ? Color.scentAmber : Color.clear, lineWidth: 1)
            )
            
            if isSearching {
                Button("Cancel") {
                    text = ""
                    isSearching = false
                    isFocused = false
                }
                .foregroundColor(.scentAmber)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSearching)
    }
}

// MARK: - Search Results

struct SearchResultsView: View {
    let results: [Fragrance]
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Results")
                    .font(.scentHeadline)
                    .foregroundColor(.scentTextPrimary)
                
                Text("(\(results.count))")
                    .font(.scentCallout)
                    .foregroundColor(.scentTextMuted)
                
                Spacer()
            }
            .padding(.horizontal)
            
            if results.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.scentTextMuted)
                    
                    Text("No fragrances found")
                        .font(.scentBody)
                        .foregroundColor(.scentTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(results.prefix(50)) { fragrance in
                        NavigationLink(value: fragrance) {
                            FragranceGridItem(fragrance: fragrance)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationDestination(for: Fragrance.self) { fragrance in
            FragranceDetailView(fragrance: fragrance)
        }
    }
}

// MARK: - Brand List

struct BrandListView: View {
    @State private var fragranceService = FragranceService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Browse by Brand")
                .font(.scentHeadline)
                .foregroundColor(.scentTextPrimary)
                .padding(.horizontal)
            
            LazyVStack(spacing: 1) {
                ForEach(fragranceService.brands, id: \.self) { brand in
                    NavigationLink(destination: BrandDetailView(brand: brand)) {
                        BrandRow(
                            brand: brand,
                            count: fragranceService.fragrances(byBrand: brand).count
                        )
                    }
                }
            }
            .background(Color.scentSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}

struct BrandRow: View {
    let brand: String
    let count: Int
    
    var displayBrand: String {
        brand.replacingOccurrences(of: "-", with: " ").capitalized
    }
    
    var body: some View {
        HStack {
            // Brand initial circle
            ZStack {
                Circle()
                    .fill(LinearGradient.scentGoldGradient)
                    .frame(width: 40, height: 40)
                
                Text(String(displayBrand.prefix(1)))
                    .font(.scentHeadline)
                    .foregroundColor(.scentBackground)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(displayBrand)
                    .font(.scentBody)
                    .foregroundColor(.scentTextPrimary)
                
                Text("\(count) fragrances")
                    .font(.scentCaption)
                    .foregroundColor(.scentTextMuted)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.scentCaption)
                .foregroundColor(.scentTextMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.scentSurface)
    }
}

#Preview {
    SearchView()
        .preferredColorScheme(.dark)
}

