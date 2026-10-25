import MapKit
import Testing
@testable import ThirdSpace

struct MapBoundsTests {
    @Test func regionBecomesBoundsAroundItsCenter() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 10, longitude: 20),
            span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 4))

        #expect(MapBounds(region: region) == MapBounds(minLatitude: 9, maxLatitude: 11, minLongitude: 18, maxLongitude: 22))
    }

    @Test func containsPointsInsideAndOnTheEdge() {
        let bounds = MapBounds(minLatitude: 9, maxLatitude: 11, minLongitude: 18, maxLongitude: 22)

        #expect(bounds.contains(latitude: 10, longitude: 20))
        #expect(bounds.contains(latitude: 11, longitude: 22))
        #expect(!bounds.contains(latitude: 12, longitude: 20))
    }

    @Test func alaskaBoundsIncludeAleutiansAcrossTheDateLine() {
        let bounds = MapBounds(region: USMapArea.alaska.region)
        #expect(bounds.contains(latitude: 52.9, longitude: 173.2))
        #expect(bounds.contains(latitude: 51.9, longitude: -176.6))
        #expect(bounds.contains(latitude: 61.2, longitude: -149.9))
        #expect(!bounds.contains(latitude: 60, longitude: 100))
    }

    @Test func explicitWrappedBoundsAndWorldHaveConsistentEdges() {
        let bounds = MapBounds(minLatitude: -10, maxLatitude: 10, minLongitude: 170, maxLongitude: -170)
        #expect(bounds.contains(latitude: 0, longitude: 179))
        #expect(bounds.contains(latitude: 0, longitude: -179))
        #expect(!bounds.contains(latitude: 0, longitude: 0))
        let world = MapBounds(minLatitude: -90, maxLatitude: 90, minLongitude: -180, maxLongitude: 180)
        #expect(world.contains(latitude: 0, longitude: 180))
        #expect(world.contains(latitude: 0, longitude: -180))
        #expect(!world.contains(latitude: 0, longitude: .nan))
    }
}
