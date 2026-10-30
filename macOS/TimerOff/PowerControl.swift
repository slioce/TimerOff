import AppKit
import ApplicationServices

/// The one place that touches the system: asks System Events to shut the Mac down.
enum PowerControl {
    /// With `TIMEROFF_DRYRUN=1` in the environment the shutdown is logged instead of run, so the whole flow can be tried safely.
    static let isDryRun = ProcessInfo.processInfo.environment["TIMEROFF_DRYRUN"] == "1"

    private static let systemEvents = "com.apple.systemevents"
    private static let notRunning = OSStatus(procNotFound)

    /// Makes sure the app may automate System Events, prompting the user if macOS has not asked yet.
    /// Called when the timer is armed, so the question never comes at the moment of the shutdown.
    static func requestPermission() async -> Bool {
        await Task.detached {
            for attempt in 0..<4 {
                let status = permissionStatus()
                if status != notRunning { return status == noErr }
                // System Events is not running yet: launch it and ask again.
                if attempt == 0 { await launchSystemEvents() }
                try? await Task.sleep(for: .milliseconds(500))
            }
            return false
        }.value
    }

    static func shutDown() {
        if isDryRun {
            NSLog("TimerOff dry run: would tell System Events to shut down")
            return
        }
        var error: NSDictionary?
        NSAppleScript(source: "tell application \"System Events\" to shut down")?.executeAndReturnError(&error)
        if let error { NSLog("TimerOff: shutdown failed: %@", error) }
    }

    private static func permissionStatus() -> OSStatus {
        guard let target = NSAppleEventDescriptor(bundleIdentifier: systemEvents).aeDesc else { return notRunning }
        return AEDeterminePermissionToAutomateTarget(target, typeWildCard, typeWildCard, true)
    }

    private static func launchSystemEvents() async {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: systemEvents) else { return }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        _ = try? await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
    }
}
