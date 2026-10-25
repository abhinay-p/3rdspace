import SwiftUI

enum DiscoveryAreaSelection {
    case region(USMapArea)
    case city(DiscoveryNeighborhood)
    case currentLocation
}

struct DiscoveryAreaPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    let onSelect: (DiscoveryAreaSelection) -> Void

    var body: some View {
        NavigationStack {
            List {
                if search.isEmpty {
                    Section {
                        Button("Use Current Location", systemImage: "location.fill") {
                            select(.currentLocation)
                        }
                    }
                    Section("United States") {
                        ForEach(USMapArea.allCases) { area in
                            Button(area.rawValue) { select(.region(area)) }
                                .foregroundStyle(Theme.text)
                        }
                    }
                }
                Section("Cities") {
                    ForEach(cities) { place in
                        Button { select(.city(place)) } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(place.name).foregroundStyle(Theme.text)
                                Text(place.city).font(.caption).foregroundStyle(Color.secondary)
                            }.padding(.vertical, 3)
                        }
                    }
                    if cities.isEmpty {
                        Text("No matching cities").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Choose Area")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Search cities")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var cities: [DiscoveryNeighborhood] {
        DiscoveryNeighborhood.all.filter {
            search.isEmpty || $0.name.localizedStandardContains(search) || $0.city.localizedStandardContains(search)
        }.sorted { $0.city.localizedStandardCompare($1.city) == .orderedAscending }
    }

    private func select(_ selection: DiscoveryAreaSelection) {
        onSelect(selection)
        dismiss()
    }
}

struct PublicEventSourcesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.publicEvents) private var publicEvents

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Events are published by public organizers. Open the original listing for meeting points, registration, fees, and changes.")
                }
                Section("Calendars") {
                    Link("National Park Service", destination: URL(string: "https://www.nps.gov/planyourvisit/event-search.htm")!)
                    Link("Library of Congress", destination: URL(string: "https://www.loc.gov/events/")!)
                }
                Section("Latest listings") {
                    if let date = publicEvents?.lastUpdated {
                        LabeledContent("Saved on") {
                            Text(date, format: .dateTime.month().day().year()).foregroundStyle(.secondary)
                        }
                    }
                    Text("Coverage varies by location. A place without listings may still host events. Saved listings remain available when a refresh cannot finish.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("About These Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
