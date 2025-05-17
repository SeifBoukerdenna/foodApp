import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showLogin = false
    @State private var hasCompletedOnboarding = false
    @State private var showVerificationScreen = false
    @State private var showDisplayNameSetup = false
    @State private var isNewUserSignup = false
    @State private var selectedTab = 0
    
    // Check if we should auto-login
    @State private var shouldAttemptAutoLogin = true
    
    var body: some View {
        ZStack {
            if authViewModel.isAuthenticated {
                if isNewUserSignup && showVerificationScreen {
                    // Show verification screen only after new user signup
                    EmailVerificationView(viewModel: authViewModel, onContinue: {
                        showVerificationScreen = false
                        showDisplayNameSetup = true
                        isNewUserSignup = false
                    })
                    .preferredColorScheme(.dark)
                    .environmentObject(authViewModel)
                } else if showDisplayNameSetup {
                    // Show display name setup before entering main app
                    DisplayNameSetupView(onComplete: {
                        showDisplayNameSetup = false
                        hasCompletedOnboarding = true
                    })
                    .environmentObject(authViewModel)
                } else if !hasCompletedOnboarding {
                    // Onboarding screens
                    OnboardingContainer()
                        .environmentObject(authViewModel)
                        .onDisappear {
                            hasCompletedOnboarding = true
                        }
                } else {
                    // MAIN APP VIEW WITH RED NAVBAR
                    MainAppView(
                        selectedTab: $selectedTab,
                        authViewModel: authViewModel
                    )
                }
            } else {
                // Authentication
                if showLogin {
                    LoginView(showLogin: $showLogin, onLogin: { _ in
                        // After login, user goes straight to main app or onboarding
                        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                        
                        // Check if display name is set - if not, go to display name setup
                        if let user = authViewModel.user, user.displayName?.isEmpty ?? true {
                            showDisplayNameSetup = true
                        }
                    })
                    .environmentObject(authViewModel)
                } else {
                    SignUpView(showLogin: $showLogin, onSignUp: { _ in
                        // After signup, mark as new user and show verification
                        isNewUserSignup = true
                        showVerificationScreen = true
                    })
                    .environmentObject(authViewModel)
                }
            }
        }
        .onAppear {
            // Attempt auto-login on app start if applicable
            if shouldAttemptAutoLogin {
                shouldAttemptAutoLogin = false
                
                // Check if user has completed onboarding before
                hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                
                // Try auto-login
                let loginAttempted = authViewModel.attemptAutoLogin()
                
                if !loginAttempted {
                    // If no auto-login possible, check if a user is already signed in
                    if let user = authViewModel.authService.getCurrentUser() {
                        authViewModel.user = user
                        authViewModel.isAuthenticated = true
                        
                        // Check if we need to show display name setup
                        if user.displayName?.isEmpty ?? true {
                            showDisplayNameSetup = true
                        }
                    }
                }
            }
        }
        // Listen for auth state changes from SignUpView
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            // Only handle transitions from not authenticated to authenticated
            if newValue && !oldValue {
                print("AUTH STATE CHANGED: User now authenticated")
                
                // If this was a new signup and not auto-login
                if isNewUserSignup {
                    print("NEW USER SIGNUP: Showing verification screen")
                    showVerificationScreen = true
                }
            }
        }
        // Save onboarding status when it changes
        .onChange(of: hasCompletedOnboarding) { oldValue, newValue in
            if newValue {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            }
        }
    }
}

// Extract the main app view to simplify the ContentView
struct MainAppView: View {
    @Binding var selectedTab: Int
    var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content based on selected tab
            ZStack {
                switch selectedTab {
                case 0:
                    HomeView(displayName: authViewModel.user?.displayName ?? "User")
                        .environmentObject(authViewModel)
                case 1:
                    Text("Friends")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                case 2:
                    Text("Map")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                case 3:
                    Text("Cart")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                case 4:
                    ProfileView()
                        .environmentObject(authViewModel)
                default:
                    HomeView(displayName: authViewModel.user?.displayName ?? "User")
                        .environmentObject(authViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            
            // CUSTOM RED NAVBAR
            HStack(spacing: 0) {
                // Home button
                tabButton(
                    icon: "house.fill",
                    title: "Home",
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                
                // Friends button
                tabButton(
                    icon: "person.2.fill",
                    title: "Friends",
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )
                
                // Center button holder
                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: UIScreen.main.bounds.width / 5)
                }
                
                // Cart button
                tabButton(
                    icon: "cart.fill",
                    title: "Cart",
                    isSelected: selectedTab == 3,
                    action: { selectedTab = 3 }
                )
                
                // Profile button
                tabButton(
                    icon: "person.crop.circle.fill",
                    title: "Profile",
                    isSelected: selectedTab == 4,
                    action: { selectedTab = 4 }
                )
            }
            .frame(height: 49)
            .padding(.top, 8)
            .padding(.bottom, 28) // Safe area padding
            .background(
                Color.brandRed
                    .cornerRadius(25, corners: [.topLeft, .topRight])
                    .edgesIgnoringSafeArea(.bottom)
            )
            
            // Special center button
            VStack {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.brandRed)
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                .offset(y: -15)
                .onTapGesture {
                    selectedTab = 2
                }
                
                Spacer()
                    .frame(height: 83) // Match tab bar height
            }
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.dark)
        .onAppear {
            // Check email verification status but don't show the verification screen
            authViewModel.checkEmailVerificationStatus()
        }
    }
    
    // Helper function for tab buttons
    private func tabButton(icon: String, title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                
                Text(title)
                    .font(.system(size: 12))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .frame(maxWidth: .infinity)
        }
    }
}

// Helper extension for rounded corners
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
