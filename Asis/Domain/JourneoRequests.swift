import Foundation

/// Input and URL errors without embedding user inputs or credentials.
/// Example: `JourneoRequestError.invalidParameter("VehicleId")`.
public enum JourneoRequestError: Error, Equatable {
    case invalidParameter(String)
    case invalidURL
}

/// Alternative stop identifiers documented for StopEvents; exactly one is sent.
/// Example: `JourneoStopIdentifier.atcoCode("6110114")`.
public enum JourneoStopIdentifier {
    case atcoCode(String)
    case smsCode(String)
}

/// Stop event selection. Omitting it requests both arrivals and departures.
/// Example: `JourneoEventType.departure`.
public enum JourneoEventType: String {
    case arrival
    case departure
}

/// Wire ordering labels transcribed from section 3.1, including the documented "RelaDep" spelling.
/// Portal verification is needed before assuming that this spelling is accepted by the live service.
/// Example: `JourneoEventOrdering.scheduledArrival`.
public enum JourneoEventOrdering: String {
    case scheduledArrival = "SchArr"
    case scheduledDeparture = "SchDep"
    case realArrival = "RealArr"
    case realDeparture = "RelaDep"
}

/// Response time zone selection; Local means the server's local time.
/// Example: `JourneoTimeFormat.utc`.
public enum JourneoTimeFormat: String {
    case utc = "UTC"
    case local = "Local"
}

/// Pure GET contracts from the NOVUS-RT Open API guide, sections 3, 4, 5, 7 and 11.
/// Query names follow parameter tables, whose casing differs from some examples.
/// AreaSearch uses the named NE/SW bounds and the numerical example, not a radius.
/// GetStops full-detail JSON is unspecified by the guide and is returned as validated JSON data.
/// Example: `JourneoRequest.stopDetails(atcoCode: "6110114")`.
public enum JourneoRequest {
    case stopEvents(stop: JourneoStopIdentifier, eventType: JourneoEventType? = nil,
                    lookaheadMinutes: Int? = nil, maxEvents: Int? = nil,
                    minVisitsPerService: Int? = nil, ordering: JourneoEventOrdering? = nil,
                    timeFormat: JourneoTimeFormat? = nil)
    case stopDetails(atcoCode: String)
    case getStops(date: String, fullDetails: Bool? = nil)
    case areaSearch(northEastLatitude: Double, northEastLongitude: Double,
                    southWestLatitude: Double, southWestLongitude: Double)
    case vehicleStatus(vehicleID: String, timeFormat: JourneoTimeFormat? = nil)

    /// Builds a request pinned to the configured HTTPS origin, including its port.
    /// The base URL is treated as an API directory even when its trailing slash is omitted.
    /// Identifiers remain query values, so slashes and ampersands cannot change the request path.
    /// Positive event limits and a real Gregorian CCYY-MM-DD date are required.
    /// - Parameters:
    ///   - configuration: Configuration obtained from the fail-closed resolver.
    /// - Returns: A GET request with authentication, JSON accept header, and a 15 second timeout.
    /// - Throws: JourneoRequestError for malformed inputs or a changed origin.
    /// Example: `try JourneoRequest.getStops(date: "2026-10-19").urlRequest(configuration: config)`.
    public func urlRequest(configuration: JourneoConfiguration) throws -> URLRequest {
        let (path, query) = try pathAndQuery()
        let base = configuration.baseURL
        guard var components = URLComponents(
            url: base.appendingPathComponent(path), resolvingAgainstBaseURL: true
        ) else { throw JourneoRequestError.invalidURL }
        components.queryItems = query
        guard let url = components.url,
              url.scheme == base.scheme, url.scheme == "https",
              url.host == base.host, url.port == base.port else {
            throw JourneoRequestError.invalidURL
        }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(configuration.apiKey, forHTTPHeaderField: configuration.headerName)
        return request
    }

    private func pathAndQuery() throws -> (String, [URLQueryItem]) {
        var query: [URLQueryItem] = []
        func add(_ name: String, _ value: String?) {
            if let value { query.append(URLQueryItem(name: name, value: value)) }
        }
        func identifier(_ name: String, _ value: String) throws {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) else {
                throw JourneoRequestError.invalidParameter(name)
            }
            add(name, trimmed)
        }
        func positive(_ name: String, _ value: Int?) throws {
            if let value {
                guard value > 0 else { throw JourneoRequestError.invalidParameter(name) }
                add(name, String(value))
            }
        }

        switch self {
        case let .stopEvents(stop, eventType, lookahead, maxEvents, minimum, ordering, timeFormat):
            switch stop {
            case .atcoCode(let code): try identifier("AtcoCode", code)
            case .smsCode(let code): try identifier("SMSCode", code)
            }
            add("EventType", eventType?.rawValue)
            try positive("Lookahead", lookahead)
            try positive("MaxEvents", maxEvents)
            try positive("MinVisitsPerService", minimum)
            add("Ordering", ordering?.rawValue)
            add("TimeFormat", timeFormat?.rawValue)
            return ("StopEvents", query)
        case .stopDetails(let code):
            try identifier("atcoCode", code)
            return ("StopDetails", query)
        case let .getStops(date, fullDetails):
            guard Self.isCalendarDate(date) else { throw JourneoRequestError.invalidParameter("date") }
            add("date", date)
            add("FullDetails", fullDetails.map { $0 ? "true" : "false" })
            return ("GetStops", query)
        case let .areaSearch(neLat, neLong, swLat, swLong):
            for (name, value, range) in [
                ("ne_lat", neLat, -90.0...90.0), ("ne_long", neLong, -180.0...180.0),
                ("sw_lat", swLat, -90.0...90.0), ("sw_long", swLong, -180.0...180.0)
            ] {
                guard value.isFinite, range.contains(value) else {
                    throw JourneoRequestError.invalidParameter(name)
                }
                add(name, String(value))
            }
            guard neLat > swLat, neLong > swLong else {
                throw JourneoRequestError.invalidParameter("boundingBox")
            }
            return ("AreaSearch", query)
        case let .vehicleStatus(vehicleID, timeFormat):
            try identifier("VehicleId", vehicleID)
            add("TimeFormat", timeFormat?.rawValue)
            return ("VehicleStatus", query)
        }
    }

    private static func isCalendarDate(_ value: String) -> Bool {
        guard value.utf8.count == 10,
              value.range(of: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", options: .regularExpression) != nil else { return false }
        let parts = value.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, parts[0] > 0 else { return false }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = DateComponents(year: parts[0], month: parts[1], day: parts[2])
        guard let date = calendar.date(from: components) else { return false }
        let actual = calendar.dateComponents([.year, .month, .day], from: date)
        return actual.year == parts[0] && actual.month == parts[1] && actual.day == parts[2]
    }
}
