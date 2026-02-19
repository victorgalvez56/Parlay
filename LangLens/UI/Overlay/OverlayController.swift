import AppKit
import SwiftUI

@MainActor
final class OverlayController {
    private var panel: OverlayPanel?
    private var dismissTask: Task<Void, Never>?

    func showProcessing() {
        show(response: nil, isProcessing: true, duration: 0)
    }

    func show(response: LangResponse, duration: TimeInterval = 10) {
        show(response: response, isProcessing: false, duration: duration)
    }

    func hide() {
        dismissTask?.cancel()
        guard let panel else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.3
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                self?.panel?.orderOut(nil)
                self?.panel = nil
            }
        })
    }

    private func show(response: LangResponse?, isProcessing: Bool, duration: TimeInterval) {
        dismissTask?.cancel()
        panel?.orderOut(nil)

        guard let screen = NSScreen.main else { return }
        let content = OverlayContentView(response: response, isProcessing: isProcessing)
        let hostView = NSHostingView(rootView: content)
        hostView.frame.size = hostView.fittingSize

        let padding: CGFloat = 20
        let x = screen.visibleFrame.maxX - hostView.frame.width - padding
        let y = screen.visibleFrame.minY + padding
        let frame = NSRect(x: x, y: y, width: hostView.frame.width, height: hostView.frame.height)

        let newPanel = OverlayPanel(contentRect: frame)
        newPanel.contentView = hostView
        newPanel.alphaValue = 0
        newPanel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            newPanel.animator().alphaValue = 1
        }

        self.panel = newPanel

        if duration > 0 {
            dismissTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                self?.hide()
            }
        }
    }
}
