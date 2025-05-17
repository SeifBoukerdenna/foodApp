import Foundation

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let username: String
    let displayName: String
}

struct RegisterResponse: Codable {
    let uid: String
    let username: String
    let email: String?
    let displayName: String
}

struct VerifyTokenRequest: Codable {
    let token: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let token: String
    let user: UserData
}

struct UserData: Codable {
    let uid: String
    let username: String
    let email: String?
    let displayName: String
}
