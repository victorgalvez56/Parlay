import Foundation

struct VocabEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let word: String
    let translation: String
    let pronunciation: String?
    let context: String?
    let sourceLang: String
    let targetLang: String
    let timestamp: Date

    init(word: String, translation: String, pronunciation: String? = nil, context: String? = nil, sourceLang: String, targetLang: String) {
        self.id = UUID()
        self.word = word
        self.translation = translation
        self.pronunciation = pronunciation
        self.context = context
        self.sourceLang = sourceLang
        self.targetLang = targetLang
        self.timestamp = Date()
    }
}
