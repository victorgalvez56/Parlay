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
            guard let ld = lhs.value.first?.timestamp, let rd = rhs.value.first?.timestamp else { return false }
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
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .font(.title3)
                .foregroundStyle(.blue)
            Text("Learning History")
                .font(.headline)
            Spacer()
            Text("\(appState.allVocab.count) entries")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.caption)
            TextField("Search history...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.callout)
        }
        .padding(8)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
                                Divider().padding(.leading, 12)
                            }
                        }
                    } header: {
                        Text(dateStr)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.top, 10)
                            .padding(.bottom, 4)
                    }
                }
            }
        }
    }

    private func entryRow(_ entry: VocabEntry) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.word)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(2)

                Text(entry.translation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let pron = entry.pronunciation, !pron.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "speaker.wave.1")
                            .font(.caption2)
                        Text(pron)
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }

                if let context = entry.context, !context.isEmpty {
                    Text(context)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .italic()
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(timeString(entry.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Button {
                    delegate.deleteVocabEntry(entry.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Delete entry")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("No history yet")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("Use Cmd+Shift+L to start learning")
                .font(.caption)
                .foregroundStyle(.tertiary)
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
                Label("Clear All", systemImage: "trash")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red.opacity(0.8))

            Spacer()

            Button {
                Task { await delegate.loadAllVocab() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
    }

    // MARK: - Helpers

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
