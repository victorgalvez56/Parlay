import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController {
    static let shared = OnboardingWindowController()
    private var window: NSWindow?

    func show(appState: AppState, delegate: AppDelegate) {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = OnboardingView(appState: appState, delegate: delegate) {
            self.close()
        }
        let hostingController = NSHostingController(rootView: view)
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "Welcome to Parlay"
        newWindow.styleMask = [.titled, .closable]
        newWindow.setContentSize(NSSize(width: 480, height: 400))
        newWindow.isReleasedWhenClosed = false
        newWindow.center()
        newWindow.level = .floating
        NSApp.activate(ignoringOtherApps: true)
        newWindow.makeKeyAndOrderFront(nil)
        newWindow.orderFrontRegardless()
        newWindow.level = .normal
        self.window = newWindow
    }

    func close() {
        window?.close()
        window = nil
    }
}
