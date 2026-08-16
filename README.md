# Nearterm

A minimal macOS menu-bar app for Apple Reminders.

Open `Nearterm.xcodeproj` in Xcode, select the **Nearterm** scheme, and run. The first launch asks for Reminders access.

To build, install, and launch the latest macOS version without opening Xcode, run:

```sh
./Scripts/install-nearterm.sh
```

The script installs the app at `~/Applications/Nearterm.app`, where it can be launched from Finder, Spotlight, Launchpad, or the Dock.

- **Today** includes incomplete reminders overdue or due before tomorrow.
- **Next 7** includes incomplete reminders due after today and within the following seven days.
- The app uses one list segmented into **Today** and **Week** sections.
- Recurring reminders are categorized by due date like other reminders.

The circle beside a reminder marks it complete. Refresh reloads EventKit, and the power button quits the helper.

## iOS and widgets

The Xcode project also contains the **Nearterm iOS** app and **Nearterm Widgets** extension for iOS/iPadOS 17+. The small widget shows Today and Next 7 counts; the large widget lists today's reminders. Widget data stays on-device in the shared App Group.

Before distributing, select an Apple Developer team for both iOS targets and supply the final app icon. See `Distribution/AppStoreConnect.md` for the TestFlight checklist.
