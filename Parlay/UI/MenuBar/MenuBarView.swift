import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState
    let delegate: AppDelegate

    var body: some View {
        VStack(spacing: 0) {
            // Subtle top-edge highlight simulating light catching the glass
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0), .white.opacity(0.15), .white.opacity(0)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 0.5)

            headerSection
            glassDivider
            statusStrip
            glassDivider
            actionSection
            if !appState.allPermissionsGranted {
                glassDivider
                permissionsSection
            }
            if let response = appState.lastResponse {
                glassDivider
                lastResultCard(response)
            }
            glassDivider
            footerSection
        }
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.05, green: 0.05, blue: 0.08).opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 0.5)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.55), radius: 20, x: 0, y: 8)
        .preferredColorScheme(.dark)
    }

    private var glassDivider: some View {
        Rectangle().fill(.white.opacity(0.06)).frame(height: 0.5)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                Text(LanguagePair.flag(for: appState.nativeLang))
                    .font(.title2)
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.28))
                Text(LanguagePair.flag(for: appState.targetLang))
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Parlay")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(appState.targetLangName)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            Text(appState.learningLevel.capitalized)
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(Color(red: 0.45, green: 0.62, blue: 1.0).opacity(0.12))
                        .overlay(Capsule().strokeBorder(Color(red: 0.45, green: 0.62, blue: 1.0).opacity(0.25), lineWidth: 0.5))
                )
                .foregroundStyle(Color(red: 0.45, green: 0.62, blue: 1.0))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Status Strip

    private var statusStrip: some View {
        HStack(spacing: 8) {
            statusIndicator
            statusText
            Spacer()
            if appState.errorMessage != nil {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.white.opacity(0.025))
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
            Text("Listening — ⌘⇧L to stop")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.green)
        } else if appState.isProcessing {
            Text("Analyzing…")
                .font(.system(size: 11))
                .foregroundStyle(.orange)
        } else if !appState.isWhisperReady {
            Text("Loading speech model…")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
        } else if appState.canRecord {
            Text("Ready — press ⌘⇧L to start")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
        } else {
            Text("Unavailable")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
        }
    }

    // MARK: - Actions

    private var actionSection: some View {
        VStack(spacing: 6) {
            if appState.isRecording {
                glassActionButton("Stop & Analyze", icon: "stop.circle.fill", gradient: [.green, .green.opacity(0.85)]) {
                    delegate.toggleRecording()
                }
                glassActionButton("Cancel", icon: "xmark.circle", gradient: [.white.opacity(0.08), .white.opacity(0.05)]) {
                    delegate.cancelRecording()
                }
                .keyboardShortcut(.escape, modifiers: [])
            } else {
                glassActionButton("Start Listening", icon: "mic.fill", gradient: [Color(red: 0, green: 0.478, blue: 1.0), Color(red: 0, green: 0.4, blue: 0.867)]) {
                    delegate.toggleRecording()
                }
                .disabled(!appState.canRecord)

                Text("⌘⇧L")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.28))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func glassActionButton(_ title: String, icon: String, gradient: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Permissions

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PERMISSIONS")
                .font(.system(size: 9, weight: .semibold))
                .kerning(1.5)
                .foregroundStyle(.white.opacity(0.28))

            permissionRow("Microphone", granted: appState.hasMicrophonePermission) {
                delegate.openSystemPreferences(for: "mic")
            }
            permissionRow("Accessibility", granted: appState.hasAccessibilityPermission) {
                delegate.openSystemPreferences(for: "accessibility")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func permissionRow(_ name: String, granted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: granted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundStyle(granted ? .green : .white.opacity(0.28))
                Text(name)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.72))
                Spacer()
                if !granted {
                    Text("Grant →")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(red: 0.45, green: 0.62, blue: 1.0))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.03)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Last Result Card

    private func lastResultCard(_ r: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(modeColor(r))
                        .frame(width: 3, height: 14)
                    Text(modeLabel(r).uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .kerning(1.5)
                        .foregroundStyle(modeColor(r))
                }
                Spacer()
                Button {
                    SpeechService.shared.speak(speakableText(r), lang: appState.targetLang)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(width: 24, height: 24)
                        .background(
                            Circle().fill(.white.opacity(0.04))
                                .overlay(Circle().strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
                        )
                }
                .buttonStyle(.plain)
                .help("Listen")
            }

            if let transcription = appState.lastTranscription {
                Text("\u{201C}\(transcription)\u{201D}")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.28))
                    .lineLimit(1)
            }

            Text(r.mainText)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            if let pronunciation = r.pronunciation {
                HStack(spacing: 6) {
                    Text(pronunciation)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.45))
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.03)))
        .padding(.horizontal, 12)
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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func footerButton(_ label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 10))
                Text(label).font(.system(size: 11))
            }
            .foregroundStyle(.white.opacity(0.45))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
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
        if r.isPronunciation { return Color(red: 0.306, green: 0.859, blue: 0.722) }
        if r.isCorrection    { return Color(red: 1.0, green: 0.42, blue: 0.36) }
        return Color(red: 0.961, green: 0.784, blue: 0.259)
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
