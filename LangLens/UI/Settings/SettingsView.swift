import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var saveStatus: String?

    @State private var nativeLang: String = UserDefaults.standard.string(forKey: "nativeLang") ?? "es"
    @State private var targetLang: String = UserDefaults.standard.string(forKey: "targetLang") ?? "en"
    @State private var learningLevel: String = UserDefaults.standard.string(forKey: "learningLevel") ?? "intermediate"
    @State private var whisperModel: String = UserDefaults.standard.string(forKey: "whisperModel") ?? "base"
    @State private var overlayDuration: Double = {
        let d = UserDefaults.standard.double(forKey: "overlayDuration")
        return d == 0 ? 10 : d
    }()
    @State private var hideFromScreenShare: Bool = UserDefaults.standard.object(forKey: "hideFromScreenShare") as? Bool ?? true
    private let levels = ["beginner", "intermediate", "advanced"]
    private let whisperModels = ["tiny", "base", "small", "medium"]

    var body: some View {
        TabView {
            languageTab.tabItem { Label("Languages", systemImage: "globe") }
            apiTab.tabItem { Label("API", systemImage: "key") }
            advancedTab.tabItem { Label("Advanced", systemImage: "gearshape") }
        }
        .frame(width: 420, height: 320)
        .onAppear {
            apiKey = KeychainHelper.loadAPIKey() ?? ""
        }
    }

    // MARK: - Language Tab

    private var languageTab: some View {
        Form {
            Picker("Native Language", selection: $nativeLang) {
                ForEach(LanguagePair.supported, id: \.code) { lang in
                    Text("\(lang.flag) \(lang.name)").tag(lang.code)
                }
            }
            .onChange(of: nativeLang) { _, val in UserDefaults.standard.set(val, forKey: "nativeLang") }

            Picker("Learning", selection: $targetLang) {
                ForEach(LanguagePair.supported, id: \.code) { lang in
                    Text("\(lang.flag) \(lang.name)").tag(lang.code)
                }
            }
            .onChange(of: targetLang) { _, val in UserDefaults.standard.set(val, forKey: "targetLang") }

            Picker("Level", selection: $learningLevel) {
                ForEach(levels, id: \.self) { level in
                    Text(level.capitalized).tag(level)
                }
            }
            .onChange(of: learningLevel) { _, val in UserDefaults.standard.set(val, forKey: "learningLevel") }

            Section {
                Text("Look at your screen, press Cmd+Shift+L, and ask a question about what you see in the target language or your native language.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // MARK: - API Tab

    private var apiTab: some View {
        Form {
            SecureField("OpenAI API Key", text: $apiKey)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Save") {
                    do {
                        try KeychainHelper.saveAPIKey(apiKey)
                        saveStatus = "Saved"
                    } catch {
                        saveStatus = "Error: \(error.localizedDescription)"
                    }
                }
                .disabled(apiKey.isEmpty)

                if let status = saveStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(status == "Saved" ? .green : .red)
                }
            }

            Section {
                Text("Your API key is encrypted and stored locally at ~/.config/langlens/")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Advanced Tab

    private var advancedTab: some View {
        Form {
            Picker("Whisper Model", selection: $whisperModel) {
                ForEach(whisperModels, id: \.self) { Text($0).tag($0) }
            }
            .onChange(of: whisperModel) { _, val in UserDefaults.standard.set(val, forKey: "whisperModel") }

            HStack {
                Text("Overlay Duration")
                Slider(value: $overlayDuration, in: 3...30, step: 1)
                Text("\(Int(overlayDuration))s")
                    .monospacedDigit()
                    .frame(width: 30)
            }
            .onChange(of: overlayDuration) { _, val in UserDefaults.standard.set(val, forKey: "overlayDuration") }

            Toggle("Hide overlay during screen sharing", isOn: $hideFromScreenShare)
                .onChange(of: hideFromScreenShare) { _, val in UserDefaults.standard.set(val, forKey: "hideFromScreenShare") }

            Text("When enabled, the overlay is invisible in screen recordings, screenshots, and screen sharing (Zoom, Meet, Teams, etc.)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func show() {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView()
        let hostingController = NSHostingController(rootView: view)
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "LangLens Settings"
        newWindow.styleMask = [.titled, .closable]
        newWindow.center()
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = newWindow
    }
}
