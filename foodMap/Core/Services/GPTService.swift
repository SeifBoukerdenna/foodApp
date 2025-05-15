import Foundation
import Combine

protocol GPTServiceProtocol {
    func getRestaurantSuggestions(preferences: RestaurantPreferences) -> AnyPublisher<ChatCompletionResponse, Error>
    func getChatCompletion(request: ChatCompletionRequest) -> AnyPublisher<ChatCompletionResponse, Error>
}

class GPTService: GPTServiceProtocol {
    // MARK: - Properties
    private let networkClient: NetworkClient
    
    // MARK: - Initializer
    init() {
        // IMPORTANT: Replace with your Mac's ACTUAL IP address (not the "x")
        // Using "localhost" when testing in simulator, or your Mac's IP when on a physical device
        #if targetEnvironment(simulator)
        let baseURLString = "http://localhost:3000"
        #else
        let baseURLString = "http://192.168.2.12:3000" // REPLACE with your actual IP
        #endif
        
        self.networkClient = NetworkClient(baseURLString: baseURLString)
        print("GPT Service initialized with base URL: \(baseURLString)")
    }
    
    // For testing with a custom network client
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    // MARK: - Public Methods
    func getRestaurantSuggestions(preferences: RestaurantPreferences) -> AnyPublisher<ChatCompletionResponse, Error> {
        let userId = UserDefaults.standard.string(forKey: "userId") ?? UUID().uuidString
        print("Getting restaurant suggestions for user ID: \(userId)")
        
        // Prepare additional preferences in the correct format
        var additionalPrefs = [String: Bool]()
        if preferences.location?.lowercased() == "downtown" {
            additionalPrefs["quietEnvironment"] = true
            additionalPrefs["outdoorSeating"] = true
        }
        
        // Create a properly formatted request matching the server format
        let enhancedPreferences = RestaurantPreferences(
            cuisine: preferences.cuisine,
            dietary: preferences.dietary,
            priceRange: preferences.priceRange,
            location: preferences.location,
            additionalPreferences: additionalPrefs.isEmpty ? nil : additionalPrefs
        )
        
        let request = RestaurantSuggestionsRequest(
            userId: userId,
            preferences: enhancedPreferences
        )
        
        print("Restaurant suggestion request: \(request)")
        
        return networkClient.post(endpoint: "api/v1/gpt/restaurant-suggestions", body: request)
    }
    
    func getChatCompletion(request: ChatCompletionRequest) -> AnyPublisher<ChatCompletionResponse, Error> {
        return networkClient.post(endpoint: "api/v1/gpt/chat", body: request)
    }
}
