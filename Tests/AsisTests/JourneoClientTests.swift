import XCTest
import Alamofire
@testable import Asis

/// Tests the Journeo transport boundary using synthetic configuration and an isolated URL protocol.
final class JourneoClientTests: XCTestCase {
    private var session: Session!
    private var client: JourneoClient!

    override func setUpWithError() throws {
        try super.setUpWithError()
        JourneoStubProtocol.reset()
        let transport = URLSessionConfiguration.ephemeral
        transport.protocolClasses = [JourneoStubProtocol.self]
        session = Session(configuration: transport)
        let config = try configuration()
        client = JourneoClient(configurationProvider: { config }, session: session)
    }

    override func tearDown() {
        client.cancel()
        session.session.invalidateAndCancel()
        client = nil
        session = nil
        super.tearDown()
    }

    func testConfiguredHeaderAndSuccessfulStopDetails() {
        JourneoStubProtocol.respond(body: #"{"atcocode":"6110114","name":"Test stop","coordinate":{"latitude":51.458821,"longitude":0.0}}"#)
        let done = expectation(description: "details")
        done.assertForOverFulfill = true
        client.stopDetails(atcoCode: "6110114") { result in
            XCTAssertTrue(Thread.isMainThread)
            switch result {
            case .success(let stop): XCTAssertEqual(stop.atcoCode, "6110114")
            case .failure: XCTFail("Expected decoded stop")
            }
            done.fulfill()
        }
        wait(for: [done], timeout: 3)
        XCTAssertEqual(JourneoStubProtocol.requests.count, 1)
        XCTAssertEqual(JourneoStubProtocol.requests.first?.value(forHTTPHeaderField: "X-Test-Subscription"),
                       "unit-test-primary")
        XCTAssertEqual(JourneoStubProtocol.requests.first?.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testHTTPFailureCompletesOnceOnMain() {
        JourneoStubProtocol.respond(status: 503, body: "upstream unavailable")
        assertStopDetailsFailure()
    }

    func testMalformedJSONCompletesOnceOnMain() {
        JourneoStubProtocol.respond(body: "not JSON")
        assertStopDetailsFailure()
    }

    func testSchemaMismatchFailsRatherThanReturningEmptySuccess() {
        JourneoStubProtocol.respond(body: "{}")
        assertStopDetailsFailure()
    }

    func testRedirectIsRefusedWithoutForwardingAuthentication() {
        JourneoStubProtocol.respond(status: 302, body: "", redirect: URL(string: "https://other.example/StopDetails"))
        assertStopDetailsFailure()
        XCTAssertEqual(JourneoStubProtocol.requests.first?.url?.host, "transit.example")
    }

    func testThrowingProviderCompletesOnMainAndSendsNothing() {
        client = JourneoClient(configurationProvider: { throw JourneoConfigurationError.fileMissing }, session: session)
        let done = expectation(description: "missing configuration")
        done.assertForOverFulfill = true
        let active = client!
        DispatchQueue.global().async {
            active.stopDetails(atcoCode: "6110114") { result in
                XCTAssertTrue(Thread.isMainThread)
                switch result {
                case .success: XCTFail("Missing configuration must fail")
                case .failure(let error): XCTAssertEqual(error as? JourneoConfigurationError, .fileMissing)
                }
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 3)
        XCTAssertTrue(JourneoStubProtocol.requests.isEmpty)
    }

    func testInvalidInputCompletesOnMainAndSendsNothing() {
        let done = expectation(description: "invalid input")
        done.assertForOverFulfill = true
        client.vehicleStatus(vehicleID: "") { result in
            XCTAssertTrue(Thread.isMainThread)
            switch result {
            case .success: XCTFail("Invalid input must fail")
            case .failure(let error): XCTAssertEqual(error as? JourneoRequestError, .invalidParameter("VehicleId"))
            }
            done.fulfill()
        }
        wait(for: [done], timeout: 3)
        XCTAssertTrue(JourneoStubProtocol.requests.isEmpty)
    }

    func testConfigurationIsResolvedForEveryCall() throws {
        let config = try configuration()
        var resolutions = 0
        client = JourneoClient(configurationProvider: {
            resolutions += 1
            if resolutions == 1 { return config }
            throw JourneoConfigurationError.fileMissing
        }, session: session)
        JourneoStubProtocol.respond(body: #"{"atcocodes":[]}"#)
        let first = expectation(description: "configured")
        client.getStops(date: "2026-10-19") { result in
            if case .failure = result { XCTFail("First call should succeed") }
            first.fulfill()
        }
        wait(for: [first], timeout: 3)
        let second = expectation(description: "configuration removed")
        client.getStops(date: "2026-10-19") { result in
            if case .success = result { XCTFail("Second call must fail closed") }
            second.fulfill()
        }
        wait(for: [second], timeout: 3)
        XCTAssertEqual(resolutions, 2)
        XCTAssertEqual(JourneoStubProtocol.requests.count, 1)
    }

    func testDocumentedResponsesDecodeForEveryOperation() {
        let cases: [(String, (@escaping (Bool) -> Void) -> Void)] = [
            (#"{"time":"2017-09-05T12:11:47Z","atcocode":"6110114","name":"Hilton Road","events":[{"operator":"GCB","publicservicename":"15","destination":"George Square","schedulearrivaltime":"12:26","scheduledeparturetime":"12:26","arrivaltime":null,"departuretime":null}]}"#, { callback in
                self.client.stopEvents(stop: .atcoCode("6110114")) { result in
                    XCTAssertTrue(Thread.isMainThread)
                    callback((try? result.get().events.count) == 1)
                }
            }),
            (#"{"time":"2017-09-05T12:28:04Z","id":"70276","fleetno":"STWS-10523","lastupdate":"2017-09-05T12:27:19Z","status":"Unknown","coordinate":{"latitude":55.8655357,"longitude":-4.2509732},"operator":"STWS","publicservicename":"X25A","delay":0,"block":"G40","journey":"73"}"#, { callback in
                self.client.vehicleStatus(vehicleID: "70276") { result in
                    XCTAssertTrue(Thread.isMainThread)
                    callback((try? result.get().id) == "70276")
                }
            }),
            (#"{"items":[{"type":"STOP","id":"61601197","name":"Cumbernauld Road","options":{"icon":"/stop.png"},"latitude":55.92082,"longitude":0.0},{"type":"VEHICLE","id":"70276","name":"STWS-10523","options":{"icon":"/ontime.png"},"latitude":55.923111,"longitude":-4.0527635,"operator":"STWS","publicservicename":"X25A","delay":0}]}"#, { callback in
                self.client.areaSearch(northEastLatitude: 55.934, northEastLongitude: -4.046,
                                       southWestLatitude: 55.918, southWestLongitude: -4.061) { result in
                    XCTAssertTrue(Thread.isMainThread)
                    callback((try? result.get().items.count) == 2)
                }
            }),
            (#"{"atcocodes":["40004407248A","40004407169B"]}"#, { callback in
                self.client.getStops(date: "2017-09-05") { result in
                    XCTAssertTrue(Thread.isMainThread)
                    callback((try? result.get()) != nil)
                }
            })
        ]
        for (body, invoke) in cases {
            JourneoStubProtocol.respond(body: body)
            let done = expectation(description: "sample response")
            done.assertForOverFulfill = true
            invoke { success in
                XCTAssertTrue(success)
                done.fulfill()
            }
            wait(for: [done], timeout: 3)
        }
    }

    func testFullDetailsValidatesJSONWithoutAssumingUndocumentedEnvelope() {
        for (body, success) in [("[]", true), ("not JSON", false)] {
            JourneoStubProtocol.respond(body: body)
            let done = expectation(description: "full details")
            client.getStops(date: "2026-10-19", fullDetails: true) { result in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertEqual((try? result.get()) != nil, success)
                done.fulfill()
            }
            wait(for: [done], timeout: 3)
        }
    }

    func testCancellationPreservesExactlyOneMainQueueFailure() {
        JourneoStubProtocol.respond(body: "", hold: true)
        let started = expectation(description: "started")
        JourneoStubProtocol.onStart = { started.fulfill() }
        let done = expectation(description: "cancelled")
        done.assertForOverFulfill = true
        client.stopDetails(atcoCode: "6110114") { result in
            XCTAssertTrue(Thread.isMainThread)
            switch result {
            case .success: XCTFail("Cancelled request must fail")
            case .failure(let error): XCTAssertTrue((error as? AFError)?.isExplicitlyCancelledError == true)
            }
            done.fulfill()
        }
        wait(for: [started], timeout: 3)
        client.cancel()
        wait(for: [done], timeout: 3)
    }

    func testLegacyTransitBaseURLIsUnchangedInAppBundle() {
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "TransitAPIBaseURL") as? String,
                       "https://tfe-opendata.com/api/v1/")
    }

    private func configuration() throws -> JourneoConfiguration {
        try JourneoConfiguration.resolve(plistData: PropertyListSerialization.data(
            fromPropertyList: ["JourneoAPIBaseURL": "https://transit.example/api/",
                              "JourneoAPIKeyHeaderName": "X-Test-Subscription",
                              "JourneoAPIKey": "unit-test-primary"], format: .xml, options: 0
        ))
    }

    private func assertStopDetailsFailure(file: StaticString = #filePath, line: UInt = #line) {
        let done = expectation(description: "failure")
        done.assertForOverFulfill = true
        client.stopDetails(atcoCode: "6110114") { result in
            XCTAssertTrue(Thread.isMainThread, file: file, line: line)
            if case .success = result { XCTFail("Expected failure", file: file, line: line) }
            done.fulfill()
        }
        wait(for: [done], timeout: 3)
        XCTAssertEqual(JourneoStubProtocol.requests.count, 1, file: file, line: line)
    }
}

private final class JourneoStubProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var status = 200
    private static var body = Data()
    private static var hold = false
    private static var redirect: URL?
    private static var captured: [URLRequest] = []
    private static var startHandler: (() -> Void)?

    static var requests: [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return captured
    }

    static var onStart: (() -> Void)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return startHandler
        }
        set {
            lock.lock()
            startHandler = newValue
            lock.unlock()
        }
    }

    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        status = 200
        body = Data()
        hold = false
        redirect = nil
        captured = []
        startHandler = nil
    }

    static func respond(status: Int = 200, body: String, hold: Bool = false, redirect: URL? = nil) {
        lock.lock()
        defer { lock.unlock() }
        self.status = status
        self.body = Data(body.utf8)
        self.hold = hold
        self.redirect = redirect
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        Self.captured.append(request)
        let status = Self.status
        let body = Self.body
        let hold = Self.hold
        let redirect = Self.redirect
        let start = Self.startHandler
        Self.lock.unlock()
        start?()
        guard !hold, let url = request.url else { return }
        if let redirect, url.host == "transit.example",
           let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil,
                                          headerFields: ["Location": redirect.absoluteString]) {
            client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: redirect), redirectResponse: response)
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        guard let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil,
                                             headerFields: ["Content-Type": "application/json"]) else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
