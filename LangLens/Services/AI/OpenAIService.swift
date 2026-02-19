import Foundation

actor OpenAIService {
    private let session = URLSession.shared
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    func analyze(base64Image: String, prompt: String, detail: String = "low") async throws -> LangResponse {
        guard let apiKey = KeychainHelper.loadAPIKey(), !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }

        let request = OpenAIChatRequest(
            model: "gpt-4o",
            messages: [
                OpenAIMessage(role: "user", content: [
                    .text(prompt),
                    .imageURL(url: "data:image/jpeg;base64,\(base64Image)", detail: detail),
                ]),
            ],
            maxTokens: 800,
            temperature: 0.3
        )

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else { throw OpenAIError.invalidResponse }
        guard http.statusCode == 200 else {
            if let err = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw OpenAIError.apiError(err.error.message)
            }
            throw OpenAIError.httpError(http.statusCode)
        }

        let chatResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content else { throw OpenAIError.emptyResponse }
        return try parseResponse(from: content)
    }

    private func parseResponse(from content: String) throws -> LangResponse {
        var json = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if json.hasPrefix("```json") { json = String(json.dropFirst(7)) }
        else if json.hasPrefix("```") { json = String(json.dropFirst(3)) }
        if json.hasSuffix("```") { json = String(json.dropLast(3)) }
        json = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = json.data(using: .utf8) else { throw OpenAIError.parseError }
        return try JSONDecoder().decode(LangResponse.self, from: data)
    }
}

enum OpenAIError: LocalizedError {
    case missingAPIKey, invalidResponse, httpError(Int), apiError(String), emptyResponse, parseError
    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "API key not set. Go to Settings."
        case .invalidResponse: return "Invalid response from OpenAI"
        case .httpError(let c): return "OpenAI HTTP \(c)"
        case .apiError(let m): return "OpenAI: \(m)"
        case .emptyResponse: return "Empty response"
        case .parseError: return "Failed to parse AI response"
        }
    }
}
