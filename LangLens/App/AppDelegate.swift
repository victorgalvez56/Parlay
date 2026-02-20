import AppKit

@MainActor
final class AppDelegate: NSObject {
    var appState: AppState!

    private let hotkeyService = HotkeyService()
    private let audioCaptureService = AudioCaptureService()
    private let whisperService = WhisperService()
    private let openAIService = OpenAIService()
    private let vocabularyStore = VocabularyStore()
    private let languageContext = LanguageContext()
    private lazy var overlayController = OverlayController()
    private let writingMonitor = WritingMonitorService()
    private lazy var writingAlertController = WritingAlertController()
    private lazy var writingIndicator = WritingMonitorIndicator()

    func setup() {
        checkPermissions()
        setupHotkey()
        loadWhisperModel()
        setupWritingMonitor()
        Task { await loadRecentVocab() }
        observeWindowVisibility()
    }

    // MARK: - Screen Share Visibility

    private nonisolated func observeWindowVisibility() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let window = notification.object as? NSWindow else { return }
            MainActor.assumeIsolated {
                let hide = UserDefaults.standard.object(forKey: "hideFromScreenShare") as? Bool ?? true
                guard hide else { return }
                if window.title == "LangLens Settings" { return }
                if window.sharingType != .none {
                    window.sharingType = .none
                }
            }
        }
    }

    // MARK: - Permissions

    func checkPermissions() {
        appState.hasAccessibilityPermission = AccessibilityPermission.hasPermission()
        Task {
            appState.hasMicrophonePermission = await AudioPermission.requestPermission()
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

    func loadAllVocab() async {
        let all = await vocabularyStore.loadAll()
        appState.allVocab = all
    }

    func deleteVocabEntry(_ id: UUID) {
        Task {
            try? await vocabularyStore.delete(id)
            await loadAllVocab()
            await loadRecentVocab()
        }
    }

    func clearAllVocab() {
        Task {
            try? await vocabularyStore.clearAll()
            await loadAllVocab()
            await loadRecentVocab()
        }
    }

    // MARK: - Writing Monitor

    private func setupWritingMonitor() {
        writingMonitor.onWritingError = { [weak self] alert in
            self?.writingAlertController.show(alert: alert)
        }
        writingMonitor.onStatusChange = { [weak self] status in
            self?.appState.writingMonitorStatus = status
            self?.writingIndicator.show(status: status)
        }
    }

    func toggleWritingMonitor() {
        appState.isWritingMonitorEnabled.toggle()
        if appState.isWritingMonitorEnabled {
            writingMonitor.targetLang = appState.targetLang
            writingMonitor.nativeLang = appState.nativeLang
            writingMonitor.level = appState.learningLevel
            writingMonitor.start()
        } else {
            writingMonitor.stop()
            writingAlertController.dismiss()
            writingIndicator.hide()
            appState.writingMonitorStatus = .idle
        }
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
                let transcription = try await whisperService.transcribe(audioData: audioData)

                appState.lastTranscription = transcription
                Log.info("[AppDelegate] Transcription: \(transcription)")

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
                    prompt: prompt
                )

                appState.lastResponse = response
                appState.isProcessing = false

                overlayController.targetLang = appState.targetLang
                overlayController.show(response: response, duration: appState.overlayDuration)

                // Auto-play pronunciation
                if response.isPronunciation {
                    let text = response.pronunciation ?? response.mainText
                    SpeechService.shared.speak(text, lang: appState.targetLang)
                }

                let entry = VocabEntry(
                    word: transcription,
                    translation: response.mainText,
                    pronunciation: response.pronunciation,
                    context: response.contextNote,
                    sourceLang: appState.nativeLang,
                    targetLang: appState.targetLang
                )
                try? await vocabularyStore.save(entry)
                await loadRecentVocab()

                Log.info("[AppDelegate] Response (\(response.mode)): \(response.mainText)")
            } catch {
                appState.isProcessing = false
                appState.errorMessage = error.localizedDescription
                overlayController.hide()
                Log.error("[AppDelegate] Process failed: \(error)")
            }
        }
    }
}
