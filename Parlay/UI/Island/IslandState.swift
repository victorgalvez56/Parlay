import Foundation
import SwiftUI

@MainActor
@Observable
final class IslandState {
    enum Phase: Equatable {
        case idle                  // header only — always visible
        case recording
        case processing
        case result(LangResponse)

        static func == (lhs: Phase, rhs: Phase) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.recording, .recording), (.processing, .processing): return true
            case (.result(let a), .result(let b)): return a == b
            default: return false
            }
        }

        var isExpanded: Bool {
            if case .result = self { return true }
            return false
        }

        var hasContent: Bool {
            self != .idle
        }
    }

    var phase: Phase = .idle
    var nativeLang: String = "es"
    var targetLang: String = "en"
    var learningLevel: String = "intermediate"
    var isWhisperReady: Bool = false
    var onPlay: ((String, String) -> Void)?
}
