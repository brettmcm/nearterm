import Foundation

struct ReminderSnapshot: Codable, Equatable, Sendable {
    let updatedAt: Date
    let reminders: [ReminderItem]
}

protocol ReminderSnapshotStoring: Sendable {
    func load() -> ReminderSnapshot?
    func save(_ snapshot: ReminderSnapshot) throws
}

struct AppGroupSnapshotStore: ReminderSnapshotStoring {
    static let suiteName = "group.com.brettmcm.nearterm.shared"
    private let key = "reminder-snapshot-v1"

    func load() -> ReminderSnapshot? {
        guard let data = UserDefaults(suiteName: Self.suiteName)?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ReminderSnapshot.self, from: data)
    }

    func save(_ snapshot: ReminderSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        UserDefaults(suiteName: Self.suiteName)?.set(data, forKey: key)
    }
}

final class MemorySnapshotStore: ReminderSnapshotStoring, @unchecked Sendable {
    private var snapshot: ReminderSnapshot?
    init(snapshot: ReminderSnapshot? = nil) { self.snapshot = snapshot }
    func load() -> ReminderSnapshot? { snapshot }
    func save(_ snapshot: ReminderSnapshot) throws { self.snapshot = snapshot }
}
