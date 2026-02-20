import AVFoundation

@MainActor
final class SpeechService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()
    private(set) var isSpeaking = false

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speak text in the given language code (e.g. "en", "es")
    func speak(_ text: String, lang: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: voiceLocale(for: lang))
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        utterance.pitchMultiplier = 1.0
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    // MARK: - Helpers

    private func voiceLocale(for code: String) -> String {
        switch code {
        case "en": return "en-US"
        case "es": return "es-ES"
        case "fr": return "fr-FR"
        case "de": return "de-DE"
        case "it": return "it-IT"
        case "pt": return "pt-BR"
        case "ja": return "ja-JP"
        case "ko": return "ko-KR"
        case "zh": return "zh-CN"
        case "ru": return "ru-RU"
        case "ar": return "ar-SA"
        case "hi": return "hi-IN"
        case "tr": return "tr-TR"
        case "nl": return "nl-NL"
        case "sv": return "sv-SE"
        case "pl": return "pl-PL"
        case "th": return "th-TH"
        case "vi": return "vi-VN"
        default: return "en-US"
        }
    }
}
