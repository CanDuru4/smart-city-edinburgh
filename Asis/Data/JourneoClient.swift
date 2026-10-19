import Foundation
import Alamofire

/// Separate NOVUS-RT client that resolves configuration on every call and never uses legacy settings.
/// All completions are asynchronous on the main queue. Redirects are refused to avoid forwarding
/// a custom authentication header to another origin. The secondary key is reserved for manual rotation.
/// Example: `JourneoClient().stopDetails(atcoCode: "6110114") { result in /* handle result */ }`.
final class JourneoClient {
    private let configurationProvider: () throws -> JourneoConfiguration
    private let session: Session
    private let lock = NSLock()
    private var requests: [UUID: DataRequest] = [:]

    /// Creates a client without accessing configuration or sending a request.
    /// - Parameters:
    ///   - configurationProvider: Resolver invoked for every operation.
    ///   - session: Injectable Alamofire transport.
    /// - Returns: An idle client.
    /// Example: `JourneoClient(session: session)`.
    init(configurationProvider: @escaping () throws -> JourneoConfiguration = { try JourneoConfiguration.resolve() },
         session: Session = AF) {
        self.configurationProvider = configurationProvider
        self.session = session
    }

    /// Fetches events for one ATCO or SMS stop identifier.
    /// - Parameters:
    ///   - stop: Exactly one stop identifier.
    ///   - eventType: Arrival, departure, or both when omitted.
    ///   - lookaheadMinutes: Positive future window in minutes; the service default is one hour.
    ///   - maxEvents: Positive event limit, or the service default.
    ///   - minVisitsPerService: Positive minimum visits per service within the window.
    ///   - ordering: Guide ordering label, including its unverified RelaDep spelling.
    ///   - timeFormat: UTC or server-local time; omitted uses the service default.
    ///   - completion: Receives decoded events or a configuration, input, transport, or decoding error on main.
    /// - Returns: Nothing; errors are delivered to completion.
    /// Example: `client.stopEvents(stop: .atcoCode("6110114")) { result in /* handle result */ }`.
    func stopEvents(stop: JourneoStopIdentifier, eventType: JourneoEventType? = nil,
                    lookaheadMinutes: Int? = nil, maxEvents: Int? = nil,
                    minVisitsPerService: Int? = nil, ordering: JourneoEventOrdering? = nil,
                    timeFormat: JourneoTimeFormat? = nil,
                    completion: @escaping (Result<JourneoStopEvents, Error>) -> Void) {
        fetch(.stopEvents(stop: stop, eventType: eventType, lookaheadMinutes: lookaheadMinutes,
                          maxEvents: maxEvents, minVisitsPerService: minVisitsPerService,
                          ordering: ordering, timeFormat: timeFormat), completion: completion)
    }

    /// Fetches a stop's documented details.
    /// - Parameters:
    ///   - atcoCode: Nonempty ATCO identifier.
    ///   - completion: Receives details or an error on main.
    /// - Returns: Nothing; errors are delivered to completion.
    /// Example: `client.stopDetails(atcoCode: "6110114") { result in /* handle result */ }`.
    func stopDetails(atcoCode: String, completion: @escaping (Result<JourneoStopDetails, Error>) -> Void) {
        fetch(.stopDetails(atcoCode: atcoCode), completion: completion)
    }

    /// Fetches stops with events on a date, validating the documented code-only response when applicable.
    /// FullDetails has no documented response envelope, so valid JSON is returned without inventing a model.
    /// - Parameters:
    ///   - date: Gregorian calendar date in CCYY-MM-DD format.
    ///   - fullDetails: Whether to request full details; omitted uses the service's code-only default.
    ///   - completion: Receives validated JSON data or an error on main.
    /// - Returns: Nothing; errors are delivered to completion.
    /// Example: `client.getStops(date: "2026-10-19") { result in /* handle result */ }`.
    func getStops(date: String, fullDetails: Bool? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        perform(.getStops(date: date, fullDetails: fullDetails), decode: { data in
            if fullDetails == true {
                _ = try JSONSerialization.jsonObject(with: data)
            } else {
                _ = try JSONDecoder().decode(JourneoStopCodes.self, from: data)
            }
            return data
        }, completion: completion)
    }

    /// Fetches stops and vehicles in a nonempty NE/SW bounding box.
    /// - Parameters:
    ///   - northEastLatitude: North latitude in degrees, within -90 to 90.
    ///   - northEastLongitude: East longitude in degrees, within -180 to 180.
    ///   - southWestLatitude: South latitude, strictly below north.
    ///   - southWestLongitude: West longitude, strictly below east; antimeridian boxes are unsupported.
    ///   - completion: Receives area items or an error on main.
    /// - Returns: Nothing; errors are delivered to completion.
    /// Example: `client.areaSearch(northEastLatitude: 55.934, northEastLongitude: -4.046, southWestLatitude: 55.918, southWestLongitude: -4.061) { result in /* handle result */ }`.
    func areaSearch(northEastLatitude: Double, northEastLongitude: Double,
                    southWestLatitude: Double, southWestLongitude: Double,
                    completion: @escaping (Result<JourneoAreaSearch, Error>) -> Void) {
        fetch(.areaSearch(northEastLatitude: northEastLatitude, northEastLongitude: northEastLongitude,
                          southWestLatitude: southWestLatitude, southWestLongitude: southWestLongitude),
              completion: completion)
    }

    /// Fetches the current status of one vehicle.
    /// - Parameters:
    ///   - vehicleID: Nonempty vehicle identifier.
    ///   - timeFormat: UTC or server-local response time.
    ///   - completion: Receives vehicle status or an error on main.
    /// - Returns: Nothing; errors are delivered to completion.
    /// Example: `client.vehicleStatus(vehicleID: "70276") { result in /* handle result */ }`.
    func vehicleStatus(vehicleID: String, timeFormat: JourneoTimeFormat? = nil,
                       completion: @escaping (Result<JourneoVehicleStatus, Error>) -> Void) {
        fetch(.vehicleStatus(vehicleID: vehicleID, timeFormat: timeFormat), completion: completion)
    }

    /// Cancels this client's in-flight requests without cancelling other clients sharing its session.
    /// - Returns: Nothing; cancelled operations retain their main-queue failure completions.
    /// Example: `client.cancel()`.
    func cancel() {
        lock.lock()
        let active = Array(requests.values)
        requests.removeAll()
        lock.unlock()
        active.forEach { $0.cancel() }
    }

    private func fetch<Response: Decodable>(_ operation: JourneoRequest,
                                            completion: @escaping (Result<Response, Error>) -> Void) {
        perform(operation, decode: { try JSONDecoder().decode(Response.self, from: $0) }, completion: completion)
    }

    private func perform<Response>(_ operation: JourneoRequest, decode: @escaping (Data) throws -> Response,
                                   completion: @escaping (Result<Response, Error>) -> Void) {
        let request: URLRequest
        do {
            request = try operation.urlRequest(configuration: configurationProvider())
        } catch {
            DispatchQueue.main.async { completion(.failure(error)) }
            return
        }
        let id = UUID()
        lock.lock()
        let active = session.request(request)
            .redirect(using: Redirector(behavior: .doNotFollow))
            .validate(statusCode: 200..<300)
        requests[id] = active
        lock.unlock()
        active.responseData(queue: .main) { [weak self] response in
            if let self {
                self.lock.lock()
                self.requests.removeValue(forKey: id)
                self.lock.unlock()
            }
            switch response.result {
            case .success(let data): completion(Result { try decode(data) })
            case .failure(let error): completion(.failure(error))
            }
        }
    }
}
