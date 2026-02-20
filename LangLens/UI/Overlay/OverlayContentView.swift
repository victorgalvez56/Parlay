import SwiftUI

struct OverlayContentView: View {
    let response: LangResponse?
    let isProcessing: Bool
    var targetLang: String = "en"
    var onPlaySound: ((String, String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isProcessing {
                processingView
            } else if let response {
                responseView(response)
            }
        }
        .padding(16)
        .frame(width: 360)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.3), radius: 12)
    }

    private var processingView: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("Analyzing...")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
    }

    private func responseView(_ r: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Mode badge + play button
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: modeBadgeIcon(r))
                        .font(.caption2)
                    Text(modeBadgeLabel(r))
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(modeBadgeColor(r))

                Spacer()

                Button {
                    let text = speakableText(r)
                    onPlaySound?(text, targetLang)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Listen")
            }

            if r.isPronunciation {
                pronunciationView(r)
            } else if r.isCorrection {
                correctionView(r)
            } else {
                translationView(r)
            }

            // Examples
            if !r.examples.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.isPronunciation ? "In Context" : r.isCorrection ? "Alternatives" : "Examples")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                    ForEach(Array(r.examples.prefix(3).enumerated()), id: \.offset) { _, example in
                        Text("• \(example)")
                            .font(.caption)
                            .foregroundStyle(.primary.opacity(0.8))
                    }
                }
            }

            // Context note
            if let note = r.contextNote, !note.isEmpty {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .italic()
            }

            // Difficulty badge
            if let difficulty = r.difficulty {
                HStack {
                    Spacer()
                    Text(difficulty.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(difficultyColor(difficulty).opacity(0.2))
                        .foregroundStyle(difficultyColor(difficulty))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Translation Mode

    private func translationView(_ r: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let translation = r.translation, !translation.isEmpty {
                Text(translation)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let pronunciation = r.pronunciation, !pronunciation.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "speaker.wave.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(pronunciation)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            if let grammar = r.grammar, !grammar.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Grammar")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                    Text(grammar)
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Correction Mode

    private func correctionView(_ r: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Corrected sentence (main result)
            if let corrected = r.correctedText, !corrected.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text(corrected)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // What was wrong
            if let issues = r.originalIssues, !issues.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Issues")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                    Text(issues)
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Grammar explanation
            if let grammar = r.grammar, !grammar.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Grammar")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                    Text(grammar)
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // What you meant (native lang translation)
            if let translation = r.translation, !translation.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Meaning")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
                    Text(translation)
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.85))
                }
            }
        }
    }

    // MARK: - Pronunciation Mode

    private func pronunciationView(_ r: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // IPA phonetic
            if let phonetic = r.phonetic, !phonetic.isEmpty {
                Text(phonetic)
                    .font(.title2)
                    .fontWeight(.bold)
                    .fontDesign(.serif)
                    .foregroundStyle(.primary)
            }

            // Simplified pronunciation
            if let pronunciation = r.pronunciation, !pronunciation.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "speaker.wave.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(pronunciation)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            // Sound breakdown
            if let breakdown = r.soundBreakdown, !breakdown.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sounds")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.teal)
                    Text(breakdown)
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Meaning
            if let translation = r.translation, !translation.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Meaning")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
                    Text(translation)
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.85))
                }
            }
        }
    }

    // MARK: - Mode Badge Helpers

    private func modeBadgeIcon(_ r: LangResponse) -> String {
        if r.isPronunciation { return "waveform" }
        if r.isCorrection { return "checkmark.circle" }
        return "textformat"
    }

    private func modeBadgeLabel(_ r: LangResponse) -> String {
        if r.isPronunciation { return "Pronunciation" }
        if r.isCorrection { return "Correction" }
        return "Translation"
    }

    private func modeBadgeColor(_ r: LangResponse) -> Color {
        if r.isPronunciation { return .teal }
        if r.isCorrection { return .orange }
        return .blue
    }

    private func speakableText(_ r: LangResponse) -> String {
        if r.isPronunciation {
            // Speak the word itself, not the IPA
            return r.pronunciation ?? r.phonetic ?? r.mainText
        }
        if r.isCorrection {
            return r.correctedText ?? r.mainText
        }
        return r.translation ?? r.mainText
    }

    private func difficultyColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .blue
        }
    }
}
