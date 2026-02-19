import AppKit
import ScreenCaptureKit

@MainActor
final class AppDelegate: NSObject {
    var appState: AppState!

    private let hotkeyService = HotkeyService()
    private let screenCaptureService = ScreenCaptureService()
    private let audioCaptureService = AudioCaptureService()
    private let whisperService = WhisperService()
    private let openAIService = OpenAIService()
    private let vocabularyStore = VocabularyStore()
    private let languageContext = LanguageContext()
    private lazy var overlayController = OverlayController()

    func setup() {
        checkPermissions()
        setupHotkey()
        loadWhisperModel()
        Task { await loadRecentVocab() }
    }

    // MARK: - Permissions

    func checkPermissions() {
        appState.hasAccessibilityPermission = AccessibilityPermission.hasPermission()
        appState.hasScreenCapturePermission = CGPreflightScreenCaptureAccess()
        Task {
            appState.hasMicrophonePermission = await AudioPermission.requestPermission()
        }
    }

    func requestScreenPermission() {
        CGRequestScreenCaptureAccess()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.appState.hasScreenCapturePermission = CGPreflightScreenCaptureAccess()
        }
    }

    func requestAccessibilityPermission() {
        AccessibilityPermission.requestPermission()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.appState.hasAccessibilityPermission = AccessibilityPermission.hasPermission()
            if self?.appState.hasAccessibilityPermission == true {
                self?.setupHotkey()
            }
        }
    }

    func openSystemPreferences(for pane: String) {
        let url: URL?
        switch pane {
        case "screen":
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
        case "mic":
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
        case "accessibility":
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        default: url = nil
        }
        if let url { NSWorkspace.shared.open(url) }
    }

    // MARK: - Hotkey

    private func setupHotkey() {
        hotkeyService.onToggle = { [weak self] in self?.toggleRecording() }
        hotkeyService.onCancel = { [weak self] in self?.cancelRecording() }
        hotkeyService.start()
        appState.isHotkeyActive = hotkeyService.isActive
    }

    // MARK: - Whisper

    private func loadWhisperModel() {
        Task {
            do {
                try await whisperService.loadModel(name: appState.whisperModel)
                appState.isWhisperReady = true
                Log.info("[AppDelegate] Whisper model loaded")
            } catch {
                Log.error("[AppDelegate] Whisper load failed: \(error)")
                appState.errorMessage = "Failed to load speech model: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Vocabulary

    private func loadRecentVocab() async {
        let recent = await vocabularyStore.loadRecent(10)
        appState.recentVocab = recent
    }

    // MARK: - Recording Flow

    func toggleRecording() {
        if appState.isRecording {
            stopRecordingAndProcess()
        } else {
            startRecording()
        }
    }

    func cancelRecording() {
        guard appState.isRecording else { return }
        _ = audioCaptureService.stopRecording()
        appState.isRecording = false
        appState.errorMessage = nil
        Log.info("[AppDelegate] Recording cancelled")
    }

    private func startRecording() {
        guard appState.canRecord else {
            if !appState.allPermissionsGranted {
                appState.errorMessage = "Missing permissions: \(appState.missingPermissions.joined(separator: ", "))"
            } else if !appState.isWhisperReady {
                appState.errorMessage = "Speech model still loading..."
            }
            return
        }

        appState.errorMessage = nil
        do {
            try audioCaptureService.startRecording()
            appState.isRecording = true
            Log.info("[AppDelegate] Recording started")
        } catch {
            appState.errorMessage = "Mic error: \(error.localizedDescription)"
            Log.error("[AppDelegate] Recording failed: \(error)")
        }
    }

    private func stopRecordingAndProcess() {
        let audioData = audioCaptureService.stopRecording()
        appState.isRecording = false
        appState.isProcessing = true
        overlayController.showProcessing()

        Task {
            do {
                async let frameResult = screenCaptureService.captureFrame()
                async let transcriptionResult = whisperService.transcribe(audioData: audioData)

                let frame = try await frameResult
                let transcription = try await transcriptionResult

                appState.lastTranscription = transcription
                Log.info("[AppDelegate] Transcription: \(transcription)")

                let base64 = ImageUtils.cgImageToBase64JPEG(frame, quality: 0.6)
                let context = languageContext.generateContext(
                    nativeLang: appState.nativeLang,
                    targetLang: appState.targetLang,
                    level: appState.learningLevel,
                    recentVocab: appState.recentVocab
                )
                let prompt = PromptBuilder.buildPrompt(
                    transcription: transcription,
                    nativeLang: appState.nativeLang,
                    targetLang: appState.targetLang,
                    level: appState.learningLevel,
                    languageContext: context
                )

                let response = try await openAIService.analyze(
                    base64Image: base64,
                    prompt: prompt,
                    detail: appState.imageDetail
                )

                appState.lastResponse = response
                appState.isProcessing = false

                overlayController.show(response: response, duration: appState.overlayDuration)

                // Save to vocabulary if there's a translation
                let entry = VocabEntry(
                    word: transcription,
                    translation: response.translation,
                    pronunciation: response.pronunciation,
                    context: response.contextNote,
                    sourceLang: appState.nativeLang,
                    targetLang: appState.targetLang
                )
                try? await vocabularyStore.save(entry)
                await loadRecentVocab()

                Log.info("[AppDelegate] Response: \(response.translation)")
            } catch {
                appState.isProcessing = false
                appState.errorMessage = error.localizedDescription
                overlayController.hide()
                Log.error("[AppDelegate] Process failed: \(error)")
            }
        }
    }
}
