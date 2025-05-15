import Foundation

enum Environment {
    case development
    case staging
    case production
    
    var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:3000/api/v1"
        case .staging:
            return "https://staging-api.foodmap.com/api/v1"
        case .production:
            return "https://api.foodmap.com/api/v1"
        }
    }
}

struct Configuration {
    static let shared = Configuration()
    
    // MARK: - Properties
    #if DEBUG
    let environment: Environment = .development
    #else
    let environment: Environment = .production
    #endif
    
    var baseURL: String {
        return environment.baseURL
    }
    
    // Use this for local testing on physical devices
    var localNetworkURL: String {
        // Replace with your computer's IP address when testing on a physical device
        return "http://192.168.2.12:3000/api/v1"
    }
    
    // Method to get the appropriate URL based on the running environment
    func getBaseURL(forPhysicalDevice: Bool = false) -> String {
        if environment == .development && forPhysicalDevice {
            return localNetworkURL
        }
        return baseURL
    }
}
