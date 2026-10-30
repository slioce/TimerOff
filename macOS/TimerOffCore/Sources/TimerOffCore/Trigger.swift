import Foundation

/// When the shutdown should happen: after a number of minutes, or at a time of day.
public enum Trigger: Equatable, Sendable {
    case after(minutes: Int)
    case at(hour: Int, minute: Int)

    public enum Error: Swift.Error, Equatable {
        case zeroDuration
        case invalidTime
    }

    /// The absolute moment this trigger stands for. A time of day that has already passed means tomorrow.
    public func targetDate(from now: Date = Date(), calendar: Calendar = .current) throws -> Date {
        switch self {
        case .after(let minutes):
            guard minutes > 0 else { throw Error.zeroDuration }
            return now.addingTimeInterval(TimeInterval(minutes * 60))
        case .at(let hour, let minute):
            guard (0..<24).contains(hour), (0..<60).contains(minute) else { throw Error.invalidTime }
            guard let today = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) else { throw Error.invalidTime }
            if today > now { return today }
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { throw Error.invalidTime }
            return tomorrow
        }
    }
}
