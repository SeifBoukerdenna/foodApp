import Foundation
import Combine

protocol GPTServiceProtocol {
    func getRestaurantSuggestions(preferences: RestaurantPreferences) -> AnyPublisher<ChatCompletionResponse, Error>
    func getChatCompletion(request: ChatCompletionRequest) -> AnyPublisher<ChatCompletionResponse, Error>
}

class GPTService: GPTServiceProtocol {
    // MARK: - Properties
    private let networkClient: NetworkClient
    private let appEnvironment: AppEnvironment
    
    // MARK: - Initializer
    init(appEnvironment: AppEnvironment = AppEnvironment.shared) {
        self.appEnvironment = appEnvironment
        self.networkClient = NetworkClient(baseURLString: appEnvironment.apiBaseURL)
        
        print("GPT Service initialized with base URL: \(appEnvironment.apiBaseURL)")
    }
    
    // For testing with a custom network client
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
        self.appEnvironment = AppEnvironment.shared
    }
    
    // MARK: - Public Methods
    func getRestaurantSuggestions(preferences: RestaurantPreferences) -> AnyPublisher<ChatCompletionResponse, Error> {
        let userId = appEnvironment.currentUserId
        print("Getting restaurant suggestions for user ID: \(userId)")
        
        let request = RestaurantSuggestionsRequest(
            userId: userId,
            preferences: preferences
        )
        
        print("Restaurant suggestion request: \(request)")
        
        // Use the requiresAuth parameter
        return networkClient.post(
            endpoint: AppEnvironment.Endpoints.restaurantSuggestions,
            body: request,
            requiresAuth: true // Require authentication
        )
    }
    
    func getChatCompletion(request: ChatCompletionRequest) -> AnyPublisher<ChatCompletionResponse, Error> {
        return networkClient.post(
            endpoint: AppEnvironment.Endpoints.chatCompletion,
            body: request,
            requiresAuth: true  // Require authentication
        )
    }
}
