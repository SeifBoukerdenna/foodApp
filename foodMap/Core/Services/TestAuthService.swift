import Foundation
import Combine

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
