import MapKit
import SwiftUI

struct VenueMapPreview: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let business: Business
    @State private var position: MapCameraPosition

    init(business: Business) {
        self.business = business
        _position = State(initialValue: Self.position(for: business.coordinate))
    }

    var body: some View {
        Map(position: $position, interactionModes: []) {
            Annotation(business.name, coordinate: business.coordinate, anchor: .bottom) {
                BusinessPin(category: business.category, isSelected: true, hasEventSoon: false)
            }
            .annotationTitles(.hidden)
        }
        .mapStyle(.standard(emphasis: .muted, pointsOfInterest: .excludingAll))
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onChange(of: [business.latitude, business.longitude]) {
            withAnimation(Motion.animation(reduceMotion: reduceMotion)) {
                position = Self.position(for: business.coordinate)
            }
        }
        .accessibilityLabel("Map of \(business.address)")
    }

    private static func position(for coordinate: CLLocationCoordinate2D) -> MapCameraPosition {
        .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500))
    }
}
