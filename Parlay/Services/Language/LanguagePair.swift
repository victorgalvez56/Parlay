import Foundation

enum LanguagePair {
    static let supported: [(code: String, name: String, flag: String)] = [
        ("en", "English", "🇺🇸"),
        ("es", "Spanish", "🇪🇸"),
        ("fr", "French", "🇫🇷"),
        ("de", "German", "🇩🇪"),
        ("it", "Italian", "🇮🇹"),
        ("pt", "Portuguese", "🇧🇷"),
        ("ja", "Japanese", "🇯🇵"),
        ("ko", "Korean", "🇰🇷"),
        ("zh", "Chinese", "🇨🇳"),
        ("ru", "Russian", "🇷🇺"),
        ("ar", "Arabic", "🇸🇦"),
        ("hi", "Hindi", "🇮🇳"),
        ("tr", "Turkish", "🇹🇷"),
        ("nl", "Dutch", "🇳🇱"),
        ("sv", "Swedish", "🇸🇪"),
        ("pl", "Polish", "🇵🇱"),
        ("th", "Thai", "🇹🇭"),
        ("vi", "Vietnamese", "🇻🇳"),
    ]

    static func name(for code: String) -> String {
        supported.first { $0.code == code }?.name ?? code
    }

    static func flag(for code: String) -> String {
        supported.first { $0.code == code }?.flag ?? "🌐"
    }
}
