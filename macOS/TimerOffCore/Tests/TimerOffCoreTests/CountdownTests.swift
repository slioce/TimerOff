import Foundation
import Testing
@testable import TimerOffCore

/// A clock and a ticker the test drives by hand, one second at a time.
@MainActor
final class Harness {
    var now = Date(timeIntervalSince1970: 1_780_000_000)
    var tick: (@MainActor () -> Void)?
    var cancelled = 0
    var ticks: [Int] = []
    var warnings: [Int] = []
    var fires = 0
    private(set) var countdown: Countdown!

    init(warningSeconds: Int = 30) {
        countdown = Countdown(warningSeconds: warningSeconds, now: { [unowned self] in now }, makeTicker: { [unowned self] tick in
            self.tick = tick
            return ManualTicker(harness: self)
        })
        countdown.onTick = { [unowned self] in ticks.append($0) }
        countdown.onWarning = { [unowned self] in warnings.append($0) }
        countdown.onFire = { [unowned self] in fires += 1 }
    }

    func arm(seconds: Int) {
        countdown.arm(target: now.addingTimeInterval(TimeInterval(seconds)))
    }

    func advance(seconds: Int) {
        for _ in 0..<seconds {
            now.addTimeInterval(1)
            tick?()
        }
    }
}

struct ManualTicker: Ticker {
    let harness: Harness
    func cancel() { MainActor.assumeIsolated { harness.cancelled += 1 } }
}

@MainActor
struct CountdownTests {
    @Test func reportsTheFirstTickAtOnceThenEverySecond() {
        let h = Harness()
        h.arm(seconds: 3)
        #expect(h.ticks == [3])
        h.advance(seconds: 2)
        #expect(h.ticks == [3, 2, 1])
        #expect(h.countdown.remaining == 1)
    }

    @Test func warnsOnceWhenTheWarningSecondsAreReached() {
        let h = Harness()
        h.arm(seconds: 35)
        h.advance(seconds: 10)
        #expect(h.warnings == [30])
    }

    @Test func warnsRightAwayWhenArmedInsideTheWarningWindow() {
        let h = Harness()
        h.arm(seconds: 20)
        #expect(h.warnings == [20])
    }

    @Test func firesOnceAtZeroAndStops() {
        let h = Harness()
        h.arm(seconds: 2)
        h.advance(seconds: 5)
        #expect(h.fires == 1)
        #expect(h.ticks == [2, 1, 0])
        #expect(h.cancelled == 1)
        #expect(!h.countdown.isArmed)
        #expect(h.countdown.remaining == 0)
    }

    @Test func cancelStopsEverything() {
        let h = Harness()
        h.arm(seconds: 40)
        h.advance(seconds: 2)
        h.countdown.cancel()
        h.advance(seconds: 50)
        #expect(h.ticks == [40, 39, 38])
        #expect(h.warnings.isEmpty)
        #expect(h.fires == 0)
        #expect(h.countdown.target == nil)
    }

    @Test func armingAgainReplacesTheCountdown() {
        let h = Harness()
        h.arm(seconds: 35)
        h.advance(seconds: 10)
        h.arm(seconds: 35)
        h.advance(seconds: 10)
        #expect(h.warnings == [30, 30])
        #expect(h.cancelled == 1)
    }
}
