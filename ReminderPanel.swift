import AppKit
import SwiftUI

struct ReminderPanel: View {
    @ObservedObject var store: ReminderStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        panelContent
            .tint(primaryColor)
            .task { await store.load() }
    }

    private var panelContent: some View {
        panelContents
            .background(colorScheme == .dark ? Color.black : Color.white)
    }

    private var panelContents: some View {
        content
            .padding(32)
            .frame(width: 360, alignment: .topLeading)
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .idle, .loading:
            statusView("Loading reminders…", symbol: "clock") {
                ProgressView().controlSize(.small)
            }
        case .denied:
            statusView("Reminders access is off", symbol: "lock") {
                Button("Open Privacy Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders")!)
                }
                .buttonStyle(.borderedProminent)
            }
        case let .failed(message):
            statusView(message, symbol: "exclamationmark.triangle") {
                Button("Try Again") { Task { await store.load() } }
                    .buttonStyle(.borderedProminent)
            }
        case .ready:
            dailyBrief
        }
    }

    private var dailyBrief: some View {
        let tasks = store.todayItems.filter { !$0.isCompleted }
        return VStack(alignment: .leading, spacing: 32) {
            header
            eventSection(store.todayEvents)
            taskSection(tasks)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        HStack(spacing: 24) {
            HStack(spacing: 4) {
                Text(Date.now.formatted(.dateTime.weekday(.wide)))
                    .font(interSemiBold)
                    .foregroundStyle(primaryColor)
                Text(Date.now.formatted(.dateTime.month(.wide).day().year()))
                    .font(interRegular)
                    .foregroundStyle(primaryColor)
            }
            Spacer(minLength: 0)
            Menu {
                Button {
                    Task { await store.setDemoMode(!store.isDemoMode) }
                } label: {
                    Label("Demo mode", systemImage: store.isDemoMode ? "checkmark.circle.fill" : "play.circle")
                }
                Divider()
                Button { Task { await store.load() } } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                Divider()
                Button("Quit Nearterm") { NSApplication.shared.terminate(nil) }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(secondaryColor)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
    }

    private func eventSection(_ events: [CalendarEventItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if events.isEmpty {
                emptySummary(symbol: "cup.and.heat.waves.fill", strong: "no events", suffix: "remaining today")
            } else {
                summary(prefix: "You have", strong: countLabel(events.count, singular: "event"), suffix: "remaining today")
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(events) { event in
                        HStack(spacing: 4) {
                            Image(systemName: event.hasVideoCall ? "video.fill" : "circle.dotted")
                                .frame(width: 20)
                            Text(event.title).font(interRegular)
                            Text("at").font(interRegular)
                            Text(event.startDate.formatted(date: .omitted, time: .shortened)).font(interSemiBold)
                        }
                        .foregroundStyle(contentColor)
                        .lineLimit(1)
                        .timelineStyle()
                    }
                }
            }
        }
    }

    private func taskSection(_ items: [ReminderItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if items.isEmpty {
                emptySummary(symbol: "checkmark.circle.fill", strong: "no tasks", suffix: "today")
            } else {
                summary(prefix: "You have", strong: countLabel(items.count, singular: "task"), suffix: "today")
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items) { item in reminderRow(item) }
                }
            }
        }
    }

    private func summary(prefix: String, strong: String, suffix: String) -> some View {
        HStack(spacing: 4) {
            Text(prefix).font(interRegular).foregroundStyle(tertiaryColor)
            Text(strong).font(interSemiBold).foregroundStyle(primaryColor)
            Text(suffix).font(interRegular).foregroundStyle(tertiaryColor)
        }
    }

    private func emptySummary(symbol: String, strong: String, suffix: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).foregroundStyle(secondaryColor)
            Text("You have").font(interRegular).foregroundStyle(tertiaryColor)
            Text(strong).font(interSemiBold).foregroundStyle(primaryColor)
            Text(suffix).font(interRegular).foregroundStyle(tertiaryColor)
        }
        .font(.system(size: 13))
    }

    private func reminderRow(_ item: ReminderItem) -> some View {
        ReminderRow(item: item) {
            Task { await store.toggleCompletion(item) }
        } reschedule: { date in
            Task { await store.reschedule(item, to: date) }
        } openInReminders: { openInReminders(item) }
    }

    private func countLabel(_ count: Int, singular: String) -> String {
        "\(count) \(count == 1 ? singular : singular + "s")"
    }

    private func openInReminders(_ item: ReminderItem) {
        let identifier = item.externalIdentifier
            .replacingOccurrences(of: "x-apple-reminder://", with: "")
            .split(separator: "/").last.map(String.init) ?? item.externalIdentifier
        if let encoded = identifier.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
           let url = URL(string: "x-apple-reminderkit://REMCDReminder/\(encoded)/details") {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Reminders.app"))
        }
    }

    private func statusView<Action: View>(
        _ message: String,
        symbol: String,
        @ViewBuilder action: () -> Action
    ) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 20)).foregroundStyle(secondaryColor)

            Text(message)
                .font(interRegular).foregroundStyle(secondaryColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            action()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var interRegular: Font { .custom("Inter-Regular", fixedSize: 13) }
    private var interSemiBold: Font { .custom("Inter-SemiBold", fixedSize: 13) }
    private var primaryColor: Color { colorScheme == .dark ? Color(red: 0.86, green: 0.86, blue: 0.86) : Color(red: 0.11, green: 0.11, blue: 0.11) }
    private var secondaryColor: Color { colorScheme == .dark ? Color(red: 0.66, green: 0.66, blue: 0.66) : tertiaryColor }
    private var tertiaryColor: Color { Color(red: 0.43, green: 0.43, blue: 0.43) }
    private var contentColor: Color { colorScheme == .dark ? tertiaryColor : primaryColor }
}

private extension View {
    func timelineStyle() -> some View {
        padding(.vertical, 2)
            .padding(.leading, 12)
            .overlay(alignment: .leading) {
                Rectangle().fill(Color(red: 0.63, green: 0.63, blue: 0.63).opacity(0.15)).frame(width: 2)
            }
    }
}

private struct ReminderRow: View {
    let item: ReminderItem
    let complete: () -> Void
    let reschedule: (Date?) -> Void
    let openInReminders: () -> Void

    @State private var isHovered = false
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Button(action: complete) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13))
                    .foregroundStyle(isHovered ? hoverColor : rowColor)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(item.isCompleted ? "Mark incomplete" : "Mark complete")
            .accessibilityLabel("\(item.isCompleted ? "Restore" : "Complete") \(item.title)")

            Text(item.title)
                .font(.custom("Inter-Regular", fixedSize: 13))
                .foregroundStyle(isHovered ? hoverColor : rowColor)
                .strikethrough(item.isCompleted)
                .opacity(item.isCompleted ? 0.56 : 1)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .timelineStyle()
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .onHover { isHovered = $0 }
        .contextMenu {
            Menu("Reschedule") {
                Button("Today") { reschedule(startOfDay(offset: 0)) }
                Button("Tomorrow") { reschedule(startOfDay(offset: 1)) }
                Button("One week") { reschedule(startOfDay(offset: 7)) }

                Divider()

                Button("Remove date") { reschedule(nil) }
            }

            Button {
                openInReminders()
            } label: {
                Label("Open in Reminders", systemImage: "arrow.up.forward.app")
            }
        }
    }

    private func startOfDay(offset: Int) -> Date {
        Calendar.current.date(
            byAdding: .day,
            value: offset,
            to: Calendar.current.startOfDay(for: Date())
        )!
    }

    private var secondaryColor: Color { Color(red: 0.66, green: 0.66, blue: 0.66) }
    private var tertiaryColor: Color { Color(red: 0.43, green: 0.43, blue: 0.43) }
    private var rowColor: Color { colorScheme == .dark ? tertiaryColor : Color(red: 0.11, green: 0.11, blue: 0.11) }
    private var hoverColor: Color { colorScheme == .dark ? secondaryColor : Color.black }

}
