import SwiftUI
import WidgetKit

struct NeartermEntry: TimelineEntry {
    let date: Date
    let snapshot: ReminderSnapshot?
}

struct NeartermProvider: TimelineProvider {
    private let store = AppGroupSnapshotStore()

    func placeholder(in context: Context) -> NeartermEntry {
        NeartermEntry(date: Date(), snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (NeartermEntry) -> Void) {
        completion(NeartermEntry(date: Date(), snapshot: context.isPreview ? .preview : store.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NeartermEntry>) -> Void) {
        let now = Date()
        let nextMidnight = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now))!
        completion(Timeline(entries: [NeartermEntry(date: now, snapshot: store.load())], policy: .after(nextMidnight)))
    }
}

struct NeartermWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NeartermEntry

    var body: some View {
        Group {
            if family == .systemSmall { countsView }
            else { todayList }
        }
        .containerBackground(for: .widget) { Color(uiColor: .systemBackground) }
    }

    private var countsView: some View {
        let reminders = entry.snapshot?.reminders ?? []
        let filter = ReminderFilter()
        return VStack(alignment: .leading, spacing: 12) {
            Text("Nearterm").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Link(destination: ReminderRoute(section: .today).url) {
                metric(value: filter.today(reminders, now: entry.date).count, label: "Today")
            }
            Link(destination: ReminderRoute(section: .upcoming).url) {
                metric(value: filter.upcoming(reminders, now: entry.date).count, label: "Next 7")
            }
            Spacer(minLength: 0)
        }
    }

    private func metric(value: Int, label: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(value, format: .number).font(.title2.bold()).foregroundStyle(.primary)
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }

    private var todayList: some View {
        let items = ReminderFilter().today(entry.snapshot?.reminders ?? [], now: entry.date)
        let visible = Array(items.prefix(5))
        return VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Today").font(.headline)
                Spacer()
                Text(items.count, format: .number).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            if visible.isEmpty {
                Spacer()
                Label(entry.snapshot == nil ? "Open Nearterm to sync" : "Nothing due today", systemImage: "checkmark.circle")
                    .font(.subheadline).foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(visible) { item in
                    Link(destination: ReminderRoute(section: .today, reminderID: item.id).url) {
                        HStack(spacing: 7) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.caption).foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.title).font(.caption.weight(.medium)).lineLimit(1).strikethrough(item.isCompleted)
                                Text(item.listName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                if items.count > visible.count {
                    Link("+\(items.count - visible.count) more", destination: ReminderRoute(section: .today).url)
                        .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct NeartermWidget: Widget {
    let kind = "NeartermWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NeartermProvider()) { entry in
            NeartermWidgetView(entry: entry)
        }
        .configurationDisplayName("Nearterm")
        .description("See what is due today and over the next week.")
        .supportedFamilies([.systemSmall, .systemLarge])
    }
}

@main
struct NeartermWidgetBundle: WidgetBundle {
    var body: some Widget { NeartermWidget() }
}

private extension ReminderSnapshot {
    static var preview: ReminderSnapshot {
        let now = Date()
        return ReminderSnapshot(updatedAt: now, reminders: [
            ReminderItem(id: "1", title: "Send project update", listName: "Work", listColor: nil, dueDate: now, isCompleted: false, completionDate: nil, recurrence: nil, eventIdentifier: "1", externalIdentifier: "1"),
            ReminderItem(id: "2", title: "Pick up groceries", listName: "Personal", listColor: nil, dueDate: now, isCompleted: false, completionDate: nil, recurrence: nil, eventIdentifier: "2", externalIdentifier: "2")
        ])
    }
}

struct NeartermWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NeartermWidgetView(entry: NeartermEntry(date: .now, snapshot: .preview))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            NeartermWidgetView(entry: NeartermEntry(date: .now, snapshot: .preview))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
