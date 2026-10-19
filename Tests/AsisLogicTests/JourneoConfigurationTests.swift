import Foundation
import XCTest
@testable import AsisLogic

/// Exercises the configuration boundary with synthetic values only.
final class JourneoConfigurationTests: XCTestCase {
    private let fixture: [String: Any] = [
        "JourneoAPIBaseURL": "https://transit.example/api/",
        "JourneoAPIKeyHeaderName": "X-Test-Subscription",
        "JourneoAPIKey": "unit-test-primary",
        "JourneoAPIKeySecondary": "unit-test-secondary"
    ]

    func testValidPlistTrimsValuesAndRedactsDescriptions() throws {
        let padded = fixture.mapValues { "  \($0)  " }
        let config = try resolve(padded)
        XCTAssertEqual(config.baseURL.absoluteString, "https://transit.example/api/")
        XCTAssertEqual(config.headerName, "X-Test-Subscription")
        XCTAssertEqual(config.apiKey, fixture["JourneoAPIKey"] as? String)
        XCTAssertEqual(config.secondaryKey, fixture["JourneoAPIKeySecondary"] as? String)
        for text in [config.description, config.debugDescription, String(describing: config), String(reflecting: config)] {
            XCTAssertFalse(text.contains(config.apiKey))
            XCTAssertFalse(text.contains(try XCTUnwrap(config.secondaryKey)))
            XCTAssertTrue(text.contains("redacted"))
        }
    }

    func testMissingFileAndMalformedPlistFailClosed() throws {
        XCTAssertThrowsError(try JourneoConfiguration.resolve(plistData: nil)) {
            XCTAssertEqual($0 as? JourneoConfigurationError, .fileMissing)
        }
        XCTAssertThrowsError(try JourneoConfiguration.resolve(plistData: Data("not a plist".utf8))) {
            XCTAssertEqual($0 as? JourneoConfigurationError, .unreadable)
        }
        let array = try PropertyListSerialization.data(fromPropertyList: ["array"], format: .xml, options: 0)
        XCTAssertThrowsError(try JourneoConfiguration.resolve(plistData: array)) {
            XCTAssertEqual($0 as? JourneoConfigurationError, .unreadable)
        }
    }

    func testEachRequiredKeyMustExist() throws {
        for key in ["JourneoAPIBaseURL", "JourneoAPIKeyHeaderName", "JourneoAPIKey"] {
            var values = fixture
            values.removeValue(forKey: key)
            assertError(values, .missingValue(key))
        }
        var values = fixture
        values.removeValue(forKey: "JourneoAPIKeySecondary")
        XCTAssertNil(try resolve(values).secondaryKey)
    }

    func testEveryPresentValueMustBeANonemptyString() {
        for key in fixture.keys {
            for blank in ["", " \t\r\n "] {
                var values = fixture
                values[key] = blank
                assertError(values, .emptyValue(key))
            }
            var values = fixture
            values[key] = 42
            assertError(values, .unreadable)
        }
    }

    func testBaseURLRequiresHTTPSAndHostWithoutCredentialsQueryOrFragment() {
        for base in ["http://transit.example/api/", "transit.example/api/", "/api/", "https://",
                     "https:///api/", "https://user:password@transit.example/api/",
                     "https://transit.example/api/?token=fixture", "https://transit.example/api/#fragment",
                     "https://transit.example:0/api/", "https://transit.example:65536/api/"] {
            var values = fixture
            values["JourneoAPIBaseURL"] = base
            assertError(values, .insecureBaseURL)
        }
    }

    func testHTTPTokenAndReservedHeaderValidation() throws {
        for name in ["X Test", "X:Test", "X\nTest", "X-Test\r\n", "X-é", "X/Test",
                     "Accept", "Host", "Content-Length", "Transfer-Encoding"] {
            var values = fixture
            values["JourneoAPIKeyHeaderName"] = name
            assertError(values, .invalidHeaderName)
        }
        var values = fixture
        values["JourneoAPIKeyHeaderName"] = "!#$%&'*+-.^_`|~0123456789AZaz"
        XCTAssertNotNil(try resolve(values))
    }

    func testControlCharactersInCredentialValuesAreRejectedWithoutDisclosure() {
        for key in ["JourneoAPIKey", "JourneoAPIKeySecondary"] {
            var values = fixture
            values[key] = "unit-test\r\ninjected"
            assertError(values, .unreadable)
        }
    }

    func testCommittedTemplateHasExactlyEmptyValuesAndFailsClosed() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("Asis/Keys.example.plist"))
        let values = try XCTUnwrap(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String])
        XCTAssertEqual(Set(values.keys), Set(fixture.keys))
        XCTAssertTrue(values.values.allSatisfy(\.isEmpty))
        XCTAssertThrowsError(try JourneoConfiguration.resolve(plistData: data)) {
            XCTAssertEqual($0 as? JourneoConfigurationError, .emptyValue("JourneoAPIBaseURL"))
        }
    }

    func testBundleWithoutKeysFailsClosed() {
        XCTAssertThrowsError(try JourneoConfiguration.resolve(bundle: Bundle(for: Self.self))) {
            XCTAssertEqual($0 as? JourneoConfigurationError, .fileMissing)
        }
    }

    private func resolve(_ values: [String: Any]) throws -> JourneoConfiguration {
        try JourneoConfiguration.resolve(plistData: PropertyListSerialization.data(
            fromPropertyList: values, format: .xml, options: 0
        ))
    }

    private func assertError(_ values: [String: Any], _ expected: JourneoConfigurationError,
                             file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try resolve(values), file: file, line: line) {
            XCTAssertEqual($0 as? JourneoConfigurationError, expected, file: file, line: line)
        }
    }
}
