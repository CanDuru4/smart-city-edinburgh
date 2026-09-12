import Foundation
import Alamofire

/// Fetches Transport for Edinburgh data with bounded, validated requests.
///
/// Register a completion before calling a getter. Every request completes on the main
/// queue, including transport, HTTP, and decoding failures.
/// Example: `getStopsBaseData(endPoint: "stops")`.
final class GetBaseData {
    typealias basedataCallBack = ([Stop]?, Bool, String) -> Void
    typealias baseBusdataCallBack = ([Vehicle]?, Bool, String) -> Void
    typealias baseTimedataCallBack = ([Trip]?, Bool, String) -> Void
    typealias baseServicedataCallBack = ([Service]?, Bool, String) -> Void

    private let baseURL: URL?
    private let session: Session
    private var request: DataRequest?

    /// Creates a client with an optional session for deterministic network testing.
    /// - Parameters:
    ///   - baseURL: HTTPS API root. Defaults to the app's TransitAPIBaseURL setting.
    ///   - session: Alamofire session used for requests.
    /// - Returns: A client. Does not throw; invalid URLs fail through request completions.
    /// - Example: `GetBaseData(baseURL: URL(string: "https://example.com/api/v1/"))`.
    init(baseURL: URL? = (Bundle.main.object(forInfoDictionaryKey: "TransitAPIBaseURL") as? String).flatMap(URL.init(string:)), session: Session = AF) {
        self.baseURL = baseURL
        self.session = session
    }

    /// Cancels the active request while preserving its failure completion.
    /// - Returns: Nothing. Does not throw. Call when abandoning a journey search.
    func cancel() {
        request?.cancel()
        request = nil
    }

    private var callBack: basedataCallBack?
    private var callBusBack: baseBusdataCallBack?
    private var callTimeback: baseTimedataCallBack?
    private var callServiceback: baseServicedataCallBack?

    func getStopsBaseData(endPoint: String) {
        fetch(StopsDataSetup.self, endpoint: endPoint) { result in
            switch result {
            case .success(let data): self.callBack?(data.stops.filter(\.hasValidCoordinate), true, "")
            case .failure(let error): self.callBack?(nil, false, error.localizedDescription)
            }
        }
    }

    func getBusBaseData(endPoint: String) {
        fetch(BusDataSetup.self, endpoint: endPoint) { result in
            switch result {
            case .success(let data):
                self.callBusBack?(data.vehicles.filter { (-90...90).contains($0.latitude) && (-180...180).contains($0.longitude) }, true, "")
            case .failure(let error): self.callBusBack?(nil, false, error.localizedDescription)
            }
        }
    }

    func getTimeBaseData(endPoint: String) {
        fetch(TimetableModel.self, endpoint: endPoint) { result in
            switch result {
            case .success(let data): self.callTimeback?(data.journeys, true, "")
            case .failure(let error): self.callTimeback?(nil, false, error.localizedDescription)
            }
        }
    }

    func getServiceData(endPoint: String) {
        fetch(ServiceData.self, endpoint: endPoint) { result in
            switch result {
            case .success(let data): self.callServiceback?(data.services, true, "")
            case .failure(let error): self.callServiceback?(nil, false, error.localizedDescription)
            }
        }
    }

    private func fetch<T: Decodable>(_ type: T.Type, endpoint: String, completion: @escaping (Result<T, Error>) -> Void) {
        guard let baseURL, baseURL.scheme == "https",
              let url = URL(string: endpoint, relativeTo: baseURL)?.absoluteURL,
              url.host == baseURL.host, url.scheme == "https" else {
            DispatchQueue.main.async { completion(.failure(URLError(.badURL))) }
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        self.request = session.request(request).validate(statusCode: 200..<300).responseData { [weak self] response in
            self?.request = nil
            switch response.result {
            case .success(let data):
                completion(Result { try JSONDecoder().decode(T.self, from: data) })
            case .failure(let error): completion(.failure(error))
            }
        }
    }

    func completionHandler(callBack: @escaping basedataCallBack) { self.callBack = callBack }
    func busCompletionHandler(callBusBack: @escaping baseBusdataCallBack) { self.callBusBack = callBusBack }
    func timeCompletionHandler(callTimeBack: @escaping baseTimedataCallBack) { self.callTimeback = callTimeBack }
    func serviceCompletionHandler(callServiceBack: @escaping baseServicedataCallBack) { self.callServiceback = callServiceBack }
}
