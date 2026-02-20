import AppKit
import SwiftUI

@MainActor
final class WritingMonitorIndicator {
    private var panel: OverlayPanel?

    func show(status: AppState.WritingMonitorStatus) {
        if status == .idle {
            hide()
            return
        }

        let isChecking = status == .checking
        let content = IndicatorPill(isChecking: isChecking)
        let hostView = NSHostingView(rootView: content)
        hostView.frame.size = hostView.fittingSize

        guard let screen = NSScreen.main else { return }
        let x = screen.visibleFrame.midX - hostView.frame.width / 2
        let y = screen.visibleFrame.maxY - hostView.frame.height - 8
        let frame = NSRect(x: x, y: y, width: hostView.frame.width, height: hostView.frame.height)

        if let panel {
            panel.contentView = hostView
            panel.setFrame(frame, display: true)
            if !panel.isVisible {
                panel.alphaValue = 0
                panel.orderFrontRegardless()
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.2
                    panel.animator().alphaValue = 1
                }
            }
        } else {
            let newPanel = OverlayPanel(contentRect: frame)
            newPanel.contentView = hostView
            newPanel.ignoresMouseEvents = true
            newPanel.alphaValue = 0
            newPanel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.2
                newPanel.animator().alphaValue = 1
            }
            self.panel = newPanel
        }
    }

    func hide() {
        guard let panel, panel.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                self?.panel?.orderOut(nil)
                self?.panel = nil
            }
        })
    }
}

private struct IndicatorPill: View {
    let isChecking: Bool

    var body: some View {
        HStack(spacing: 5) {
            if isChecking {
                ProgressView()
                    .controlSize(.mini)
                    .scaleEffect(0.7)
            } else {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
            }
            Text(isChecking ? "Checking..." : "Watching")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(isChecking ? .orange : .green)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 4)
        .overlay(
            Capsule()
                .stroke(isChecking ? .orange.opacity(0.4) : .green.opacity(0.3), lineWidth: 1)
        )
    }
}
