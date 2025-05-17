import SwiftUI
import MapKit

struct HomeView: View {
    // MARK: - Properties
    let displayName: String
    @StateObject private var viewModel = HomeViewModel()
    @State private var showPreferencesSheet = false
    @State private var searchText = ""
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.5741, longitude: -73.6921), // Laval coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showLogoutConfirmation = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Dark map background
            Map(coordinateRegion: $region)
                .colorScheme(.dark)
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Verification Status Banner (if needed)
                if let user = authViewModel.user, !user.isEmailVerified {
                    VerificationStatusView(viewModel: authViewModel)
                }
                
                // Header with search and logout button
                VStack(spacing: 16) {
                    // Spacer for status bar
                    Spacer().frame(height: 44)
                    
                    // Search bar and logout button
                    HStack(spacing: 12) {
                        // Search bar (takes most of the space)
                        searchBarView
                        
                        // Logout button
                        Button(action: {
                            showLogoutConfirmation = true
                        }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(Color.brandRed)
                                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
                
                // Always show the container, just change its content
                suggestionsContainerView
            }
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.dark)
        .onAppear {
            // Check email verification status when view appears
            authViewModel.checkEmailVerificationStatus()
            
            // Load suggestions after a small delay to avoid state updates during view render
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.getDefaultSuggestions()
            }
        }
        .sheet(isPresented: $showPreferencesSheet) {
            PreferencesSheet(isPresented: $showPreferencesSheet) { preferences in
                viewModel.getRestaurantSuggestions(preferences: preferences)
            }
        }
        .alert(isPresented: $showLogoutConfirmation) {
            Alert(
                title: Text("Log Out"),
                message: Text("Are you sure you want to log out?"),
                primaryButton: .destructive(Text("Log Out")) {
                    authViewModel.signOut()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Search Bar View
    private var searchBarView: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.7))
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
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Suggestions Container
    private var suggestionsContainerView: some View {
        VStack(spacing: 0) {
            // Container for either penguin CTA or restaurant suggestions
            if viewModel.isLoading || viewModel.errorMessage != nil || !viewModel.suggestedRestaurants.isEmpty {
                // Show suggestions/loading/error
                suggestionContent
            } else {
                // Show penguin CTA
                penguinCTAView
            }
        }
        .padding(.bottom, 85) // Space for tab bar
    }
    
    // MARK: - Penguin CTA View
    private var penguinCTAView: some View {
        VStack(spacing: 0) {
            // Penguin image
            Image("penguin_chef")
                .resizable()
                .scaledToFit()
                .frame(width: 100)
                .padding(.bottom, -10)
            
            // CTA Button
            Button(action: {
                viewModel.getDefaultSuggestions()
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Oh Mighty Penguin, Find")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text("Me a Feast!")
                        .font(.system(size: 18, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Suggestion Content (Loading, Error, or Results)
    private var suggestionContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Restaurant Suggestions")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Customize button
                Button(action: {
                    showPreferencesSheet = true
                }) {
                    HStack(spacing: 4) {
                        Text("Customize")
                            .font(.subheadline)
                        
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        Capsule()
                            .fill(Color.brandRed)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Content
            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView
            } else {
                suggestionsView
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Chef Penguin is cooking up suggestions...")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: 16) {
            Text("😕")
                .font(.system(size: 40))
            
            Text(viewModel.errorMessage ?? "Error: The operation couldn't be completed.")
                .font(.body)
                .foregroundColor(.red.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                viewModel.getDefaultSuggestions()
            }) {
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
    
    // MARK: - Suggestions View
    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Restaurant suggestions content
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
    
    // MARK: - Restaurant Card
    private func restaurantCard(_ restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Restaurant name
            Text(restaurant.name)
                .font(.headline)
                .foregroundColor(.white)
            
            // Restaurant details
            Text(restaurant.description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
            
            // Tags
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
    
    // MARK: - Helper Methods
    private func parseRestaurantSuggestions() -> [Restaurant] {
        // This is a simple parser that extracts restaurant names and descriptions
        // from the GPT response text
        let text = viewModel.suggestedRestaurants
        
        // Split by numbered list items (assumes the format includes numbers like "1. ")
        let pattern = #"\d+\.\s+\*\*([^*]+)\*\*:([^\n]+)(?:\n\n|\.$|\z)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return [Restaurant(
                id: UUID().uuidString,
                name: "Restaurant Recommendations",
                description: text,
                tags: ["Italian", "Vegetarian", "Gluten-Free"]
            )]
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
                        
                        let tags: [String] = ["Italian", "Vegetarian", "Gluten-Free"]
                        
                        restaurants.append(Restaurant(
                            id: UUID().uuidString,
                            name: name,
                            description: description,
                            tags: tags
                        ))
                    }
                }
            }
        }
        
        // If no matches, create a fallback restaurant from the whole text
        if restaurants.isEmpty {
            restaurants = [
                Restaurant(
                    id: UUID().uuidString,
                    name: "Restaurant Recommendations",
                    description: text,
                    tags: ["Italian", "Vegetarian", "Gluten-Free"]
                )
            ]
        }
        
        return restaurants
    }
}

// MARK: - Restaurant Model
struct Restaurant {
    let id: String
    let name: String
    let description: String
    let tags: [String]
}

// MARK: - Preferences Sheet
struct PreferencesSheet: View {
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
                        .padding(.bottom, 60) // Extra padding to avoid keyboard overlap
                    }
                    .padding()
                }
            }
            .navigationTitle("Food Preferences")
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
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white)
            .padding(.bottom, 4)
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
                        Text(option)
                            .font(.system(size: 14))
                        
                        Spacer()
                        
                        if selectedDietary.contains(option.lowercased()) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.brandRed)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
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
        Button(action: {
            selectedPriceRange = range
        }) {
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
            Toggle("Quiet Environment", isOn: $quietEnvironment)
                .toggleStyle(SwitchToggleStyle(tint: .brandRed))
            
            Toggle("Outdoor Seating", isOn: $outdoorSeating)
                .toggleStyle(SwitchToggleStyle(tint: .brandRed))
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
    
    private func submitPreferences() {
        // Convert selected options to lowercase for API
        let dietaryLowercase = selectedDietary.map { $0.lowercased() }
        
        // Create additional preferences dictionary
        var additionalPrefs = [String: Bool]()
        additionalPrefs["quietEnvironment"] = quietEnvironment
        additionalPrefs["outdoorSeating"] = outdoorSeating
        
        let preferences = RestaurantPreferences(
            cuisine: cuisine,
            dietary: dietaryLowercase,
            priceRange: selectedPriceRange,
            location: location,
            additionalPreferences: additionalPrefs
        )
        
        onSubmit(preferences)
        isPresented = false
    }
}
