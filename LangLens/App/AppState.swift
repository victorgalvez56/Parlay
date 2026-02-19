import SwiftUI
import Observation

@Observable
final class AppState {
    // MARK: - Recording State
    var isRecording = false
    var isProcessing = false
    var isWhisperReady = false
    var isHotkeyActive = false

    // MARK: - Results
    var lastTranscription: String?
    var lastResponse: LangResponse?
    var errorMessage: String?

    // MARK: - Vocabulary
    var recentVocab: [VocabEntry] = []

    // MARK: - Permissions
    var hasScreenCapturePermission = false
    var hasMicrophonePermission = false
    var hasAccessibilityPermission = false

    var allPermissionsGranted: Bool {
        hasScreenCapturePermission && hasMicrophonePermission && hasAccessibilityPermission
    }

    var missingPermissions: [String] {
        var missing: [String] = []
        if !hasScreenCapturePermission { missing.append("Screen Recording") }
        if !hasMicrophonePermission { missing.append("Microphone") }
        if !hasAccessibilityPermission { missing.append("Accessibility") }
        return missing
    }

    var canRecord: Bool {
        allPermissionsGranted && isWhisperReady && !isProcessing
    }

    // MARK: - Settings
    var nativeLang: String {
        get { UserDefaults.standard.string(forKey: "nativeLang") ?? "es" }
        set { UserDefaults.standard.set(newValue, forKey: "nativeLang") }
    }

    var targetLang: String {
        get { UserDefaults.standard.string(forKey: "targetLang") ?? "en" }
        set { UserDefaults.standard.set(newValue, forKey: "targetLang") }
    }

    var learningLevel: String {
        get { UserDefaults.standard.string(forKey: "learningLevel") ?? "intermediate" }
        set { UserDefaults.standard.set(newValue, forKey: "learningLevel") }
    }

    var whisperModel: String {
        get { UserDefaults.standard.string(forKey: "whisperModel") ?? "base" }
        set { UserDefaults.standard.set(newValue, forKey: "whisperModel") }
    }

    var overlayDuration: TimeInterval {
        get { UserDefaults.standard.double(forKey: "overlayDuration").nonZero ?? 10.0 }
        set { UserDefaults.standard.set(newValue, forKey: "overlayDuration") }
    }

    var imageDetail: String {
        get { UserDefaults.standard.string(forKey: "imageDetail") ?? "low" }
        set { UserDefaults.standard.set(newValue, forKey: "imageDetail") }
    }

    var menuBarIcon: String {
        if isRecording { return "waveform.circle.fill" }
        if isProcessing { return "ellipsis.circle.fill" }
        return "character.book.closed.fill"
    }

    var nativeLangName: String { LanguagePair.name(for: nativeLang) }
    var targetLangName: String { LanguagePair.name(for: targetLang) }
}

private extension Double {
    var nonZero: Double? {
        self == 0 ? nil : self
    }
}
