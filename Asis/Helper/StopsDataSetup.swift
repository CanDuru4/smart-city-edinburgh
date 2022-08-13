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
    var name: String?
    var latitude: Double?
    var longitude: Double?
    var destinations, services: [String]
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case latitude = "latitude"
        case longitude = "longitude"
        case destinations, services

    }
}

