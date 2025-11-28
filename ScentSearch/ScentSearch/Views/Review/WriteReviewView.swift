//
//  WriteReviewView.swift
//  ScentSearch
//
//  View for writing or editing a fragrance review
//

import SwiftUI

struct WriteReviewView: View {
    let fragrance: Fragrance
    
    @Environment(\.dismiss) private var dismiss
    @State private var reviewService = ReviewService.shared
    
    @State private var rating = 0
    @State private var title = ""
    @State private var reviewText = ""
    @State private var longevity: Double = 6
    @State private var sillage: Double = 3
    @State private var showLongevity = false
    @State private var showSillage = false
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var existingReview: Review? {
        reviewService.getUserReview(for: fragrance.id)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.scentBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Fragrance Info
                        HStack(spacing: 16) {
                            AsyncImage(url: URL(string: fragrance.imageUrl ?? "")) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                default:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.scentSurfaceLight)
                                        .overlay(
                                            Image(systemName: "drop.fill")
                                                .foregroundColor(.scentAmber.opacity(0.5))
                                        )
                                }
                            }
                            .frame(width: 80, height: 80)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fragrance.displayBrand)
                                    .font(.scentCaption)
                                    .foregroundColor(.scentAmber)
                                    .textCase(.uppercase)
                                
                                Text(fragrance.name)
                                    .font(.scentHeadline)
                                    .foregroundColor(.scentTextPrimary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Rating
                        VStack(spacing: 12) {
                            Text("Your Rating")
                                .font(.scentHeadline)
                                .foregroundColor(.scentTextPrimary)
                            
                            StarRating(rating: $rating, size: 36, spacing: 8)
                            
                            Text(ratingLabel)
                                .font(.scentCaption)
                                .foregroundColor(.scentTextSecondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.scentSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        
                        // Title (Optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title (Optional)")
                                .font(.scentCaption)
                                .foregroundColor(.scentTextSecondary)
                            
                            TextField("Summarize your thoughts", text: $title)
                                .foregroundColor(.scentTextPrimary)
                                .padding()
                                .background(Color.scentSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        
                        // Review Text (Optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Review (Optional)")
                                .font(.scentCaption)
                                .foregroundColor(.scentTextSecondary)
                            
                            TextEditor(text: $reviewText)
                                .foregroundColor(.scentTextPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 120)
                                .padding()
                                .background(Color.scentSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        
                        // Longevity
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                withAnimation {
                                    showLongevity.toggle()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.scentAmber)
                                    Text("Longevity")
                                        .font(.scentHeadline)
                                        .foregroundColor(.scentTextPrimary)
                                    Spacer()
                                    
                                    if showLongevity {
                                        Text("\(Int(longevity)) hours")
                                            .font(.scentCallout)
                                            .foregroundColor(.scentAmber)
                                    }
                                    
                                    Image(systemName: showLongevity ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.scentTextMuted)
                                }
                            }
                            
                            if showLongevity {
                                VStack(spacing: 8) {
                                    Slider(value: $longevity, in: 1...12, step: 1)
                                        .tint(.scentAmber)
                                    
                                    HStack {
                                        Text("1h")
                                            .font(.scentCaption2)
                                        Spacer()
                                        Text("12h+")
                                            .font(.scentCaption2)
                                    }
                                    .foregroundColor(.scentTextMuted)
                                }
                            }
                        }
                        .padding()
                        .background(Color.scentSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        
                        // Sillage
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                withAnimation {
                                    showSillage.toggle()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "wave.3.right")
                                        .foregroundColor(.scentAmber)
                                    Text("Sillage")
                                        .font(.scentHeadline)
                                        .foregroundColor(.scentTextPrimary)
                                    Spacer()
                                    
                                    if showSillage {
                                        Text(sillageLabel)
                                            .font(.scentCallout)
                                            .foregroundColor(.scentAmber)
                                    }
                                    
                                    Image(systemName: showSillage ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.scentTextMuted)
                                }
                            }
                            
                            if showSillage {
                                VStack(spacing: 8) {
                                    Slider(value: $sillage, in: 1...5, step: 1)
                                        .tint(.scentAmber)
                                    
                                    HStack {
                                        Text("Intimate")
                                            .font(.scentCaption2)
                                        Spacer()
                                        Text("Beast Mode")
                                            .font(.scentCaption2)
                                    }
                                    .foregroundColor(.scentTextMuted)
                                }
                            }
                        }
                        .padding()
                        .background(Color.scentSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        
                        Spacer()
                            .frame(height: 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle(existingReview != nil ? "Edit Review" : "Write Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.scentAmber)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        submitReview()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .tint(.scentAmber)
                        } else {
                            Text("Submit")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.scentAmber)
                    .disabled(rating == 0 || isSubmitting)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadExistingReview()
            }
        }
    }
    
    private var ratingLabel: String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Great"
        case 5: return "Excellent"
        default: return "Tap to rate"
        }
    }
    
    private var sillageLabel: String {
        switch Int(sillage) {
        case 1: return "Intimate"
        case 2: return "Light"
        case 3: return "Moderate"
        case 4: return "Strong"
        case 5: return "Beast Mode"
        default: return ""
        }
    }
    
    private func loadExistingReview() {
        if let review = existingReview {
            rating = review.rating
            title = review.title ?? ""
            reviewText = review.text ?? ""
            if let l = review.longevity {
                longevity = Double(l)
                showLongevity = true
            }
            if let s = review.sillage {
                sillage = Double(s)
                showSillage = true
            }
        }
    }
    
    private func submitReview() {
        isSubmitting = true
        
        Task {
            do {
                try await reviewService.createReview(
                    fragranceId: fragrance.id,
                    rating: rating,
                    title: title.isEmpty ? nil : title,
                    text: reviewText.isEmpty ? nil : reviewText,
                    longevity: showLongevity ? Int(longevity) : nil,
                    sillage: showSillage ? Int(sillage) : nil
                )
                
                await MainActor.run {
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isSubmitting = false
                }
            }
        }
    }
}

#Preview {
    WriteReviewView(fragrance: .sample)
        .preferredColorScheme(.dark)
}

