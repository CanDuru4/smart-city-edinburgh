import Foundation

/// Coordinate object shown in the StopDetails and VehicleStatus examples.
/// Example: decode the guide's `{"latitude":51.458821,"longitude":0.0}`.
struct JourneoCoordinate: Decodable {
    let latitude: Double
    let longitude: Double
}

/// StopDetails response from section 7.3; no legacy stop contract is implied.
/// Example: `try JSONDecoder().decode(JourneoStopDetails.self, from: data)`.
struct JourneoStopDetails: Decodable {
    let atcoCode: String
    let name: String
    let coordinate: JourneoCoordinate

    private enum CodingKeys: String, CodingKey {
        case atcoCode = "atcocode"
        case name, coordinate
    }
}

/// StopEvents envelope from section 3.3. Times remain wire strings because the guide varies formats.
/// Example: `try JSONDecoder().decode(JourneoStopEvents.self, from: data)`.
struct JourneoStopEvents: Decodable {
    let time: String
    let atcoCode: String
    let name: String
    let events: [Event]

    private enum CodingKeys: String, CodingKey {
        case atcoCode = "atcocode"
        case time, name, events
    }

    /// A documented stop event; real arrival and departure times can be null.
    /// Example: `response.events.first?.destination`.
    struct Event: Decodable {
        let operatorCode: String
        let publicServiceName: String
        let destination: String
        let scheduledArrivalTime: String?
        let scheduledDepartureTime: String?
        let arrivalTime: String?
        let departureTime: String?

        private enum CodingKeys: String, CodingKey {
            case operatorCode = "operator"
            case publicServiceName = "publicservicename"
            case destination
            case scheduledArrivalTime = "schedulearrivaltime"
            case scheduledDepartureTime = "scheduledeparturetime"
            case arrivalTime = "arrivaltime"
            case departureTime = "departuretime"
        }
    }
}

/// VehicleStatus response from section 4.3. IDs are strings, including numeric-looking IDs.
/// Example: `try JSONDecoder().decode(JourneoVehicleStatus.self, from: data)`.
struct JourneoVehicleStatus: Decodable {
    let time: String
    let id: String
    let fleetNumber: String
    let lastUpdate: String
    let status: String
    let coordinate: JourneoCoordinate
    let operatorCode: String
    let publicServiceName: String?
    let delay: Int?
    let block: String?
    let journey: String?

    private enum CodingKeys: String, CodingKey {
        case time, id, status, coordinate, delay, block, journey
        case fleetNumber = "fleetno"
        case lastUpdate = "lastupdate"
        case operatorCode = "operator"
        case publicServiceName = "publicservicename"
    }
}

/// AreaSearch response from sections 5.3; item types stay strings to tolerate future types.
/// Example: `try JSONDecoder().decode(JourneoAreaSearch.self, from: data)`.
struct JourneoAreaSearch: Decodable {
    let items: [Item]

    /// A stop or vehicle in the requested box. Operator fields are absent on stops.
    /// Example: `response.items.first?.name`.
    struct Item: Decodable {
        let type: String
        let id: String
        let name: String
        let options: Options?
        let latitude: Double
        let longitude: Double
        let operatorCode: String?
        let publicServiceName: String?
        let delay: Int?

        private enum CodingKeys: String, CodingKey {
            case type, id, name, options, latitude, longitude, delay
            case operatorCode = "operator"
            case publicServiceName = "publicservicename"
        }
    }

    /// Display metadata from the sample; icon paths are data and are never fetched by this client.
    /// Example: `response.items.first?.options?.icon`.
    struct Options: Decodable {
        let icon: String?
    }
}

/// The documented GetStops response when FullDetails is omitted or false.
/// The full-detail envelope has no example in the guide, so it has no invented model.
/// Example: `try JSONDecoder().decode(JourneoStopCodes.self, from: data)`.
struct JourneoStopCodes: Decodable {
    let atcoCodes: [String]

    private enum CodingKeys: String, CodingKey {
        case atcoCodes = "atcocodes"
    }
}
