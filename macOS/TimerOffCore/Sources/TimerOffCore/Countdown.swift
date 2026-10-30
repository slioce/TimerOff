import Foundation

/// Something that calls back once a second until cancelled.
public protocol Ticker {
    func cancel()
}

/// Makes a ticker that runs `tick` once a second on the main actor.
public typealias TickerFactory = @MainActor (_ tick: @escaping @MainActor () -> Void) -> Ticker

/// Counts down to a target date, reporting the seconds left, a single warning and the moment it fires.
@MainActor
public final class Countdown {
    public let warningSeconds: Int
    public var onTick: ((Int) -> Void)?
    public var onWarning: ((Int) -> Void)?
    public var onFire: (() -> Void)?
    public private(set) var target: Date?

    private let now: () -> Date
    private let makeTicker: TickerFactory
    private var ticker: Ticker?
    private var warned = false

    public init(warningSeconds: Int = 30, now: @escaping () -> Date = Date.init, makeTicker: @escaping TickerFactory = Countdown.timerTicker) {
        self.warningSeconds = warningSeconds
        self.now = now
        self.makeTicker = makeTicker
    }

    public var isArmed: Bool { ticker != nil }

    /// Whole seconds left, never negative; zero when idle.
    public var remaining: Int {
        guard let target else { return 0 }
        return max(0, Int((target.timeIntervalSince(now())).rounded()))
    }

    /// Starts counting down to `target`, replacing any countdown in progress. Reports the first tick right away.
    public func arm(target: Date) {
        cancel()
        self.target = target
        warned = false
        ticker = makeTicker { [weak self] in self?.tick() }
        tick()
    }

    /// Stops the countdown; nothing is reported after this.
    public func cancel() {
        ticker?.cancel()
        ticker = nil
        target = nil
    }

    private func tick() {
        guard isArmed else { return }
        let remaining = remaining
        onTick?(remaining)
        if remaining == 0 {
            cancel()
            onFire?()
        } else if !warned && remaining <= warningSeconds {
            warned = true
            onWarning?(remaining)
        }
    }

    /// The default ticker, a one-second repeating `Timer` on the main run loop.
    public static func timerTicker(_ tick: @escaping @MainActor () -> Void) -> Ticker {
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            MainActor.assumeIsolated { tick() }
        }
        timer.tolerance = 0.1
        return TimerTicker(timer: timer)
    }
}

private struct TimerTicker: Ticker {
    let timer: Timer
    func cancel() { timer.invalidate() }
}
