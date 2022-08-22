//
//  ServiceData.swift
//  Asis
//
//  Created by Can Duru on 19.08.2022.
//

import Foundation

// MARK: - ServiceData
struct ServiceData: Codable {
    let lastUpdated: Int
    let services: [Service]

    enum CodingKeys: String, CodingKey {
        case lastUpdated = "last_updated"
        case services
    }
}

// MARK: - Service
struct Service: Codable {
    let name, serviceDescription: String
    let routes: [Route]

    enum CodingKeys: String, CodingKey {
        case name
        case serviceDescription = "description"
        case routes
    }
}

// MARK: - Route
struct Route: Codable {
    let destination: String
    let points: [Point]
    let stops: [String]
}

// MARK: - Point
struct Point: Codable {
    let stopID: String?
    let latitude, longitude: Double

    enum CodingKeys: String, CodingKey {
        case stopID = "stop_id"
        case latitude, longitude
    }
}
