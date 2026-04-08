import SwiftUI

@main
struct ParlayApp: App {
    @State private var appState = AppState()
    private let adaptor = AppDelegateAdaptor()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(appState: appState, delegate: adaptor.delegate)
        } label: {
            Image(systemName: appState.menuBarIcon)
        }
        .menuBarExtraStyle(.window)
    }

    init() {
        adaptor.delegate.appState = appState
        adaptor.delegate.setup()
    }
}

@MainActor
final class AppDelegateAdaptor: NSObject {
    lazy var delegate = AppDelegate()
}
