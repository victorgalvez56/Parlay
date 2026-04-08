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
    var allVocab: [VocabEntry] = []

    // MARK: - Permissions
    var hasMicrophonePermission = false
    var hasAccessibilityPermission = false

    var allPermissionsGranted: Bool {
        hasMicrophonePermission && hasAccessibilityPermission
    }

    var missingPermissions: [String] {
        var missing: [String] = []
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

    var hideFromScreenShare: Bool {
        get { UserDefaults.standard.object(forKey: "hideFromScreenShare") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "hideFromScreenShare") }
    }

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
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
