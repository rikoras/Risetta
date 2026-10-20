import AppKit
import Foundation
import SwiftUI

struct EditorState: Identifiable {
    enum Mode {
        case add
        case edit
    }

    let id = UUID()
    var mode: Mode
    var accountID: UUID?
    var issuer: String
    var accountName: String
    var secret: String
    var error: String?
    var revealSecret: Bool

    init(
        mode: Mode,
        accountID: UUID? = nil,
        issuer: String = "",
        accountName: String = "",
        secret: String = "",
        error: String? = nil,
        revealSecret: Bool = false
    ) {
        self.mode = mode
        self.accountID = accountID
        self.issuer = issuer
        self.accountName = accountName
        self.secret = secret
        self.error = error
        self.revealSecret = revealSecret
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var selectedIDs: Set<UUID> = []
    @Published var now = Date()
    @Published var searchText = ""
    @Published var searchVisible = false
    @Published var editor: EditorState?
    @Published var pinSheetVisible = false
    @Published var pendingDelete: Account?
    @Published var toast: String?
    @Published var toastIsError = false
    @Published var loadError: String?

    var onPinRequested: (() -> Void)?
    var onWidgetClosed: (() -> Void)?

    private let store: VaultStore
    private var timer: Timer?
    private var toastWorkItem: DispatchWorkItem?

    init() {
        store = VaultStore()
        let settings = PinSettingsStore.load()

        do {
            accounts = try store.load()
        } catch {
            loadError = error.localizedDescription
        }

        let validIDs = Set(accounts.map(\.id))
        if let savedIDs = settings.accountIDs {
            selectedIDs = Set(savedIDs).intersection(validIDs)
        } else {
            selectedIDs = validIDs
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.now = Date()
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    deinit {
        timer?.invalidate()
        toastWorkItem?.cancel()
    }

    var filteredAccounts: [Account] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return accounts
        }

        return accounts.filter { account in
            account.displayIssuer.localizedCaseInsensitiveContains(query)
                || account.displayAccount.localizedCaseInsensitiveContains(query)
        }
    }

    var selectedAccounts: [Account] {
        accounts.filter { selectedIDs.contains($0.id) }
    }

    func code(for account: Account) -> String {
        Totp.code(for: account, at: now)
    }

    func remainingSeconds(for account: Account) -> Int {
        Totp.remainingSeconds(for: account, at: now)
    }

    func remainingFraction(for account: Account) -> Double {
        Totp.remainingFraction(for: account, at: now)
    }

    func copy(_ account: Account) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(code(for: account), forType: .string)
        showToast("已复制")
    }

    func showToast(_ message: String, error: Bool = false) {
        toastWorkItem?.cancel()
        toast = message
        toastIsError = error

        let workItem = DispatchWorkItem { [weak self] in
            self?.toast = nil
        }
        toastWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + (error ? 3.2 : 2.0), execute: workItem)
    }

    func beginAdd() {
        guard editor == nil, pendingDelete == nil else {
            return
        }
        searchVisible = false
        editor = EditorState(mode: .add)
    }

    func beginEdit(_ account: Account) {
        guard editor == nil, pendingDelete == nil else {
            return
        }
        searchVisible = false
        editor = EditorState(
            mode: .edit,
            accountID: account.id,
            issuer: account.issuer,
            accountName: account.accountName,
            secret: account.secret
        )
    }

    func saveEditor() {
        guard var draft = editor else {
            return
        }

        var issuer = draft.issuer.trimmingCharacters(in: .whitespacesAndNewlines)
        var secret = draft.secret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !secret.isEmpty else {
            draft.error = "请填写密钥。"
            editor = draft
            return
        }

        var algorithm = "SHA1"
        var digits = 6
        var period = 30

        if let existing = draft.accountID.flatMap({ id in accounts.first(where: { $0.id == id }) }) {
            algorithm = existing.algorithm
            digits = existing.digits
            period = existing.period
        }

        var accountName = draft.accountName.trimmingCharacters(in: .whitespacesAndNewlines)

        if let parsed = OtpAuthParser.parse(secret) {
            secret = parsed.secret
            algorithm = parsed.algorithm
            digits = parsed.digits
            period = parsed.period
            if accountName.isEmpty, let parsedAccount = parsed.accountName {
                accountName = parsedAccount
            }
            if let parsedIssuer = parsed.issuer {
                issuer = parsedIssuer
            }
        } else {
            secret = Totp.normalize(secret)
        }

        guard !issuer.isEmpty else {
            draft.error = "请填写名称。"
            editor = draft
            return
        }

        guard Totp.isValid(secret: secret) else {
            draft.error = "密钥格式不正确。"
            editor = draft
            return
        }

        draft.issuer = issuer
        let finalIssuer = issuer

        var nextAccounts = accounts
        if let id = draft.accountID,
           let index = nextAccounts.firstIndex(where: { $0.id == id }) {
            nextAccounts[index] = Account(
                id: id,
                issuer: finalIssuer,
                accountName: accountName,
                secret: secret,
                algorithm: algorithm,
                digits: digits,
                period: period
            )
        } else {
            nextAccounts.append(Account(
                issuer: finalIssuer,
                accountName: accountName,
                secret: secret,
                algorithm: algorithm,
                digits: digits,
                period: period
            ))
        }
        accounts = nextAccounts

        if persist() {
            editor = nil
            refreshSelection()
        } else {
            draft.error = "无法写入账户数据。"
            editor = draft
        }
    }

    func requestDeleteEditing() {
        guard let id = editor?.accountID,
              let account = accounts.first(where: { $0.id == id })
        else {
            return
        }

        editor = nil
        pendingDelete = account
    }

    func delete(_ account: Account) {
        accounts = accounts.filter { $0.id != account.id }
        selectedIDs = selectedIDs.subtracting([account.id])
        pendingDelete = nil
        _ = persist()
    }

    func closeTopOverlay() {
        if editor != nil {
            editor = nil
        } else if pendingDelete != nil {
            pendingDelete = nil
        } else if pinSheetVisible {
            pinSheetVisible = false
        } else if searchVisible {
            searchVisible = false
        }
    }

    func setSelected(_ id: UUID, selected: Bool) {
        var next = selectedIDs
        if selected {
            next.insert(id)
        } else {
            next.remove(id)
        }
        selectedIDs = next
    }

    func confirmPin() {
        guard !selectedIDs.isEmpty else {
            return
        }

        var settings = PinSettingsStore.load()
        settings.accountIDs = Array(selectedIDs)
        PinSettingsStore.save(settings)

        pinSheetVisible = false
        onPinRequested?()
    }

    func updateWidgetPosition(left: Double, top: Double) {
        var settings = PinSettingsStore.load()
        settings.left = left
        settings.top = top
        PinSettingsStore.save(settings)
    }

    func closePinWidget() {
        onWidgetClosed?()
    }

    private func refreshSelection() {
        let validIDs = Set(accounts.map(\.id))
        selectedIDs = selectedIDs.intersection(validIDs)
    }

    private func persist() -> Bool {
        do {
            try store.save(accounts)
            return true
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "无法保存账户数据"
            alert.informativeText = "数据目录：\(store.fileURL.deletingLastPathComponent().path)\n原因：\(error.localizedDescription)"
            alert.addButton(withTitle: "好")
            alert.runModal()
            return false
        }
    }
}
