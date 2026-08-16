import SwiftUI
import UIKit

struct IOSReminderPanel: View {
    @ObservedObject var store: ReminderStore
    @State private var highlightedReminderID: String?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                content
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .navigationTitle("Nearterm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarMenu }
        }
        .tint(interactionColor)
        .task { await store.load() }
        .onOpenURL(perform: handleURL)
    }

    @ToolbarContentBuilder
    private var toolbarMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button { Task { await store.load() } } label: {
                    Label("Refresh Reminders", systemImage: "arrow.clockwise")
                }
                .disabled(store.state == .loading)
                Button { openRemindersApp() } label: {
                    Label("Open Reminders", systemImage: "arrow.up.forward.app")
                }
            } label: {
                Image(systemName: "ellipsis").frame(width: 32, height: 32)
            }
            .accessibilityLabel("More options")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .idle, .loading:
            statusView("Loading reminders…", symbol: "clock") { ProgressView() }
        case .denied:
            statusView("Reminders access is off", symbol: "lock") {
                Button("Open Settings") { openSettings() }.buttonStyle(.borderedProminent)
            }
        case let .failed(message):
            statusView(message, symbol: "exclamationmark.triangle") {
                Button("Try Again") { Task { await store.load() } }.buttonStyle(.borderedProminent)
            }
        case .ready:
            reminderList
        }
    }

    private var reminderList: some View {
        let today = store.todayItems
        let week = store.nextWeekDayGroups

        return Group {
            if today.isEmpty && week.isEmpty {
                statusView("Nothing due today or this week", symbol: "checkmark.circle") { EmptyView() }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 18) {
                            todayCard(today)
                            weekSections(week)
                        }
                    }
                    .refreshable { await store.load() }
                    .scrollIndicators(.hidden)
                    .onChange(of: highlightedReminderID) { _, identifier in
                        guard let identifier else { return }
                        withAnimation { proxy.scrollTo(identifier, anchor: .center) }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func todayCard(_ items: [ReminderItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items) { item in
                    reminderRow(item)
                }
            }
            .padding(4)
            .background(subtleSurfaceColor)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
    }

    @ViewBuilder
    private func weekSections(_ groups: [ReminderDayGroup]) -> some View {
        ForEach(groups) { group in
            VStack(alignment: .leading, spacing: 4) {
                Text(group.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.custom("DepartureMono-Regular", fixedSize: 10))
                    .foregroundStyle(mutedColor)
                    .textCase(.uppercase)
                    .padding(.horizontal, 8)

                ForEach(group.items) { item in
                    reminderRow(item)
                }
            }
        }
    }

    private func reminderRow(_ item: ReminderItem) -> some View {
        IOSReminderRow(item: item, isHighlighted: item.id == highlightedReminderID) {
            Task { await store.toggleCompletion(item) }
        } reschedule: { date in
            Task { await store.reschedule(item, to: date) }
        } openInReminders: { openInReminders(item) }
        .id(item.id)
    }

    private func statusView<Action: View>(_ message: String, symbol: String, @ViewBuilder action: () -> Action) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.title3).foregroundStyle(.secondary)
            Text(message).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
            action()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
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
            UIApplication.shared.open(url) { success in if !success { openRemindersApp() } }
        } else { openRemindersApp() }
    }

    private var interactionColor: Color { colorScheme == .dark ? .white : .black }
    private var mutedColor: Color { colorScheme == .dark ? Color(red: 0.57, green: 0.60, blue: 0.64) : Color(red: 0.38, green: 0.40, blue: 0.47) }
    private var subtleSurfaceColor: Color { colorScheme == .dark ? Color(red: 0.035, green: 0.043, blue: 0.055) : Color(red: 0.969, green: 0.973, blue: 0.980) }
}

private struct IOSReminderRow: View {
    let item: ReminderItem
    let isHighlighted: Bool
    let complete: () -> Void
    let reschedule: (Date?) -> Void
    let openInReminders: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: complete) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(item.isCompleted ? interactionColor : tertiaryColor)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(item.isCompleted ? "Restore" : "Complete") \(item.title)")

            Text(item.title)
                .font(.body.weight(.medium))
                .foregroundStyle(inkColor)
                .strikethrough(item.isCompleted)
                .opacity(item.isCompleted ? 0.56 : 1)
                .lineLimit(2)
            .padding(.vertical, 7)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(isHighlighted ? subtleSurfaceColor : .clear))
        .contextMenu {
            Button("Today") { reschedule(startOfDay(offset: 0)) }
            Button("Tomorrow") { reschedule(startOfDay(offset: 1)) }
            Button("One Week") { reschedule(startOfDay(offset: 7)) }
            Button("Remove Date") { reschedule(nil) }
            Divider()
            Button(action: openInReminders) { Label("Open in Reminders", systemImage: "arrow.up.forward.app") }
        }
    }

    private func startOfDay(offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: Date()))!
    }
    private var interactionColor: Color { colorScheme == .dark ? .white : .black }
    private var inkColor: Color { colorScheme == .dark ? Color(red: 0.82, green: 0.84, blue: 0.86) : Color(red: 0.19, green: 0.20, blue: 0.23) }
    private var mutedColor: Color { colorScheme == .dark ? Color(red: 0.57, green: 0.60, blue: 0.64) : Color(red: 0.38, green: 0.40, blue: 0.47) }
    private var tertiaryColor: Color { colorScheme == .dark ? Color(red: 0.38, green: 0.42, blue: 0.47) : Color(red: 0.57, green: 0.60, blue: 0.64) }
    private var subtleSurfaceColor: Color { colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06) }
}
