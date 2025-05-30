import SwiftUI
import MapKit

// MARK: - Restaurant Model
struct Restaurant {
    let id: String
    let name: String
    let description: String
    let tags: [String]
}

struct HomeView: View {
    // MARK: - Properties
    let displayName: String
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var mapViewModel = MapViewModel() // Add MapViewModel for search
    @State private var showPreferencesSheet = false
    @State private var searchText = ""
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.5741, longitude: -73.6921),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showLogoutConfirmation = false
    @State private var showSearchResults = false // Add state for search results
    @State private var selectedPlace: PlaceResult? // Add selected place state
    @State private var showDirectionsSheet = false // Add directions sheet state
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {}
                .colorScheme(.dark)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if let user = authViewModel.user, !user.isEmailVerified {
                    VerificationStatusView(viewModel: authViewModel)
                }
                
                VStack(spacing: 16) {
                    Spacer().frame(height: 44)
                    
                    HStack(spacing: 12) {
                        searchBarView
                        
                        Button(action: { showLogoutConfirmation = true }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.brandRed).shadow(color: .black.opacity(0.2), radius: 4, y: 2))
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
                
                // Show search results or suggestions container
                if showSearchResults && !mapViewModel.searchResults.isEmpty {
                    searchResultsView
                } else {
                    suggestionsContainerView
                }
            }
        }
        .sheet(isPresented: $showDirectionsSheet) {
            if let place = selectedPlace {
                DirectionsSheet(
                    place: place,
                    mapViewModel: mapViewModel,
                    isPresented: $showDirectionsSheet
                )
            }
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.dark)
        .onAppear {
            authViewModel.checkEmailVerificationStatus()
            mapViewModel.startLocationServices() // Start location services
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.getDefaultSuggestions()
            }
        }
        .sheet(isPresented: $showPreferencesSheet) {
            FoodPreferencesSheet(isPresented: $showPreferencesSheet) { preferences in
                viewModel.getRestaurantSuggestions(preferences: preferences)
            }
        }
        .alert(isPresented: $showLogoutConfirmation) {
            Alert(
                title: Text("Log Out"),
                message: Text("Are you sure you want to log out?"),
                primaryButton: .destructive(Text("Log Out")) { authViewModel.signOut() },
                secondaryButton: .cancel()
            )
        }
        .onChange(of: searchText) { oldValue, newValue in
            if newValue.isEmpty {
                showSearchResults = false
                mapViewModel.clearSearchResults()
            } else {
                // Debounce search with a small delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if searchText == newValue { // Only search if text hasn't changed
                        searchForPlaces(query: newValue)
                    }
                }
            }
        }
    }
    
    // MARK: - Search Function
    private func searchForPlaces(query: String) {
        print("🔍 HomeView: Searching for places with query: '\(query)'")
        mapViewModel.searchPlaces(query: query)
        showSearchResults = true
    }
    
    private var searchBarView: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.7))
                .frame(height: 50)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.3), lineWidth: 1))
            
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.7))
                TextField("Where do you want to eat?", text: $searchText)
                    .foregroundColor(.white)
                    .accentColor(.white)
                
                // Clear button
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        showSearchResults = false
                        mapViewModel.clearSearchResults()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Search Results View
    private var searchResultsView: some View {
        VStack(spacing: 0) {
            // Results header
            HStack {
                Text("Search Results")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Hide") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSearchResults = false
                    }
                }
                .font(.subheadline)
                .foregroundColor(.brandRed)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Search results or loading/error states
            if mapViewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Searching for places...")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if let errorMessage = mapViewModel.errorMessage {
                VStack(spacing: 16) {
                    Text("😕").font(.system(size: 40))
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.red.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: { searchForPlaces(query: searchText) }) {
                        Text("Try Again")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.brandRed)
                            .cornerRadius(10)
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if mapViewModel.searchResults.isEmpty {
                VStack(spacing: 12) {
                    Text("No places found")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Try searching for:\n• Restaurant names (McDonald's, KFC)\n• Food types (pizza, sushi)\n• Neighborhoods")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            } else {
                // Results list
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(mapViewModel.searchResults) { place in
                            PlaceSearchCard(place: place) {
                                selectedPlace = place
                                showDirectionsSheet = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 1))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 85)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var suggestionsContainerView: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading || viewModel.errorMessage != nil || !viewModel.suggestedRestaurants.isEmpty {
                suggestionContent
            } else {
                penguinCTAView
            }
        }
        .padding(.bottom, 85)
    }
    
    private var penguinCTAView: some View {
        VStack(spacing: 0) {
            Image("penguin_chef")
                .resizable()
                .scaledToFit()
                .frame(width: 100)
                .padding(.bottom, -10)
            
            Button(action: { viewModel.getDefaultSuggestions() }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Oh Mighty Penguin, Find").font(.system(size: 18, weight: .bold))
                    Text("Me a Feast!").font(.system(size: 18, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.8))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
                )
                .foregroundColor(.white)
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var suggestionContent: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Restaurant Suggestions").font(.headline).foregroundColor(.white)
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.suggestedRestaurants = ""
                        viewModel.errorMessage = nil
                    }
                }) {
                    Text("Hide").font(.subheadline).foregroundColor(.brandRed)
                }
                
                Button(action: { showPreferencesSheet = true }) {
                    HStack(spacing: 4) {
                        Text("Customize").font(.subheadline)
                        Image(systemName: "slider.horizontal.3").font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Capsule().fill(Color.brandRed))
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.errorMessage != nil {
                errorView
            } else {
                suggestionsView
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 1))
        )
        .padding(.horizontal, 16)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(1.5)
            Text("Chef Penguin is cooking up suggestions...")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Text("😕").font(.system(size: 40))
            Text(viewModel.errorMessage ?? "Error: The operation couldn't be completed.")
                .font(.body)
                .foregroundColor(.red.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { viewModel.getDefaultSuggestions() }) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.brandRed)
                    .cornerRadius(10)
            }
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(parseRestaurantSuggestions(), id: \.id) { restaurant in
                        restaurantCard(restaurant)
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: 300)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private func restaurantCard(_ restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(restaurant.name).font(.headline).foregroundColor(.white)
            Text(restaurant.description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
            
            HStack {
                ForEach(restaurant.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.brandRed.opacity(0.8))
                        .cornerRadius(4)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func parseRestaurantSuggestions() -> [Restaurant] {
        let text = viewModel.suggestedRestaurants
        let pattern = #"\d+\.\s+\*\*([^*]+)\*\*:([^\n]+)(?:\n\n|\.$|\z)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return [Restaurant(id: UUID().uuidString, name: "Restaurant Recommendations", description: text, tags: ["Italian", "Vegetarian", "Gluten-Free"])]
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        var restaurants: [Restaurant] = []
        
        if !matches.isEmpty {
            for match in matches {
                if match.numberOfRanges >= 3 {
                    let nameRange = match.range(at: 1)
                    let descRange = match.range(at: 2)
                    
                    if nameRange.location != NSNotFound && descRange.location != NSNotFound {
                        let name = nsString.substring(with: nameRange).trimmingCharacters(in: .whitespacesAndNewlines)
                        let description = nsString.substring(with: descRange).trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        restaurants.append(Restaurant(id: UUID().uuidString, name: name, description: description, tags: ["Italian", "Vegetarian", "Gluten-Free"]))
                    }
                }
            }
        }
        
        if restaurants.isEmpty {
            restaurants = [Restaurant(id: UUID().uuidString, name: "Restaurant Recommendations", description: text, tags: ["Italian", "Vegetarian", "Gluten-Free"])]
        }
        
        return restaurants
    }
}

// MARK: - Place Search Card Component
struct PlaceSearchCard: View {
    let place: PlaceResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Place image placeholder
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

// MARK: - Preferences Sheet (unchanged)
struct FoodPreferencesSheet: View {
    @Binding var isPresented: Bool
    var onSubmit: (RestaurantPreferences) -> Void
    
    @State private var cuisine = "Italian"
    @State private var selectedDietary: [String] = ["vegetarian", "gluten-free"]
    @State private var selectedPriceRange: PriceRange = .moderate
    @State private var location = "Downtown"
    @State private var quietEnvironment = true
    @State private var outdoorSeating = true
    
    private let dietaryOptions = ["Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free", "Kosher", "Halal"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        sectionHeader("Cuisine")
                        customTextField(placeholder: "Enter cuisine (Italian, Mexican, etc.)", text: $cuisine)
                        
                        sectionHeader("Dietary Preferences")
                        dietarySelectionGrid
                        
                        sectionHeader("Price Range")
                        priceRangePicker
                        
                        sectionHeader("Location")
                        customTextField(placeholder: "Enter location or neighborhood", text: $location)
                        
                        sectionHeader("Additional Preferences")
                        additionalPreferencesSection
                        
                        Button(action: submitPreferences) {
                            Text("Get Recommendations")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.brandRed)
                                .cornerRadius(12)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 60)
                    }
                    .padding()
                }
            }
            .navigationTitle("Food Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }.foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title).font(.headline).foregroundColor(.white).padding(.bottom, 4)
    }
    
    private func customTextField(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            .foregroundColor(.white)
    }
    
    private var dietarySelectionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(dietaryOptions, id: \.self) { option in
                Button(action: {
                    let lowerOption = option.lowercased()
                    if selectedDietary.contains(lowerOption) {
                        selectedDietary.removeAll { $0 == lowerOption }
                    } else {
                        selectedDietary.append(lowerOption)
                    }
                }) {
                    HStack {
                        Text(option).font(.system(size: 14))
                        Spacer()
                        Image(systemName: selectedDietary.contains(option.lowercased()) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedDietary.contains(option.lowercased()) ? .brandRed : .gray)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                .foregroundColor(.white)
            }
        }
    }
    
    private var priceRangePicker: some View {
        HStack(spacing: 0) {
            priceButton("$", range: .budget)
            priceButton("$$", range: .moderate)
            priceButton("$$$", range: .expensive)
            priceButton("$$$$", range: .luxury)
        }
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
    
    private func priceButton(_ label: String, range: PriceRange) -> some View {
        Button(action: { selectedPriceRange = range }) {
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(selectedPriceRange == range ? Color.brandRed : Color.clear)
                .foregroundColor(selectedPriceRange == range ? .white : .gray)
        }
    }
    
    private var additionalPreferencesSection: some View {
        VStack(spacing: 12) {
            Toggle("Quiet Environment", isOn: $quietEnvironment).toggleStyle(SwitchToggleStyle(tint: .brandRed))
            Toggle("Outdoor Seating", isOn: $outdoorSeating).toggleStyle(SwitchToggleStyle(tint: .brandRed))
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
    
    private func submitPreferences() {
        let additionalPrefs = ["quietEnvironment": quietEnvironment, "outdoorSeating": outdoorSeating]
        let preferences = RestaurantPreferences(
            cuisine: cuisine,
            dietary: selectedDietary.map { $0.lowercased() },
            priceRange: selectedPriceRange,
            location: location,
            additionalPreferences: additionalPrefs
        )
        onSubmit(preferences)
        isPresented = false
    }
}

// MARK: - Directions Sheet
struct DirectionsSheet: View {
    let place: PlaceResult
    @ObservedObject var mapViewModel: MapViewModel
    @Binding var isPresented: Bool
    
    @State private var selectedMode: TransportMode = .driving
    @State private var directionsResponse: DirectionsResponse?
    @State private var isLoadingDirections = false
    @State private var directionsError: String?
    
    enum TransportMode: String, CaseIterable {
        case driving = "driving"
        case walking = "walking"
        case transit = "transit"
        
        var icon: String {
            switch self {
            case .driving: return "car.fill"
            case .walking: return "figure.walk"
            case .transit: return "bus.fill"
            }
        }
        
        var title: String {
            switch self {
            case .driving: return "Driving"
            case .walking: return "Walking"
            case .transit: return "Transit"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Place info header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(place.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(place.address)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        if let rating = place.rating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
                
                // Transport mode selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Transportation")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        ForEach(TransportMode.allCases, id: \.self) { mode in
                            Button(action: {
                                selectedMode = mode
                                getDirections()
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 24))
                                    Text(mode.title)
                                        .font(.caption)
                                }
                                .foregroundColor(selectedMode == mode ? .white : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedMode == mode ? Color.brandRed : Color.white.opacity(0.1))
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Directions results
                ScrollView {
                    VStack(spacing: 16) {
                        if isLoadingDirections {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                Text("Getting directions...")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(height: 150)
                        } else if let error = directionsError {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.yellow)
                                
                                Text(error)
                                    .foregroundColor(.red.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                
                                Button("Try Again") {
                                    getDirections()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.brandRed)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .frame(height: 150)
                        } else if let directions = directionsResponse?.routes.first?.legs.first {
                            // Journey overview
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Duration")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                        Text(directions.duration.text)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Distance")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                        Text(directions.distance.text)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                
                                // Step-by-step directions
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Directions")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    ForEach(Array(directions.steps.enumerated()), id: \.offset) { index, step in
                                        HStack(alignment: .top, spacing: 12) {
                                            Text("\(index + 1)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .frame(width: 20, height: 20)
                                                .background(Circle().fill(Color.brandRed))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(step.instructions.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white)
                                                
                                                HStack {
                                                    Text(step.distance.text)
                                                        .font(.caption)
                                                        .foregroundColor(.white.opacity(0.6))
                                                    
                                                    Text("•")
                                                        .foregroundColor(.white.opacity(0.6))
                                                    
                                                    Text(step.duration.text)
                                                        .font(.caption)
                                                        .foregroundColor(.white.opacity(0.6))
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        
                                        if index < directions.steps.count - 1 {
                                            Divider()
                                                .background(Color.white.opacity(0.2))
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .background(Color.black)
            .navigationTitle("Directions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            getDirections()
        }
    }
    
    private func getDirections() {
        guard let userLocation = mapViewModel.userLocation,
              let placeLocation = place.location else {
            directionsError = "Location not available"
            return
        }
        
        isLoadingDirections = true
        directionsError = nil
        
        let origin = "\(userLocation.latitude),\(userLocation.longitude)"
        let destination = "\(placeLocation.latitude),\(placeLocation.longitude)"
        
        let request = DirectionsRequest(
            origin: origin,
            destination: destination,
            mode: selectedMode.rawValue
        )
        
        let mapsService = MapsService()
        mapsService.getDirections(request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [self] completion in
                    isLoadingDirections = false
                    
                    if case let .failure(error) = completion {
                        directionsError = "Failed to get directions: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [self] response in
                    directionsResponse = response
                    directionsError = nil
                }
            )
            .store(in: &mapViewModel.cancellables)
    }
}
