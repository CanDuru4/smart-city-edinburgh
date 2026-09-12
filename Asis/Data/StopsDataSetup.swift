//
//  StopNames.swift
//  Asis
//
//  Created by Can Duru on 2.08.2022.
//

import Foundation

struct StopsDataSetup: Decodable {
    let lastUpdated: Int
    let stops: [Stop]

    enum CodingKeys: String, CodingKey {
        case lastUpdated = "last_updated"
        case stops
    }
}

struct Stop: Decodable {
    var stopID: Int
    var name: String?
    var latitude: Double?
    var longitude: Double?
    var destinations, services: [String]

    /// Indicates whether this stop can be placed on a map without inventing coordinates.
    var hasValidCoordinate: Bool {
        guard let latitude, let longitude else { return false }
        return (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case stopID = "stop_id"
        case name = "name"
        case latitude = "latitude"
        case longitude = "longitude"
        case destinations, services

    }
}
