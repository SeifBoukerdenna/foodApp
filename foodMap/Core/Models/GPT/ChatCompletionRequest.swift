import Foundation

struct ChatCompletionRequest: Codable {
    var messages: [Message]
    var model: String?
    var temperature: Double?
    var maxTokens: Int?
    var topP: Double?
    var frequencyPenalty: Double?
    var presencePenalty: Double?
    
    enum CodingKeys: String, CodingKey {
        case messages
        case model
        case temperature
        case maxTokens = "maxTokens"
        case topP = "topP"
        case frequencyPenalty = "frequencyPenalty"
        case presencePenalty = "presencePenalty"
    }
}
