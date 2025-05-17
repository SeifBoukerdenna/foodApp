import Foundation

struct VerifyEmailRequest: Codable {
    let email: String
}

struct VerificationResponse: Codable {
    let success: Bool
}

struct VerificationStatusRequest: Codable {
    let email: String
}

struct VerificationStatusResponse: Codable {
    let isVerified: Bool
}
