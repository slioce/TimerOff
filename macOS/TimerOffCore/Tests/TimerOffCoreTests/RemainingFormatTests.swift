import Testing
@testable import TimerOffCore

struct RemainingFormatTests {
    @Test func underAnHourShowsMinutesAndSeconds() {
        #expect(formatRemaining(0) == "00:00")
        #expect(formatRemaining(7) == "00:07")
        #expect(formatRemaining(3599) == "59:59")
    }

    @Test func fromAnHourOnShowsHours() {
        #expect(formatRemaining(3600) == "1:00:00")
        #expect(formatRemaining(7384) == "2:03:04")
    }

    @Test func negativeIsZero() {
        #expect(formatRemaining(-3) == "00:00")
    }
}
