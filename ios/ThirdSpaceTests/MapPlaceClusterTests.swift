import Foundation
import Testing
@testable import ThirdSpace

struct MapPlaceClusterTests {
    private func business(_ index: Int, latitude: Double, longitude: Double) -> Business {
        let suffix = String(format: "%012d", index)
        return Business(id: UUID(uuidString: "00000000-0000-0000-0000-\(suffix)")!,
                        name: "Place \(index)", category: .communitySpace, description: "", address: "",
                        latitude: latitude, longitude: longitude)
    }

    private var places: [Business] {
        (0..<30).map { index in
            // Two separated groups that are each close enough to share a wide cell.
            business(index, latitude: index < 15 ? 37.1 : 41.1,
                     longitude: (index < 15 ? -122.2 : -74.2) + Double(index % 15) * 0.001)
        }
    }

    @Test func combinesNearbyPlacesAndKeepsDistantCitiesSeparate() {
        let clusters = MapPlaceCluster.make(businesses: places, latitudeDelta: 29)

        #expect(clusters.count == 2)
        #expect(clusters.allSatisfy { $0.businesses.count == 15 })
        let west = clusters.first { $0.longitude < -100 }!
        #expect(abs(west.latitude - 37.1) < 0.000001)
        #expect(abs(west.longitude - (-122.193)) < 0.000001)
    }

    @Test func preservesEveryBusinessExactlyOnce() {
        let clusters = MapPlaceCluster.make(businesses: places, latitudeDelta: 29)
        let members = clusters.flatMap(\.businesses)

        #expect(members.count == places.count)
        #expect(Set(members.map(\.id)) == Set(places.map(\.id)))
        #expect(Set(members.map(\.id)).count == members.count)
    }

    @Test func zoomRegionIncludesOutlyingMemberOfASkewedCluster() throws {
        let skewed = (0..<30).map { index in
            business(index, latitude: index == 29 ? 37.9 : 30.1,
                     longitude: index == 29 ? -108.1 : -115.9)
        }
        let clusters = MapPlaceCluster.make(businesses: skewed, latitudeDelta: 29)
        #expect(clusters.count == 1)
        let cluster = try #require(clusters.first)
        let bounds = MapBounds(region: cluster.zoomRegion)

        #expect(cluster.businesses.count == 30)
        #expect(skewed.allSatisfy { bounds.contains(latitude: $0.latitude, longitude: $0.longitude) })
    }

    @Test func reorderingInputDoesNotChangeClusterIdentityOrMemberOrder() {
        let forward = MapPlaceCluster.make(businesses: places, latitudeDelta: 29)
        let reverse = MapPlaceCluster.make(businesses: Array(places.reversed()), latitudeDelta: 29)

        #expect(forward.map(\.id) == reverse.map(\.id))
        #expect(forward.map { $0.businesses.map(\.id) } == reverse.map { $0.businesses.map(\.id) })
        #expect(forward.map(\.latitude) == reverse.map(\.latitude))
        #expect(forward.map(\.longitude) == reverse.map(\.longitude))
    }

    @Test func neighborhoodZoomRestoresIndividualPinsWithStableIDs() {
        let wide = MapPlaceCluster.make(businesses: places, latitudeDelta: 29)
        let near = MapPlaceCluster.make(businesses: places, latitudeDelta: 0.05)
        let nearer = MapPlaceCluster.make(businesses: Array(places.reversed()), latitudeDelta: 0.01)

        #expect(near.count > wide.count)
        #expect(near.count == places.count)
        #expect(near.allSatisfy { $0.businesses.count == 1 })
        #expect(near.map(\.id) == nearer.map(\.id))
    }

    @Test func smallResultSetsDoNotHideIndividualPlaces() {
        let small = Array(places.prefix(10))
        let clusters = MapPlaceCluster.make(businesses: small, latitudeDelta: 100)

        #expect(clusters.count == small.count)
        #expect(clusters.allSatisfy { $0.businesses.count == 1 })
    }

    @Test func invalidSpansAndEmptyInventoryRemainSafe() {
        for span in [0.0, -1, Double.nan, Double.infinity, -Double.infinity] {
            let clusters = MapPlaceCluster.make(businesses: places, latitudeDelta: span)
            #expect(clusters.count == places.count)
            #expect(clusters.allSatisfy { $0.businesses.count == 1 })
        }
        #expect(MapPlaceCluster.make(businesses: [], latitudeDelta: 29).isEmpty)
    }

    @Test func nationwideDensityHasFarFewerPinsAtOverviewZoom() {
        let nationwide = (0..<775).map { index in
            business(index, latitude: 25 + Double(index % 24),
                     longitude: -124 + Double(((index / 24) * 7) % 60))
        }
        let clusters = MapPlaceCluster.make(businesses: nationwide, latitudeDelta: 29)

        #expect(clusters.count <= 100)
        #expect(clusters.flatMap(\.businesses).count == nationwide.count)
    }
}
