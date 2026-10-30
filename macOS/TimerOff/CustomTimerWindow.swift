import AppKit
import TimerOffCore

/// Small window for a timer that is not one of the presets: a duration, or a time of day.
@MainActor
final class CustomTimerWindow: NSObject, NSWindowDelegate {
    private let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: true)
    private let mode = NSSegmentedControl(labels: [String(localized: "After a duration"), String(localized: "At a time")], trackingMode: .selectOne, target: nil, action: nil)
    private let hours = NumberField(range: 0...23, value: 0)
    private let minutes = NumberField(range: 0...59, value: 30)
    private let time = NSDatePicker()
    private let durationRow = NSStackView()
    private let timeRow = NSStackView()
    private let onStart: (Trigger) -> Void

    init(onStart: @escaping (Trigger) -> Void) {
        self.onStart = onStart
        super.init()

        window.title = String(localized: "Custom Timer")
        window.isReleasedWhenClosed = false
        window.delegate = self

        mode.selectedSegment = 0
        mode.target = self
        mode.action = #selector(modeChanged)

        durationRow.setViews([hours, label("h"), minutes, label("min")], in: .center)
        durationRow.spacing = 6
        durationRow.setCustomSpacing(16, after: label("h"))

        time.datePickerStyle = .textFieldAndStepper
        time.datePickerElements = .hourMinute
        timeRow.setViews([label(String(localized: "Shut down at")), time], in: .center)
        timeRow.spacing = 8

        let start = NSButton(title: String(localized: "Start"), target: self, action: #selector(start))
        start.keyEquivalent = "\r"
        let cancel = NSButton(title: String(localized: "Cancel"), target: self, action: #selector(close))
        cancel.keyEquivalent = "\u{1b}"
        let buttons = NSStackView(views: [cancel, start])
        buttons.spacing = 12

        let column = NSStackView(views: [mode, durationRow, timeRow, buttons])
        column.orientation = .vertical
        column.alignment = .centerX
        column.spacing = 16
        column.setCustomSpacing(24, after: timeRow)
        column.edgeInsets = NSEdgeInsets(top: 20, left: 24, bottom: 20, right: 24)
        NSLayoutConstraint.activate([column.widthAnchor.constraint(greaterThanOrEqualToConstant: 300)])
        window.contentView = column
        modeChanged()
    }

    func show() {
        time.dateValue = Date().addingTimeInterval(3600)
        window.setContentSize(window.contentView!.fittingSize)
        window.center()
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private var trigger: Trigger {
        if mode.selectedSegment == 0 {
            return .after(minutes: hours.value * 60 + minutes.value)
        }
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time.dateValue)
        return .at(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
    }

    @objc private func modeChanged() {
        durationRow.isHidden = mode.selectedSegment != 0
        timeRow.isHidden = mode.selectedSegment != 1
    }

    @objc private func start() {
        let trigger = trigger
        if case .after(let total) = trigger, total <= 0 {
            NSSound.beep()
            return
        }
        close()
        onStart(trigger)
    }

    @objc private func close() {
        window.close()
    }

    private func label(_ text: String) -> NSTextField {
        NSTextField(labelWithString: text)
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
        field.alignment = .right
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
        field.widthAnchor.constraint(equalToConstant: 44).isActive = true
    }

    required init?(coder: NSCoder) { fatalError() }

    var value: Int { stepper.integerValue }

    @objc private func typed() { stepper.integerValue = field.integerValue }
    @objc private func stepped() { field.integerValue = stepper.integerValue }
}
