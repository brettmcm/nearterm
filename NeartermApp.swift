import SwiftUI

@main
struct NeartermApp: App {
    @StateObject private var reminderStore = ReminderStore()

    var body: some Scene {
        MenuBarExtra {
            ReminderPanel(store: reminderStore)
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
                .accessibilityLabel("Nearterm")
        }
        .menuBarExtraStyle(.window)
    }
}
