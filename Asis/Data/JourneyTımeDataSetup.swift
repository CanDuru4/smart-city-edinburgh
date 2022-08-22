//
//  JourneyTımeDataSetup.swift
//  Asis
//
//  Created by Can Duru on 16.08.2022.
//

import Foundation
import MapKit

struct TimetableModel: Decodable {
    let startStopID, finishStopID, date, duration: Int
    let journeys: [Trip]

    enum CodingKeys: String, CodingKey {
        case startStopID = "start_stop_id"
        case finishStopID = "finish_stop_id"
        case date, duration, journeys
    }
}

struct Trip: Decodable {
    let serviceName, destination: String
    let departures: [Departure]
    
    enum CodingKeys: String, CodingKey {
        case serviceName = "service_name"
        case destination, departures
    }
}

struct Departure: Decodable {
    let stopID: Int
    let name, time: String
    let timingPoint: Bool

    enum CodingKeys: String, CodingKey {
        case stopID = "stop_id"
        case name, time
        case timingPoint = "timing_point"
    }
}
