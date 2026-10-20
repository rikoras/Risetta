import CryptoKit
import Foundation

enum Base32 {
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
    private static let lookup: [Character: UInt32] = {
        var map: [Character: UInt32] = [:]
        for (index, character) in alphabet.enumerated() {
            map[character] = UInt32(index)
        }
        return map
    }()

    static func decode(_ input: String) -> Data? {
        var output = Data()
        var buffer: UInt32 = 0
        var bits = 0

        for character in input.uppercased() {
            guard let value = lookup[character] else {
                if character == "=" || character == " " || character == "-" || character == "\n" || character == "\r" || character == "\t" {
                    continue
                }
                return nil
            }

            buffer = (buffer << 5) | value
            bits += 5

            if bits >= 8 {
                bits -= 8
                output.append(UInt8((buffer >> UInt32(bits)) & 0xFF))
            }
        }

        return output.isEmpty ? nil : output
    }
}

struct OtpAuthInfo {
    var issuer: String?
    var accountName: String?
    var secret: String
    var algorithm: String
    var digits: Int
    var period: Int
}

enum OtpAuthParser {
    static func parse(_ raw: String) -> OtpAuthInfo? {
        guard let components = URLComponents(string: raw),
              components.scheme?.lowercased() == "otpauth",
              components.host?.lowercased() == "totp",
              let queryItems = components.queryItems
        else {
            return nil
        }

        var values: [String: String] = [:]
        for item in queryItems {
            values[item.name.lowercased()] = item.value ?? ""
        }

        guard let secret = values["secret"], !secret.isEmpty else {
            return nil
        }

        let label = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var labelIssuer: String?
        var labelAccount: String?

        if let separator = label.firstIndex(of: ":") {
            labelIssuer = String(label[..<separator]).trimmingCharacters(in: .whitespacesAndNewlines)
            labelAccount = String(label[label.index(after: separator)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if !label.isEmpty {
            labelAccount = label
        }

        let algorithm = (values["algorithm"] ?? "SHA1").uppercased()
        let digits = Int(values["digits"] ?? "") ?? 6
        let period = Int(values["period"] ?? "") ?? 30

        guard ["SHA1", "SHA256", "SHA512"].contains(algorithm),
              (6...8).contains(digits),
              period >= 10
        else {
            return nil
        }

        return OtpAuthInfo(
            issuer: values["issuer"].flatMap { $0.isEmpty ? nil : $0 } ?? labelIssuer,
            accountName: labelAccount,
            secret: secret,
            algorithm: algorithm,
            digits: digits,
            period: period
        )
    }
}

enum Totp {
    static func normalize(_ secret: String) -> String {
        secret
            .uppercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    static func isValid(secret: String) -> Bool {
        let normalized = normalize(secret)
        return !normalized.isEmpty && Base32.decode(normalized) != nil
    }

    static func code(for account: Account, at date: Date = Date()) -> String {
        let normalized = normalize(account.secret)
        guard let keyData = Base32.decode(normalized) else {
            return String(repeating: "•", count: max(6, account.digits))
        }

        let period = max(10, account.period)
        let counter = Int64(floor(date.timeIntervalSince1970 / Double(period)))
        var counterData = Data()
        var value = UInt64(bitPattern: counter)
        for _ in 0..<8 {
            counterData.append(UInt8(value & 0xFF))
            value >>= 8
        }

        let hash = hmac(key: keyData, message: counterData, algorithm: account.algorithm)
        guard hash.count >= 20 else {
            return String(repeating: "•", count: max(6, account.digits))
        }

        let offset = Int(hash[hash.count - 1] & 0x0F)
        guard offset + 4 <= hash.count else {
            return String(repeating: "•", count: max(6, account.digits))
        }

        let binary = (UInt32(hash[offset]) << 24)
            | (UInt32(hash[offset + 1]) << 16)
            | (UInt32(hash[offset + 2]) << 8)
            | UInt32(hash[offset + 3])
        let truncated = binary & 0x7FFF_FFFF

        var modulus: UInt32 = 1
        for _ in 0..<max(6, account.digits) {
            modulus *= 10
        }

        let code = truncated % modulus
        return String(format: "%0\(max(6, account.digits))d", Int(code))
    }

    static func remainingSeconds(for account: Account, at date: Date = Date()) -> Int {
        let period = max(10, account.period)
        let elapsed = Int(date.timeIntervalSince1970) % period
        return period - elapsed
    }

    static func remainingFraction(for account: Account, at date: Date = Date()) -> Double {
        let period = max(10, account.period)
        return Double(remainingSeconds(for: account, at: date)) / Double(period)
    }

    private static func hmac(key: Data, message: Data, algorithm: String) -> Data {
        let symmetricKey = SymmetricKey(data: key)
        switch algorithm.uppercased() {
        case "SHA256":
            return Data(HMAC<SHA256>.authenticationCode(for: message, using: symmetricKey))
        case "SHA512":
            return Data(HMAC<SHA512>.authenticationCode(for: message, using: symmetricKey))
        default:
            return Data(HMAC<Insecure.SHA1>.authenticationCode(for: message, using: symmetricKey))
        }
    }
}
