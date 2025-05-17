import Foundation
import Combine
import FirebaseCore
import FirebaseAuth

protocol AuthenticationServiceProtocol {
    func login(email: String, password: String) -> AnyPublisher<User, Error>
    func signUp(email: String, password: String, displayName: String?) -> AnyPublisher<User, Error>
    func resetPassword(email: String) -> AnyPublisher<Void, Error>
    func signOut() -> AnyPublisher<Void, Error>
    func getCurrentUser() -> User?
    func getIdToken() -> AnyPublisher<String, Error>
    func sendEmailVerification() -> AnyPublisher<Void, Error>
    func checkEmailVerificationStatus() -> AnyPublisher<Bool, Error>
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
        }
    }
}

class AuthenticationService: AuthenticationServiceProtocol {
    private let networkClient: NetworkClient
    
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
                    print("Firebase create user error: \(error.localizedDescription)")
                    promise(.failure(AuthError.signUpError))
                    return
                }
                
                guard let firebaseUser = authResult?.user else {
                    promise(.failure(AuthError.userNotFound))
                    return
                }
                
                // Update display name if provided
                let changeRequest = firebaseUser.createProfileChangeRequest()
                changeRequest.displayName = displayName
                
                changeRequest.commitChanges { [weak self] error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Failed to update profile: \(error.localizedDescription)")
                    }
                    
                    // Now create the user in our backend
                    let registerRequest = RegisterRequest(
                        email: email,
                        password: password,
                        username: email.split(separator: "@").first?.lowercased() ?? email.lowercased(),
                        displayName: displayName ?? "User"
                    )
                    
                    // Create a typed publisher variable
                    let registrationPublisher: AnyPublisher<RegisterResponse, Error> =
                        self.networkClient.post(endpoint: "api/v1/auth/register", body: registerRequest)
                    
                    registrationPublisher
                        .map { response -> User in
                            return User(
                                id: firebaseUser.uid,
                                email: email,
                                displayName: displayName,
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
}

#if DEBUG
extension AuthenticationService {
    static func testAuthentication() {
        let authService = AuthenticationService()
        let email = "test@example.com"
        let password = "password123"
        
        print("🔑 Testing user registration...")
        
        authService.signUp(email: email, password: password, displayName: "Test User")
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("❌ Registration failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { user in
                    print("✅ Registration successful: \(user.id)")
                    
                    print("🔑 Testing login...")
                    authService.login(email: email, password: password)
                        .sink(
                            receiveCompletion: { completion in
                                if case let .failure(error) = completion {
                                    print("❌ Login failed: \(error.localizedDescription)")
                                }
                            },
                            receiveValue: { user in
                                print("✅ Login successful: \(user.id)")
                                
                                print("🔑 Testing token retrieval...")
                                authService.getIdToken()
                                    .sink(
                                        receiveCompletion: { completion in
                                            if case let .failure(error) = completion {
                                                print("❌ Token retrieval failed: \(error.localizedDescription)")
                                            }
                                        },
                                        receiveValue: { token in
                                            print("✅ Token retrieved: \(token.prefix(10))...")
                                            
                                            print("🔑 Testing verification email...")
                                            authService.sendEmailVerification()
                                                .sink(
                                                    receiveCompletion: { completion in
                                                        if case let .failure(error) = completion {
                                                            print("❌ Send verification email failed: \(error.localizedDescription)")
                                                        } else {
                                                            print("✅ Verification email sent")
                                                        }
                                                        
                                                        print("🔑 Testing sign out...")
                                                        authService.signOut()
                                                            .sink(
                                                                receiveCompletion: { completion in
                                                                    if case let .failure(error) = completion {
                                                                        print("❌ Sign out failed: \(error.localizedDescription)")
                                                                    } else {
                                                                        print("✅ Sign out successful")
                                                                    }
                                                                },
                                                                receiveValue: { _ in }
                                                            )
                                                            .store(in: &AppEnvironment.shared.cancellables)
                                                    },
                                                    receiveValue: { _ in }
                                                )
                                                .store(in: &AppEnvironment.shared.cancellables)
                                        }
                                    )
                                    .store(in: &AppEnvironment.shared.cancellables)
                            }
                        )
                        .store(in: &AppEnvironment.shared.cancellables)
                }
            )
            .store(in: &AppEnvironment.shared.cancellables)
    }
}
#endif
