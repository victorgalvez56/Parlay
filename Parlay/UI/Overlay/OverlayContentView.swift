import SwiftUI

struct OverlayContentView: View {
    let response: LangResponse?
    let isProcessing: Bool
    var targetLang: String = "en"
    var onPlaySound: ((String, String) -> Void)?

    private var modeAccent: Color {
        guard let r = response else { return Color(red: 0.306, green: 0.875, blue: 0.722) }
        if r.isPronunciation { return Color(red: 0.306, green: 0.875, blue: 0.722) } // mint
        if r.isCorrection    { return Color(red: 1.0,   green: 0.42,  blue: 0.36)  } // coral
        return Color(red: 0.961, green: 0.784, blue: 0.259)                          // amber
    }

    var body: some View {
        ZStack {
            // Ambient glow behind the card
            RoundedRectangle(cornerRadius: 18)
                .fill(modeAccent.opacity(0.07))
                .blur(radius: 22)
                .padding(-10)

            VStack(alignment: .leading, spacing: 0) {
                if isProcessing {
                    processingView
                } else if let r = response {
                    responseView(r)
                }
            }
            .padding(18)
            .background(cardBackground)
        }
        .frame(width: 360)
        .shadow(color: .black.opacity(0.55), radius: 24, y: 10)
        .preferredColorScheme(.dark)
    }

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.075, green: 0.075, blue: 0.095))
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [modeAccent.opacity(0.35), modeAccent.opacity(0.08), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Processing

    private var processingView: some View {
        HStack(spacing: 10) {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    ProcessingDot(index: i, color: modeAccent)
                }
            }
            Text("ANALYZING")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .kerning(2)
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 14)
    }

    // MARK: - Response

    private func responseView(_ r: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow(r)

            if r.isPronunciation {
                pronunciationContent(r)
            } else if r.isCorrection {
                correctionContent(r)
            } else {
                translationContent(r)
            }

            if !r.examples.isEmpty {
                thinDivider
                examplesSection(r)
            }

            if let note = r.contextNote, !note.isEmpty {
                Text(note)
                    .font(.system(size: 11).italic())
                    .foregroundStyle(.white.opacity(0.28))
            }
        }
    }

    private func headerRow(_ r: LangResponse) -> some View {
        HStack(alignment: .center) {
            // Mode pill
            HStack(spacing: 5) {
                Capsule()
                    .fill(modeAccent)
                    .frame(width: 3, height: 13)
                Text(modeBadgeLabel(r).uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .kerning(1.8)
                    .foregroundStyle(modeAccent)
            }

            Spacer()

            if let difficulty = r.difficulty {
                Text(difficulty.uppercased())
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .kerning(1.2)
                    .foregroundStyle(difficultyColor(difficulty))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(difficultyColor(difficulty).opacity(0.12)))
            }

            Button {
                onPlaySound?(speakableText(r), targetLang)
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.07))
                            .overlay(Circle().strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
                    )
            }
            .buttonStyle(.plain)
            .help("Listen")
        }
    }

    // MARK: - Translation

    private func translationContent(_ r: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let translation = r.translation {
                Text(translation)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let pronunciation = r.pronunciation {
                pronunciationLine(pronunciation)
            }
            if let grammar = r.grammar {
                infoBlock("GRAMMAR", grammar, color: Color(red: 0.45, green: 0.62, blue: 1.0))
            }
        }
    }

    // MARK: - Correction

    private func correctionContent(_ r: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let corrected = r.correctedText {
                Text(corrected)
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let issues = r.originalIssues {
                infoBlock("ISSUES", issues, color: modeAccent)
            }
            if let grammar = r.grammar {
                infoBlock("GRAMMAR", grammar, color: Color(red: 0.45, green: 0.62, blue: 1.0))
            }
            if let translation = r.translation {
                infoBlock("MEANING", translation, color: Color(red: 0.78, green: 0.52, blue: 1.0))
            }
        }
    }

    // MARK: - Pronunciation

    private func pronunciationContent(_ r: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let phonetic = r.phonetic {
                Text(phonetic)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(modeAccent)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let pronunciation = r.pronunciation {
                pronunciationLine(pronunciation)
            }
            if let breakdown = r.soundBreakdown {
                infoBlock("SOUNDS", breakdown, color: modeAccent)
            }
            if let translation = r.translation {
                infoBlock("MEANING", translation, color: Color(red: 0.78, green: 0.52, blue: 1.0))
            }
        }
    }

    // MARK: - Examples

    private func examplesSection(_ r: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(r.isPronunciation ? "IN CONTEXT" : r.isCorrection ? "ALTERNATIVES" : "EXAMPLES")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .kerning(1.5)
                .foregroundStyle(.white.opacity(0.28))

            ForEach(Array(r.examples.prefix(2).enumerated()), id: \.offset) { _, ex in
                HStack(alignment: .top, spacing: 7) {
                    Rectangle()
                        .fill(modeAccent.opacity(0.4))
                        .frame(width: 1.5)
                        .padding(.top, 3)
                    Text(ex)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.58))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Reusable Components

    private func infoBlock(_ label: String, _ content: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Rectangle()
                .fill(color.opacity(0.55))
                .frame(width: 2)
                .padding(.top, 2)
                .padding(.bottom, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .kerning(1.5)
                    .foregroundStyle(color)
                Text(content)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func pronunciationLine(_ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "waveform")
                .font(.system(size: 9))
                .foregroundStyle(modeAccent.opacity(0.6))
            Text(text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.white.opacity(0.42))
        }
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.07))
            .frame(height: 1)
    }

    // MARK: - Helpers

    private func modeBadgeLabel(_ r: LangResponse) -> String {
        if r.isPronunciation { return "Pronunciation" }
        if r.isCorrection    { return "Correction" }
        return "Translation"
    }

    private func speakableText(_ r: LangResponse) -> String {
        if r.isPronunciation { return r.pronunciation ?? r.phonetic ?? r.mainText }
        if r.isCorrection    { return r.correctedText ?? r.mainText }
        return r.translation ?? r.mainText
    }

    private func difficultyColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "beginner":     return .green
        case "intermediate": return Color(red: 1.0, green: 0.65, blue: 0.2)
        case "advanced":     return Color(red: 1.0, green: 0.35, blue: 0.3)
        default:             return .blue
        }
    }
}

// MARK: - Processing Dot

private struct ProcessingDot: View {
    let index: Int
    let color: Color
    @State private var animating = false

    var body: some View {
        Circle()
            .fill(color.opacity(animating ? 0.9 : 0.2))
            .frame(width: 5, height: 5)
            .scaleEffect(animating ? 1.2 : 0.8)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.55)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.18)
                ) {
                    animating = true
                }
            }
    }
}
