//
//  GetData.swift
//  Asis
//
//  Created by Can Duru on 2.08.2022.
//

//MARK: Import
import Foundation
import Alamofire

class GetBaseData {

//MARK: Set Up
    fileprivate var baseUrl = "https://tfe-opendata.com/api/v1/"
    typealias basedataCallBack = (_ stops:[Stop]?, _ status: Bool, _ message:String) -> Void
    typealias baseBusdataCallBack = (_ busses:[Vehicle]?, _ status: Bool, _ message:String) -> Void
    typealias baseTimedataCallBack = (_ times:[Trip]?, _ status: Bool, _ message:String) -> Void
    typealias baseServicedataCallBack = (_ times:[Service]?, _ status: Bool, _ message:String) -> Void

    
    
//MARK: Call Back
    var callBack:basedataCallBack?
    var callBusBack:baseBusdataCallBack?
    var callTimeback: baseTimedataCallBack?
    var callServiceback: baseServicedataCallBack?
    
    

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
    
    
    
//MARK: Time Data
    func getTimeBaseData(endPoint: String) {
        AF.request(self.baseUrl + endPoint, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil, interceptor: nil).response { (TimeresponseData) in
            guard let data = TimeresponseData.data else {
                self.callTimeback?(nil, false, "")
                return
            }
            do {
            let basedata = try JSONDecoder().decode(TimetableModel.self, from: data)
                self.callTimeback?(basedata.journeys , true, "")
                
            } catch {
                self.callTimeback?(nil, false, error.localizedDescription)
                print("-------------------------------")
                print(String(describing: error))
                print("-------------------------------")
            }
        }
    }
    
    
    
//MARK: Service Data
    func getServiceData(endPoint: String) {
        AF.request(self.baseUrl + endPoint, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil, interceptor: nil).response { (ServiceresponseData) in
            guard let data = ServiceresponseData.data else {
                self.callServiceback?(nil, false, "")
               
                return}
            do {
            let basedata = try JSONDecoder().decode(ServiceData.self, from: data)
                self.callServiceback?(basedata.services, true, "")
                
            } catch {
                self.callServiceback?(nil, false, error.localizedDescription)
            }
        }
    }
    
    func completionHandler(callBack: @escaping basedataCallBack) {
        self.callBack = callBack
    }
    
    func busCompletionHandler(callBusBack: @escaping baseBusdataCallBack) {
        self.callBusBack = callBusBack
    }
    
    func timeCompletionHandler(callTimeBack: @escaping baseTimedataCallBack) {
        self.callTimeback = callTimeBack
    }
    
    func serviceCompletionHandler(callServiceBack: @escaping baseServicedataCallBack) {
        self.callServiceback = callServiceBack
    }
}
