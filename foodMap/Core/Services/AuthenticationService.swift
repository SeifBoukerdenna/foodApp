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
}

enum AuthError: Error {
    case signInError
    case signUpError
    case signOutError
    case userNotFound
    case tokenError
    case serverError(String)
    case networkError
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
                                joinDate: Date()
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
            // First create the user in our backend
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
                .flatMap { (response: RegisterResponse) -> AnyPublisher<User, Error> in
                    // After successful registration, log in
                    return self.login(email: email, password: password)
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
            displayName: firebaseUser.displayName
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
}
