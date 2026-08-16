import Combine
import EventKit
import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

protocol ReminderRepository: Sendable {
    func requestAccess() async throws -> Bool
    func fetch() async -> [ReminderItem]
    func toggleCompletion(_ item: ReminderItem) async throws -> ReminderItem?
    func reschedule(_ item: ReminderItem, to date: Date?) async throws -> ReminderItem?
}

struct CalendarEventItem: Identifiable, Sendable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let hasVideoCall: Bool
}

protocol CalendarEventRepository: Sendable {
    func requestAccess() async throws -> Bool
    func fetchToday(now: Date) async -> [CalendarEventItem]
}

final class EventKitCalendarRepository: CalendarEventRepository, @unchecked Sendable {
    private let eventStore = EKEventStore()

    func requestAccess() async throws -> Bool {
        try await eventStore.requestFullAccessToEvents()
    }

    func fetchToday(now: Date) async -> [CalendarEventItem] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate)
            .filter { !$0.isAllDay && $0.endDate > now }
            .sorted { $0.startDate < $1.startDate }
            .map {
                CalendarEventItem(
                    id: $0.eventIdentifier,
                    title: $0.title,
                    startDate: $0.startDate,
                    endDate: $0.endDate,
                    hasVideoCall: $0.hasAttendees || $0.url != nil
                )
            }
    }
}

final class EventKitReminderRepository: ReminderRepository, @unchecked Sendable {
    private let eventStore = EKEventStore()

    func requestAccess() async throws -> Bool {
        try await eventStore.requestFullAccessToReminders()
    }

    func fetch() async -> [ReminderItem] {
        let predicate = eventStore.predicateForReminders(in: nil)
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: (reminders ?? []).map(Self.makeItem))
            }
        }
    }

    func toggleCompletion(_ item: ReminderItem) async throws -> ReminderItem? {
        guard let reminder = eventStore.calendarItem(withIdentifier: item.eventIdentifier) as? EKReminder else { return nil }
        reminder.isCompleted.toggle()
        try eventStore.save(reminder, commit: true)
        return Self.makeItem(reminder)
    }

    func reschedule(_ item: ReminderItem, to date: Date?) async throws -> ReminderItem? {
        guard let reminder = eventStore.calendarItem(withIdentifier: item.eventIdentifier) as? EKReminder else { return nil }
        reminder.dueDateComponents = date.map { newDate in
            var components = Calendar.current.dateComponents([.calendar, .timeZone, .year, .month, .day], from: newDate)
            if let existing = reminder.dueDateComponents {
                components.hour = existing.hour
                components.minute = existing.minute
                components.second = existing.second
            }
            return components
        }
        try eventStore.save(reminder, commit: true)
        return Self.makeItem(reminder)
    }

    private static func makeItem(_ reminder: EKReminder) -> ReminderItem {
        let cgColor = reminder.calendar.cgColor
        let color = cgColor.flatMap { color -> ReminderItem.ListColor? in
            guard let components = color.components else { return nil }
            if components.count == 2 {
                return .init(red: components[0], green: components[0], blue: components[0], alpha: components[1])
            }
            guard components.count >= 3 else { return nil }
            return .init(red: components[0], green: components[1], blue: components[2], alpha: components.count > 3 ? components[3] : 1)
        }
        return ReminderItem(
            id: reminder.calendarItemIdentifier,
            title: reminder.title,
            listName: reminder.calendar.title,
            listColor: color,
            dueDate: reminder.dueDateComponents.flatMap { Calendar.current.date(from: $0) },
            isCompleted: reminder.isCompleted,
            completionDate: reminder.completionDate,
            recurrence: recurrence(for: reminder),
            eventIdentifier: reminder.calendarItemIdentifier,
            externalIdentifier: reminder.calendarItemExternalIdentifier
        )
    }

    private static func recurrence(for reminder: EKReminder) -> ReminderItem.Recurrence? {
        guard let rule = reminder.recurrenceRules?.first else { return nil }
        switch rule.frequency {
        case .daily: return ReminderItem.Recurrence.daily
        case .weekly: return ReminderItem.Recurrence.weekly
        case .monthly: return ReminderItem.Recurrence.monthly
        default: return ReminderItem.Recurrence.other
        }
    }
}

@MainActor
final class ReminderStore: ObservableObject {
    enum State: Equatable { case idle, loading, ready, denied, failed(String) }

    @Published private(set) var state: State = .idle
    @Published private(set) var reminders: [ReminderItem] = []
    @Published private(set) var todayEvents: [CalendarEventItem] = []
    @Published private(set) var isDemoMode = false
    private let repository: any ReminderRepository
    private let calendarRepository: any CalendarEventRepository
    private let snapshotStore: any ReminderSnapshotStoring
    private let filter: ReminderFilter

    init(
        repository: any ReminderRepository = EventKitReminderRepository(),
        calendarRepository: any CalendarEventRepository = EventKitCalendarRepository(),
        snapshotStore: any ReminderSnapshotStoring = AppGroupSnapshotStore(),
        filter: ReminderFilter = ReminderFilter()
    ) {
        self.repository = repository
        self.calendarRepository = calendarRepository
        self.snapshotStore = snapshotStore
        self.filter = filter
    }

    var todayItems: [ReminderItem] { filter.today(reminders) }
    var nextWeekItems: [ReminderItem] { filter.upcoming(reminders) }
    var nextWeekDayGroups: [ReminderDayGroup] { filter.groupedByDay(nextWeekItems) }

    func load() async {
        guard !isDemoMode else {
            loadDemoContent()
            return
        }
        // Keep the current brief visible while refreshing. SwiftUI reruns the
        // panel's task whenever the menu-bar window is reopened, and replacing
        // ready content with the loading view causes a visible flash.
        if state != .ready {
            state = .loading
        }
        do {
            guard try await repository.requestAccess() else { state = .denied; return }
            reminders = await repository.fetch()
            if (try? await calendarRepository.requestAccess()) == true {
                todayEvents = await calendarRepository.fetchToday(now: Date())
            } else {
                todayEvents = []
            }
            state = .ready
            persistSnapshot()
        } catch {
            state = .failed(Self.userFacingMessage(for: error))
        }
    }

    func toggleCompletion(_ item: ReminderItem) async {
        if isDemoMode {
            updateDemoItem(item, isCompleted: !item.isCompleted, dueDate: item.dueDate)
            return
        }
        do {
            guard let updated = try await repository.toggleCompletion(item) else { await load(); return }
            update(updated)
        } catch { state = .failed(error.localizedDescription) }
    }

    func reschedule(_ item: ReminderItem, to date: Date?) async {
        if isDemoMode {
            updateDemoItem(item, isCompleted: item.isCompleted, dueDate: date)
            return
        }
        do {
            guard let updated = try await repository.reschedule(item, to: date) else { await load(); return }
            update(updated)
        } catch { state = .failed(error.localizedDescription) }
    }

    private func update(_ item: ReminderItem) {
        if let index = reminders.firstIndex(where: { $0.id == item.id }) { reminders[index] = item }
        else { reminders.append(item) }
        persistSnapshot()
    }

    func setDemoMode(_ enabled: Bool) async {
        isDemoMode = enabled
        if enabled {
            loadDemoContent()
        } else {
            state = .loading
            reminders = []
            todayEvents = []
            await load()
        }
    }

    private func loadDemoContent(now: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        func time(_ hour: Int, _ minute: Int = 0) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? now
        }

        todayEvents = [
            CalendarEventItem(id: "demo-event-1", title: "Team stand-up", startDate: time(9, 30), endDate: time(10), hasVideoCall: true),
            CalendarEventItem(id: "demo-event-2", title: "Project review", startDate: time(13), endDate: time(14), hasVideoCall: true),
            CalendarEventItem(id: "demo-event-3", title: "Focus time", startDate: time(15, 30), endDate: time(17), hasVideoCall: false)
        ]
        reminders = [
            demoReminder(id: 1, title: "Send the weekly update", list: "Work", dueDate: time(9)),
            demoReminder(id: 2, title: "Review project notes", list: "Work", dueDate: time(11, 30)),
            demoReminder(id: 3, title: "Pick up groceries", list: "Personal", dueDate: time(17, 30)),
            demoReminder(id: 4, title: "Book a dentist appointment", list: "Personal", dueDate: time(18)),
            demoReminder(id: 5, title: "Water the plants", list: "Home", dueDate: time(20))
        ]
        state = .ready
    }

    private func demoReminder(id: Int, title: String, list: String, dueDate: Date) -> ReminderItem {
        ReminderItem(
            id: "demo-reminder-\(id)",
            title: title,
            listName: list,
            listColor: nil,
            dueDate: dueDate,
            isCompleted: false,
            completionDate: nil,
            recurrence: nil,
            eventIdentifier: "demo-reminder-\(id)",
            externalIdentifier: "demo-reminder-\(id)"
        )
    }

    private func updateDemoItem(_ item: ReminderItem, isCompleted: Bool, dueDate: Date?) {
        guard let index = reminders.firstIndex(where: { $0.id == item.id }) else { return }
        reminders[index] = ReminderItem(
            id: item.id,
            title: item.title,
            listName: item.listName,
            listColor: item.listColor,
            dueDate: dueDate,
            isCompleted: isCompleted,
            completionDate: isCompleted ? Date() : nil,
            recurrence: item.recurrence,
            eventIdentifier: item.eventIdentifier,
            externalIdentifier: item.externalIdentifier
        )
    }

    private func persistSnapshot() {
        try? snapshotStore.save(ReminderSnapshot(updatedAt: Date(), reminders: reminders))
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    private static func userFacingMessage(for error: any Error) -> String {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain && nsError.code == 4099 {
            return "Nearterm couldn’t connect to the macOS Reminders service. Quit and reopen Nearterm, then try again."
        }
        return error.localizedDescription
    }
}
