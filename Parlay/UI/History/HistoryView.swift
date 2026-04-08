import SwiftUI

struct HistoryView: View {
    @Bindable var appState: AppState
    let delegate: AppDelegate

    @State private var searchText = ""
    @State private var showingClearConfirm = false

    private var filteredEntries: [VocabEntry] {
        if searchText.isEmpty { return appState.allVocab }
        let query = searchText.lowercased()
        return appState.allVocab.filter {
            $0.word.lowercased().contains(query) ||
            $0.translation.lowercased().contains(query) ||
            ($0.context?.lowercased().contains(query) ?? false)
        }
    }

    private var groupedByDate: [(String, [VocabEntry])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let grouped = Dictionary(grouping: filteredEntries) { entry in
            formatter.string(from: entry.timestamp)
        }

        return grouped.sorted { lhs, rhs in
            guard let ld = lhs.value.first?.timestamp,
                  let rd = rhs.value.first?.timestamp else { return false }
            return ld > rd
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            if appState.allVocab.isEmpty {
                emptyState
            } else {
                searchBar
                entryList
                Divider()
                footerBar
            }
        }
        .frame(width: 480, height: 520)
        .onAppear {
            Task { await delegate.loadAllVocab() }
        }
        .alert("Clear All History?", isPresented: $showingClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                delegate.clearAllVocab()
            }
        } message: {
            Text("This will permanently delete all \(appState.allVocab.count) entries.")
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.blue)
            Text("Learning History")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Text("\(appState.allVocab.count) entries")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(.secondary.opacity(0.1)))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.tertiary)
                .font(.system(size: 12))
            TextField("Search words, translations…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 8).fill(.primary.opacity(0.05)))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - List

    private var entryList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(groupedByDate, id: \.0) { dateStr, entries in
                    Section {
                        ForEach(entries) { entry in
                            entryRow(entry)
                            if entry.id != entries.last?.id {
                                Divider()
                                    .padding(.leading, 48)
                            }
                        }
                    } header: {
                        Text(dateStr.uppercased())
                            .font(.system(size: 9, weight: .semibold))
                            .kerning(1)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.top, 12)
                            .padding(.bottom, 4)
                    }
                }
            }
        }
    }

    private func entryRow(_ entry: VocabEntry) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Mode accent strip (left border)
            Rectangle()
                .fill(modeColorForEntry(entry))
                .frame(width: 3)
                .padding(.vertical, 10)
                .padding(.leading, 14)

            // Content
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.word)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(2)

                    Text(entry.translation)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    if let pron = entry.pronunciation, !pron.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "waveform")
                                .font(.system(size: 9))
                            Text(pron)
                                .font(.system(size: 11, design: .monospaced))
                        }
                        .foregroundStyle(.tertiary)
                    }

                    if let context = entry.context, !context.isEmpty {
                        Text(context)
                            .font(.system(size: 11).italic())
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(timeString(entry.timestamp))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)

                    Button {
                        delegate.deleteVocabEntry(entry.id)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Delete entry")
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .padding(.vertical, 10)
        }
        .contentShape(Rectangle())
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "text.book.closed")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            VStack(spacing: 4) {
                Text("No history yet")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Use Cmd+Shift+L to start learning")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack {
            Button {
                showingClearConfirm = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "trash").font(.system(size: 10))
                    Text("Clear All").font(.system(size: 11))
                }
                .foregroundStyle(.red.opacity(0.75))
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                Task { await delegate.loadAllVocab() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 10))
                    Text("Refresh").font(.system(size: 11))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    // MARK: - Helpers

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Derive a color from the entry context/word — since VocabEntry has no mode field,
    /// we use pronunciation (which only exists for pronunciation entries) as a heuristic.
    private func modeColorForEntry(_ entry: VocabEntry) -> Color {
        if entry.pronunciation != nil && entry.context == nil {
            return Color(red: 0.306, green: 0.875, blue: 0.722) // mint = pronunciation
        }
        return .blue.opacity(0.7)
    }
}

// MARK: - Window Controller

@MainActor
final class HistoryWindowController {
    static let shared = HistoryWindowController()
    private var window: NSWindow?

    func show(appState: AppState, delegate: AppDelegate) {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = HistoryView(appState: appState, delegate: delegate)
        let hostingController = NSHostingController(rootView: view)
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "Learning History"
        newWindow.styleMask = [.titled, .closable, .resizable]
        newWindow.setContentSize(NSSize(width: 480, height: 520))
        newWindow.minSize = NSSize(width: 380, height: 300)
        newWindow.center()
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = newWindow
    }
}
