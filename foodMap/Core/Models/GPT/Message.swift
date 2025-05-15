import Foundation

struct Message: Codable {
    let role: String
    let content: String
    
    static func user(content: String) -> Message {
        return Message(role: "user", content: content)
    }
    
    static func system(content: String) -> Message {
        return Message(role: "system", content: content)
    }
    
    static func assistant(content: String) -> Message {
        return Message(role: "assistant", content: content)
    }
}
