import Foundation
import Combine
import FirebaseCore
import FirebaseAuth
import Security

protocol AuthenticationServiceProtocol {
    func login(email: String, password: String) -> AnyPublisher<User, Error>
    func signUp(email: String, password: String, displayName: String?) -> AnyPublisher<User, Error>
    func resetPassword(email: String) -> AnyPublisher<Void, Error>
    func signOut() -> AnyPublisher<Void, Error>
    func getCurrentUser() -> User?
    func getIdToken() -> AnyPublisher<String, Error>
    func sendEmailVerification() -> AnyPublisher<Void, Error>
    func checkEmailVerificationStatus() -> AnyPublisher<Bool, Error>
    func saveCredentials(email: String, password: String) -> Bool
    func getCredentials() -> (email: String, password: String)?
}

enum AuthError: Error, LocalizedError {
    case signInError
    case signUpError
    case signOutError
    case userNotFound
    case tokenError
    case serverError(String)
    case networkError
    case verificationError
    case keychainError
    
    var errorDescription: String? {
        switch self {
        case .signInError:
            return "Failed to sign in. Please check your credentials and try again."
        case .signUpError:
            return "Failed to create account. This email may already be in use."
        case .signOutError:
            return "Failed to sign out. Please try again."
        case .userNotFound:
            return "User not found. Please sign in again."
        case .tokenError:
            return "Authentication error. Please sign in again."
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .verificationError:
            return "Failed to verify email. Please try again later."
        case .keychainError:
            return "Failed to securely store or retrieve credentials."
        }
    }
}

class AuthenticationService: AuthenticationServiceProtocol {
    private let networkClient: NetworkClient
    private var cancellables = Set<AnyCancellable>()

    
    init(networkClient: NetworkClient = NetworkClient(baseURLString: AppEnvironment.shared.apiBaseURL)) {
        self.networkClient = networkClient
    }
    
    func login(email: String, password: String) -> AnyPublisher<User, Error> {
        return Future<User, Error> { promise in
            // First authenticate with Firebase
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Firebase authentication error: \(error.localizedDescription)")
                    promise(.failure(AuthError.signInError))
                    return
                }
                
                guard let firebaseUser = authResult?.user else {
                    promise(.failure(AuthError.userNotFound))
                    return
                }
                
                // Save credentials on successful login
                _ = self.saveCredentials(email: email, password: password)
                
                // Get Firebase ID token
                firebaseUser.getIDToken { token, error in
                    if let error = error {
                        print("Failed to get ID token: \(error.localizedDescription)")
                        promise(.failure(AuthError.tokenError))
                        return
                    }
                    
                    guard let token = token else {
                        promise(.failure(AuthError.tokenError))
                        return
                    }
                    
                    // Verify the token with our server to get user data
                    let verifyTokenRequest: [String: String] = ["token": token]
                    
                    // Create a typed publisher variable
                    let tokenVerification: AnyPublisher<UserData, Error> =
                        self.networkClient.post(endpoint: "api/v1/auth/verify-token", body: verifyTokenRequest)
                    
                    // Now use the typed publisher
                    tokenVerification
                        .map { userData -> User in
                            return User(
                                id: userData.uid,
                                email: userData.email ?? "",
                                displayName: userData.displayName,
                                profileImageURL: nil,
                                friends: [],
                                favoriteRestaurants: [],
                                lastActive: Date(),
                                joinDate: Date(),
                                isEmailVerified: firebaseUser.isEmailVerified
                            )
                        }
                        .sink(
                            receiveCompletion: { completion in
                                if case let .failure(error) = completion {
                                    promise(.failure(error))
                                }
                            },
                            receiveValue: { user in
                                promise(.success(user))
                            }
                        )
                        .store(in: &AppEnvironment.shared.cancellables)
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func signUp(email: String, password: String, displayName: String?) -> AnyPublisher<User, Error> {
        return Future<User, Error> { promise in
            // Create Firebase user first
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
                guard let self = self else { return }
                
                if let error = error {
                    // Get detailed Firebase error
                    let nsError = error as NSError
                    let errorCode = nsError.code
                    let errorMessage = nsError.localizedDescription
                    
                    print("Firebase create user detailed error:")
                    print("Code: \(errorCode)")
                    print("Message: \(errorMessage)")
                    
                    promise(.failure(AuthError.signUpError))
                    return
                }
                
                guard let firebaseUser = authResult?.user else {
                    promise(.failure(AuthError.userNotFound))
                    return
                }
                
                // Successfully created Firebase user
                print("✅ Firebase Auth user created: \(firebaseUser.uid)")
                
                // Save credentials on successful signup
                _ = self.saveCredentials(email: email, password: password)
                
                // Update display name if provided
                let changeRequest = firebaseUser.createProfileChangeRequest()
                changeRequest.displayName = displayName
                
                changeRequest.commitChanges { [weak self] error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Failed to update profile: \(error.localizedDescription)")
                    }
                    
                    // Create user in backend database
                    let registerRequest = RegisterRequest(
                        email: email,
                        password: "**REDACTED**", // Don't send actual password to backend
                        username: email.split(separator: "@").first?.lowercased() ?? email.lowercased(),
                        displayName: displayName ?? "User"
                    )
                    
                    // API call to register in backend
                    self.networkClient.post(endpoint: "api/v1/auth/register", body: registerRequest)
                        .map { (response: RegisterResponse) -> User in
                            print("✅ Backend registration successful: \(response.uid)")
                            return User(
                                id: firebaseUser.uid,
                                email: email,
                                displayName: displayName,
                                isEmailVerified: firebaseUser.isEmailVerified
                            )
                        }
                        .catch { error -> AnyPublisher<User, Error> in
                            // Check for specific errors
                            if let networkError = error as? NetworkError,
                               case .httpError(let statusCode) = networkError,
                               statusCode == 409 {
                                print("⚠️ Backend reports user already exists (409) - continuing anyway")
                                // Even if our backend reports conflict, we still have a valid Firebase user
                            } else {
                                print("❌ Backend registration failed: \(error)")
                            }
                            
                            // Always return success with Firebase user
                            // since Firebase Auth is our source of truth
                            return Just(User(
                                id: firebaseUser.uid,
                                email: email,
                                displayName: displayName,
                                isEmailVerified: firebaseUser.isEmailVerified
                            ))
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                        }
                        .sink(
                            receiveCompletion: { completion in
                                if case let .failure(error) = completion {
                                    // This shouldn't happen due to the catch above
                                    print("❌ Unexpected error: \(error)")
                                    promise(.failure(error))
                                }
                            },
                            receiveValue: { user in
                                promise(.success(user))
                            }
                        )
                        .store(in: &self.cancellables)
                }
            }
        }.eraseToAnyPublisher()
    }

    // New helper method to separate concerns
    private func createUserInDatabase(firebaseUser: FirebaseAuth.User, email: String, displayName: String?) -> AnyPublisher<User, Error> {
        let registerRequest = RegisterRequest(
            email: email,
            password: "**REDACTED**", // Never send actual password to backend
            username: email.split(separator: "@").first?.lowercased() ?? email.lowercased(),
            displayName: displayName ?? "User"
        )
        
        // Create a typed publisher variable
        return networkClient.post(endpoint: "api/v1/auth/register", body: registerRequest)
            .map { (response: RegisterResponse) -> User in
                print("✅ Registration successful: \(response.uid)")
                return User(
                    id: firebaseUser.uid,
                    email: email,
                    displayName: displayName,
                    isEmailVerified: firebaseUser.isEmailVerified
                )
            }
            .catch { error -> AnyPublisher<User, Error> in
                print("❌ Registration API error: \(error)")
                // If our backend fails, still return a user based on Firebase auth
                return Just(User(
                    id: firebaseUser.uid,
                    email: email,
                    displayName: displayName,
                    isEmailVerified: firebaseUser.isEmailVerified
                ))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func resetPassword(email: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func signOut() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            do {
                try Auth.auth().signOut()
                promise(.success(()))
            } catch {
                promise(.failure(AuthError.signOutError))
            }
        }.eraseToAnyPublisher()
    }
    
    func getCurrentUser() -> User? {
        guard let firebaseUser = Auth.auth().currentUser else { return nil }
        
        return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName,
            isEmailVerified: firebaseUser.isEmailVerified
        )
    }
    
    func getIdToken() -> AnyPublisher<String, Error> {
        return Future<String, Error> { promise in
            guard let firebaseUser = Auth.auth().currentUser else {
                promise(.failure(AuthError.userNotFound))
                return
            }
            
            firebaseUser.getIDToken { token, error in
                if let error = error {
                    promise(.failure(error))
                } else if let token = token {
                    promise(.success(token))
                } else {
                    promise(.failure(AuthError.tokenError))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func sendEmailVerification() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            guard let user = Auth.auth().currentUser else {
                promise(.failure(AuthError.userNotFound))
                return
            }
            
            user.sendEmailVerification { error in
                if let error = error {
                    print("Failed to send verification email: \(error.localizedDescription)")
                    promise(.failure(AuthError.verificationError))
                } else {
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func checkEmailVerificationStatus() -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            guard let user = Auth.auth().currentUser else {
                promise(.failure(AuthError.userNotFound))
                return
            }
            
            // Reload user to get the latest verification status
            user.reload { error in
                if let error = error {
                    print("Failed to reload user: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                
                // Get fresh user after reload
                if let freshUser = Auth.auth().currentUser {
                    promise(.success(freshUser.isEmailVerified))
                } else {
                    promise(.failure(AuthError.userNotFound))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func sendSimpleEmailVerification() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            guard let user = Auth.auth().currentUser else {
                promise(.failure(AuthError.userNotFound))
                return
            }
            
            // Use the basic method without custom ActionCodeSettings
            user.sendEmailVerification { error in
                if let error = error {
                    print("Failed to send verification email: \(error.localizedDescription)")
                    promise(.failure(error))
                } else {
                    print("✅ Verification email sent directly through Firebase")
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Keychain methods
    
    // Save credentials to keychain
    func saveCredentials(email: String, password: String) -> Bool {
        // Create dictionary of credentials
        let credentials = [
            "email": email,
            "password": password
        ]
        
        // Convert dictionary to data
        guard let credentialsData = try? JSONSerialization.data(withJSONObject: credentials) else {
            print("Failed to serialize credentials")
            return false
        }
        
        // Create keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.foodmap.credentials",
            kSecAttrAccount as String: "foodMapUser",
            kSecValueData as String: credentialsData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Delete any existing credentials
        SecItemDelete(query as CFDictionary)
        
        // Add new credentials
        let status = SecItemAdd(query as CFDictionary, nil)
        
        // Return true if successful, false otherwise
        return status == errSecSuccess
    }
    
    // Get credentials from keychain
    func getCredentials() -> (email: String, password: String)? {
        // Create keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.foodmap.credentials",
            kSecAttrAccount as String: "foodMapUser",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        // Execute query
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        // Check if query was successful
        guard status == errSecSuccess,
              let data = result as? Data,
              let credentials = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let email = credentials["email"],
              let password = credentials["password"] else {
            return nil
        }
        
        return (email, password)
    }
}
