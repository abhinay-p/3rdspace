import MapKit

struct DiscoveryNeighborhood: Identifiable, Hashable {
    let name: String
    let city: String
    let latitude: Double
    let longitude: Double
    let timeZoneID: String

    var id: String { "\(city):\(name)" }
    var region: MKCoordinateRegion {
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                           latitudinalMeters: 3200, longitudinalMeters: 3200)
    }
    static let all: [Self] = [
        .init(name: "Mission District", city: "San Francisco", latitude: 37.7599, longitude: -122.4212, timeZoneID: "America/Los_Angeles"),
        .init(name: "Silver Lake", city: "Los Angeles", latitude: 34.095, longitude: -118.274, timeZoneID: "America/Los_Angeles"),
        .init(name: "Williamsburg", city: "New York", latitude: 40.714, longitude: -73.960, timeZoneID: "America/New_York"),
        .init(name: "Wicker Park", city: "Chicago", latitude: 41.907, longitude: -87.676, timeZoneID: "America/Chicago"),
        .init(name: "South End", city: "Boston", latitude: 42.342, longitude: -71.072, timeZoneID: "America/New_York"),
        .init(name: "Capitol Hill", city: "Seattle", latitude: 47.618, longitude: -122.319, timeZoneID: "America/Los_Angeles"),
        .init(name: "East Austin", city: "Austin", latitude: 30.266, longitude: -97.727, timeZoneID: "America/Chicago"),
    ] + SampleCity.nationwideAdditions.map { city in
        let count = Double(city.places.count)
        return DiscoveryNeighborhood(name: city.name, city: "\(city.name), \(city.state)",
            latitude: city.places.reduce(0) { $0 + $1.latitude } / count,
            longitude: city.places.reduce(0) { $0 + $1.longitude } / count,
            timeZoneID: city.timeZoneID)
    }
}
