# App Store Connect handoff

## App record

- Name: Nearterm (subject to availability)
- Primary locale: English (U.S.)
- Bundle ID: `com.brettmcm.nearterm.ios`
- macOS Bundle ID: `com.brettmcm.nearterm.ios` (shared with iOS for the single multi-platform app record)
- SKU: `nearterm-ios-1`
- Category: Productivity
- Version: 1.0 (build 1)
- App privacy: Data Not Collected
- Export compliance: No non-exempt encryption
- Login/demo account: None

## External beta copy

**Description:** Nearterm is a quiet, focused view of Apple Reminders. See what is due today and what is coming in the next week in one simple list. Complete or reschedule tasks without losing your place.

**Review notes:** Nearterm requires Full Access to Reminders. To test, create dated reminders in Apple Reminders, then launch Nearterm and grant access. No account or demo credentials are required. Widgets read an on-device snapshot updated by the app and refresh on a best-effort schedule.

## Required from the account owner

- Apple Developer team selection and App Store Connect access
- Final Icon Composer package: `Nearterm.icon` (integrated)
- Feedback email: `brettmcm@me.com`
- Beta-review contact details
- Support and privacy-policy URLs

## Upload checklist

1. Create the App ID, widget App ID, and shared App Group in Certificates, Identifiers & Profiles.
2. Create the App Store Connect app record using the values above.
3. Select the development team for all targets and confirm automatic signing resolves profiles.
4. Increment `CURRENT_PROJECT_VERSION` for every upload.
5. Archive the `Nearterm iOS` scheme for Any iOS Device and run Validate App.
6. Distribute to App Store Connect, wait for processing, complete beta compliance, and attach the build to an external testing group.
7. Submit the build for Beta App Review; do not create a production submission.

The iOS target has **Designed for iPhone/iPad on Mac** disabled. Do not enable it in App Store Connect: that compatibility build uses the iOS `WindowGroup` and appears as a normal window on macOS. Mac testers should receive the native macOS build described below.

## macOS platform

- Add macOS to the existing Nearterm App Store Connect record; do not create a second app record.
- There is no separate bundle-ID association step. Add macOS as a platform on the existing Nearterm app record; both app targets use the record's `com.brettmcm.nearterm.ios` bundle ID.
- Archive and upload the `Nearterm` scheme separately from the iOS build.
- In App Store Connect, add the uploaded build under the app's **macOS** platform and assign that build to the Mac TestFlight group. Confirm the build's supported platform is macOS before inviting testers.
- The Mac target uses App Sandbox with Reminders access and Hardened Runtime.
- Export a conventional macOS AppIcon set from the Nearterm Icon Composer artwork before Mac TestFlight upload; assigning the `.icon` package directly to the macOS 14 target currently fails Xcode asset compilation.
