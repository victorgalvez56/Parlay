import Foundation

actor OpenAIService {
    private let session = URLSession.shared
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    func analyze(prompt: String) async throws -> LangResponse {
        guard let apiKey = KeychainHelper.loadAPIKey(), !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }

        let request = OpenAIChatRequest(
            model: "gpt-4o",
            messages: [
                OpenAIMessage(role: "user", content: [
                    .text(prompt),
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

    func analyzeWriting(prompt: String) async throws -> WritingAlert {
        guard let apiKey = KeychainHelper.loadAPIKey(), !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }

        let request = OpenAIChatRequest(
            model: "gpt-4o-mini",
            messages: [
                OpenAIMessage(role: "user", content: [
                    .text(prompt),
                ]),
            ],
            maxTokens: 300,
            temperature: 0.2
        )

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 15
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
        return try parseWritingAlert(from: content)
    }

    private func parseWritingAlert(from content: String) throws -> WritingAlert {
        var json = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if json.hasPrefix("```json") { json = String(json.dropFirst(7)) }
        else if json.hasPrefix("```") { json = String(json.dropFirst(3)) }
        if json.hasSuffix("```") { json = String(json.dropLast(3)) }
        json = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = json.data(using: .utf8) else { throw OpenAIError.parseError }
        return try JSONDecoder().decode(WritingAlert.self, from: data)
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
