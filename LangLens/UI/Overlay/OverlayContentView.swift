import SwiftUI

struct OverlayContentView: View {
    let response: LangResponse?
    let isProcessing: Bool

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
            // Translation (main answer)
            Text(r.translation)
                .font(.title3)
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)

            // Pronunciation
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

            // Grammar
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

            // Examples
            if !r.examples.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Examples")
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

    private func difficultyColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .blue
        }
    }
}
