import CoreLocation

@Observable
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    private(set) var location: CLLocation?
    private(set) var isRequesting = false
    var errorMessage: String?
    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private var timeoutTask: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestAccess() {
        guard !isRequesting else { return }
        isRequesting = true
        errorMessage = nil
        location = nil
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            requestFix()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            fail("Location access is off. You can enable it for 3rdSpace in Settings, or keep exploring the sample neighborhoods.")
        @unknown default:
            fail("Location isn't available right now. Try again, or explore a sample neighborhood.")
        }
    }

    func cancelRequest() {
        isRequesting = false
        timeoutTask?.cancel()
        timeoutTask = nil
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // The delegate also fires during initialization. Only an explicit tap on
        // Use my location should request a fix or display a permission error.
        guard isRequesting else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            requestFix()
        case .denied, .restricted:
            fail("Location access is off. You can enable it for 3rdSpace in Settings, or keep exploring the sample neighborhoods.")
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isRequesting else { return }
        guard let fix = locations.last(where: { $0.horizontalAccuracy >= 0 }) else {
            fail("We couldn't find your location. Try again, or explore a sample neighborhood.")
            return
        }
        timeoutTask?.cancel()
        timeoutTask = nil
        isRequesting = false
        location = fix
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        guard isRequesting else { return }
        fail("We couldn't find your location. Check that Location Services are on, then try again. You can still explore the sample neighborhoods.")
    }

    private func requestFix() {
        timeoutTask?.cancel()
        manager.requestLocation()
        timeoutTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(20))
                guard let self, self.isRequesting else { return }
                self.fail("Finding your location took too long. Try again, or explore a sample neighborhood.")
            } catch {
                // A completed or canceled request no longer needs a timeout.
            }
        }
    }

    private func fail(_ message: String) {
        cancelRequest()
        errorMessage = message
    }
}
