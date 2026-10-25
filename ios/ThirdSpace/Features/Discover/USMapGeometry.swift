import MapKit
import SwiftUI

enum USMapArea: String, CaseIterable, Identifiable {
    case mainland = "United States", alaska = "Alaska", hawaii = "Hawaii"
    var id: Self { self }

    var region: MKCoordinateRegion {
        switch self {
        case .mainland: return MKCoordinateRegion(center: .init(latitude: 39, longitude: -97),
                                                  span: .init(latitudeDelta: 29, longitudeDelta: 61))
        case .alaska: return MKCoordinateRegion(center: .init(latitude: 63, longitude: -153),
                                                span: .init(latitudeDelta: 24, longitudeDelta: 80))
        case .hawaii: return MKCoordinateRegion(center: .init(latitude: 20.8, longitude: -157.3),
                                                span: .init(latitudeDelta: 6, longitudeDelta: 9))
        }
    }

    var cameraBounds: MapCameraBounds {
        let region: MKCoordinateRegion
        switch self {
        case .mainland:
            region = .init(center: .init(latitude: 38.5, longitude: -97),
                           span: .init(latitudeDelta: 28, longitudeDelta: 60))
        case .alaska:
            region = .init(center: .init(latitude: 62, longitude: -154),
                           span: .init(latitudeDelta: 24, longitudeDelta: 80))
        case .hawaii:
            region = .init(center: .init(latitude: 20.5, longitude: -157),
                           span: .init(latitudeDelta: 5, longitudeDelta: 9))
        }
        return MapCameraBounds(centerCoordinateBounds: region, minimumDistance: 500,
                               maximumDistance: self == .mainland ? 30_000_000 : (self == .alaska ? 20_000_000 : 5_000_000))
    }

    static func containing(_ coordinate: CLLocationCoordinate2D) -> Self {
        if coordinate.latitude > 50 { return .alaska }
        if coordinate.longitude < -150 { return .hawaii }
        return .mainland
    }
}

enum USMapGeometry {
    // Bundled Census geometry keeps the country mask available without a network request.
    static let polygons: [MKPolygon] = {
        guard let url = Bundle.main.url(forResource: "us-boundary", withExtension: "geojson"),
              let data = try? Data(contentsOf: url),
              let features = try? MKGeoJSONDecoder().decode(data) else { return [] }
        return features.compactMap { $0 as? MKGeoJSONFeature }.flatMap(\.geometry).flatMap { shape -> [MKPolygon] in
            if let polygon = shape as? MKPolygon { return [polygon] }
            if let multi = shape as? MKMultiPolygon { return multi.polygons }
            return []
        }
    }()

    static let outsideMask: MKPolygon = {
        let world = MKMapRect.world
        let points = [
            MKMapPoint(x: world.minX, y: world.minY),
            MKMapPoint(x: world.maxX, y: world.minY),
            MKMapPoint(x: world.maxX, y: world.maxY),
            MKMapPoint(x: world.minX, y: world.maxY)
        ]
        return MKPolygon(points: points, count: points.count, interiorPolygons: polygons)
    }()

    static func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let point = MKMapPoint(coordinate)
        return polygons.contains { polygon in
            guard polygon.boundingMapRect.contains(point) else { return false }
            let path = CGMutablePath()
            addRing(polygon, to: path)
            for interior in polygon.interiorPolygons ?? [] { addRing(interior, to: path) }
            return path.contains(CGPoint(x: point.x, y: point.y), using: .evenOdd)
        }
    }

    private static func addRing(_ polygon: MKPolygon, to path: CGMutablePath) {
        guard polygon.pointCount > 2 else { return }
        let points = polygon.points()
        path.move(to: CGPoint(x: points[0].x, y: points[0].y))
        for index in 1..<polygon.pointCount {
            path.addLine(to: CGPoint(x: points[index].x, y: points[index].y))
        }
        path.closeSubpath()
    }
}
