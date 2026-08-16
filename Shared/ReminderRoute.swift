import Foundation

enum ReminderSection: String, CaseIterable, Identifiable, Codable, Sendable {
    case today
    case upcoming

    var id: Self { self }
    var title: String {
        switch self {
        case .today: "Today"
        case .upcoming: "Week"
        }
    }
}

struct ReminderRoute: Equatable, Sendable {
    static let scheme = "nearterm"
    let section: ReminderSection
    let reminderID: String?

    init(section: ReminderSection, reminderID: String? = nil) {
        self.section = section
        self.reminderID = reminderID
    }

    init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }
        let sectionName = url.host ?? url.pathComponents.dropFirst().first
        guard let sectionName, let section = ReminderSection(rawValue: sectionName) else { return nil }
        self.section = section
        self.reminderID = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "reminder" })?.value
    }

    var url: URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = section.rawValue
        if let reminderID {
            components.queryItems = [URLQueryItem(name: "reminder", value: reminderID)]
        }
        return components.url!
    }
}
