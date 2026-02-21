import AppKit
import SwiftUI

@MainActor
final class WritingMonitorIndicator {
    private var borderPanel: OverlayPanel?
    private var labelPanel: OverlayPanel?

    func show(status: AppState.WritingMonitorStatus, elementFrame: NSRect?) {
        if status == .idle {
            hide()
            return
        }

        guard let frame = elementFrame, frame.width > 0, frame.height > 0 else {
            hide()
            return
        }

        let isChecking = status == .checking
        let borderColor: NSColor = isChecking ? .orange : .systemGreen

        // Border overlay around the text field
        showBorder(around: frame, color: borderColor)

        // Small label above the text field
        showLabel(above: frame, isChecking: isChecking)
    }

    func hide() {
        if let borderPanel {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.2
                borderPanel.animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                MainActor.assumeIsolated {
                    self?.borderPanel?.orderOut(nil)
                    self?.borderPanel = nil
                }
            })
        }
        if let labelPanel {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.2
                labelPanel.animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                MainActor.assumeIsolated {
                    self?.labelPanel?.orderOut(nil)
                    self?.labelPanel = nil
                }
            })
        }
    }

    // MARK: - Border

    private func showBorder(around frame: NSRect, color: NSColor) {
        let padding: CGFloat = 3
        let borderFrame = frame.insetBy(dx: -padding, dy: -padding)

        let borderView = NSHostingView(rootView: BorderOverlay(color: Color(nsColor: color)))
        borderView.frame.size = borderFrame.size

        if let borderPanel {
            borderPanel.contentView = borderView
            borderPanel.setFrame(borderFrame, display: true)
            if !borderPanel.isVisible {
                borderPanel.alphaValue = 0
                borderPanel.orderFrontRegardless()
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.15
                    borderPanel.animator().alphaValue = 1
                }
            }
        } else {
            let panel = OverlayPanel(contentRect: borderFrame)
            panel.contentView = borderView
            panel.ignoresMouseEvents = true
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.15
                panel.animator().alphaValue = 1
            }
            self.borderPanel = panel
        }
    }

    // MARK: - Label

    private func showLabel(above frame: NSRect, isChecking: Bool) {
        let content = IndicatorLabel(isChecking: isChecking)
        let hostView = NSHostingView(rootView: content)
        hostView.frame.size = hostView.fittingSize

        let x = frame.minX
        let y = frame.maxY + 4
        let labelFrame = NSRect(x: x, y: y, width: hostView.frame.width, height: hostView.frame.height)

        if let labelPanel {
            labelPanel.contentView = hostView
            labelPanel.setFrame(labelFrame, display: true)
            if !labelPanel.isVisible {
                labelPanel.alphaValue = 0
                labelPanel.orderFrontRegardless()
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.15
                    labelPanel.animator().alphaValue = 1
                }
            }
        } else {
            let panel = OverlayPanel(contentRect: labelFrame)
            panel.contentView = hostView
            panel.ignoresMouseEvents = true
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.15
                panel.animator().alphaValue = 1
            }
            self.labelPanel = panel
        }
    }
}

// MARK: - Views

private struct BorderOverlay: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(color, lineWidth: 2)
            .background(color.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct IndicatorLabel: View {
    let isChecking: Bool

    var body: some View {
        HStack(spacing: 4) {
            if isChecking {
                ProgressView()
                    .controlSize(.mini)
                    .scaleEffect(0.6)
            } else {
                Circle()
                    .fill(.green)
                    .frame(width: 5, height: 5)
            }
            Text(isChecking ? "Checking..." : "Watching")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(isChecking ? .orange : .green)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 2)
    }
}
