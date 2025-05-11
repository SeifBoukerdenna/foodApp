import Foundation
import Combine

protocol AuthenticationServiceProtocol {
    func login(email: String, password: String) -> AnyPublisher<User, Error>
    func signUp(email: String, password: String, displayName: String?) -> AnyPublisher<User, Error>
    func resetPassword(email: String) -> AnyPublisher<Void, Error>
}

class AuthenticationService: AuthenticationServiceProtocol {
    // Mock implementation - replace with real auth when ready
    func login(email: String, password: String) -> AnyPublisher<User, Error> {
        // Mock successful login
        let user = User(id: UUID().uuidString, email: email, displayName: "Test User")
        return Just(user)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func signUp(email: String, password: String, displayName: String?) -> AnyPublisher<User, Error> {
        // Mock successful signup
        let user = User(id: UUID().uuidString, email: email, displayName: displayName)
        return Just(user)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func resetPassword(email: String) -> AnyPublisher<Void, Error> {
        // Mock successful password reset
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
