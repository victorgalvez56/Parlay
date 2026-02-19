import Foundation
import CryptoKit

enum KeychainHelper {
    private static let configDir: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/langlens")
    }()

    private static let keyFile: URL = {
        configDir.appendingPathComponent(".api-key")
    }()

    private static var encryptionKey: SymmetricKey {
        let seed = machineID + "com.victorgalvez.LangLens.salt"
        let hash = SHA256.hash(data: Data(seed.utf8))
        return SymmetricKey(data: hash)
    }

    static func saveAPIKey(_ key: String) throws {
        try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        let data = Data(key.utf8)
        let sealed = try AES.GCM.seal(data, using: encryptionKey)
        guard let combined = sealed.combined else { throw KeychainError.encodingFailed }
        try combined.write(to: keyFile)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: keyFile.path)
    }

    static func loadAPIKey() -> String? {
        guard let combined = try? Data(contentsOf: keyFile) else { return nil }
        guard let box = try? AES.GCM.SealedBox(combined: combined) else { return nil }
        guard let data = try? AES.GCM.open(box, using: encryptionKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func deleteAPIKey() {
        try? FileManager.default.removeItem(at: keyFile)
    }

    private static var machineID: String {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(service) }
        guard let uuid = IORegistryEntryCreateCFProperty(service, "IOPlatformUUID" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String else {
            return "fallback-langlens-key"
        }
        return uuid
    }
}

enum KeychainError: LocalizedError {
    case encodingFailed
    var errorDescription: String? { "Failed to encrypt API key" }
}
