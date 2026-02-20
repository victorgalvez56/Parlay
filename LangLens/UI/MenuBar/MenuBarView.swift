import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState
    let delegate: AppDelegate

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            statusSection
            Divider()
            actionSection
            Divider()
            writingMonitorSection
            if !appState.allPermissionsGranted {
                Divider()
                permissionsSection
            }
            if let response = appState.lastResponse {
                Divider()
                lastResultSection(response)
            }
            Divider()
            footerSection
        }
        .frame(width: 320)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("\(LanguagePair.flag(for: appState.nativeLang)) → \(LanguagePair.flag(for: appState.targetLang))")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("LangLens")
                    .font(.headline)
                Text("\(appState.nativeLangName) → \(appState.targetLangName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(appState.learningLevel.capitalized)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.blue.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(12)
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(spacing: 6) {
            if appState.isRecording {
                Label("Listening... (Cmd+Shift+L to stop)", systemImage: "waveform.circle.fill")
                    .foregroundStyle(.green)
                    .font(.callout)
            } else if appState.isProcessing {
                Label("Analyzing...", systemImage: "ellipsis.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.callout)
            } else if !appState.isWhisperReady {
                Label("Loading speech model...", systemImage: "arrow.down.circle")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else if appState.canRecord {
                Label("Ready — Cmd+Shift+L to ask", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.callout)
            }

            if let error = appState.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .padding(10)
    }

    // MARK: - Actions

    private var actionSection: some View {
        VStack(spacing: 4) {
            if appState.isRecording {
                Button {
                    delegate.cancelRecording()
                } label: {
                    Label("Cancel (Esc)", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .keyboardShortcut(.escape, modifiers: [])

                Button {
                    delegate.toggleRecording()
                } label: {
                    Label("Stop & Analyze", systemImage: "stop.circle.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Button {
                    delegate.toggleRecording()
                } label: {
                    Label("Start Listening", systemImage: "mic.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(!appState.canRecord)
            }
        }
        .padding(8)
    }

    // MARK: - Permissions

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Setup Required")
                .font(.caption)
                .foregroundStyle(.secondary)

            permissionRow(
                "Microphone",
                granted: appState.hasMicrophonePermission,
                action: { delegate.openSystemPreferences(for: "mic") }
            )
            permissionRow(
                "Accessibility",
                granted: appState.hasAccessibilityPermission,
                action: { delegate.openSystemPreferences(for: "accessibility") }
            )
        }
        .padding(10)
    }

    private func permissionRow(_ name: String, granted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundStyle(granted ? .green : .orange)
                Text(name)
                    .font(.caption)
                Spacer()
                if !granted {
                    Text("Grant")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Writing Monitor

    private var writingMonitorSection: some View {
        Button {
            delegate.toggleWritingMonitor()
        } label: {
            HStack {
                Image(systemName: appState.isWritingMonitorEnabled ? "pencil.circle.fill" : "pencil.circle")
                    .foregroundStyle(appState.isWritingMonitorEnabled ? .green : .secondary)
                Text("Writing Monitor")
                    .font(.callout)
                Spacer()
                Text(appState.isWritingMonitorEnabled ? "ON" : "OFF")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(appState.isWritingMonitorEnabled ? .green : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(appState.isWritingMonitorEnabled ? .green.opacity(0.15) : .secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Last Result

    private func lastResultSection(_ response: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Last Result")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    let text: String
                    if response.isPronunciation {
                        text = response.pronunciation ?? response.mainText
                    } else if response.isCorrection {
                        text = response.correctedText ?? response.mainText
                    } else {
                        text = response.translation ?? response.mainText
                    }
                    SpeechService.shared.speak(text, lang: appState.targetLang)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Listen")
            }

            if let transcription = appState.lastTranscription {
                Text("Q: \(transcription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(response.mainText)
                .font(.callout)
                .fontWeight(.medium)
                .lineLimit(3)

            if let pronunciation = response.pronunciation {
                Text(pronunciation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Button {
                HistoryWindowController.shared.show(appState: appState, delegate: delegate)
            } label: {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            Button("Settings...") {
                SettingsWindowController.shared.show()
            }
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(10)
    }
}
