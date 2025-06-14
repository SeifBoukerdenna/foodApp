import Foundation
import SwiftUI
import Combine

/// Central environment configuration for the app
class AppEnvironment: ObservableObject {
    static let shared = AppEnvironment()
    
    // MARK: - API Configuration
    let apiBaseURL: String
    
    // MARK: - App Configuration
    @Published var hasCompletedOnboarding = false
    @Published var currentUserId: String
    
    // Add a cancellables property for Combine
    var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Configure API URL
        #if targetEnvironment(simulator)
        self.apiBaseURL = "http://localhost:3000"
        #else
        self.apiBaseURL = "http://192.168.2.12:3000"
        #endif
        
        // Initialize user ID or generate a new one
        if let savedUserId = UserDefaults.standard.string(forKey: "userId") {
            self.currentUserId = savedUserId
        } else {
            let newUserId = UUID().uuidString
            UserDefaults.standard.set(newUserId, forKey: "userId")
            self.currentUserId = newUserId
        }
    }
    
    // MARK: - API Endpoints
    struct Endpoints {
        static let restaurantSuggestions = "api/v1/gpt/restaurant-suggestions"
        static let chatCompletion = "api/v1/gpt/chat"
        static let searchPlaces = "api/v1/maps/search"
        static let placeDetails = "api/v1/maps/place-details"
        static let directions = "api/v1/maps/directions"
        static let photoUrl = "api/v1/maps/photo"
    }
    
    // MARK: - App Settings
    func updateUserId(_ userId: String) {
        self.currentUserId = userId
        UserDefaults.standard.set(userId, forKey: "userId")
    }
    
    // Add a new method for token headers
    func getAuthHeaders() -> AnyPublisher<[String: String], Error> {
        return AuthenticationService().getIdToken()
            .map { token in
                return ["Authorization": "Firebase \(token)"]
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Environment Values
struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment.shared
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
