//
//  Network.swift
//  Asis
//
//  Created by Can Duru on 4.08.2022.
//

import Foundation
import Alamofire

class Network {
    static let shared = Network()
    var manager = NetworkReachabilityManager(host: "www.apple.com")
    fileprivate var isReachable = false
    
    func startMonitoring(){
        self.manager?.startListening(onQueue: DispatchQueue.main, onUpdatePerforming: { (networkStatus) in
            
            if networkStatus == .reachable(.cellular) || networkStatus == .reachable(.ethernetOrWiFi) {
                self.isReachable = true
            } else {
                self.isReachable = false
            }
        })
    }
    
    func isConnnected() -> Bool {
        return self.isReachable
    }
}
