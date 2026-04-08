import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState
    let delegate: AppDelegate

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            statusStrip
            Divider()
            actionSection
            if !appState.allPermissionsGranted {
                Divider()
                permissionsSection
            }
            if let response = appState.lastResponse {
                Divider()
                lastResultCard(response)
            }
            Divider()
            footerSection
        }
        .frame(width: 320)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 10) {
            HStack(spacing: 3) {
                Text(LanguagePair.flag(for: appState.nativeLang))
                    .font(.title2)
                Image(systemName: "arrow.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.tertiary)
                Text(LanguagePair.flag(for: appState.targetLang))
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Parlay")
                    .font(.system(size: 14, weight: .semibold))
                Text(appState.targetLangName)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(appState.learningLevel.capitalized)
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(.blue.opacity(0.1)))
                .foregroundStyle(.blue)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - Status Strip

    private var statusStrip: some View {
        HStack(spacing: 7) {
            statusIndicator
            statusText
            Spacer()
            if appState.errorMessage != nil {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.primary.opacity(0.04))
    }

    @ViewBuilder
    private var statusIndicator: some View {
        if appState.isRecording {
            PulsingDot(color: .green)
        } else if appState.isProcessing {
            ProgressView().controlSize(.mini).scaleEffect(0.7)
        } else if appState.canRecord {
            Circle().fill(.green.opacity(0.6)).frame(width: 6, height: 6)
        } else {
            Circle().fill(.secondary.opacity(0.4)).frame(width: 6, height: 6)
        }
    }

    @ViewBuilder
    private var statusText: some View {
        if appState.isRecording {
            Text("Listening — Cmd+Shift+L to stop")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.green)
        } else if appState.isProcessing {
            Text("Analyzing…")
                .font(.system(size: 11))
                .foregroundStyle(.orange)
        } else if !appState.isWhisperReady {
            Text("Loading speech model…")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        } else if appState.canRecord {
            Text("Ready — press Cmd+Shift+L")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        } else {
            Text("Unavailable")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private var actionSection: some View {
        VStack(spacing: 4) {
            if appState.isRecording {
                menuButton("Stop & Analyze", icon: "stop.circle.fill", tint: .green) {
                    delegate.toggleRecording()
                }
                menuButton("Cancel", icon: "xmark.circle", tint: .secondary) {
                    delegate.cancelRecording()
                }
                .keyboardShortcut(.escape, modifiers: [])
            } else {
                menuButton("Start Listening", icon: "mic.fill", tint: .blue) {
                    delegate.toggleRecording()
                }
                .disabled(!appState.canRecord)
            }
        }
        .padding(10)
    }

    private func menuButton(_ title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(tint)
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 13))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 7).fill(tint.opacity(0.07)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Permissions

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SETUP REQUIRED")
                .font(.system(size: 9, weight: .semibold))
                .kerning(1)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 8)

            permissionRow("Microphone", granted: appState.hasMicrophonePermission) {
                delegate.openSystemPreferences(for: "mic")
            }
            permissionRow("Accessibility", granted: appState.hasAccessibilityPermission) {
                delegate.openSystemPreferences(for: "accessibility")
            }
        }
        .padding(.bottom, 6)
    }

    private func permissionRow(_ name: String, granted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: granted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundStyle(granted ? .green : .secondary)
                Text(name)
                    .font(.system(size: 12))
                Spacer()
                if !granted {
                    Text("Grant →")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Last Result Card

    private func lastResultCard(_ r: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                HStack(spacing: 4) {
                    Capsule()
                        .fill(modeColor(r))
                        .frame(width: 2.5, height: 11)
                    Text(modeLabel(r).uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .kerning(1.2)
                        .foregroundStyle(modeColor(r))
                }
                Spacer()
                Button {
                    SpeechService.shared.speak(speakableText(r), lang: appState.targetLang)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Listen")
            }

            if let transcription = appState.lastTranscription {
                Text("\u{201C}\(transcription)\u{201D}")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(r.mainText)
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            if let pronunciation = r.pronunciation {
                Text(pronunciation)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(11)
        .background(RoundedRectangle(cornerRadius: 9).fill(.primary.opacity(0.04)))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(spacing: 0) {
            footerButton("History", icon: "clock.arrow.circlepath") {
                HistoryWindowController.shared.show(appState: appState, delegate: delegate)
            }
            footerButton("Settings", icon: "gearshape") {
                SettingsWindowController.shared.show()
            }
            Spacer()
            footerButton("Quit", icon: "power") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
    }

    private func footerButton(_ label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10))
                Text(label).font(.system(size: 11))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func modeLabel(_ r: LangResponse) -> String {
        if r.isPronunciation { return "Pronunciation" }
        if r.isCorrection    { return "Correction" }
        return "Translation"
    }

    private func modeColor(_ r: LangResponse) -> Color {
        if r.isPronunciation { return .teal }
        if r.isCorrection    { return .orange }
        return .blue
    }

    private func speakableText(_ r: LangResponse) -> String {
        if r.isPronunciation { return r.pronunciation ?? r.phonetic ?? r.mainText }
        if r.isCorrection    { return r.correctedText ?? r.mainText }
        return r.translation ?? r.mainText
    }
}

// MARK: - Pulsing Status Dot

private struct PulsingDot: View {
    let color: Color
    @State private var animating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.25))
                .frame(width: animating ? 14 : 6, height: animating ? 14 : 6)
                .onAppear {
                    withAnimation(
                        .easeOut(duration: 1.1)
                        .repeatForever(autoreverses: false)
                    ) { animating = true }
                }
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
        }
    }
}
