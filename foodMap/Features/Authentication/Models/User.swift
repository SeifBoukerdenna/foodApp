import Foundation

struct User: Identifiable, Codable {
    var id: String
    var email: String
    var displayName: String?
    var profileImageURL: String?
    var friends: [String]? // IDs of friends
    var favoriteRestaurants: [String]? // IDs of favorite restaurants
    

    var lastActive: Date?
    var joinDate: Date
    
    init(id: String, email: String, displayName: String?, profileImageURL: String?,
         friends: [String]?, favoriteRestaurants: [String]?, lastActive: Date?, joinDate: Date) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.friends = friends
        self.favoriteRestaurants = favoriteRestaurants
        self.lastActive = lastActive
        self.joinDate = joinDate
    }
    
    // Keep the original simple constructor
    init(id: String, email: String, displayName: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.joinDate = Date()
        self.friends = []
        self.favoriteRestaurants = []
    }
}
