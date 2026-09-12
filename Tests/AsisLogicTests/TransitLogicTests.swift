import Foundation
import XCTest
@testable import AsisLogic

final class TransitLogicTests: XCTestCase {
    func testShortTagRetainsEveryByte() {
        XCTAssertEqual(CardIdentifier.hex(Data([0, 1, 15, 255])), "00010FFF")
    }

    func testEmptyTagDoesNotCreateAnIdentifier() {
        XCTAssertEqual(CardIdentifier.hex(Data()), "")
    }

    func testJourneyAcrossMidnightHasPositiveDuration() {
        XCTAssertEqual(TransitTime.duration(from: "23:55", to: "00:10"), 15)
    }

    func testNormalJourneyDuration() {
        XCTAssertEqual(TransitTime.duration(from: "14:10", to: "14:35"), 25)
    }

    func testMalformedTimetableIsRejected() {
        XCTAssertNil(TransitTime.duration(from: "invalid", to: "14:35"))
        XCTAssertNil(TransitTime.duration(from: "25:01", to: "14:35"))
    }

    func testEdinburghDepartureUsesWinterTimeAndRespectsSearchWindow() throws {
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-01-12T12:00:00Z"))
        let date = try XCTUnwrap(TransitTime.departureDate("12:10", after: now, within: 15))
        XCTAssertEqual(date.timeIntervalSince(now), 600)
        XCTAssertNil(TransitTime.departureDate("11:59", after: now, within: 15))
        XCTAssertNil(TransitTime.departureDate("12:16", after: now, within: 15))
    }

    func testEdinburghDepartureUsesSummerTimeAndCrossesMidnight() throws {
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-07-12T22:55:00Z"))
        let date = try XCTUnwrap(TransitTime.departureDate("00:05", after: now, within: 15))
        XCTAssertEqual(date.timeIntervalSince(now), 600)
    }
}
