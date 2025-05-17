import Foundation

struct User: Identifiable, Codable {
    var id: String
    var email: String
    var displayName: String?
    var isEmailVerified: Bool
    var profileImageURL: String?
    var friends: [String]?
    var favoriteRestaurants: [String]?
    var lastActive: Date?
    var joinDate: Date
    
    init(id: String, email: String, displayName: String?, profileImageURL: String?,
         friends: [String]?, favoriteRestaurants: [String]?, lastActive: Date?, joinDate: Date, isEmailVerified: Bool = false) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.friends = friends
        self.favoriteRestaurants = favoriteRestaurants
        self.lastActive = lastActive
        self.joinDate = joinDate
        self.isEmailVerified = isEmailVerified
    }
    
    init(id: String, email: String, displayName: String? = nil, isEmailVerified: Bool = false) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.joinDate = Date()
        self.friends = []
        self.favoriteRestaurants = []
        self.isEmailVerified = isEmailVerified
    }
}
