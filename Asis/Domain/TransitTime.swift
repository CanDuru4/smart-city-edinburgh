import Foundation

/// Interprets Edinburgh timetable clock values independently of the phone's time zone.
///
/// Example: `TransitTime.duration(from: "23:55", to: "00:10")` returns 15 minutes.
enum TransitTime {
    /// Calculates elapsed minutes between departure and arrival, including midnight.
    /// - Parameters:
    ///   - departure: A timetable time in `HH:mm` format.
    ///   - arrival: A timetable time in `HH:mm` format.
    /// - Returns: Elapsed minutes, or nil for invalid times. Does not throw.
    static func duration(from departure: String, to arrival: String) -> Int? {
        guard let start = minutes(departure), let end = minutes(arrival) else { return nil }
        return (end - start + 1440) % 1440
    }

    /// Resolves an upcoming Edinburgh departure inside the requested search window.
    /// - Parameters:
    ///   - clock: The provider's `HH:mm` departure time.
    ///   - reference: The instant the timetable search started.
    ///   - horizon: Maximum wait in minutes, preventing past times from becoming tomorrow's trips.
    /// - Returns: The absolute departure date, or nil if invalid or outside the window.
    ///   Does not throw. Example: a 00:05 departure is valid at 23:55 with a 15 minute window.
    static func departureDate(_ clock: String, after reference: Date, within horizon: Int) -> Date? {
        guard let minuteOfDay = minutes(clock), horizon > 0,
              let zone = TimeZone(identifier: "Europe/London") else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let components = DateComponents(hour: minuteOfDay / 60, minute: minuteOfDay % 60, second: 0)
        guard let date = calendar.nextDate(after: reference.addingTimeInterval(-1), matching: components,
                                           matchingPolicy: .strict, repeatedTimePolicy: .first),
              date >= reference, date.timeIntervalSince(reference) <= Double(horizon * 60) else { return nil }
        return date
    }

    private static func minutes(_ value: String) -> Int? {
        let parts = value.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2, parts.allSatisfy({ $0.count == 2 && $0.allSatisfy(\.isNumber) }),
              let hour = Int(parts[0]), let minute = Int(parts[1]),
              (0..<24).contains(hour), (0..<60).contains(minute) else { return nil }
        return hour * 60 + minute
    }
}
