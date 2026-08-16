import Foundation

struct ReminderItem: Identifiable, Hashable, Codable, Sendable {
    enum Recurrence: String, Codable, Sendable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case other = "Other"
    }

    struct ListColor: Hashable, Codable, Sendable {
        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double
    }

    let id: String
    let title: String
    let listName: String
    let listColor: ListColor?
    let dueDate: Date?
    let isCompleted: Bool
    let completionDate: Date?
    let recurrence: Recurrence?
    let eventIdentifier: String
    let externalIdentifier: String

    func isOverdue(now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard !isCompleted, let dueDate else { return false }
        return dueDate < calendar.startOfDay(for: now)
    }

    func dueLabel(now: Date = Date(), calendar: Calendar = .current) -> String? {
        guard let dueDate else { return nil }
        if isOverdue(now: now, calendar: calendar) {
            return "Overdue · \(dueDate.formatted(.dateTime.month(.abbreviated).day()))"
        }
        if calendar.isDate(dueDate, inSameDayAs: now) {
            let includesTime = calendar.component(.hour, from: dueDate) != 0
                || calendar.component(.minute, from: dueDate) != 0
            return includesTime ? "Today · \(dueDate.formatted(date: .omitted, time: .shortened))" : "Today"
        }
        return dueDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}
