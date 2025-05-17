import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showLogin = false
    @State private var hasCompletedOnboarding = false
    @State private var displayName = "JjaJ" // Default name for testing
    
    var body: some View {
        if authViewModel.isAuthenticated || hasCompletedOnboarding {
            // Main app screens
            HomeView(displayName: authViewModel.user?.displayName ?? displayName)
                .preferredColorScheme(.dark) // Force dark mode per design
                .environmentObject(authViewModel) // Pass the auth view model
        } else {
            // Authentication and onboarding
            if showLogin {
                LoginView(showLogin: $showLogin, onLogin: { username in
                    displayName = username
                    hasCompletedOnboarding = true
                })
                .environmentObject(authViewModel)
            } else {
                SignUpView(showLogin: $showLogin, onSignUp: { username in
                    displayName = username
                    hasCompletedOnboarding = true
                })
                .environmentObject(authViewModel)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
