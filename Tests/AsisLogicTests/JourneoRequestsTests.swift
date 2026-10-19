import Foundation
import XCTest
@testable import AsisLogic

/// Checks exact wire contracts against the guide's parameter tables and sample coordinates.
final class JourneoRequestsTests: XCTestCase {
    func testStopEventsAllOptionsAndAlternativeIdentifiers() throws {
        try assertRequest(
            .stopEvents(stop: .atcoCode("6110114"), eventType: .arrival, lookaheadMinutes: 60,
                        maxEvents: 10, minVisitsPerService: 2, ordering: .scheduledArrival, timeFormat: .utc),
            path: "StopEvents",
            query: ["AtcoCode": "6110114", "EventType": "arrival", "Lookahead": "60",
                    "MaxEvents": "10", "MinVisitsPerService": "2", "Ordering": "SchArr", "TimeFormat": "UTC"]
        )
        try assertRequest(.stopEvents(stop: .smsCode("36235349")), path: "StopEvents",
                          query: ["SMSCode": "36235349"])
        try assertRequest(.stopEvents(stop: .atcoCode("6110114"), eventType: .departure,
                                      ordering: .realDeparture, timeFormat: .local), path: "StopEvents",
                          query: ["AtcoCode": "6110114", "EventType": "departure",
                                  "Ordering": "RelaDep", "TimeFormat": "Local"])
        XCTAssertEqual(JourneoEventOrdering.scheduledDeparture.rawValue, "SchDep")
        XCTAssertEqual(JourneoEventOrdering.realArrival.rawValue, "RealArr")
    }

    func testStopDetailsMatchesParameterTable() throws {
        try assertRequest(.stopDetails(atcoCode: "6110114"), path: "StopDetails", query: ["atcoCode": "6110114"])
    }

    func testGetStopsDateAndFullDetails() throws {
        try assertRequest(.getStops(date: "2017-09-05"), path: "GetStops", query: ["date": "2017-09-05"])
        for details in [true, false] {
            try assertRequest(.getStops(date: "2024-02-29", fullDetails: details), path: "GetStops",
                              query: ["date": "2024-02-29", "FullDetails": details ? "true" : "false"])
        }
    }

    func testAreaSearchUsesGuideBoundingBoxNotRadius() throws {
        try assertRequest(.areaSearch(northEastLatitude: 55.934, northEastLongitude: -4.046,
                                      southWestLatitude: 55.918, southWestLongitude: -4.061),
                          path: "AreaSearch",
                          query: ["ne_lat": "55.934", "ne_long": "-4.046", "sw_lat": "55.918", "sw_long": "-4.061"])
    }

    func testVehicleStatusIdentifierAndOptionalTimeFormat() throws {
        try assertRequest(.vehicleStatus(vehicleID: "70276"), path: "VehicleStatus", query: ["VehicleId": "70276"])
        try assertRequest(.vehicleStatus(vehicleID: "70276", timeFormat: .local), path: "VehicleStatus",
                          query: ["VehicleId": "70276", "TimeFormat": "Local"])
    }

    func testIdentifiersAreTrimmedEncodedQueryValuesAndCannotChangeOrigin() throws {
        let value = "https://other.example/?x=1&fake=2#part"
        try assertRequest(.stopDetails(atcoCode: "  \(value)  "), path: "StopDetails", query: ["atcoCode": value])
    }

    func testBaseDirectoryWorksWithOrWithoutTrailingSlashAndPreservesPort() throws {
        for base in ["https://transit.example:8443/api", "https://transit.example:8443/api/"] {
            let request = try JourneoRequest.getStops(date: "2026-10-19").urlRequest(configuration: configuration(base))
            XCTAssertEqual(request.url?.path, "/api/GetStops")
            XCTAssertEqual(request.url?.port, 8443)
            XCTAssertEqual(request.url?.host, "transit.example")
            XCTAssertEqual(request.url?.scheme, "https")
        }
    }

    func testInvalidInputsThrowForEveryOperation() throws {
        let invalid: [JourneoRequest] = [
            .stopEvents(stop: .atcoCode(" ")), .stopEvents(stop: .smsCode("")),
            .stopEvents(stop: .atcoCode("1"), lookaheadMinutes: 0),
            .stopEvents(stop: .atcoCode("1"), maxEvents: -1),
            .stopEvents(stop: .atcoCode("1"), minVisitsPerService: 0),
            .stopDetails(atcoCode: "\t"), .vehicleStatus(vehicleID: "\n"),
            .vehicleStatus(vehicleID: "a\nb"),
            .areaSearch(northEastLatitude: .nan, northEastLongitude: 1, southWestLatitude: 0, southWestLongitude: 0),
            .areaSearch(northEastLatitude: 91, northEastLongitude: 1, southWestLatitude: 0, southWestLongitude: 0),
            .areaSearch(northEastLatitude: 1, northEastLongitude: 181, southWestLatitude: 0, southWestLongitude: 0),
            .areaSearch(northEastLatitude: 1, northEastLongitude: 1, southWestLatitude: -.infinity, southWestLongitude: 0),
            .areaSearch(northEastLatitude: 1, northEastLongitude: 1, southWestLatitude: 0, southWestLongitude: -181),
            .areaSearch(northEastLatitude: 0, northEastLongitude: 1, southWestLatitude: 1, southWestLongitude: 0),
            .areaSearch(northEastLatitude: 1, northEastLongitude: 0, southWestLatitude: 0, southWestLongitude: 1),
            .areaSearch(northEastLatitude: 1, northEastLongitude: 1, southWestLatitude: 1, southWestLongitude: 0)
        ] + ["", "2026-02-29", "2026-13-01", "2026-04-31", "2026-00-01", "0000-01-01",
             "2026-1-01", "2026-10-19T00:00:00Z", "2026-10-19\n"].map { .getStops(date: $0) }
        let config = try configuration()
        for operation in invalid {
            XCTAssertThrowsError(try operation.urlRequest(configuration: config)) {
                XCTAssertTrue($0 is JourneoRequestError)
            }
        }
    }

    private func configuration(_ base: String = "https://transit.example/api/") throws -> JourneoConfiguration {
        try JourneoConfiguration.resolve(plistData: PropertyListSerialization.data(
            fromPropertyList: ["JourneoAPIBaseURL": base, "JourneoAPIKeyHeaderName": "X-Test-Subscription",
                              "JourneoAPIKey": "unit-test-primary"], format: .xml, options: 0
        ))
    }

    private func assertRequest(_ operation: JourneoRequest, path: String, query: [String: String],
                               file: StaticString = #filePath, line: UInt = #line) throws {
        let config = try configuration()
        let request = try operation.urlRequest(configuration: config)
        XCTAssertEqual(request.httpMethod, "GET", file: file, line: line)
        XCTAssertEqual(request.timeoutInterval, 15, file: file, line: line)
        XCTAssertEqual(request.url?.path, "/api/\(path)", file: file, line: line)
        XCTAssertEqual(request.url?.host, config.baseURL.host, file: file, line: line)
        XCTAssertEqual(request.url?.scheme, "https", file: file, line: line)
        XCTAssertEqual(request.value(forHTTPHeaderField: config.headerName), config.apiKey, file: file, line: line)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json", file: file, line: line)
        let url = try XCTUnwrap(request.url)
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertEqual(items.count, query.count, file: file, line: line)
        XCTAssertEqual(Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") }), query,
                       file: file, line: line)
        XCTAssertFalse(url.absoluteString.contains(config.apiKey), file: file, line: line)
    }
}
