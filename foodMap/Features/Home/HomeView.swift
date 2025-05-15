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
    @State private var showingSearchResults = false
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            // Map Background - Full screen with dark mode styling
            Map(coordinateRegion: $region)
                .ignoresSafeArea()
                .colorScheme(.dark)
            
            // Search bar at the top
            VStack(spacing: 0) {
                // Top safety space
                Color.clear.frame(height: 48)
                
                // Search Bar
                searchBar
                
                Spacer()
            }
            
            // Restaurant suggestion overlay when results exist
            if viewModel.isLoading || viewModel.errorMessage != nil {
                VStack {
                    Spacer()
                    suggestionOverlay
                }
            }
            
            // Bottom "Find me a feast" card
            VStack {
                Spacer()
                findMeAFeastCard
                    .padding(.bottom, 80) // Make room for tab bar
            }
            
            // Penguin overlay (in bottom right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("penguin_chef")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70)
                        .padding(.trailing, 16)
                        .padding(.bottom, 120)
                }
            }
            
            // Tab bar at bottom
            VStack {
                Spacer()
                CustomTabBar(selectedTab: .home)
            }
            .ignoresSafeArea(.keyboard)
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.dark)
        .onAppear {
            // Get restaurant suggestions automatically when the view appears
            if viewModel.suggestedRestaurants.isEmpty && viewModel.errorMessage == nil {
                viewModel.getDefaultSuggestions()
            }
        }
        .sheet(isPresented: $showPreferencesSheet) {
            PreferencesSheet(isPresented: $showPreferencesSheet, onSubmit: { preferences in
                viewModel.getRestaurantSuggestions(preferences: preferences)
            })
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .frame(height: 50)
                .shadow(radius: 2)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Where do you want to eat?", text: $searchText)
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Find Me A Feast Card
    private var findMeAFeastCard: some View {
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
            )
            .foregroundColor(.white)
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Suggestion Overlay
    private var suggestionOverlay: some View {
        VStack(spacing: 0) {
            // Header - black background with title
            Text("Restaurant Suggestions")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(Color.black)
            
            // Content
            if viewModel.isLoading {
                loadingView
                    .frame(height: 250)
            } else if let errorMessage = viewModel.errorMessage {
                errorView
                    .frame(height: 250)
            } else if !viewModel.suggestedRestaurants.isEmpty {
                suggestionsView
                    .frame(height: 250)
            }
        }
        .background(Color.black)
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
        .padding(.bottom, 80) // Space for the tab bar
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ZStack {
            Color.white
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .scaleEffect(1.5)
                
                Text("Finding delicious options for you...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Error View
    private var errorView: some View {
        ZStack {
            Color.white
            
            VStack(spacing: 16) {
                Text("😕")
                    .font(.system(size: 50))
                
                Text("Error: The operation couldn't be completed. (foodMap.NetworkError error 2.)")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    viewModel.getDefaultSuggestions()
                }) {
                    Text("Try Again")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.black)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Suggestions View
    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Color.white

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image("penguin_chef")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                        
                        Text("Chef Penguin's Recommendations")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    
                    ScrollView {
                        Text(viewModel.suggestedRestaurants)
                            .font(.body)
                            .foregroundColor(.black)
                    }
                    
                    Button(action: {
                        showPreferencesSheet = true
                    }) {
                        HStack {
                            Text("Customize Preferences")
                                .font(.system(size: 14, weight: .medium))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.brandRed)
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
    }
}

// MARK: - Tab Bar
struct CustomTabBar: View {
    enum Tab {
        case home, friends, map, cart, profile
    }
    
    var selectedTab: Tab
    
    var body: some View {
        HStack(spacing: 0) {
            tabButton(title: "Home", icon: "house.fill", isSelected: selectedTab == .home)
            tabButton(title: "Friends", icon: "person.2.fill", isSelected: selectedTab == .friends)
            
            // Center map button
            Button(action: {}) {
                Circle()
                    .fill(Color.brandRed)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    )
                    .offset(y: -15)
                    .shadow(radius: 4)
            }
            .frame(width: UIScreen.main.bounds.width / 5)
            
            tabButton(title: "Cart", icon: "cart.fill", isSelected: selectedTab == .cart)
            tabButton(title: "Profile", icon: "person.crop.circle.fill", isSelected: selectedTab == .profile)
        }
        .padding(.top, 8)
        .padding(.bottom, 30) // Add extra padding at bottom for safe area
        .background(Color.brandRed)
    }
    
    private func tabButton(title: String, icon: String, isSelected: Bool) -> some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.system(size: 12))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .frame(maxWidth: .infinity)
        }
    }
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

// MARK: - View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(displayName: "JjaJ")
    }
}
