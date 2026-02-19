import Foundation

struct LangResponse: Codable, Equatable {
    let translation: String
    let pronunciation: String?
    let grammar: String?
    let examples: [String]
    let contextNote: String?
    let difficulty: String?
}
