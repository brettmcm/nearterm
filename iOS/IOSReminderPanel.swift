import SwiftUI
import UIKit

struct IOSReminderPanel: View {
    @ObservedObject var store: ReminderStore
    @State private var highlightedReminderID: String?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                content
                    .padding(32)
                    .frame(maxWidth: 560, alignment: .topLeading)
                    .frame(maxWidth: .infinity, alignment: .top)
            }
            .refreshable { await store.load() }
            .scrollIndicators(.hidden)
            .background(backgroundColor)
            .onChange(of: highlightedReminderID) { _, identifier in
                guard let identifier else { return }
                withAnimation { proxy.scrollTo(identifier, anchor: .center) }
            }
        }
        .tint(primaryColor)
        .task { await store.load() }
        .onOpenURL(perform: handleURL)
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
                Button("Open Settings") { openSettings() }
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
            .lineLimit(1)
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
                .disabled(store.state == .loading)
                Button { openRemindersApp() } label: {
                    Label("Open Reminders", systemImage: "arrow.up.forward.app")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(secondaryColor)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("More options")
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
        IOSReminderRow(item: item, isHighlighted: item.id == highlightedReminderID) {
            Task { await store.toggleCompletion(item) }
        } reschedule: { date in
            Task { await store.reschedule(item, to: date) }
        } openInReminders: {
            openInReminders(item)
        }
        .id(item.id)
    }

    private func countLabel(_ count: Int, singular: String) -> String {
        "\(count) \(count == 1 ? singular : singular + "s")"
    }

    private func handleURL(_ url: URL) {
        guard let route = ReminderRoute(url: url) else { return }
        highlightedReminderID = route.reminderID
    }

    private func openSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }

    private func openRemindersApp() {
        if let url = URL(string: "x-apple-reminder://") { UIApplication.shared.open(url) }
    }

    private func openInReminders(_ item: ReminderItem) {
        let identifier = item.externalIdentifier
            .replacingOccurrences(of: "x-apple-reminder://", with: "")
            .split(separator: "/").last.map(String.init) ?? item.externalIdentifier
        if let encoded = identifier.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
           let url = URL(string: "x-apple-reminderkit://REMCDReminder/\(encoded)/details") {
            UIApplication.shared.open(url) { success in
                if !success { openRemindersApp() }
            }
        } else {
            openRemindersApp()
        }
    }

    private func statusView<Action: View>(
        _ message: String,
        symbol: String,
        @ViewBuilder action: () -> Action
    ) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .foregroundStyle(secondaryColor)
            Text(message)
                .font(interRegular)
                .foregroundStyle(secondaryColor)
                .multilineTextAlignment(.center)
            action()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var interRegular: Font { .custom("Inter-Regular", fixedSize: 13) }
    private var interSemiBold: Font { .custom("Inter-SemiBold", fixedSize: 13) }
    private var backgroundColor: Color { colorScheme == .dark ? .black : .white }
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
                Rectangle()
                    .fill(Color(red: 0.63, green: 0.63, blue: 0.63).opacity(0.15))
                    .frame(width: 2)
            }
    }
}

private struct IOSReminderRow: View {
    let item: ReminderItem
    let isHighlighted: Bool
    let complete: () -> Void
    let reschedule: (Date?) -> Void
    let openInReminders: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Button(action: complete) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15))
                    .foregroundStyle(rowColor)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(item.isCompleted ? "Restore" : "Complete") \(item.title)")
            Text(item.title)
                .font(.custom("Inter-Regular", fixedSize: 13))
                .foregroundStyle(rowColor)
                .strikethrough(item.isCompleted)
                .opacity(item.isCompleted ? 0.56 : 1)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .timelineStyle()
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHighlighted ? highlightColor : .clear)
        )
        .contextMenu {
            Menu("Reschedule") {
                Button("Today") { reschedule(startOfDay(offset: 0)) }
                Button("Tomorrow") { reschedule(startOfDay(offset: 1)) }
                Button("One week") { reschedule(startOfDay(offset: 7)) }
                Divider()
                Button("Remove date") { reschedule(nil) }
            }
            Button(action: openInReminders) {
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

    private var rowColor: Color { colorScheme == .dark ? Color(red: 0.43, green: 0.43, blue: 0.43) : Color(red: 0.11, green: 0.11, blue: 0.11) }
    private var highlightColor: Color { colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06) }
}
