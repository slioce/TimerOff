import AppKit
import TimerOffCore

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// There is no main nib, so `NSApplicationMain` would never create the delegate.
    /// `NSApplication.delegate` is weak, so the instance must outlive `run()`.
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }

    private static let presets = [15, 30, 60, 120]

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let countdown = Countdown()
    private let statusLine = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let cancelItem = NSMenuItem(title: String(localized: "Cancel Timer"), action: #selector(cancelTimer), keyEquivalent: "")
    private lazy var customWindow = CustomTimerWindow { [weak self] trigger in self?.arm(trigger) }
    private lazy var warningPanel = WarningPanel { [weak self] in self?.cancelTimer() }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        menu.autoenablesItems = false
        for minutes in Self.presets {
            let item = NSMenuItem(title: Self.presetTitle(minutes: minutes), action: #selector(armPreset(_:)), keyEquivalent: "")
            item.target = self
            item.tag = minutes
            menu.addItem(item)
        }
        let custom = NSMenuItem(title: String(localized: "Custom…"), action: #selector(openCustom), keyEquivalent: "")
        custom.target = self
        cancelItem.target = self
        statusLine.isEnabled = false
        let quit = NSMenuItem(title: String(localized: "Quit TimerOff"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.items += [custom, .separator(), statusLine, cancelItem, .separator(), quit]
        statusItem.menu = menu
        statusItem.button?.imagePosition = .imageLeading

        countdown.onTick = { [weak self] remaining in self?.showRemaining(remaining) }
        countdown.onWarning = { [weak self] remaining in self?.warningPanel.show(remaining: remaining) }
        countdown.onFire = { [weak self] in
            self?.warningPanel.hide()
            self?.showIdle()
            PowerControl.shutDown()
        }
        showIdle()
    }

    // MARK: Arming

    @objc private func armPreset(_ sender: NSMenuItem) {
        arm(.after(minutes: sender.tag))
    }

    @objc private func openCustom() {
        customWindow.show()
    }

    private func arm(_ trigger: Trigger) {
        guard let target = try? trigger.targetDate() else { return }
        Task {
            guard await PowerControl.requestPermission() else { return showPermissionAlert() }
            countdown.arm(target: target)
            statusLine.title = Self.statusTitle(for: target)
            statusLine.isHidden = false
            cancelItem.isHidden = false
        }
    }

    @objc private func cancelTimer() {
        countdown.cancel()
        warningPanel.hide()
        showIdle()
    }

    // MARK: Menu bar

    private func showIdle() {
        statusItem.button?.image = NSImage(systemSymbolName: "power", accessibilityDescription: "TimerOff")
        statusItem.button?.attributedTitle = NSAttributedString()
        statusLine.isHidden = true
        cancelItem.isHidden = true
    }

    private func showRemaining(_ remaining: Int) {
        let urgent = remaining <= countdown.warningSeconds
        statusItem.button?.image = NSImage(systemSymbolName: urgent ? "power.circle.fill" : "power", accessibilityDescription: "TimerOff")
        statusItem.button?.attributedTitle = NSAttributedString(string: " " + formatRemaining(remaining), attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: urgent ? NSColor.systemRed : NSColor.labelColor,
        ])
        if urgent { warningPanel.update(remaining: remaining) }
    }

    private static func presetTitle(minutes: Int) -> String {
        switch minutes {
        case 60: String(localized: "Shut Down in 1 Hour")
        case 120: String(localized: "Shut Down in 2 Hours")
        default: String(localized: "Shut Down in \(minutes) Minutes")
        }
    }

    private static func statusTitle(for target: Date) -> String {
        if Calendar.current.isDateInToday(target) {
            return String(localized: "Shutting down at \(target.formatted(date: .omitted, time: .shortened))")
        }
        return String(localized: "Shutting down tomorrow at \(target.formatted(date: .omitted, time: .shortened))")
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = String(localized: "TimerOff needs permission to shut down the Mac")
        alert.informativeText = String(localized: "Allow TimerOff to control System Events in System Settings › Privacy & Security › Automation, then set the timer again.")
        alert.addButton(withTitle: String(localized: "Open System Settings"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        NSApp.activate()
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }
}
