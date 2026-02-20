import Foundation

struct LangResponse: Codable, Equatable {
    let mode: String // "translation", "correction", or "pronunciation"
    let translation: String?
    let correctedText: String?
    let originalIssues: String?
    let pronunciation: String?
    let phonetic: String?
    let soundBreakdown: String?
    let grammar: String?
    let examples: [String]
    let contextNote: String?
    let difficulty: String?

    var isCorrection: Bool { mode == "correction" }
    var isTranslation: Bool { mode == "translation" }
    var isPronunciation: Bool { mode == "pronunciation" }

    /// The main text to display prominently
    var mainText: String {
        if isCorrection {
            return correctedText ?? translation ?? ""
        }
        if isPronunciation {
            return phonetic ?? pronunciation ?? ""
        }
        return translation ?? ""
    }
}
