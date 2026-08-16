import SwiftUI

@main
struct NeartermIOSApp: App {
    @StateObject private var store = ReminderStore()

    var body: some Scene {
        WindowGroup {
            IOSReminderPanel(store: store)
        }
    }
}
