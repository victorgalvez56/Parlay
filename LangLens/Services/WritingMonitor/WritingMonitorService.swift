import AppKit
import ApplicationServices

@MainActor
final class WritingMonitorService {
    private var pollTimer: Timer?
    private var debounceTask: Task<Void, Never>?
    private var lastText = ""
    private var lastAnalyzedText = ""
    private var isAnalyzing = false

    var targetLang: String = "en"
    var nativeLang: String = "es"
    var level: String = "intermediate"
    var onWritingError: ((WritingAlert) -> Void)?

    private let openAIService = OpenAIService()

    var isMonitoring: Bool { pollTimer != nil }

    func start() {
        guard pollTimer == nil else { return }
        Log.info("[WritingMonitor] Started")
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollFocusedText()
            }
        }
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        debounceTask?.cancel()
        debounceTask = nil
        lastText = ""
        lastAnalyzedText = ""
        isAnalyzing = false
        Log.info("[WritingMonitor] Stopped")
    }

    // MARK: - Polling

    private func pollFocusedText() {
        guard let text = readFocusedTextFieldValue(), !text.isEmpty else { return }
        guard text != lastText else { return }

        lastText = text
        debounceTask?.cancel()
        debounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            guard !Task.isCancelled else { return }
            self?.analyzeIfNeeded(text)
        }
    }

    private func analyzeIfNeeded(_ text: String) {
        // Only analyze the last sentence/chunk
        let sentence = extractLastSentence(text)
        guard !sentence.isEmpty, sentence.count >= 5 else { return }
        guard sentence != lastAnalyzedText else { return }
        guard !isAnalyzing else { return }

        lastAnalyzedText = sentence
        isAnalyzing = true

        Task { @MainActor [weak self] in
            defer { self?.isAnalyzing = false }
            guard let self else { return }
            do {
                let alert = try await self.checkWriting(sentence)
                if alert.hasErrors {
                    self.onWritingError?(alert)
                }
            } catch {
                Log.error("[WritingMonitor] Analysis failed: \(error)")
            }
        }
    }

    // MARK: - Accessibility

    private func readFocusedTextFieldValue() -> String? {
        guard AccessibilityPermission.hasPermission() else { return nil }

        let systemWide = AXUIElementCreateSystemWide()
        var focusedApp: AnyObject?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp) == .success else {
            return nil
        }

        var focusedElement: AnyObject?
        guard AXUIElementCopyAttributeValue(focusedApp as! AXUIElement, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success else {
            return nil
        }

        let element = focusedElement as! AXUIElement
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value) == .success else {
            return nil
        }

        return value as? String
    }

    // MARK: - Analysis

    private func checkWriting(_ text: String) async throws -> WritingAlert {
        let prompt = PromptBuilder.buildWritingCheckPrompt(
            text: text,
            targetLang: targetLang,
            nativeLang: nativeLang,
            level: level
        )

        let response = try await openAIService.analyzeWriting(prompt: prompt)
        return response
    }

    // MARK: - Helpers

    private func extractLastSentence(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Split by sentence-ending punctuation or newlines
        let separators = CharacterSet(charactersIn: ".!?\n")
        let parts = trimmed.components(separatedBy: separators).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        // Get the last complete sentence or current partial
        if let last = parts.last {
            return last.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
    }
}
