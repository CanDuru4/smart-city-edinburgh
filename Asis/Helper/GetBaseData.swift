//
//  GetData.swift
//  Asis
//
//  Created by Can Duru on 2.08.2022.
//

import Foundation
import Alamofire

class GetBaseData {
    
    fileprivate var baseUrl = "https://tfe-opendata.com/api/v1/"
    typealias basedataCallBack = (_ stops:[Stop]?, _ status: Bool, _ message:String) -> Void
    typealias baseBusdataCallBack = (_ busses:[Vehicle]?, _ status: Bool, _ message:String) -> Void
    
    //MARK: Bus stops
    var callBack:basedataCallBack?
    var callBusBack:baseBusdataCallBack?
    

    //MARK: Bus Stops Data
    func getStopsBaseData(endPoint: String) {
        AF.request(self.baseUrl + endPoint, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil, interceptor: nil).response { (responseData) in
            guard let data = responseData.data else {
                self.callBack?(nil, false, "")
               
                return}
            do {
            let basedata = try JSONDecoder().decode(StopsDataSetup.self, from: data)
                self.callBack?(basedata.stops, true, "")
                
            } catch {
                self.callBack?(nil, false, error.localizedDescription)

            }
        }
    }
    
    
    //MARK: Bus Data
    func getBusBaseData(endPoint: String) {
        AF.request(self.baseUrl + endPoint, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil, interceptor: nil).response { (BusresponseData) in
            guard let data = BusresponseData.data else {
                self.callBusBack?(nil, false, "")
               
                return}
            do {
            let basedata = try JSONDecoder().decode(BusDataSetup.self, from: data)
                self.callBusBack?(basedata.vehicles , true, "")
                
            } catch {
                self.callBusBack?(nil, false, error.localizedDescription)

            }
        }
    }
    
    func completionHandler(callBack: @escaping basedataCallBack) {
        self.callBack = callBack
    }
    
    func busCompletionHandler(callBusBack: @escaping baseBusdataCallBack) {
        self.callBusBack = callBusBack
    }
}
