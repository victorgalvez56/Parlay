import SwiftUI

struct OnboardingView: View {
    var appState: AppState
    var delegate: AppDelegate
    var onComplete: () -> Void

    @State private var currentStep = 0
    @State private var apiKey: String = ""
    @State private var nativeLang: String = UserDefaults.standard.string(forKey: "nativeLang") ?? "es"
    @State private var targetLang: String = UserDefaults.standard.string(forKey: "targetLang") ?? "en"
    @State private var learningLevel: String = UserDefaults.standard.string(forKey: "learningLevel") ?? "intermediate"

    private let totalSteps = 5
    private let levels = ["beginner", "intermediate", "advanced"]

    var body: some View {
        VStack(spacing: 0) {
            progressDots
                .padding(.top, 16)

            Spacer()

            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: languagesStep
                case 2: apiKeyStep
                case 3: permissionsStep
                case 4: doneStep
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Spacer()

            navigationButtons
                .padding(.bottom, 20)
                .padding(.horizontal, 24)
        }
        .frame(width: 480, height: 400)
        .onAppear {
            apiKey = KeychainHelper.loadAPIKey() ?? ""
        }
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index == currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 80, height: 80)

            Text("Welcome to LangLens")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your AI language learning companion.\nSpeak, learn, and improve — right from your Mac.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Step 1: Languages

    private var languagesStep: some View {
        VStack(spacing: 20) {
            Text("Choose Your Languages")
                .font(.title2)
                .fontWeight(.semibold)

            Form {
                Picker("Native Language", selection: $nativeLang) {
                    ForEach(LanguagePair.supported, id: \.code) { lang in
                        Text("\(lang.flag) \(lang.name)").tag(lang.code)
                    }
                }

                Picker("Learning", selection: $targetLang) {
                    ForEach(LanguagePair.supported, id: \.code) { lang in
                        Text("\(lang.flag) \(lang.name)").tag(lang.code)
                    }
                }

                Picker("Level", selection: $learningLevel) {
                    ForEach(levels, id: \.self) { level in
                        Text(level.capitalized).tag(level)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Step 2: API Key

    private var apiKeyStep: some View {
        VStack(spacing: 20) {
            Text("Enter Your API Key")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                SecureField("OpenAI API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 60)

                Text("Your key is encrypted and stored locally.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Step 3: Permissions

    private var permissionsStep: some View {
        VStack(spacing: 20) {
            Text("Grant Permissions")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                permissionRow(
                    icon: "mic.fill",
                    title: "Microphone",
                    subtitle: "Required to capture your voice",
                    granted: appState.hasMicrophonePermission,
                    action: { delegate.openSystemPreferences(for: "mic") }
                )

                permissionRow(
                    icon: "accessibility",
                    title: "Accessibility",
                    subtitle: "Required for the global hotkey",
                    granted: appState.hasAccessibilityPermission,
                    action: { delegate.requestAccessibilityPermission() }
                )
            }
            .padding(.horizontal, 40)

            Button("Refresh Status") {
                delegate.checkPermissions()
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func permissionRow(icon: String, title: String, subtitle: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 30)
                .foregroundStyle(granted ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Grant") { action() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
    }

    // MARK: - Step 4: Done

    private var doneStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 8) {
                Text("Press the hotkey anytime to start:")
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    KeyCapView(label: "Cmd")
                    Text("+")
                        .foregroundStyle(.secondary)
                    KeyCapView(label: "Shift")
                    Text("+")
                        .foregroundStyle(.secondary)
                    KeyCapView(label: "L")
                }
            }
        }
    }

    // MARK: - Navigation

    private var canAdvance: Bool {
        if currentStep == 2 { return !apiKey.isEmpty }
        return true
    }

    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 && currentStep < totalSteps - 1 {
                Button("Back") {
                    withAnimation { currentStep -= 1 }
                }
                .keyboardShortcut(.escape, modifiers: [])
            }

            Spacer()

            if currentStep < totalSteps - 1 {
                Button("Next") {
                    advance()
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .disabled(!canAdvance)
            } else {
                Button("Get Started") {
                    appState.hasCompletedOnboarding = true
                    onComplete()
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func advance() {
        saveCurrentStep()
        withAnimation { currentStep += 1 }
    }

    private func saveCurrentStep() {
        switch currentStep {
        case 1:
            UserDefaults.standard.set(nativeLang, forKey: "nativeLang")
            UserDefaults.standard.set(targetLang, forKey: "targetLang")
            UserDefaults.standard.set(learningLevel, forKey: "learningLevel")
        case 2:
            if !apiKey.isEmpty {
                try? KeychainHelper.saveAPIKey(apiKey)
            }
        default:
            break
        }
    }
}

// MARK: - Key Cap View

private struct KeyCapView: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.tertiary, lineWidth: 1)
            )
    }
}
