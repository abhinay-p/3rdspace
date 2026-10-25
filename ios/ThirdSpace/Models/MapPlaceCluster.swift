import MapKit

/// A deterministic geographic grid keeps nationwide maps readable without changing
/// the underlying inventory. Neighborhood maps retain individual venue pins.
nonisolated struct MapPlaceCluster: Identifiable {
    let id: String
    let businesses: [Business]
    let latitude: Double
    let longitude: Double

    /// Fit every member, even when most places sit near one edge of the cell.
    /// The mean remains the annotation coordinate; the camera uses the bounds' center.
    var zoomRegion: MKCoordinateRegion {
        let latitudes = businesses.map(\.latitude)
        let longitudes = businesses.map(\.longitude)
        let minLatitude = latitudes.min() ?? latitude
        let maxLatitude = latitudes.max() ?? latitude
        let minLongitude = longitudes.min() ?? longitude
        let maxLongitude = longitudes.max() ?? longitude
        return MKCoordinateRegion(
            center: .init(latitude: (minLatitude + maxLatitude) / 2,
                          longitude: (minLongitude + maxLongitude) / 2),
            span: .init(latitudeDelta: max(maxLatitude - minLatitude, 0.008) * 1.4,
                        longitudeDelta: max(maxLongitude - minLongitude, 0.008) * 1.4))
    }

    private init(id: String, businesses: [Business]) {
        self.id = id
        self.businesses = businesses.sorted { $0.id.uuidString < $1.id.uuidString }
        latitude = self.businesses.reduce(0) { $0 + $1.latitude } / Double(self.businesses.count)
        longitude = self.businesses.reduce(0) { $0 + $1.longitude } / Double(self.businesses.count)
    }

    static func make(businesses: [Business], latitudeDelta: Double) -> [Self] {
        // Invalid camera spans must never reach the logarithm or integer conversion.
        // Small result sets are already readable without combining their pins.
        guard businesses.count > 24, latitudeDelta.isFinite, latitudeDelta >= 0.12 else {
            return businesses.map(single).sorted { $0.id < $1.id }
        }

        // Powers of two prevent every small zoom change from moving the grid.
        // At a mainland overview, an 8-degree cell creates roughly 50 US groups.
        let exponent = Int(ceil(log2(min(latitudeDelta, 180) / 6)))
        let cellSize = pow(2, Double(exponent))
        var buckets: [String: [Business]] = [:]
        var singles: [Self] = []
        for business in businesses {
            guard business.latitude.isFinite, business.longitude.isFinite,
                  (-90...90).contains(business.latitude), (-180...180).contains(business.longitude) else {
                // Preserve the record without attempting an unsafe grid conversion.
                singles.append(single(business))
                continue
            }
            let row = Int(floor((business.latitude + 90) / cellSize))
            let column = Int(floor((business.longitude + 180) / cellSize))
            let key = "grid:\(exponent):\(row):\(column)"
            buckets[key, default: []].append(business)
        }

        let groups = buckets.map { key, members in
            members.count == 1 ? single(members[0]) : Self(id: key, businesses: members)
        }
        return (groups + singles).sorted { $0.id < $1.id }
    }

    private static func single(_ business: Business) -> Self {
        Self(id: "place:\(business.id.uuidString.lowercased())", businesses: [business])
    }
}
