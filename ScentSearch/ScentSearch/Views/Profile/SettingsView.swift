//
//  SettingsView.swift
//  ScentSearch
//
//  App settings and account management
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var authService = AuthService.shared
    @State private var userService = UserService.shared
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.scentBackground
                    .ignoresSafeArea()
                
                List {
                    // Account Section
                    Section {
                        HStack {
                            Text("Email")
                                .foregroundColor(.scentTextSecondary)
                            Spacer()
                            Text(userService.currentProfile?.email ?? "")
                                .foregroundColor(.scentTextMuted)
                        }
                        
                        NavigationLink {
                            EditDisplayNameView()
                        } label: {
                            HStack {
                                Text("Display Name")
                                    .foregroundColor(.scentTextSecondary)
                                Spacer()
                                Text(userService.currentProfile?.displayName ?? "Not set")
                                    .foregroundColor(.scentTextMuted)
                            }
                        }
                    } header: {
                        Text("Account")
                    }
                    .listRowBackground(Color.scentSurface)
                    
                    // App Section
                    Section {
                        HStack {
                            Text("Version")
                                .foregroundColor(.scentTextSecondary)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.scentTextMuted)
                        }
                        
                        HStack {
                            Text("Fragrances in Database")
                                .foregroundColor(.scentTextSecondary)
                            Spacer()
                            Text("\(FragranceService.shared.fragrances.count)")
                                .foregroundColor(.scentTextMuted)
                        }
                    } header: {
                        Text("App Info")
                    }
                    .listRowBackground(Color.scentSurface)
                    
                    // Actions Section
                    Section {
                        Button {
                            showingSignOutAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                Text("Sign Out")
                            }
                            .foregroundColor(.scentAmber)
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Account")
                            }
                            .foregroundColor(.scentWishlist)
                        }
                    }
                    .listRowBackground(Color.scentSurface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.scentAmber)
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    // TODO: Implement account deletion
                    authService.signOut()
                    dismiss()
                }
            } message: {
                Text("This will permanently delete your account and all your data. This action cannot be undone.")
            }
        }
    }
}

// MARK: - Edit Display Name

struct EditDisplayNameView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var userService = UserService.shared
    @State private var displayName = ""
    
    var body: some View {
        ZStack {
            Color.scentBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name")
                        .font(.scentCaption)
                        .foregroundColor(.scentTextSecondary)
                    
                    TextField("Enter display name", text: $displayName)
                        .foregroundColor(.scentTextPrimary)
                        .padding()
                        .background(Color.scentSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.scentTextMuted.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Button {
                    userService.updateDisplayName(displayName)
                    dismiss()
                } label: {
                    Text("Save")
                }
                .buttonStyle(PrimaryButtonStyle(isDisabled: displayName.isEmpty))
                .disabled(displayName.isEmpty)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Edit Name")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            displayName = userService.currentProfile?.displayName ?? ""
        }
    }
}

// MARK: - Signature Selector

struct SignatureSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var userService = UserService.shared
    @State private var fragranceService = FragranceService.shared
    
    private var collectionFragrances: [Fragrance] {
        fragranceService.fragrances(byIds: userService.currentProfile?.collection ?? [])
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.scentBackground
                    .ignoresSafeArea()
                
                if collectionFragrances.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "crown")
                            .font(.system(size: 50))
                            .foregroundStyle(LinearGradient.scentGoldGradient)
                        
                        Text("No Fragrances in Collection")
                            .font(.scentTitle3)
                            .foregroundColor(.scentTextPrimary)
                        
                        Text("Add fragrances to your collection first to set a signature scent")
                            .font(.scentBody)
                            .foregroundColor(.scentTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(collectionFragrances) { fragrance in
                                Button {
                                    userService.setSignatureScent(fragrance.id)
                                    dismiss()
                                } label: {
                                    FragranceGridItem(
                                        fragrance: fragrance,
                                        isSelected: userService.isSignatureScent(fragrance.id)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Choose Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.scentAmber)
                }
                
                if userService.currentProfile?.signatureScent != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Remove") {
                            userService.setSignatureScent(nil)
                            dismiss()
                        }
                        .foregroundColor(.scentWishlist)
                    }
                }
            }
        }
    }
}

// MARK: - Top Five Editor

struct TopFiveEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var userService = UserService.shared
    @State private var fragranceService = FragranceService.shared
    @State private var selectedIds: [String] = []
    
    private var collectionFragrances: [Fragrance] {
        fragranceService.fragrances(byIds: userService.currentProfile?.collection ?? [])
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.scentBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Selection indicator
                    HStack {
                        Text("Selected: \(selectedIds.count)/5")
                            .font(.scentCallout)
                            .foregroundColor(.scentTextSecondary)
                        
                        Spacer()
                        
                        if !selectedIds.isEmpty {
                            Button("Clear") {
                                selectedIds.removeAll()
                            }
                            .font(.scentCaption)
                            .foregroundColor(.scentAmber)
                        }
                    }
                    .padding()
                    .background(Color.scentSurface)
                    
                    if collectionFragrances.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "star")
                                .font(.system(size: 50))
                                .foregroundStyle(LinearGradient.scentGoldGradient)
                            
                            Text("No Fragrances in Collection")
                                .font(.scentTitle3)
                                .foregroundColor(.scentTextPrimary)
                            
                            Text("Add fragrances to your collection first")
                                .font(.scentBody)
                                .foregroundColor(.scentTextSecondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(collectionFragrances) { fragrance in
                                    Button {
                                        toggleSelection(fragrance.id)
                                    } label: {
                                        FragranceGridItem(
                                            fragrance: fragrance,
                                            isSelected: selectedIds.contains(fragrance.id),
                                            showBadge: getBadge(for: fragrance.id)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Edit Top 5")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.scentAmber)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        userService.reorderTopFive(selectedIds)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.scentAmber)
                }
            }
            .onAppear {
                selectedIds = userService.currentProfile?.topFive ?? []
            }
        }
    }
    
    private func toggleSelection(_ id: String) {
        if let index = selectedIds.firstIndex(of: id) {
            selectedIds.remove(at: index)
        } else if selectedIds.count < 5 {
            selectedIds.append(id)
        }
    }
    
    private func getBadge(for id: String) -> FragranceGridItem.BadgeType? {
        if let index = selectedIds.firstIndex(of: id) {
            return .topFive(index + 1)
        }
        return nil
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}

