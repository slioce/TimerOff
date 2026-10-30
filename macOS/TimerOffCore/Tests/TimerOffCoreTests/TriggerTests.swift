import Foundation
import Testing
@testable import TimerOffCore

struct TriggerTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome")!
        return calendar
    }()

    func date(_ hour: Int, _ minute: Int, second: Int = 0, day: Int = 2) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: day, hour: hour, minute: minute, second: second))!
    }

    @Test func minutesAddToNow() throws {
        let now = date(20, 0)
        #expect(try Trigger.after(minutes: 15).targetDate(from: now, calendar: calendar) == now.addingTimeInterval(15 * 60))
        #expect(try Trigger.after(minutes: 90).targetDate(from: now, calendar: calendar) == date(21, 30))
    }

    @Test func zeroOrNegativeMinutesAreRejected() {
        #expect(throws: Trigger.Error.zeroDuration) { try Trigger.after(minutes: 0).targetDate(from: date(20, 0), calendar: calendar) }
        #expect(throws: Trigger.Error.zeroDuration) { try Trigger.after(minutes: -5).targetDate(from: date(20, 0), calendar: calendar) }
    }

    @Test func laterTimeTodayIsToday() throws {
        #expect(try Trigger.at(hour: 23, minute: 0).targetDate(from: date(20, 0), calendar: calendar) == date(23, 0))
    }

    @Test func earlierOrSameTimeIsTomorrow() throws {
        #expect(try Trigger.at(hour: 8, minute: 30).targetDate(from: date(20, 0), calendar: calendar) == date(8, 30, day: 3))
        #expect(try Trigger.at(hour: 20, minute: 0).targetDate(from: date(20, 0), calendar: calendar) == date(20, 0, day: 3))
        #expect(try Trigger.at(hour: 20, minute: 0).targetDate(from: date(20, 0, second: 30), calendar: calendar) == date(20, 0, day: 3))
    }

    @Test func secondsLeftInTheCurrentMinuteCount() throws {
        #expect(try Trigger.at(hour: 20, minute: 1).targetDate(from: date(20, 0, second: 40), calendar: calendar) == date(20, 1))
    }

    @Test func outOfRangeTimesAreRejected() {
        #expect(throws: Trigger.Error.invalidTime) { try Trigger.at(hour: 24, minute: 0).targetDate(from: date(20, 0), calendar: calendar) }
        #expect(throws: Trigger.Error.invalidTime) { try Trigger.at(hour: 9, minute: 60).targetDate(from: date(20, 0), calendar: calendar) }
        #expect(throws: Trigger.Error.invalidTime) { try Trigger.at(hour: -1, minute: 0).targetDate(from: date(20, 0), calendar: calendar) }
    }
}
