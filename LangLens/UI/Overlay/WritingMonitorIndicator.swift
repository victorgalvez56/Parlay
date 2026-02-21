import AppKit
import SwiftUI

@MainActor
final class WritingMonitorIndicator {
    private var panel: OverlayPanel?

    func show(status: AppState.WritingMonitorStatus, elementFrame: NSRect?) {
        if status == .idle {
            hide()
            return
        }

        guard let frame = elementFrame else {
            hide()
            return
        }

        let isChecking = status == .checking
        let content = CursorIndicator(isChecking: isChecking)
        let hostView = NSHostingView(rootView: content)
        hostView.frame.size = hostView.fittingSize

        // Position the label just below and to the right of the cursor/caret
        let x = frame.origin.x + frame.width + 4
        let y = frame.origin.y - hostView.frame.height - 2
        let labelFrame = NSRect(x: x, y: y, width: hostView.frame.width, height: hostView.frame.height)

        if let panel {
            panel.contentView = hostView
            panel.setFrame(labelFrame, display: true)
            if !panel.isVisible {
                panel.alphaValue = 0
                panel.orderFrontRegardless()
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.15
                    panel.animator().alphaValue = 1
                }
            }
        } else {
            let newPanel = OverlayPanel(contentRect: labelFrame)
            newPanel.contentView = hostView
            newPanel.ignoresMouseEvents = true
            newPanel.alphaValue = 0
            newPanel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.15
                newPanel.animator().alphaValue = 1
            }
            self.panel = newPanel
        }
    }

    func hide() {
        guard let panel, panel.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.15
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                self?.panel?.orderOut(nil)
                self?.panel = nil
            }
        })
    }
}

// MARK: - View

private struct CursorIndicator: View {
    let isChecking: Bool

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isChecking ? .orange : .green)
                .frame(width: 6, height: 6)
            if isChecking {
                ProgressView()
                    .controlSize(.mini)
                    .scaleEffect(0.6)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 2)
    }
}
