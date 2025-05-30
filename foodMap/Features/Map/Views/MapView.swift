import SwiftUI
import GoogleMaps
import GooglePlaces
import CoreLocation
import Combine

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var searchText = ""
    @State private var showingPlaceDetails = false
    @State private var selectedPlace: PlaceResult?
    @State private var penguinVisible = false
    @State private var showingSearchResults = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            // Google Maps View
            GoogleMapsView(
                viewModel: viewModel,
                selectedPlace: $selectedPlace,
                showingPlaceDetails: $showingPlaceDetails
            )
            .ignoresSafeArea()
            
            // Search Bar Overlay
            VStack {
                searchBarOverlay
                
                Spacer()
                
                // Bottom section with penguin or search results
                if showingSearchResults && !viewModel.searchResults.isEmpty {
                    searchResultsList
                } else if penguinVisible && searchText.isEmpty {
                    penguinSection
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            
            // Place Details Sheet
            if showingPlaceDetails, let place = selectedPlace {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingPlaceDetails = false
                    }
                
                VStack {
                    Spacer()
                    PlaceDetailsSheet(
                        place: place,
                        isShowing: $showingPlaceDetails,
                        onGetDirections: { place in
                            viewModel.getDirections(to: place)
                        }
                    )
                }
                .ignoresSafeArea()
            }
            
            // Loading overlay
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Searching...")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.8))
                    )
                    .padding(.bottom, 120)
                }
            }
        }
        .onAppear {
            viewModel.startLocationServices()
            // Show penguin after a short delay for better UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    penguinVisible = true
                }
            }
        }
        .onChange(of: searchText) { oldValue, newValue in
            if newValue.isEmpty {
                viewModel.clearSearchResults()
                withAnimation(.easeInOut(duration: 0.3)) {
                    penguinVisible = true
                    showingSearchResults = false
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    penguinVisible = false
                }
                // Debounce search - trigger immediately for testing
                searchForPlaces(query: newValue)
            }
        }
    }
    
    // MARK: - Search Function
    private func searchForPlaces(query: String) {
        viewModel.searchPlaces(query: query)
        withAnimation(.easeInOut(duration: 0.3)) {
            showingSearchResults = true
        }
    }
    
    // MARK: - Search Bar
    private var searchBarOverlay: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 44) // Status bar space
            
            HStack {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.8))
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("Where do you want to eat?", text: $searchText)
                            .foregroundColor(.white)
                            .accentColor(.white)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                viewModel.clearSearchResults()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingSearchResults = false
                                    penguinVisible = true
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        // Test button for debugging
                        Button("Test") {
                            searchText = "McDonald's"
                            searchForPlaces(query: "McDonald's")
                        }
                        .font(.caption)
                        .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Penguin Section
    private var penguinSection: some View {
        VStack(spacing: 0) {
            if penguinVisible {
                // Penguin image with speech bubble
                VStack(spacing: 0) {
                    Image("penguin_chef")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .padding(.bottom, -15)
                    
                    // Speech bubble with "Find Me a Feast" button
                    Button(action: {
                        viewModel.searchNearbyRestaurants()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            penguinVisible = false
                            showingSearchResults = true
                        }
                    }) {
                        Text("Oh Mighty Penguin, Find Me a Feast!")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.black, lineWidth: 2)
                                    )
                                    .shadow(radius: 4, y: 2)
                            )
                    }
                    .offset(y: -15)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
        .padding(.bottom, 100)
    }
    
    // MARK: - Search Results List
    private var searchResultsList: some View {
        VStack(spacing: 0) {
            // Results header
            HStack {
                Text(searchText.isEmpty ? "Places Near You" : "Search Results")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Hide") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingSearchResults = false
                        if searchText.isEmpty {
                            penguinVisible = true
                        }
                    }
                }
                .font(.subheadline)
                .foregroundColor(.brandRed)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color.black.opacity(0.8)
                    .cornerRadius(12, corners: [.topLeft, .topRight])
            )
            
            // Results list or error/empty state
            if viewModel.searchResults.isEmpty && !viewModel.isLoading {
                VStack(spacing: 12) {
                    if let errorMessage = viewModel.errorMessage {
                        Text("❌ \(errorMessage)")
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("No places found")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Try searching for:\n• Restaurant names (McDonald's, KFC)\n• Food types (pizza, sushi)\n• Neighborhoods")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(20)
                .background(
                    Color.black.opacity(0.8)
                        .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                )
            } else {
                // Results list
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.searchResults) { place in
                            PlaceCard(place: place) {
                                selectedPlace = place
                                showingPlaceDetails = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(
                    Color.black.opacity(0.8)
                        .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 100)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Place Card
struct PlaceCard: View {
    let place: PlaceResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Place image placeholder or actual image
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 120)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: getIconForPlace())
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.6))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let rating = place.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                            
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Text(place.address)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func getIconForPlace() -> String {
        let isRestaurant = place.types.contains { type in
            ["restaurant", "food", "meal_takeaway", "cafe", "bakery", "bar"].contains(type)
        }
        
        let isStore = place.types.contains { type in
            ["store", "shopping_mall", "supermarket"].contains(type)
        }
        
        if isRestaurant {
            return "fork.knife"
        } else if isStore {
            return "bag"
        } else {
            return "mappin"
        }
    }
}
