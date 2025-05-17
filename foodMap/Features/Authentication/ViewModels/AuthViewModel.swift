import Foundation
import FirebaseAuth
import Combine

class AuthViewModel: ObservableObject {
    // MARK: - Published Properties (Observable State)
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
    
    // MARK: - Private Properties
    private let _authService: AuthenticationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var timer: Timer?
    
    // MARK: - Public Properties
    var authService: AuthenticationServiceProtocol {
        return _authService
    }
    
    // MARK: - Initialization
    init(authService: AuthenticationServiceProtocol = AuthenticationService()) {
        self._authService = authService
        
        // Check if credentials are stored in keychain
        if let credentials = authService.getCredentials() {
            self.email = credentials.email
            self.password = credentials.password
            print("✅ Found stored credentials for: \(credentials.email)")
        }
        
        // Check if user is already logged in
        if let currentUser = authService.getCurrentUser() {
            self.user = currentUser
            self.isAuthenticated = true
            self.isEmailVerified = currentUser.isEmailVerified
            print("✅ User already authenticated: \(currentUser.id)")
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
                    
                    print("👤 Firebase auth state changed: User authenticated")
                } else {
                    print("👤 Firebase auth state changed: No user")
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
    
    // MARK: - Authentication Methods
    
    /// Login with email and password
    func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password cannot be empty"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        print("🔑 Attempting login for: \(email)")
        
        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case let .failure(error) = completion {
                        print("❌ Login failed: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] user in
                    guard let self = self else { return }
                    
                    print("✅ Login successful for user: \(user.id)")
                    self.user = user
                    self.isAuthenticated = true
                    self.isEmailVerified = user.isEmailVerified
                    
                    // Save credentials - handled in AuthService
                    
                    // Check verification status
                    self.checkEmailVerificationStatus()
                }
            )
            .store(in: &cancellables)
    }
    
    /// Sign up a new user
    func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password cannot be empty"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        print("🔑 Attempting signup for: \(email)")
        
        let finalDisplayName = displayName.isEmpty ? username : displayName
        
        authService.signUp(email: email, password: password, displayName: finalDisplayName)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case let .failure(error) = completion {
                        print("❌ Signup failed: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] user in
                    guard let self = self else { return }
                    
                    print("✅ Signup successful for user: \(user.id)")
                    self.user = user
                    self.isAuthenticated = true
                    self.isEmailVerified = user.isEmailVerified
                    
                    // Save credentials - handled in AuthService
                    
                    // Send verification email after successful signup
                    self.sendVerificationEmail()
                    
                    // Start timer to check verification status
                    self.startVerificationTimer()
                }
            )
            .store(in: &cancellables)
    }
    
    /// Sign out the current user
    func signOut() {
        isLoading = true
        
        authService.signOut()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case let .failure(error) = completion {
                        print("❌ Sign out failed: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    guard let self = self else { return }
                    
                    print("✅ Sign out successful")
                    self.user = nil
                    self.isAuthenticated = false
                    self.isEmailVerified = false
                    // Do not clear credentials, keep them for next login
                    self.errorMessage = ""
                    self.stopVerificationTimer()
                }
            )
            .store(in: &cancellables)
    }
    
    /// Request password reset for the current email
    func forgotPassword() {
        guard !email.isEmpty else {
            errorMessage = "Email cannot be empty"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        print("🔑 Sending password reset for: \(email)")
        
        authService.resetPassword(email: email)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case let .failure(error) = completion {
                        print("❌ Password reset failed: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    guard let self = self else { return }
                    
                    print("✅ Password reset email sent to \(self.email)")
                    self.errorMessage = "Password reset email sent to \(self.email). Please check your inbox."
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Email Verification Methods
    
    /// Send verification email to the current user
    func sendVerificationEmail() {
        isLoading = true
        errorMessage = ""
        
        print("📧 Sending verification email to: \(email)")
        
        // First try simple verification through Firebase (without domain)
        if let authService = self.authService as? AuthenticationService {
            authService.sendSimpleEmailVerification()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoading = false
                        
                        if case let .failure(error) = completion {
                            // If simple verification fails, show error
                            print("❌ Simple verification failed: \(error.localizedDescription)")
                            self?.errorMessage = "Failed to send verification email: \(error.localizedDescription)"
                        }
                    },
                    receiveValue: { [weak self] _ in
                        guard let self = self else { return }
                        
                        print("✅ Verification email sent")
                        self.verificationEmailSent = true
                        self.errorMessage = "Verification email sent to \(self.email). Please check your inbox."
                        
                        // Start timer to check verification status
                        self.startVerificationTimer()
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
                            print("❌ Verification email failed: \(error.localizedDescription)")
                            self?.errorMessage = "Failed to send verification email: \(error.localizedDescription)"
                        }
                    },
                    receiveValue: { [weak self] _ in
                        guard let self = self else { return }
                        
                        print("✅ Verification email sent")
                        self.verificationEmailSent = true
                        self.errorMessage = "Verification email sent to \(self.email). Please check your inbox."
                        
                        // Start timer to check verification status
                        self.startVerificationTimer()
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    /// Check the current user's email verification status
    func checkEmailVerificationStatus() {
        isCheckingEmailVerification = true
        errorMessage = ""
        
        print("🔍 Checking verification status for: \(email)")
        
        // First ensure the user is reloaded to get fresh data
        if let user = Auth.auth().currentUser {
            user.reload { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.isCheckingEmailVerification = false
                        self.errorMessage = "Failed to refresh user data: \(error.localizedDescription)"
                        print("❌ Failed to reload user: \(error.localizedDescription)")
                    }
                    return
                }
                
                // Now check verification status
                self.authService.checkEmailVerificationStatus()
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { completion in
                            self.isCheckingEmailVerification = false
                            
                            if case let .failure(error) = completion {
                                print("❌ Failed to check verification status: \(error.localizedDescription)")
                                self.errorMessage = "Failed to check verification status: \(error.localizedDescription)"
                            }
                        },
                        receiveValue: { isVerified in
                            self.isEmailVerified = isVerified
                            
                            // Update user model
                            if var currentUser = self.user {
                                currentUser.isEmailVerified = isVerified
                                self.user = currentUser
                            }
                            
                            if isVerified {
                                print("✅ Email verified successfully")
                                self.errorMessage = "Email verified successfully!"
                                self.stopVerificationTimer()
                            } else {
                                print("⏳ Email not yet verified")
                            }
                        }
                    )
                    .store(in: &self.cancellables)
            }
        } else {
            isCheckingEmailVerification = false
            errorMessage = "No user is signed in"
            print("❌ No user signed in to check verification")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Attempt to sign in with Google (placeholder for future implementation)
    func signInWithGoogle() {
        // This would require Google Sign-In SDK integration
        errorMessage = "Google Sign-In will be implemented in a future update"
        print("⚠️ Google Sign-In not yet implemented")
    }
    
    /// Start a timer to periodically check verification status
    private func startVerificationTimer() {
        stopVerificationTimer() // Stop any existing timer
        
        print("⏱️ Starting verification check timer")
        
        // Create a new timer that fires every 30 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            print("⏱️ Auto-checking verification status")
            self?.checkEmailVerificationStatus()
        }
    }
    
    /// Stop the verification timer
    private func stopVerificationTimer() {
        if timer != nil {
            print("⏱️ Stopping verification check timer")
            timer?.invalidate()
            timer = nil
        }
    }
    
    /// Attempt automatic login with stored credentials
    func attemptAutoLogin() -> Bool {
        guard !isAuthenticated,
              let credentials = authService.getCredentials(),
              !credentials.email.isEmpty,
              !credentials.password.isEmpty else {
            return false
        }
        
        print("🔄 Attempting auto-login with stored credentials")
        
        // Set credentials and login
        email = credentials.email
        password = credentials.password
        login()
        
        return true
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = ""
    }
    
    /// Update user display name
    func updateDisplayName(newName: String) -> AnyPublisher<Bool, Error> {
        guard let user = Auth.auth().currentUser else {
            return Fail(error: AuthError.userNotFound).eraseToAnyPublisher()
        }
        
        return Future<Bool, Error> { promise in
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = newName
            
            changeRequest.commitChanges { error in
                if let error = error {
                    print("❌ Failed to update display name: \(error.localizedDescription)")
                    promise(.failure(error))
                } else {
                    print("✅ Display name updated to: \(newName)")
                    // Update the local user object
                    if var currentUser = self.user {
                        currentUser.displayName = newName
                        self.user = currentUser
                    }
                    promise(.success(true))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
