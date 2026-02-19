import Foundation
import WhisperKit

actor WhisperService {
    private var whisperKit: WhisperKit?
    private var isLoading = false

    func loadModel(name: String = "base") async throws {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        whisperKit = try await WhisperKit(model: name)
    }

    func transcribe(audioData: [Float]) async throws -> String {
        guard let whisperKit else { throw WhisperError.modelNotLoaded }
        let results = try await whisperKit.transcribe(audioArray: audioData)
        let text = results.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { throw WhisperError.emptyTranscription }
        return text
    }
}

enum WhisperError: LocalizedError {
    case modelNotLoaded, emptyTranscription
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: return "Whisper model not loaded yet"
        case .emptyTranscription: return "No speech detected"
        }
    }
}
