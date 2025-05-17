import Foundation
import FirebaseAuth
import Combine


//import FirebaseAuth

class AuthViewModel: ObservableObject {
    // Published properties for observed state
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var email = ""
    @Published var password = ""
    @Published var username = ""
    @Published var displayName = ""
    @Published var errorMessage = ""
    @Published var isLoading = false
    
    private let authService: AuthenticationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    init(authService: AuthenticationServiceProtocol = AuthenticationService()) {
            self.authService = authService
            
            // Check if user is already logged in
            if let currentUser = authService.getCurrentUser() {
                self.user = currentUser
                self.isAuthenticated = true
            }
            
            // Listen for Firebase auth state changes and store the returned handle
            authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                DispatchQueue.main.async {
                    self?.isAuthenticated = user != nil
                }
            }
        }
    
    deinit {
           if let authStateHandler = authStateHandler {
               Auth.auth().removeStateDidChangeListener(authStateHandler)
           }
       }
    
    func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password cannot be empty"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case let .failure(error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] user in
                    self?.user = user
                    self?.isAuthenticated = true
                    self?.email = ""
                    self?.password = ""
                }
            )
            .store(in: &cancellables)
    }
    
    func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password cannot be empty"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        authService.signUp(email: email, password: password, displayName: displayName.isEmpty ? username : displayName)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case let .failure(error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] user in
                    self?.user = user
                    self?.isAuthenticated = true
                    self?.email = ""
                    self?.password = ""
                    self?.username = ""
                    self?.displayName = ""
                }
            )
            .store(in: &cancellables)
    }
    
    func signOut() {
        isLoading = true
        
        authService.signOut()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case let .failure(error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.user = nil
                    self?.isAuthenticated = false
                }
            )
            .store(in: &cancellables)
    }
    
    func forgotPassword() {
        guard !email.isEmpty else {
            errorMessage = "Email cannot be empty"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        authService.resetPassword(email: email)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case let .failure(error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.errorMessage = "Password reset email sent"
                }
            )
            .store(in: &cancellables)
    }
    
    func signInWithGoogle() {
        // This would require Google Sign-In SDK integration
        // For now, we'll use a placeholder message
        errorMessage = "Google Sign-In will be implemented in a future update"
    }
}
