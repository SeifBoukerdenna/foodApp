import Foundation
import SwiftUI

/// Central environment configuration for the app
class AppEnvironment: ObservableObject {
    static let shared = AppEnvironment()
    
    // MARK: - API Configuration
    let apiBaseURL: String
    
    // MARK: - App Configuration
    @Published var hasCompletedOnboarding = false
    @Published var currentUserId: String
    
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
    }
    
    // MARK: - App Settings
    func updateUserId(_ userId: String) {
        self.currentUserId = userId
        UserDefaults.standard.set(userId, forKey: "userId")
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
