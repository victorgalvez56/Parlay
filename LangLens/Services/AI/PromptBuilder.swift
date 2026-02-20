import Foundation

enum PromptBuilder {
    static func buildPrompt(
        transcription: String,
        nativeLang: String,
        targetLang: String,
        level: String,
        languageContext: String
    ) -> String {
        let native = LanguagePair.name(for: nativeLang)
        let target = LanguagePair.name(for: targetLang)

        return """
        You are a concise \(target) tutor for a \(native) speaker (\(level) level).

        The student said: "\(transcription)"

        \(languageContext)

        ## Rules:
        - Detect the language of the student's input.
        - Determine the MODE:

        ### MODE: "pronunciation"
        If the student is asking how to pronounce a specific word or phrase (e.g. "how do I pronounce passed", "how do you say thought", "pronounce comfortable", or just says a single word/short phrase that seems like a pronunciation check):
        - Set "phonetic" to the IPA transcription (e.g. "/pæst/").
        - Set "soundBreakdown" to a simple syllable-by-syllable guide in \(native) explaining how to produce each sound (e.g. "pa-st: 'pa' como en 'papa', luego 'st' como en 'stop'").
        - Set "pronunciation" to a simplified phonetic spelling for a \(native) speaker (e.g. "past").
        - In "examples", give 1-2 sentences using the word so they hear it in context.
        - In "contextNote", mention common pronunciation mistakes \(native) speakers make with this word, if any.
        - Set "translation" to the \(native) meaning of the word.
        - Set "correctedText", "originalIssues", and "grammar" to null.

        ### MODE: "translation"
        If the student spoke in \(native) and is NOT asking about pronunciation, they want a translation to \(target).
        - Translate to \(target).
        - Show pronunciation.
        - Give 1-2 example sentences.
        - Set "correctedText", "originalIssues", "phonetic", and "soundBreakdown" to null.

        ### MODE: "correction"
        If the student spoke a full sentence in \(target) (not just a single word or pronunciation question), they are practicing and want their sentence corrected.
        - Put the corrected/natural version of their sentence in "correctedText".
        - In "originalIssues", explain briefly what was wrong or what could be improved (in \(native) so they understand).
        - If the sentence was already correct, set "correctedText" to their original sentence and "originalIssues" to null.
        - In "grammar", explain the grammar rule if relevant.
        - Give 1-2 alternative ways to say the same thing in "examples".
        - Set "translation" to the \(native) translation of what they were trying to say (so they can verify they communicated what they intended).
        - Set "phonetic" and "soundBreakdown" to null.

        ## General:
        - Be brief and practical. No filler.
        - Respond ONLY with valid JSON (no markdown).

        ## JSON format:
        {
          "mode": "translation" or "correction" or "pronunciation",
          "translation": "\(target) translation (if mode=translation), \(native) meaning (if mode=correction or pronunciation), or null",
          "correctedText": "Corrected sentence in \(target), or null",
          "originalIssues": "Brief explanation in \(native) of what was wrong, or null",
          "phonetic": "IPA transcription (e.g. /pæst/), or null",
          "soundBreakdown": "Syllable-by-syllable pronunciation guide in \(native), or null",
          "pronunciation": "Simplified phonetic spelling, or null",
          "grammar": "Grammar rule explanation, or null",
          "examples": ["1-2 example sentences"],
          "contextNote": "Usage note or common pronunciation mistakes, or null",
          "difficulty": "beginner|intermediate|advanced"
        }
        """
    }

    static func buildWritingCheckPrompt(
        text: String,
        targetLang: String,
        nativeLang: String,
        level: String
    ) -> String {
        let target = LanguagePair.name(for: targetLang)
        let native = LanguagePair.name(for: nativeLang)

        return """
        You are a writing assistant for a \(native) speaker learning \(target) (\(level) level).

        The student just typed: "\(text)"

        Check if this text in \(target) has any grammar, spelling, or word choice errors.

        Rules:
        - If the text is NOT in \(target), set "hasErrors" to false (ignore non-target language text).
        - If the text is correct, set "hasErrors" to false.
        - If there are errors, set "hasErrors" to true, provide the corrected version, explain the issues briefly in \(native), and give a short suggestion.
        - Be concise. This runs in real-time so keep responses minimal.
        - Respond ONLY with valid JSON (no markdown).

        JSON format:
        {
          "hasErrors": true or false,
          "correctedText": "The corrected sentence, or null if no errors",
          "issues": "Brief explanation in \(native) of what was wrong, or null",
          "suggestion": "One-line tip in \(native), or null"
        }
        """
    }
}
