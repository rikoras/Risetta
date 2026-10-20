import Foundation

enum PinSettingsStore {
    static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support", isDirectory: true)
        return base
            .appendingPathComponent("Risetta", isDirectory: true)
            .appendingPathComponent("settings.json")
    }

    static func load() -> PinSettings {
        guard let data = try? Data(contentsOf: fileURL),
              let settings = try? JSONDecoder().decode(PinSettings.self, from: data)
        else {
            return PinSettings()
        }
        return settings
    }

    static func save(_ settings: PinSettings) {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(settings)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Pin settings are a convenience; a failed write should not block the app.
        }
    }
}
