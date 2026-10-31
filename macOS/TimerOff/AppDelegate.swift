import AppKit
import TimerOffCore

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    /// There is no main nib, so `NSApplicationMain` would never create the delegate.
    /// `NSApplication.delegate` is weak, so the instance must outlive `run()`.
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let countdown = Countdown()
    private let menu = NSMenu()
    private let cancelItem = NSMenuItem(title: String(localized: "Cancel timer"), action: #selector(cancelTimer), keyEquivalent: "")
    private lazy var mainWindow = MainWindow()
    private var arming = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = Self.hiddenMainMenu()

        // The menu on the status item mirrors the Windows tray menu; it opens on a right click.
        menu.autoenablesItems = false
        menu.delegate = self
        let show = NSMenuItem(title: String(localized: "Show TimerOff"), action: #selector(showWindow), keyEquivalent: "")
        show.target = self
        cancelItem.target = self
        let quit = NSMenuItem(title: String(localized: "Quit TimerOff"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.items = [show, cancelItem, .separator(), quit]

        if let button = statusItem.button {
            button.imagePosition = .imageLeading
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        mainWindow.onStart = { [weak self] trigger in self?.arm(trigger) }
        mainWindow.onCancel = { [weak self] in self?.cancelTimer() }
        countdown.onTick = { [weak self] remaining in self?.showRemaining(remaining) }
        countdown.onWarning = { [weak self] _ in self?.mainWindow.showWarning() }
        countdown.onFire = { [weak self] in
            self?.showIdle()
            PowerControl.shutDown()
        }
        showIdle()
        mainWindow.show()
    }

    // MARK: Arming

    private func arm(_ trigger: Trigger) {
        guard !arming, let target = try? trigger.targetDate() else { return }
        arming = true
        Task {
            defer { arming = false }
            guard await PowerControl.requestPermission() else { return showPermissionAlert() }
            mainWindow.showArmed(target: target)
            countdown.arm(target: target)
            cancelItem.isEnabled = true
        }
    }

    @objc private func cancelTimer() {
        countdown.cancel()
        showIdle()
    }

    // MARK: Menu bar

    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
        } else {
            mainWindow.show()
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil // back to the click action
    }

    @objc private func showWindow() {
        mainWindow.show()
    }

    private func showIdle() {
        statusItem.button?.image = NSImage(systemSymbolName: "power", accessibilityDescription: "TimerOff")
        statusItem.button?.attributedTitle = NSAttributedString()
        statusItem.button?.toolTip = "TimerOff – " + String(localized: "No timer set")
        cancelItem.isEnabled = false
        mainWindow.showIdle()
    }

    private func showRemaining(_ remaining: Int) {
        let urgent = remaining <= countdown.warningSeconds
        let clock = formatRemaining(remaining)
        statusItem.button?.image = NSImage(systemSymbolName: urgent ? "power.circle.fill" : "power", accessibilityDescription: "TimerOff")
        statusItem.button?.attributedTitle = NSAttributedString(string: " " + clock, attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: urgent ? NSColor.systemRed : NSColor.labelColor,
        ])
        statusItem.button?.toolTip = "TimerOff – " + String(localized: "Shutting down in \(clock)")
        mainWindow.update(remaining: remaining)
    }

    /// An agent app shows no menu bar, but a main menu still routes the standard shortcuts in the window.
    private static func hiddenMainMenu() -> NSMenu {
        let main = NSMenu()
        let app = NSMenu()
        app.addItem(withTitle: String(localized: "Quit TimerOff"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        let window = NSMenu(title: "Window")
        window.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        for submenu in [app, edit, window] {
            let item = NSMenuItem()
            item.submenu = submenu
            main.addItem(item)
        }
        return main
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = String(localized: "TimerOff needs permission to shut down the Mac")
        alert.informativeText = String(localized: "Allow TimerOff to control System Events in System Settings › Privacy & Security › Automation, then set the timer again.")
        alert.addButton(withTitle: String(localized: "Open System Settings"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        NSApp.activate(ignoringOtherApps: true) // see MainWindow.show()
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }
}
