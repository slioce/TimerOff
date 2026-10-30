import AppKit

/// Floating panel for the last seconds: the countdown in red and a Cancel button, above every window and Space.
@MainActor
final class WarningPanel {
    private let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
    private let title = NSTextField(labelWithString: "")
    private let column = NSStackView()
    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        let icon = NSImageView(image: NSImage(systemSymbolName: "power", accessibilityDescription: nil)!)
        icon.symbolConfiguration = .init(pointSize: 30, weight: .semibold)
        icon.contentTintColor = .systemRed
        title.font = .monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
        title.alignment = .center
        let detail = NSTextField(labelWithString: String(localized: "Save your work, or cancel the timer."))
        detail.font = .systemFont(ofSize: 12)
        detail.textColor = .secondaryLabelColor
        let cancel = NSButton(title: String(localized: "Cancel Shutdown"), target: self, action: #selector(cancelPressed))
        cancel.bezelStyle = .push
        cancel.controlSize = .large
        cancel.keyEquivalent = "\r"

        column.setViews([icon, title, detail, cancel], in: .center)
        column.orientation = .vertical
        column.alignment = .centerX
        column.spacing = 8
        column.setCustomSpacing(18, after: detail)
        column.edgeInsets = NSEdgeInsets(top: 22, left: 36, bottom: 24, right: 36)
        panel.contentView = Self.background(around: column)
    }

    func show(remaining: Int) {
        update(remaining: remaining)
        guard let screen = Self.screenUnderMouse() else { return }
        let size = column.fittingSize
        let visible = screen.visibleFrame
        panel.setFrame(NSRect(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2, width: size.width, height: size.height), display: true)
        panel.invalidateShadow()
        panel.orderFrontRegardless()
        NSSound.beep()
    }

    func update(remaining: Int) {
        title.stringValue = String(localized: "Shutting down in \(remaining) s")
    }

    func hide() {
        panel.orderOut(nil)
    }

    @objc private func cancelPressed() {
        onCancel()
    }

    /// Liquid Glass where available, the classic HUD material otherwise.
    private static func background(around content: NSView) -> NSView {
        if #available(macOS 26, *) {
            let glass = NSGlassEffectView()
            glass.cornerRadius = 18
            content.autoresizingMask = [.width, .height]
            glass.contentView = content
            return glass
        }
        let effect = NSVisualEffectView()
        effect.material = .hudWindow
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 18
        effect.layer?.cornerCurve = .continuous
        effect.layer?.masksToBounds = true
        content.translatesAutoresizingMaskIntoConstraints = false
        effect.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: effect.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: effect.trailingAnchor),
            content.topAnchor.constraint(equalTo: effect.topAnchor),
            content.bottomAnchor.constraint(equalTo: effect.bottomAnchor),
        ])
        return effect
    }

    private static func screenUnderMouse() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
    }
}
