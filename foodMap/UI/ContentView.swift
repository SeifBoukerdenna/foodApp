import SwiftUI

struct ContentView: View {
    @State private var showLogin = false
    @State private var hasCompletedOnboarding = false
    @State private var displayName = "JjaJ" // Default name for testing
    
    var body: some View {
        if hasCompletedOnboarding {
            // Main app screens
            HomeView(displayName: displayName)
                .preferredColorScheme(.dark) // Force dark mode per design
        } else {
            // Authentication and onboarding
            if showLogin {
                LoginView(showLogin: $showLogin, onLogin: { username in
                    displayName = username
                    hasCompletedOnboarding = true
                })
            } else {
                SignUpView(showLogin: $showLogin, onSignUp: { username in
                    displayName = username
                    hasCompletedOnboarding = true
                })
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
