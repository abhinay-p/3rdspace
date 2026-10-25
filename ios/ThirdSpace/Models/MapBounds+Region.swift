import MapKit

extension MapBounds {
    init(region: MKCoordinateRegion) {
        let halfLatitude = region.span.latitudeDelta / 2
        let halfLongitude = region.span.longitudeDelta / 2
        self.init(
            minLatitude: region.center.latitude - halfLatitude,
            maxLatitude: region.center.latitude + halfLatitude,
            minLongitude: region.center.longitude - halfLongitude,
            maxLongitude: region.center.longitude + halfLongitude)
    }
}

extension MKCoordinateRegion {
    static let continentalUS = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.5, longitude: -98.35),
        span: MKCoordinateSpan(latitudeDelta: 28, longitudeDelta: 62))
}
