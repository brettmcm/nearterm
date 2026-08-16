import XCTest
@testable import NeartermIOS

final class ReminderFilterTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    func testTodayIncludesOverdueAndCompletedToday() throws {
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 9, hour: 12)))
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: now))
        let items = [item("overdue", due: yesterday), item("complete", due: now, completed: now)]
        XCTAssertEqual(ReminderFilter(calendar: calendar).today(items, now: now).map(\.id), ["overdue", "complete"])
    }

    func testUpcomingStartsTomorrowAndEndsBeforeDayEight() throws {
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 9, hour: 12)))
        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)))
        let dayEight = try XCTUnwrap(calendar.date(byAdding: .day, value: 8, to: calendar.startOfDay(for: now)))
        let result = ReminderFilter(calendar: calendar).upcoming([item("tomorrow", due: tomorrow), item("day8", due: dayEight)], now: now)
        XCTAssertEqual(result.map(\.id), ["tomorrow"])
    }

    func testRecurringRemindersInHabitsListAreCategorizedByDueDate() throws {
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 9, hour: 12)))
        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: now))
        let dueToday = item("today", listName: "Habits", due: now, recurrence: .daily)
        let dueTomorrow = item("tomorrow", listName: "habits", due: tomorrow, recurrence: .daily)
        let filter = ReminderFilter(calendar: calendar)

        XCTAssertEqual(filter.today([dueToday], now: now).map(\.id), ["today"])
        XCTAssertEqual(filter.upcoming([dueTomorrow], now: now).map(\.id), ["tomorrow"])
    }

    func testNonRecurringReminderInHabitsListStillUsesDueDate() throws {
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 9, hour: 12)))
        let nonRecurring = item("once", listName: "Habits", due: now)
        let filter = ReminderFilter(calendar: calendar)

        XCTAssertEqual(filter.today([nonRecurring], now: now).map(\.id), ["once"])
    }

    func testSnapshotRoundTrip() throws {
        let snapshot = ReminderSnapshot(updatedAt: Date(timeIntervalSince1970: 1), reminders: [item("one", due: nil)])
        let data = try JSONEncoder().encode(snapshot)
        XCTAssertEqual(try JSONDecoder().decode(ReminderSnapshot.self, from: data), snapshot)
    }

    private func item(
        _ id: String,
        title: String? = nil,
        listName: String = "Test",
        due: Date?,
        completed: Date? = nil,
        recurrence: ReminderItem.Recurrence? = nil
    ) -> ReminderItem {
        ReminderItem(id: id, title: title ?? id, listName: listName, listColor: nil, dueDate: due, isCompleted: completed != nil, completionDate: completed, recurrence: recurrence, eventIdentifier: id, externalIdentifier: id)
    }
}
