import Foundation

struct WritingAlert: Codable, Equatable {
    let hasErrors: Bool
    let correctedText: String?
    let issues: String?
    let suggestion: String?
}
