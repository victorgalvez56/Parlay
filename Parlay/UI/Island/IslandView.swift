import SwiftUI

struct IslandView: View {
    @Bindable var state: IslandState
    var onSizeChange: ((CGSize) -> Void)?

    private let headerWidth: CGFloat = 280
    private let resultWidth: CGFloat = 360

    private var currentWidth: CGFloat {
        state.phase.isExpanded ? resultWidth : headerWidth
    }

    // Fully rounded — floating HUD, not attached to menu bar
    private var cornerRadius: CGFloat { state.phase.isExpanded ? 18 : 22 }
    private var islandShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            if state.phase.hasContent {
                contentDivider
                contentArea
            }
        }
        .frame(width: currentWidth)
        .background(.ultraThinMaterial)
        .background(glassOverlay)
        .clipShape(islandShape)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear    { onSizeChange?(geo.size) }
                    .onChange(of: geo.size) { _, s in onSizeChange?(s) }
            }
        )
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: state.phase)
        // Layered shadows = premium floating depth
        .shadow(color: .black.opacity(0.55), radius: 24, x: 0, y: 12)
        .shadow(color: .black.opacity(0.25), radius:  8, x: 0, y:  4)
        .shadow(color: .black.opacity(0.10), radius:  2, x: 0, y:  1)
    }

    // MARK: - Header (always visible)

    private var headerBar: some View {
        HStack(spacing: 10) {
            // Language pair
            HStack(spacing: 4) {
                Text(LanguagePair.flag(for: state.nativeLang))
                    .font(.system(size: 13))
                Image(systemName: "arrow.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
                Text(LanguagePair.flag(for: state.targetLang))
                    .font(.system(size: 13))
            }

            // App name
            Text("Parlay")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            // Status indicator
            statusIndicator

            // Level badge
            Text(state.learningLevel.prefix(3).uppercased())
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .kerning(0.8)
                .foregroundStyle(.white.opacity(0.45))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(.white.opacity(0.08)))
        }
        .padding(.horizontal, 14)
        .frame(height: 30)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch state.phase {
        case .idle:
            Circle()
                .fill(state.isWhisperReady ? Color.green.opacity(0.7) : Color.secondary.opacity(0.4))
                .frame(width: 5, height: 5)
        case .recording:
            RecordingDot(size: 6)
        case .processing:
            ProgressView().controlSize(.mini).scaleEffect(0.65)
        case .result:
            Circle().fill(Color.green.opacity(0.6)).frame(width: 5, height: 5)
        }
    }

    // MARK: - Divider between header and content

    private var contentDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(height: 0.5)
    }

    // MARK: - Content area (recording / processing / result)

    @ViewBuilder
    private var contentArea: some View {
        switch state.phase {
        case .idle:
            EmptyView()
        case .recording:
            recordingContent
        case .processing:
            processingContent
        case .result(let r):
            resultContent(r)
        }
    }

    // MARK: - Recording

    private var recordingContent: some View {
        HStack(spacing: 10) {
            MiniWaveform()
            Text("Listening…")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
            Text("⌘⇧L to stop")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: headerWidth)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Processing

    private var processingContent: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in IslandDot(index: i) }
            }
            Text("Analyzing")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .kerning(1.2)
                .foregroundStyle(.white.opacity(0.45))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: headerWidth)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Result card

    private func resultContent(_ r: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            modeHeader(r)
            modeBody(r)
            if !r.examples.isEmpty {
                thinDivider
                examplesSection(r)
            }
            if let note = r.contextNote, !note.isEmpty {
                Text(note)
                    .font(.system(size: 11).italic())
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func modeHeader(_ r: LangResponse) -> some View {
        HStack {
            HStack(spacing: 5) {
                Capsule().fill(accent(r)).frame(width: 3, height: 12)
                Text(modeLabel(r).uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .kerning(1.8)
                    .foregroundStyle(accent(r))
            }
            Spacer()
            if let d = r.difficulty { difficultyBadge(d) }
            playButton(r)
        }
    }

    private func playButton(_ r: LangResponse) -> some View {
        Button {
            state.onPlay?(speakable(r), state.targetLang)
        } label: {
            Image(systemName: "play.fill")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 26, height: 26)
                .background(
                    Circle().fill(.white.opacity(0.08))
                        .overlay(Circle().strokeBorder(.white.opacity(0.12), lineWidth: 0.5))
                )
        }
        .buttonStyle(.plain)
    }

    private func difficultyBadge(_ level: String) -> some View {
        Text(level.uppercased())
            .font(.system(size: 8, weight: .semibold, design: .monospaced))
            .kerning(1.2)
            .foregroundStyle(difficultyColor(level))
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(difficultyColor(level).opacity(0.14)))
    }

    @ViewBuilder
    private func modeBody(_ r: LangResponse) -> some View {
        if r.isPronunciation  { pronunciationBody(r) }
        else if r.isCorrection { correctionBody(r) }
        else                   { translationBody(r) }
    }

    private func translationBody(_ r: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let t = r.translation {
                Text(t)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let p = r.pronunciation { phonLine(p) }
            if let g = r.grammar { block("GRAMMAR", g, Color(red: 0.45, green: 0.62, blue: 1)) }
        }
    }

    private func correctionBody(_ r: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let c = r.correctedText {
                Text(c)
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let i = r.originalIssues { block("ISSUES",  i, accent(r)) }
            if let g = r.grammar        { block("GRAMMAR", g, Color(red: 0.45, green: 0.62, blue: 1)) }
            if let t = r.translation    { block("MEANING", t, Color(red: 0.78, green: 0.52, blue: 1)) }
        }
    }

    private func pronunciationBody(_ r: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let ph = r.phonetic {
                Text(ph)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(accent(r))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let p = r.pronunciation  { phonLine(p) }
            if let b = r.soundBreakdown { block("SOUNDS",  b, accent(r)) }
            if let t = r.translation    { block("MEANING", t, Color(red: 0.78, green: 0.52, blue: 1)) }
        }
    }

    private func examplesSection(_ r: LangResponse) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(r.isPronunciation ? "IN CONTEXT" : r.isCorrection ? "ALTERNATIVES" : "EXAMPLES")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .kerning(1.5)
                .foregroundStyle(.white.opacity(0.3))
            ForEach(Array(r.examples.prefix(2).enumerated()), id: \.offset) { _, ex in
                HStack(alignment: .top, spacing: 7) {
                    Rectangle().fill(accent(r).opacity(0.45)).frame(width: 1.5).padding(.top, 3)
                    Text(ex).font(.system(size: 12)).foregroundStyle(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Glass background (premium floating HUD)

    private var glassOverlay: some View {
        ZStack {
            // Rich dark tint — makes content legible while showing blur through
            islandShape.fill(Color.black.opacity(0.48))

            // Top highlight — subtle glass shimmer
            islandShape.fill(
                LinearGradient(
                    colors: [.white.opacity(0.10), .clear],
                    startPoint: .top,
                    endPoint: .init(x: 0.5, y: 0.4)
                )
            )

            // Uniform crisp border all around — intentional floating object
            islandShape.strokeBorder(.white.opacity(0.16), lineWidth: 1)
        }
    }

    // MARK: - Atoms

    private func block(_ label: String, _ text: String, _ color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Rectangle().fill(color.opacity(0.6)).frame(width: 2).padding(.vertical, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 8, weight: .bold, design: .monospaced)).kerning(1.5)
                    .foregroundStyle(color)
                Text(text)
                    .font(.system(size: 12)).foregroundStyle(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(9)
        .background(RoundedRectangle(cornerRadius: 6).fill(color.opacity(0.07)))
    }

    private func phonLine(_ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "waveform").font(.system(size: 9)).foregroundStyle(.white.opacity(0.3))
            Text(text).font(.system(size: 12, design: .monospaced)).foregroundStyle(.white.opacity(0.45))
        }
    }

    private var thinDivider: some View {
        Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
    }

    private func accent(_ r: LangResponse) -> Color {
        if r.isPronunciation { return Color(red: 0.31, green: 0.88, blue: 0.72) }
        if r.isCorrection    { return Color(red: 1.00, green: 0.42, blue: 0.36) }
        return Color(red: 0.96, green: 0.78, blue: 0.26)
    }

    private func modeLabel(_ r: LangResponse) -> String {
        if r.isPronunciation { return "Pronunciation" }
        if r.isCorrection    { return "Correction" }
        return "Translation"
    }

    private func speakable(_ r: LangResponse) -> String {
        if r.isPronunciation { return r.pronunciation ?? r.phonetic ?? r.mainText }
        if r.isCorrection    { return r.correctedText ?? r.mainText }
        return r.translation ?? r.mainText
    }

    private func difficultyColor(_ l: String) -> Color {
        switch l.lowercased() {
        case "beginner":     return .green
        case "intermediate": return Color(red: 1, green: 0.65, blue: 0.2)
        case "advanced":     return Color(red: 1, green: 0.35, blue: 0.3)
        default:             return .blue
        }
    }
}

// MARK: - Recording Dot

private struct RecordingDot: View {
    var size: CGFloat = 7
    @State private var pulsing = false
    var body: some View {
        ZStack {
            Circle().fill(Color.red.opacity(0.22))
                .frame(width: pulsing ? size * 2.6 : size, height: pulsing ? size * 2.6 : size)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                        pulsing = true
                    }
                }
            Circle().fill(Color.red).frame(width: size, height: size)
        }
    }
}

// MARK: - Mini Waveform

private struct MiniWaveform: View {
    @State private var phase: CGFloat = 0
    private let timer = Timer.publish(every: 0.07, on: .main, in: .common).autoconnect()
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.red.opacity(0.8))
                    .frame(width: 2.5, height: max(3, sin(phase + Double(i) * 0.9) * 7 + 9))
            }
        }
        .frame(height: 18)
        .onReceive(timer) { _ in
            withAnimation(.linear(duration: 0.07)) { phase += 0.35 }
        }
    }
}

// MARK: - Processing Dot

private struct IslandDot: View {
    let index: Int
    @State private var on = false
    var body: some View {
        Circle().fill(.white.opacity(on ? 0.85 : 0.2))
            .frame(width: 4, height: 4)
            .scaleEffect(on ? 1.1 : 0.9)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.15)) { on = true }
            }
    }
}
