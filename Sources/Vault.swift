import CryptoKit
import Foundation
import Security

enum VaultError: LocalizedError {
    case corrupted
    case unsupportedVersion
    case keychain(OSStatus)
    case encryption

    var errorDescription: String? {
        switch self {
        case .corrupted:
            return "账户数据文件已损坏，无法读取。"
        case .unsupportedVersion:
            return "账户数据文件版本过新，无法读取。"
        case .keychain(let status):
            return "无法访问系统钥匙串（错误码 \(status)）。"
        case .encryption:
            return "账户数据加密失败。"
        }
    }
}

private struct VaultPayload: Codable {
    var version: Int
    var accounts: [Account]
}

private enum KeychainStore {
    private static let service = "com.risetta.vault"
    private static let account = "vault-key"

    static func loadKey() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess, let data = item as? Data else {
            throw VaultError.keychain(status)
        }

        return SymmetricKey(data: data)
    }

    static func saveKey(_ key: SymmetricKey) throws {
        let data = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw VaultError.keychain(status)
        }
    }

    static func key() throws -> SymmetricKey {
        if let existing = try loadKey() {
            return existing
        }

        let key = SymmetricKey(size: .bits256)
        try saveKey(key)
        return key
    }
}

final class VaultStore {
    let fileURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support", isDirectory: true)
        fileURL = base
            .appendingPathComponent("Risetta", isDirectory: true)
            .appendingPathComponent("vault.dat")
    }

    func load() throws -> [Account] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        guard data.count > 5, Data(data.prefix(5)) == Data("RSMA1".utf8) else {
            throw VaultError.corrupted
        }

        guard let key = try KeychainStore.loadKey() else {
            throw VaultError.keychain(errSecItemNotFound)
        }
        let sealedBox = try AES.GCM.SealedBox(combined: Data(data.dropFirst(5)))
        let plaintext = try AES.GCM.open(sealedBox, using: key)
        let payload = try JSONDecoder().decode(VaultPayload.self, from: plaintext)

        guard payload.version == 1 else {
            throw VaultError.unsupportedVersion
        }

        return payload.accounts
    }

    func save(_ accounts: [Account]) throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let existingKey = try KeychainStore.loadKey()
            if existingKey == nil {
                throw VaultError.keychain(errSecItemNotFound)
            }
        }

        let payload = VaultPayload(version: 1, accounts: accounts)
        let plaintext = try JSONEncoder().encode(payload)
        let key = try KeychainStore.key()
        let sealedBox = try AES.GCM.seal(plaintext, using: key)

        guard let combined = sealedBox.combined else {
            throw VaultError.encryption
        }

        var output = Data("RSMA1".utf8)
        output.append(combined)

        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
        try output.write(to: fileURL, options: .atomic)
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }
}
