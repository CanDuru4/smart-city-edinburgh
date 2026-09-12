import CoreLocation

/// Delivers one location result to every pending caller on the main queue.
///
/// Shared requests prevent one screen from replacing another screen's callback.
/// Example: `LocationManager.shared.getUserLocation(onError: handleError) { location in }`.
final class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let manager = CLLocationManager()
    private var pending: [(Result<CLLocation, Error>) -> Void] = []
    private var timeout: DispatchWorkItem?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Requests foreground location and finishes on denial, failure, or timeout.
    /// - Parameters:
    ///   - onError: Called once if location cannot be obtained.
    ///   - completion: Called once with the latest valid location.
    /// - Returns: Nothing. Errors are delivered through `onError` instead of thrown.
    func getUserLocation(onError: @escaping (Error) -> Void = { _ in }, completion: @escaping (CLLocation) -> Void) {
        DispatchQueue.main.async { [self] in
            self.pending.append { result in
                switch result {
                case .success(let location): completion(location)
                case .failure(let error): onError(error)
                }
            }
            guard self.pending.count == 1 else { return }
            let timeout = DispatchWorkItem { [weak self] in
                self?.finish(.failure(CLError(.locationUnknown)))
            }
            self.timeout = timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: timeout)
            self.requestIfAuthorized()
        }
    }

    private func requestIfAuthorized() {
        guard !pending.isEmpty else { return }
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: manager.requestLocation()
        case .denied, .restricted: finish(.failure(CLError(.denied)))
        @unknown default: finish(.failure(CLError(.denied)))
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestIfAuthorized()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last(where: { $0.horizontalAccuracy >= 0 && abs($0.timestamp.timeIntervalSinceNow) < 60 }) else {
            finish(.failure(CLError(.locationUnknown)))
            return
        }
        finish(.success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(.failure(error))
    }

    private func finish(_ result: Result<CLLocation, Error>) {
        timeout?.cancel()
        timeout = nil
        manager.stopUpdatingLocation()
        let callbacks = pending
        pending.removeAll()
        callbacks.forEach { $0(result) }
    }
}
            
