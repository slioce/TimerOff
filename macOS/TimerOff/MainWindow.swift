import AppKit
import TimerOffCore

/// The app's window, the same as on Windows: presets, a duration or a time of day, then the countdown in their place.
@MainActor
final class MainWindow: NSObject, NSWindowDelegate {
    static let presets = [15, 30, 60, 120]

    var onStart: ((Trigger) -> Void)?
    var onCancel: (() -> Void)?

    private let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 380, height: 470), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: true)

    // Idle: choose when
    private let idleView = NSStackView()
    private let afterMode = NSButton(radioButtonWithTitle: String(localized: "After"), target: nil, action: nil)
    private let atMode = NSButton(radioButtonWithTitle: String(localized: "At"), target: nil, action: nil)
    private let hours = NumberField(range: 0...23, value: 0)
    private let minutes = NumberField(range: 0...59, value: 30)
    private let time = FocusDatePicker()
    private let errorText = NSTextField(wrappingLabelWithString: "")

    // Armed: the countdown
    private let armedView = NSStackView()
    private let armedLabel = NSTextField(labelWithString: "")
    private let countdownText = NSTextField(labelWithString: "")
    private let warningText = NSTextField(labelWithString: String(localized: "Save your work, or cancel the timer."))

    private var centered = false

    override init() {
        super.init()
        window.title = "TimerOff"
        window.isReleasedWhenClosed = false
        window.delegate = self

        let content = NSView()
        window.contentView = content
        buildIdleView()
        buildArmedView()
        for view in [idleView, armedView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(view)
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
                view.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            ])
        }
        NSLayoutConstraint.activate([
            idleView.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            armedView.centerYAnchor.constraint(equalTo: content.centerYAnchor),
        ])
        showIdle()
    }

    // MARK: Views

    private func buildIdleView() {
        let tagline = NSTextField(wrappingLabelWithString: String(localized: "Shut down this Mac later"))
        tagline.font = .systemFont(ofSize: 20, weight: .semibold)

        let grid = NSStackView()
        grid.orientation = .vertical
        grid.alignment = .leading
        grid.spacing = 12
        for row in stride(from: 0, to: Self.presets.count, by: 2) {
            let buttons = NSStackView(views: Self.presets[row..<min(row + 2, Self.presets.count)].map(presetButton))
            buttons.distribution = .fillEqually
            buttons.spacing = 12
            grid.addArrangedSubview(buttons)
            Self.stretch([buttons], to: grid)
        }

        for mode in [afterMode, atMode] {
            mode.target = self
            mode.action = #selector(modeChanged)
            mode.widthAnchor.constraint(equalToConstant: 70).isActive = true
        }
        afterMode.state = .on
        let durationRow = NSStackView(views: [afterMode, hours, label("h"), minutes, label("min")])
        durationRow.spacing = 6

        time.datePickerStyle = .textFieldAndStepper
        time.datePickerElements = .hourMinute
        time.dateValue = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
        time.target = self
        time.action = #selector(timeChanged)
        time.onFocus = { [weak self] in self?.selectAtMode() }
        let timeRow = NSStackView(views: [atMode, time])
        timeRow.spacing = 6

        errorText.textColor = .systemRed
        errorText.isHidden = true

        let start = NSButton(title: String(localized: "Start"), target: self, action: #selector(start))
        start.keyEquivalent = "\r"
        start.bezelStyle = .flexiblePush
        start.font = .systemFont(ofSize: 15)
        start.heightAnchor.constraint(equalToConstant: 40).isActive = true

        idleView.orientation = .vertical
        idleView.alignment = .leading
        idleView.spacing = 16
        idleView.setViews([tagline, grid, durationRow, timeRow, errorText, start], in: .top)
        idleView.setCustomSpacing(20, after: grid)
        idleView.setCustomSpacing(10, after: durationRow)
        idleView.setCustomSpacing(12, after: timeRow)
        Self.stretch([tagline, grid, errorText, start], to: idleView)
    }

    private func buildArmedView() {
        armedLabel.font = .systemFont(ofSize: 15)
        armedLabel.textColor = .secondaryLabelColor
        armedLabel.alignment = .center

        countdownText.font = .monospacedDigitSystemFont(ofSize: 64, weight: .bold)
        countdownText.alignment = .center

        warningText.font = .systemFont(ofSize: 14)
        warningText.textColor = .systemRed
        warningText.alignment = .center

        let cancel = NSButton(title: String(localized: "Cancel"), target: self, action: #selector(cancel))
        cancel.keyEquivalent = "\u{1b}"
        cancel.bezelStyle = .flexiblePush
        cancel.font = .systemFont(ofSize: 16)
        cancel.heightAnchor.constraint(equalToConstant: 44).isActive = true

        armedView.orientation = .vertical
        armedView.alignment = .centerX
        armedView.spacing = 8
        armedView.setViews([armedLabel, countdownText, warningText, cancel], in: .top)
        armedView.setCustomSpacing(24, after: warningText)
        Self.stretch([cancel], to: armedView)
    }

    /// Makes `views` as wide as the stack, the way a WPF StackPanel stretches its children.
    private static func stretch(_ views: [NSView], to stack: NSStackView) {
        NSLayoutConstraint.activate(views.map { $0.widthAnchor.constraint(equalTo: stack.widthAnchor) })
    }

    private func presetButton(minutes: Int) -> NSButton {
        let button = NSButton(title: Self.presetTitle(minutes: minutes), target: self, action: #selector(preset(_:)))
        button.bezelStyle = .flexiblePush
        button.font = .systemFont(ofSize: 16, weight: .semibold)
        button.tag = minutes
        button.heightAnchor.constraint(equalToConstant: 64).isActive = true
        return button
    }

    private static func presetTitle(minutes: Int) -> String {
        switch minutes {
        case 15: String(localized: "15 minutes")
        case 30: String(localized: "30 minutes")
        case 60: String(localized: "1 hour")
        case 120: String(localized: "2 hours")
        default: "\(minutes) min"
        }
    }

    private func label(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 14)
        return label
    }

    // MARK: Showing

    /// Brings the window to the front, centred the first time.
    func show() {
        if !centered {
            window.center()
            centered = true
        }
        // macOS may refuse to activate an agent app (at launch, and sometimes from the menu bar item), which would leave the
        // window behind the others. Ordering it front regardless keeps it visible; activation, when granted, adds the focus.
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    func showIdle() {
        window.level = .normal
        window.collectionBehavior = []
        countdownText.textColor = .labelColor
        warningText.alphaValue = 0
        errorText.isHidden = true
        armedView.isHidden = true
        idleView.isHidden = false
    }

    func showArmed(target: Date) {
        armedLabel.stringValue = Self.armedTitle(for: target)
        countdownText.textColor = .labelColor
        warningText.alphaValue = 0
        errorText.isHidden = true
        idleView.isHidden = true
        armedView.isHidden = false
    }

    func update(remaining: Int) {
        countdownText.stringValue = formatRemaining(remaining)
    }

    /// The last seconds: the window comes to the front above everything, on every Space, with the countdown in red.
    func showWarning() {
        countdownText.textColor = .systemRed
        warningText.alphaValue = 1
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        show()
        window.orderFrontRegardless()
        NSSound.beep()
    }

    func showError(_ message: String) {
        errorText.stringValue = message
        errorText.isHidden = false
    }

    private static func armedTitle(for target: Date) -> String {
        let time = target.formatted(date: .omitted, time: .shortened)
        if Calendar.current.isDateInToday(target) {
            return String(localized: "Shutting down at \(time)")
        }
        return String(localized: "Shutting down tomorrow at \(time)")
    }

    // MARK: Actions

    @objc private func preset(_ sender: NSButton) {
        errorText.isHidden = true
        onStart?(.after(minutes: sender.tag))
    }

    @objc private func start() {
        window.makeFirstResponder(nil) // commits a number still being typed
        let trigger: Trigger
        if afterMode.state == .on {
            let total = hours.value * 60 + minutes.value
            guard total > 0 else { return showError(String(localized: "Enter a duration of at least one minute.")) }
            trigger = .after(minutes: total)
        } else {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: time.dateValue)
            trigger = .at(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
        }
        errorText.isHidden = true
        onStart?(trigger)
    }

    @objc private func cancel() {
        onCancel?()
    }

    @objc private func modeChanged() {}

    @objc private func timeChanged() {
        selectAtMode()
    }

    private func selectAtMode() {
        atMode.state = .on
        afterMode.state = .off
    }

    /// The close button hides the window; the app keeps running in the menu bar until Quit.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        window.orderOut(nil)
        return false
    }
}

/// A whole number between bounds, typed or stepped.
@MainActor
private final class NumberField: NSStackView {
    private let field = NSTextField()
    private let stepper = NSStepper()

    init(range: ClosedRange<Int>, value: Int) {
        super.init(frame: .zero)
        let formatter = NumberFormatter()
        formatter.minimum = range.lowerBound as NSNumber
        formatter.maximum = range.upperBound as NSNumber
        formatter.allowsFloats = false
        field.formatter = formatter
        field.alignment = .center
        field.integerValue = value
        field.target = self
        field.action = #selector(typed)
        stepper.minValue = Double(range.lowerBound)
        stepper.maxValue = Double(range.upperBound)
        stepper.integerValue = value
        stepper.target = self
        stepper.action = #selector(stepped)
        setViews([field, stepper], in: .center)
        spacing = 2
        field.widthAnchor.constraint(equalToConstant: 52).isActive = true
    }

    required init?(coder: NSCoder) { fatalError() }

    /// What the field shows: a typed number counts as soon as editing ends, Return or not.
    var value: Int { field.integerValue }

    @objc private func typed() { stepper.integerValue = field.integerValue }
    @objc private func stepped() { field.integerValue = stepper.integerValue }
}

/// A date picker that reports when it takes the keyboard focus, so choosing a time selects the "At" mode.
@MainActor
private final class FocusDatePicker: NSDatePicker {
    var onFocus: (() -> Void)?

    override func becomeFirstResponder() -> Bool {
        onFocus?()
        return super.becomeFirstResponder()
    }
}
