import AppKit
import SwiftUI

@MainActor
final class IslandController {
    private var panel: NSPanel?
    private var hostView: NSHostingView<IslandView>?
    private let state = IslandState()
    private var dismissTask: Task<Void, Never>?
    private var lastSize: CGSize = .zero

    var targetLang: String {
        get { state.targetLang }
        set { state.targetLang = newValue }
    }

    // MARK: - Lifecycle

    /// Call once at app start — shows the persistent header bar
    func start(appState: AppState) {
        state.nativeLang     = appState.nativeLang
        state.targetLang     = appState.targetLang
        state.learningLevel  = appState.learningLevel
        state.isWhisperReady = appState.isWhisperReady
        state.onPlay = { text, lang in SpeechService.shared.speak(text, lang: lang) }
        createPanel()
    }

    /// Sync header data when app state changes
    func sync(appState: AppState) {
        state.nativeLang     = appState.nativeLang
        state.targetLang     = appState.targetLang
        state.learningLevel  = appState.learningLevel
        state.isWhisperReady = appState.isWhisperReady
    }

    // MARK: - Public API

    func showRecording() {
        dismissTask?.cancel()
        state.phase = .recording
    }

    func showProcessing() {
        dismissTask?.cancel()
        state.phase = .processing
    }

    func show(response: LangResponse, duration: TimeInterval = 10) {
        dismissTask?.cancel()
        state.phase = .result(response)

        guard duration > 0 else { return }
        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.hide()
        }
    }

    /// Collapse back to idle header — panel stays visible
    func hide() {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            state.phase = .idle
        }
    }

    // MARK: - Panel creation

    private func createPanel() {
        let view = IslandView(state: state) { [weak self] size in
            self?.handleSizeChange(size)
        }

        let hv = NSHostingView(rootView: view)
        // Transparent so .ultraThinMaterial shows real blur
        hv.layer?.isOpaque = false
        hv.layer?.backgroundColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0)
        self.hostView = hv

        let newPanel = NSPanel(
            contentRect: offScreenRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.level = .floating
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false
        newPanel.ignoresMouseEvents = false
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newPanel.alphaValue = 0
        newPanel.contentView = hv
        // Park off-screen so material can warm up before appearing
        newPanel.orderFrontRegardless()

        self.panel = newPanel
        self.lastSize = .zero
    }

    private func handleSizeChange(_ size: CGSize) {
        guard size.width > 1, size.height > 1 else { return }

        let delta = abs(size.width - lastSize.width) + abs(size.height - lastSize.height)
        guard delta > 2 else { return }

        let isFirst = lastSize == .zero
        lastSize = size

        guard let panel, let hv = hostView else { return }
        hv.frame.size = size
        let target = panelFrame(for: size)

        if isFirst {
            // Position correctly before fading in — eliminates glitch
            panel.setFrame(target, display: false)
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.2
                panel.animator().alphaValue = 1
            }
        } else {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.38
                ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.34, 1.56, 0.64, 1)
                panel.animator().setFrame(target, display: true)
            }
        }
    }

    private func panelFrame(for size: CGSize) -> NSRect {
        guard let screen = NSScreen.main else { return offScreenRect }
        let menuBarHeight = NSStatusBar.system.thickness
        let gap: CGFloat = 6  // deliberate gap — this is a floating HUD, not attached
        let x = (screen.frame.width - size.width) / 2
        let y = screen.frame.maxY - menuBarHeight - size.height - gap
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }

    private var offScreenRect: NSRect {
        NSRect(x: -9999, y: -9999, width: 280, height: 36)
    }
}
