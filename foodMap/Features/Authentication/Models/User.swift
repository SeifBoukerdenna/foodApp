import Foundation

struct User: Identifiable, Codable {
    var id: String
    var email: String
    var displayName: String?
    var profileImageURL: String?
    var friends: [String]? // IDs of friends
    var favoriteRestaurants: [String]? // IDs of favorite restaurants
    
    // Additional properties for social features
    var lastActive: Date?
    var joinDate: Date
    
    init(id: String, email: String, displayName: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.joinDate = Date()
        self.friends = []
        self.favoriteRestaurants = []
    }
}
