import XCTest
import Alamofire
@testable import Asis

/// Tests the real HTTP/decoding boundary using a local URL loading protocol.
final class TransitClientTests: XCTestCase {
    private var session: Session!
    private var client: GetBaseData!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [TransitStubProtocol.self]
        session = Session(configuration: configuration)
        client = GetBaseData(baseURL: URL(string: "https://transit.example/api/v1/"), session: session)
    }

    func testHTTPFailureCompletesOnceOnMainQueue() {
        TransitStubProtocol.status = 522
        TransitStubProtocol.body = Data("upstream unavailable".utf8)
        let done = expectation(description: "failure completion")
        done.assertForOverFulfill = true
        client.timeCompletionHandler { trips, success, message in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(trips)
            XCTAssertFalse(success)
            XCTAssertFalse(message.isEmpty)
            done.fulfill()
        }
        client.getTimeBaseData(endPoint: "stoptostop-timetable/")
        wait(for: [done], timeout: 3)
    }

    func testMalformedJSONProducesAFailureInsteadOfAnEmptySuccess() {
        TransitStubProtocol.status = 200
        TransitStubProtocol.body = Data("not JSON".utf8)
        let done = expectation(description: "decode failure")
        client.busCompletionHandler { vehicles, success, message in
            XCTAssertNil(vehicles)
            XCTAssertFalse(success)
            XCTAssertFalse(message.isEmpty)
            done.fulfill()
        }
        client.getBusBaseData(endPoint: "vehicle_locations")
        wait(for: [done], timeout: 3)
    }

    func testInvalidStopCoordinatesAreExcludedWithoutLosingValidStops() {
        TransitStubProtocol.status = 200
        TransitStubProtocol.body = Data(#"{"last_updated":1,"stops":[{"stop_id":1,"name":"Valid","latitude":55.95,"longitude":-3.18,"destinations":[],"services":[]},{"stop_id":2,"name":null,"latitude":null,"longitude":null,"destinations":[],"services":[]},{"stop_id":3,"name":"Invalid","latitude":123,"longitude":0,"destinations":[],"services":[]}]}"#.utf8)
        let done = expectation(description: "validated stops")
        client.completionHandler { stops, success, _ in
            XCTAssertTrue(success)
            XCTAssertEqual(stops?.map(\.stopID), [1])
            done.fulfill()
        }
        client.getStopsBaseData(endPoint: "stops")
        wait(for: [done], timeout: 3)
    }

    func testEndpointCannotChangeTheConfiguredHost() {
        let done = expectation(description: "invalid endpoint")
        client.completionHandler { stops, success, _ in
            XCTAssertNil(stops)
            XCTAssertFalse(success)
            done.fulfill()
        }
        client.getStopsBaseData(endPoint: "https://unrelated.example/stops")
        wait(for: [done], timeout: 3)
    }

    func testEmptyTimetableIsAValidResponse() {
        TransitStubProtocol.status = 200
        TransitStubProtocol.body = Data(#"{"start_stop_id":1,"finish_stop_id":2,"date":1,"duration":15,"journeys":[]}"#.utf8)
        let done = expectation(description: "empty timetable")
        client.timeCompletionHandler { trips, success, _ in
            XCTAssertTrue(success)
            XCTAssertEqual(trips?.count, 0)
            done.fulfill()
        }
        client.getTimeBaseData(endPoint: "stoptostop-timetable/")
        wait(for: [done], timeout: 3)
    }
}

private final class TransitStubProtocol: URLProtocol {
    static var status = 200
    static var body = Data()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: Self.status, httpVersion: nil, headerFields: ["Content-Type": "application/json"]) else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
