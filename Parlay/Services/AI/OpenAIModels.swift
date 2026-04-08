import Foundation

struct OpenAIChatRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let maxTokens: Int
    let temperature: Double
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: [OpenAIContent]
}

enum OpenAIContent: Codable {
    case text(String)
    case imageURL(url: String, detail: String)
    enum CodingKeys: String, CodingKey { case type, text, imageURL = "image_url" }
    struct ImageURL: Codable { let url: String; let detail: String }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .imageURL(let url, let detail):
            try container.encode("image_url", forKey: .type)
            try container.encode(ImageURL(url: url, detail: detail), forKey: .imageURL)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
            self = .text(try container.decode(String.self, forKey: .text))
        case "image_url":
            let img = try container.decode(ImageURL.self, forKey: .imageURL)
            self = .imageURL(url: img.url, detail: img.detail)
        default:
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown type: \(type)"))
        }
    }
}

struct OpenAIChatResponse: Codable {
    let choices: [Choice]
    struct Choice: Codable { let message: Msg }
    struct Msg: Codable { let content: String }
}

struct OpenAIErrorResponse: Codable {
    let error: E
    struct E: Codable { let message: String }
}
