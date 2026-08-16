import Foundation

struct ReminderDayGroup: Identifiable, Sendable {
    let date: Date
    let items: [ReminderItem]

    var id: Date { date }
}

struct ReminderFilter: Sendable {
    var calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func today(_ reminders: [ReminderItem], now: Date = Date()) -> [ReminderItem] {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        return sorted(reminders.filter {
            guard let dueDate = $0.dueDate else { return false }
            return dueDate < tomorrow && shouldInclude($0, now: now)
        })
    }

    func upcoming(_ reminders: [ReminderItem], now: Date = Date()) -> [ReminderItem] {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        let end = calendar.date(byAdding: .day, value: 7, to: tomorrow)!
        return sorted(reminders.filter {
            guard let dueDate = $0.dueDate else { return false }
            return dueDate >= tomorrow && dueDate < end && shouldInclude($0, now: now)
        })
    }

    func groupedByDay(_ reminders: [ReminderItem]) -> [ReminderDayGroup] {
        Dictionary(grouping: reminders) { item in
            calendar.startOfDay(for: item.dueDate!)
        }
        .map { ReminderDayGroup(date: $0.key, items: sorted($0.value)) }
        .sorted { $0.date < $1.date }
    }

    private func shouldInclude(_ item: ReminderItem, now: Date) -> Bool {
        guard item.isCompleted else { return true }
        guard let completionDate = item.completionDate else { return false }
        return completionDate >= calendar.startOfDay(for: now)
    }

    private func sorted(_ reminders: [ReminderItem]) -> [ReminderItem] {
        reminders.sorted {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            switch ($0.dueDate, $1.dueDate) {
            case let (left?, right?): return left < right
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        }
    }
}
