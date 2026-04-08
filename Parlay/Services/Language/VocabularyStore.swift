import Foundation

actor VocabularyStore {
    private let fileURL: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/parlay")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("vocabulary.json")
    }()

    func save(_ entry: VocabEntry) async throws {
        var entries = await loadAll()
        entries.insert(entry, at: 0)
        // Keep max 500 entries
        if entries.count > 500 { entries = Array(entries.prefix(500)) }
        let data = try JSONEncoder().encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }

    func loadAll() async -> [VocabEntry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([VocabEntry].self, from: data)) ?? []
    }

    func loadRecent(_ count: Int = 10) async -> [VocabEntry] {
        Array(await loadAll().prefix(count))
    }

    func delete(_ id: UUID) async throws {
        var entries = await loadAll()
        entries.removeAll { $0.id == id }
        let data = try JSONEncoder().encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }

    func clearAll() async throws {
        let data = try JSONEncoder().encode([VocabEntry]())
        try data.write(to: fileURL, options: .atomic)
    }
}
