import Foundation

final class LanguageContext {
    func generateContext(nativeLang: String, targetLang: String, level: String, recentVocab: [VocabEntry]) -> String {
        var context = """
        ## Language Learning Context
        - Native language: \(LanguagePair.name(for: nativeLang))
        - Target language: \(LanguagePair.name(for: targetLang))
        - Level: \(level)
        """

        if !recentVocab.isEmpty {
            context += "\n\n## Recently Learned Words\n"
            for entry in recentVocab.prefix(15) {
                context += "- \(entry.word) → \(entry.translation)"
                if let pron = entry.pronunciation { context += " (\(pron))" }
                context += "\n"
            }
        }

        return context
    }
}
