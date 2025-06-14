import Foundation
import Combine
import FirebaseAuth

class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var suggestedRestaurants: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Properties
    private let gptService: GPTServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    init(gptService: GPTServiceProtocol = GPTService()) {
        self.gptService = gptService
    }
    
    // MARK: - Public Methods
    func getRestaurantSuggestions(preferences: RestaurantPreferences) {
        isLoading = true
        errorMessage = nil
        
        // Log preferences for debugging
        print("Getting restaurant suggestions with preferences: \(preferences)")
        
        // Use a delay to ensure we're not modifying state during view updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            self.gptService.getRestaurantSuggestions(preferences: preferences)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        guard let self = self else { return }
                        
                        self.isLoading = false
                        
                        if case let .failure(error) = completion {
                            print("Error fetching restaurant suggestions: \(error)")
                            
                            // Format error message for display
                            if let networkError = error as? NetworkError {
                                switch networkError {
                                case .authenticationRequired:
                                    self.errorMessage = "Login required. Please sign in again."
                                case .tokenExpired:
                                    self.errorMessage = "Your session has expired. Please sign in again."
                                default:
                                    self.errorMessage = networkError.localizedDescription
                                }
                            } else {
                                self.errorMessage = "The operation couldn't be completed."
                            }
                        }
                    },
                    receiveValue: { [weak self] response in
                        guard let self = self else { return }
                        
                        if let firstChoice = response.choices.first {
                            self.suggestedRestaurants = firstChoice.message.content
                            print("✅ Got restaurant suggestions: \(self.suggestedRestaurants.prefix(50))...")
                        } else {
                            self.errorMessage = "No recommendations available"
                        }
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    func getDefaultSuggestions() {
        // Add additionalPreferences as a dictionary
        let additionalPrefs = [
            "quietEnvironment": true,
            "outdoorSeating": true
        ]
        
        let preferences = RestaurantPreferences(
            cuisine: "Italian",
            dietary: ["vegetarian", "gluten-free"],
            priceRange: .moderate,
            location: "Downtown",
            additionalPreferences: additionalPrefs
        )
        
        getRestaurantSuggestions(preferences: preferences)
    }
    
    func retryWithAuthentication() {
        // First check if we're authenticated
        if let user = Auth.auth().currentUser {
            // If we already have a user, try to get a fresh token
            user.getIDToken(completion: { token, error in
                if error == nil && token != nil {
                    // Token refreshed, try the request again
                    self.getDefaultSuggestions()
                } else {
                    // Display auth error
                    self.errorMessage = "Authentication error. Please log out and try again."
                }
            })
        } else {
            self.errorMessage = "Please sign in to continue."
        }
    }
}
