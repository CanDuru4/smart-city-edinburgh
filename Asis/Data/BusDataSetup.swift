//
//  BusDataSetup.swift
//  Asis
//
//  Created by Can Duru on 8.08.2022.
//

import Foundation

//MARK: - BusDataSetup
struct BusDataSetup: Decodable {
    let lastUpdated: Int
    let vehicles: [Vehicle]

    enum CodingKeys: String, CodingKey {
        case lastUpdated = "last_updated"
        case vehicles
    }
}

//MARK: - Vehicle
struct Vehicle: Decodable {
    let vehicleID: String
    let latitude, longitude: Double
    let serviceName, destination: String?

    enum CodingKeys: String, CodingKey {
        case vehicleID = "vehicle_id"
        case latitude = "latitude"
        case longitude = "longitude"
        case serviceName = "service_name"
        case destination
    }
}
