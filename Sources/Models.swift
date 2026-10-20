import Foundation

struct Account: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var issuer: String
    var accountName: String
    var secret: String
    var algorithm: String
    var digits: Int
    var period: Int

    init(
        id: UUID = UUID(),
        issuer: String,
        accountName: String,
        secret: String,
        algorithm: String = "SHA1",
        digits: Int = 6,
        period: Int = 30
    ) {
        self.id = id
        self.issuer = issuer
        self.accountName = accountName
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
    }

    var displayIssuer: String {
        let trimmed = issuer.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "账户" : trimmed
    }

    var displayAccount: String {
        accountName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var initial: String {
        let source = displayIssuer.trimmingCharacters(in: .whitespacesAndNewlines)
        return source.isEmpty ? "R" : String(source.prefix(1)).uppercased()
    }
}

struct PinSettings: Codable {
    var accountIDs: [UUID]? = nil
    var left: Double? = nil
    var top: Double? = nil
}
