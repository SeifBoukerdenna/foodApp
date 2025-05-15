import Foundation

enum PriceRange: String, Codable {
    case budget = "budget"
    case moderate = "moderate"
    case expensive = "expensive"
    case luxury = "luxury"
}

struct RestaurantPreferences: Codable {
    var cuisine: String?
    var dietary: [String]?
    var priceRange: PriceRange?
    var location: String?
    var additionalPreferences: [String: Bool]?
    
    enum CodingKeys: String, CodingKey {
        case cuisine
        case dietary
        case priceRange = "priceRange"
        case location
        case additionalPreferences
    }
}

struct RestaurantSuggestionsRequest: Codable {
    var userId: String?
    var preferences: RestaurantPreferences
}
