import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showLogin = false
    @State private var hasCompletedOnboarding = false
    @State private var displayName = "FoodLover" // Default name for testing
    @State private var showVerificationScreen = false
    @State private var selectedTab = 0
    
    // Check if we should auto-login
    @State private var shouldAttemptAutoLogin = true
    
    var body: some View {
        if authViewModel.isAuthenticated {
            if showVerificationScreen {
                // Show verification screen right after signup
                EmailVerificationView(viewModel: authViewModel, onContinue: {
                    showVerificationScreen = false
                    hasCompletedOnboarding = true
                })
                .preferredColorScheme(.dark)
                .environmentObject(authViewModel)
            } else if hasCompletedOnboarding {
                // MAIN APP VIEW WITH RED NAVBAR
                ZStack(alignment: .bottom) {
                    // Content based on selected tab
                    ZStack {
                        switch selectedTab {
                        case 0:
                            HomeView(displayName: authViewModel.user?.displayName ?? displayName)
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
                            HomeView(displayName: authViewModel.user?.displayName ?? displayName)
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
                    // Check email verification status
                    authViewModel.checkEmailVerificationStatus()
                }
            } else {
                // Onboarding screens
                OnboardingContainer()
                    .environmentObject(authViewModel)
                    .onDisappear {
                        hasCompletedOnboarding = true
                    }
            }
        } else {
            // Authentication
            if showLogin {
                LoginView(showLogin: $showLogin, onLogin: { username in
                    displayName = username
                    hasCompletedOnboarding = true
                })
                .environmentObject(authViewModel)
            } else {
                SignUpView(showLogin: $showLogin, onSignUp: { username in
                    displayName = username
                    showVerificationScreen = true
                })
                .environmentObject(authViewModel)
            }
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
    
    // Auto-login with stored credentials
    private func attemptAutoLogin() {
        guard shouldAttemptAutoLogin,
              !authViewModel.isAuthenticated,
              let authService = authViewModel.authService as? AuthenticationService,
              let credentials = authService.getCredentials() else {
            // If we don't have credentials or already authenticated, do nothing
            shouldAttemptAutoLogin = false
            return
        }
        
        // Prevent multiple attempts
        shouldAttemptAutoLogin = false
        
        // Only auto-login if we have stored credentials
        print("Attempting auto-login with stored credentials")
        authViewModel.email = credentials.email
        authViewModel.password = credentials.password
        authViewModel.login()
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
