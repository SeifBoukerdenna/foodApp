import Foundation
import Combine

class AuthViewModel: ObservableObject {
    // Published properties for observed state
    @Published var isAuthenticated = false
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage = ""
    
    // For future implementation:
    func login() {
        // Implement actual login logic here
        print("Login attempted with: \(email)")
    }
    
    func signInWithGoogle() {
        // Implement Google sign-in
        print("Google sign-in attempted")
    }
    
    func forgotPassword() {
        // Implement password reset
        print("Password reset for: \(email)")
    }
}
