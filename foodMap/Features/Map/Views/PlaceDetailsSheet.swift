import SwiftUI
import Combine

struct PlaceDetailsSheet: View {
    let place: PlaceResult
    @Binding var isShowing: Bool
    let onGetDirections: (PlaceResult) -> Void
    
    @State private var placeDetails: PlaceDetailsResult?
    @State private var isLoadingDetails = false
    @StateObject private var mapsService = MapsService()
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 6)
                .padding(.top, 8)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header with image and basic info
                    headerSection
                    
                    // Rating and basic details
                    ratingSection
                    
                    // Action buttons
                    actionButtons
                    
                    // Contact information
                    if let details = placeDetails {
                        contactSection(details: details)
                    }
                    
                    // Opening hours
                    if let details = placeDetails, let hours = details.openingHours {
                        openingHoursSection(hours: hours)
                    }
                    
                    // Reviews
                    if let details = placeDetails, !details.reviews.isEmpty {
                        reviewsSection(reviews: details.reviews)
                    }
                }
                .padding(16)
                .padding(.bottom, 40)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .frame(maxHeight: UIScreen.main.bounds.height * 0.8)
        .onAppear {
            loadPlaceDetails()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Place image placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(
                    VStack {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.6))
                        
                        if isLoadingDetails {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.top, 8)
                        }
                    }
                )
            
            // Place name and address
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(place.address)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Rating Section
    private var ratingSection: some View {
        HStack(spacing: 16) {
            if let rating = place.rating {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            if let priceLevel = place.priceLevel {
                HStack(spacing: 2) {
                    ForEach(0..<4) { index in
                        Text("$")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(index < priceLevel ? .brandRed : .white.opacity(0.3))
                    }
                }
            }
            
            Spacer()
            
            // Open/Closed status
            if let hours = place.openingHours {
                Text(hours.openNow == true ? "Open" : "Closed")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(hours.openNow == true ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Get Directions button
            Button(action: {
                onGetDirections(place)
                isShowing = false
            }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Directions")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.brandRed)
                .cornerRadius(10)
            }
            
            // Call button (if phone number available)
            if let details = placeDetails, let phoneNumber = details.phoneNumber {
                Button(action: {
                    callPlace(phoneNumber: phoneNumber)
                }) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Call")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Contact Section
    private func contactSection(details: PlaceDetailsResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                if let phoneNumber = details.phoneNumber {
                    HStack {
                        Image(systemName: "phone")
                            .foregroundColor(.brandRed)
                            .frame(width: 20)
                        
                        Text(phoneNumber)
                            .foregroundColor(.white)
                    }
                }
                
                if let website = details.website {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.brandRed)
                            .frame(width: 20)
                        
                        Text(website)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                    .onTapGesture {
                        openWebsite(website)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
    
    // MARK: - Opening Hours Section
    private func openingHoursSection(hours: OpeningHours) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hours")
                .font(.headline)
                .foregroundColor(.white)
            
            if let weekdayText = hours.weekdayText {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(weekdayText, id: \.self) { dayHours in
                        Text(dayHours)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Reviews Section
    private func reviewsSection(reviews: [PlaceReview]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reviews")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(reviews.prefix(3), id: \.time) { review in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(review.authorName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            HStack(spacing: 2) {
                                ForEach(0..<5) { index in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(index < review.rating ? .yellow : .white.opacity(0.3))
                                }
                            }
                        }
                        
                        Text(review.text)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(3)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadPlaceDetails() {
        isLoadingDetails = true
        
        mapsService.getPlaceDetails(request: PlaceDetailsRequest(placeId: place.placeId))
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoadingDetails = false
                    
                    if case let .failure(error) = completion {
                        print("❌ Failed to load place details: \(error)")
                    }
                },
                receiveValue: { details in
                    placeDetails = details
                    print("✅ Loaded details for \(details.name)")
                }
            )
            .store(in: &cancellables)
    }
    
    private func callPlace(phoneNumber: String) {
        let cleanedNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        if let url = URL(string: "tel://\(cleanedNumber)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openWebsite(_ website: String) {
        if let url = URL(string: website) {
            UIApplication.shared.open(url)
        }
    }
}

// Remove the extension - cancellables are now properly defined in the class
