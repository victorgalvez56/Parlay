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
    var onStatusChange: ((AppState.WritingMonitorStatus, NSRect?) -> Void)?

    private let openAIService = OpenAIService()

    var isMonitoring: Bool { pollTimer != nil }

    func start() {
        guard pollTimer == nil else { return }
        lastText = ""
        lastAnalyzedText = ""
        Log.info("[WritingMonitor] Started — target: \(targetLang), native: \(nativeLang)")
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
        guard let text = readFocusedTextFieldValue() else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard trimmed != lastText else { return }

        Log.info("[WritingMonitor] Text changed (\(trimmed.count) chars)")
        lastText = trimmed
        let elementFrame = readFocusedElementFrame()
        onStatusChange?(.watching, elementFrame)
        debounceTask?.cancel()
        debounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            guard !Task.isCancelled else { return }
            self?.analyzeIfNeeded(trimmed)
        }
    }

    private func analyzeIfNeeded(_ text: String) {
        let sentence = extractLastSentence(text)
        guard !sentence.isEmpty, sentence.count >= 3 else {
            Log.info("[WritingMonitor] Skipped — sentence too short: \"\(sentence)\"")
            return
        }
        guard sentence != lastAnalyzedText else {
            Log.info("[WritingMonitor] Skipped — already analyzed")
            return
        }
        guard !isAnalyzing else {
            Log.info("[WritingMonitor] Skipped — already analyzing")
            return
        }

        lastAnalyzedText = sentence
        isAnalyzing = true
        let elementFrame = readFocusedElementFrame()
        onStatusChange?(.checking, elementFrame)
        Log.info("[WritingMonitor] Analyzing: \"\(sentence)\"")

        Task { @MainActor [weak self] in
            defer {
                self?.isAnalyzing = false
                self?.onStatusChange?(.idle, nil)
            }
            guard let self else { return }
            do {
                let alert = try await self.checkWriting(sentence)
                Log.info("[WritingMonitor] Result — hasErrors: \(alert.hasErrors), corrected: \(alert.correctedText ?? "nil")")
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
        guard AccessibilityPermission.hasPermission() else {
            return nil
        }

        let systemWide = AXUIElementCreateSystemWide()

        var focusedAppRef: AnyObject?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedAppRef) == .success,
              let focusedApp = focusedAppRef as! AXUIElement? else {
            return nil
        }

        var focusedElementRef: AnyObject?
        guard AXUIElementCopyAttributeValue(focusedApp, kAXFocusedUIElementAttribute as CFString, &focusedElementRef) == .success,
              let focusedElement = focusedElementRef as! AXUIElement? else {
            return nil
        }

        // Try kAXValueAttribute first (standard text fields)
        var value: AnyObject?
        if AXUIElementCopyAttributeValue(focusedElement, kAXValueAttribute as CFString, &value) == .success,
           let text = value as? String {
            return text
        }

        // Fallback: try selected text
        var selectedText: AnyObject?
        if AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextAttribute as CFString, &selectedText) == .success,
           let text = selectedText as? String, !text.isEmpty {
            return text
        }

        return nil
    }

    private func readFocusedElementFrame() -> NSRect? {
        guard AccessibilityPermission.hasPermission() else { return nil }

        let systemWide = AXUIElementCreateSystemWide()

        var focusedAppRef: AnyObject?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedAppRef) == .success,
              let focusedApp = focusedAppRef as! AXUIElement? else {
            return nil
        }

        var focusedElementRef: AnyObject?
        guard AXUIElementCopyAttributeValue(focusedApp, kAXFocusedUIElementAttribute as CFString, &focusedElementRef) == .success,
              let focusedElement = focusedElementRef as! AXUIElement? else {
            return nil
        }

        var positionRef: AnyObject?
        var sizeRef: AnyObject?
        guard AXUIElementCopyAttributeValue(focusedElement, kAXPositionAttribute as CFString, &positionRef) == .success,
              AXUIElementCopyAttributeValue(focusedElement, kAXSizeAttribute as CFString, &sizeRef) == .success else {
            return nil
        }

        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionRef as! AXValue, .cgPoint, &position),
              AXValueGetValue(sizeRef as! AXValue, .cgSize, &size) else {
            return nil
        }

        // Convert from top-left origin (Accessibility) to bottom-left origin (AppKit)
        guard let screen = NSScreen.main else { return nil }
        let flippedY = screen.frame.height - position.y - size.height
        return NSRect(x: position.x, y: flippedY, width: size.width, height: size.height)
    }

    // MARK: - Analysis

    private func checkWriting(_ text: String) async throws -> WritingAlert {
        let prompt = PromptBuilder.buildWritingCheckPrompt(
            text: text,
            targetLang: targetLang,
            nativeLang: nativeLang,
            level: level
        )

        return try await openAIService.analyzeWriting(prompt: prompt)
    }

    // MARK: - Helpers

    private func extractLastSentence(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let separators = CharacterSet(charactersIn: ".!?\n")
        let parts = trimmed.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if let last = parts.last {
            return last
        }
        return trimmed
    }
}
