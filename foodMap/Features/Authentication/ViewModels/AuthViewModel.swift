import Foundation
import FirebaseAuth
import Combine

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
    @Published var isEmailVerified = false
    @Published var isCheckingEmailVerification = false
    @Published var verificationEmailSent = false
    
    private let authService: AuthenticationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var timer: Timer?
    
    init(authService: AuthenticationServiceProtocol = AuthenticationService()) {
        self.authService = authService
        
        // Check if user is already logged in
        if let currentUser = authService.getCurrentUser() {
            self.user = currentUser
            self.isAuthenticated = true
            self.isEmailVerified = currentUser.isEmailVerified
        }
        
        // Listen for Firebase auth state changes and store the returned handle
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                if let user = user {
                    self?.isEmailVerified = user.isEmailVerified
                    self?.email = user.email ?? ""
                    
                    // Create User object
                    self?.user = User(
                        id: user.uid,
                        email: user.email ?? "",
                        displayName: user.displayName,
                        isEmailVerified: user.isEmailVerified
                    )
                }
            }
        }
    }
    
    deinit {
        if let authStateHandler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(authStateHandler)
        }
        stopVerificationTimer()
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
                    self?.isEmailVerified = user.isEmailVerified
                    self?.email = user.email
                    self?.password = ""
                    
                    // Check verification status
                    self?.checkEmailVerificationStatus()
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
                    guard let self = self else { return }
                    
                    self.user = user
                    self.isAuthenticated = true
                    self.isEmailVerified = user.isEmailVerified
                    
                    // Send verification email after successful signup
                    self.sendVerificationEmail()
                    
                    // Start timer to check verification status
                    self.startVerificationTimer()
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
                    self?.isEmailVerified = false
                    self?.email = ""
                    self?.password = ""
                    self?.username = ""
                    self?.displayName = ""
                    self?.errorMessage = ""
                    self?.stopVerificationTimer()
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
                    self?.errorMessage = "Password reset email sent to \(self?.email ?? "your email"). Please check your inbox."
                }
            )
            .store(in: &cancellables)
    }
    
    func sendVerificationEmail() {
        isLoading = true
        errorMessage = ""
        
        // First try simple verification through Firebase (without domain)
        if let authService = self.authService as? AuthenticationService {
            authService.sendSimpleEmailVerification()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoading = false
                        
                        if case let .failure(error) = completion {
                            // If simple verification fails, show error
                            print("Simple verification failed: \(error.localizedDescription)")
                            self?.errorMessage = "Failed to send verification email: \(error.localizedDescription)"
                        }
                    },
                    receiveValue: { [weak self] _ in
                        self?.verificationEmailSent = true
                        self?.errorMessage = "Verification email sent to \(self?.email ?? "your email"). Please check your inbox."
                        
                        // Start timer to check verification status
                        self?.startVerificationTimer()
                    }
                )
                .store(in: &cancellables)
        } else {
            // Fallback to regular verification method
            authService.sendEmailVerification()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoading = false
                        
                        if case let .failure(error) = completion {
                            self?.errorMessage = "Failed to send verification email: \(error.localizedDescription)"
                        }
                    },
                    receiveValue: { [weak self] _ in
                        self?.verificationEmailSent = true
                        self?.errorMessage = "Verification email sent to \(self?.email ?? "your email"). Please check your inbox."
                        
                        // Start timer to check verification status
                        self?.startVerificationTimer()
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    func checkEmailVerificationStatus() {
        isCheckingEmailVerification = true
        errorMessage = ""
        
        // First ensure the user is reloaded to get fresh data
        if let user = Auth.auth().currentUser {
            user.reload { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.isCheckingEmailVerification = false
                        self?.errorMessage = "Failed to refresh user data: \(error.localizedDescription)"
                    }
                    return
                }
                
                // Now check verification status
                self?.authService.checkEmailVerificationStatus()
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { [weak self] completion in
                            self?.isCheckingEmailVerification = false
                            
                            if case let .failure(error) = completion {
                                self?.errorMessage = "Failed to check verification status: \(error.localizedDescription)"
                            }
                        },
                        receiveValue: { [weak self] isVerified in
                            guard let self = self else { return }
                            
                            self.isEmailVerified = isVerified
                            
                            // Update user model
                            if var currentUser = self.user {
                                currentUser.isEmailVerified = isVerified
                                self.user = currentUser
                            }
                            
                            if isVerified {
                                self.errorMessage = "Email verified successfully!"
                                self.stopVerificationTimer()
                            }
                        }
                    )
                    .store(in: &self!.cancellables)
            }
        } else {
            isCheckingEmailVerification = false
            errorMessage = "No user is signed in"
        }
    }
    
    // Start a timer to periodically check verification status
    private func startVerificationTimer() {
        stopVerificationTimer() // Stop any existing timer
        
        // Create a new timer that fires every 30 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkEmailVerificationStatus()
        }
    }
    
    // Stop the verification timer
    private func stopVerificationTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func signInWithGoogle() {
        // This would require Google Sign-In SDK integration
        // For now, we'll use a placeholder message
        errorMessage = "Google Sign-In will be implemented in a future update"
    }
}
