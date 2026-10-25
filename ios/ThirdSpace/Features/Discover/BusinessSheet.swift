import MapKit
import SwiftUI

struct BusinessSheet: View {
    let business: Business
    @Environment(\.repositories) private var repositories
    @Environment(\.publicEvents) private var publicEvents
    @Environment(\.dismiss) private var dismiss
    @State private var events: [Event]?
    @State private var loadFailed = false
    @State private var loadRevision = 0

    var body: some View {
        NavigationStack {
            List {
                Section {
                    header
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: 0))
                        .listRowBackground(Color.clear)
                }

                Section {
                    VenueMapPreview(business: business)
                        .padding(.vertical, 4)
                        .accessibilityHidden(true)
                    Label(business.address, systemImage: "mappin.and.ellipse")
                        .font(.body)
                        .textSelection(.enabled)
                    Button(action: openDirections) {
                        Label("Get directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                            .frame(minHeight: 28)
                    }
                }

                if !business.description.isEmpty {
                    Section("About") {
                        Text(business.description)
                            .font(.body)
                            .textSelection(.enabled)
                            .padding(.vertical, 4)
                    }
                }

                eventsSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                        .labelStyle(.iconOnly)
                }
            }
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event, business: business)
            }
            .refreshable { await refreshEvents() }
            .task(id: loadKey) { await loadEvents() }
            .onDisappear { loadRevision += 1 }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(business.category.title, systemImage: business.category.symbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(business.category.color)
            Text(business.name)
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private var eventsSection: some View {
        Section("Upcoming events") {
            if hasRefreshFailure {
                VStack(alignment: .leading, spacing: 12) {
                    Label(events == nil ? "Couldn’t load events" : "Couldn’t refresh events",
                          systemImage: "wifi.exclamationmark")
                        .foregroundStyle(.secondary)
                    Button("Try again") { Task { await refreshEvents() } }
                        .buttonStyle(.bordered)
                        .disabled(publicEvents?.isRefreshing == true)
                }
                .padding(.vertical, 4)
            }

            if let events {
                if events.isEmpty {
                    if publicEvents?.isRefreshing == true {
                        loadingEvents
                    } else if !hasRefreshFailure {
                        Label {
                            Text("No upcoming events listed here yet.")
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    ForEach(events) { event in
                        NavigationLink(value: event) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(event.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(event.formatted(event.startTime, using: .dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(event.timeRangeText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                EventTimingLabel(event: event)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            } else if !hasRefreshFailure {
                loadingEvents
            }
        }
    }

    private var loadingEvents: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Loading events…")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var loadKey: VenueEventsLoadKey {
        VenueEventsLoadKey(businessID: business.id, catalogRevision: publicEvents?.revision ?? 0)
    }

    private var hasRefreshFailure: Bool {
        loadFailed || publicEvents?.refreshFailed == true
    }

    private func refreshEvents() async {
        await publicEvents?.refresh(force: true)
        await loadEvents()
    }

    private func loadEvents() async {
        loadRevision += 1
        let revision = loadRevision
        loadFailed = false
        do {
            let loaded = try await repositories.events.upcomingEvents(for: business.id)
            try Task.checkCancellation()
            guard revision == loadRevision else { return }
            events = loaded.sorted { $0.startTime < $1.startTime }
        } catch is CancellationError {
            return
        } catch {
            guard revision == loadRevision else { return }
            loadFailed = true
        }
    }

    private func openDirections() {
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: business.coordinate))
        destination.name = business.name
        destination.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
    }
}

private struct VenueEventsLoadKey: Hashable {
    let businessID: Business.ID
    let catalogRevision: Int
}
