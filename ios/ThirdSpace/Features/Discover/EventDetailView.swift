import MapKit
import SwiftUI

struct EventDetailView: View {
    let event: Event
    let business: Business
    @Environment(\.savedEventsStore) private var savedEvents
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        List {
            Section {
                header
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: 0))
                    .listRowBackground(Color.clear)
            }

            Section("When") {
                EventInfoRow(
                    symbolName: "calendar",
                    title: event.dateText,
                    detail: event.formatted(event.startTime, using: .dateTime.year()))
                EventInfoRow(
                    symbolName: "clock",
                    title: event.timeRangeText,
                    detail: event.durationText)
                if let capacity = event.capacity {
                    EventInfoRow(
                        symbolName: "person.2",
                        title: "Up to \(capacity) people",
                        detail: "Ask the venue about availability")
                }
            }

            if !event.description.isEmpty {
                Section("About this event") {
                    Text(event.description)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(.vertical, 4)
                }
            }

            Section("Location") {
                venue
                Button(action: openDirections) {
                    Label("Get directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                        .frame(minHeight: 28)
                }
            }

            if let sourceURL = event.sourceURL {
                Section {
                    Link(destination: sourceURL) {
                        HStack(spacing: 12) {
                            Label("View event on \(sourceName)", systemImage: "link")
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.semibold))
                                .accessibilityHidden(true)
                        }
                        .frame(minHeight: 28)
                    }
                } header: {
                    Text("Event source")
                } footer: {
                    Text("Check the organizer’s page for registration, fees, meeting points, and schedule changes.")
                }
            }

            Section {
                Label(isSaved ? "Saved to your plans" : "Make a plan", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } footer: {
                Text("Saving keeps this event on this device. It doesn’t reserve a spot.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Label("Share event", systemImage: "square.and.arrow.up")
                }
                Button {
                    withAnimation(Motion.animation(reduceMotion: reduceMotion)) {
                        savedEvents.toggle(event.id)
                    }
                } label: {
                    Label(isSaved ? "Unsave event" : "Save event", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                        .contentTransition(Motion.reduceMotionRequested(systemPreference: reduceMotion) ? .identity : .symbolEffect(.replace))
                }
                .accessibilityIdentifier("save-event")
                .accessibilityLabel(isSaved ? "Unsave event" : "Save event")
                .accessibilityHint(isSaved ? "Removes this event from Saved" : "Keeps this event in Saved on this device")
            }
        }
        .sensoryFeedback(.selection, trigger: isSaved)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(event.category.title, systemImage: event.category.symbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(event.category.color)

            Text(event.title)
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text(business.name)
                .font(.title3)
                .foregroundStyle(.secondary)
            EventTimingLabel(event: event)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private var venue: some View {
        VStack(alignment: .leading, spacing: 14) {
            VenueMapPreview(business: business)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(business.name)
                    .font(.headline)
                Text(business.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 4)
    }

    private var isSaved: Bool { savedEvents.contains(event.id) }
    private var sourceName: String { event.sourceName ?? "organizer’s website" }

    private var shareText: String {
        """
        \(event.title)
        at \(business.name)
        \(event.formatted(event.startTime, using: .dateTime.weekday(.wide).month(.wide).day().year()))
        \(event.timeRangeText)
        \(business.address)

        \(event.description)

        \(event.sourceURL?.absoluteString ?? "https://maps.apple.com/?ll=\(business.latitude),\(business.longitude)")
        """
    }

    private func openDirections() {
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: business.coordinate))
        destination.name = business.name
        destination.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
    }
}

private struct EventInfoRow: View {
    let symbolName: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Image(systemName: symbolName)
                .font(.body)
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }
}
