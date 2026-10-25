import SwiftUI

struct MyBusinessView: View {
    @Environment(\.repositories) private var repositories
    @Environment(\.ownedBusinessID) private var businessID
    @State private var business: Business?
    @State private var events: [Event] = []
    @State private var isEditingVenue = false
    @State private var eventDraft: EventDraft?
    @State private var hasLoaded = false
    @State private var loadFailed = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var loadGeneration = 0

    var body: some View {
        NavigationStack {
            Group {
                if let business {
                    dashboard(for: business)
                } else if loadFailed {
                    ContentUnavailableView {
                        Label("Couldn't load your venue", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text("Your changes are safe. Try loading your venue again.")
                    } actions: {
                        Button("Try Again") { Task { await reload() } }
                            .buttonStyle(.borderedProminent)
                    }
                } else if hasLoaded || businessID == nil {
                    ContentUnavailableView(
                        "No business linked", systemImage: "storefront",
                        description: Text("There isn't a venue linked to this device yet."))
                } else {
                    ProgressView("Loading your venue")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
            .navigationTitle("My Business")
            .toolbar {
                if let business {
                    ToolbarItem(placement: .primaryAction) {
                        Button("New Event", systemImage: "plus") {
                            eventDraft = EventDraft(event: .draft(for: business), isNew: true)
                        }
                        .disabled(isDeleting)
                    }
                }
            }
            .sheet(isPresented: $isEditingVenue) {
                if let business {
                    VenueEditor(business: business) { await reload() }
                }
            }
            .sheet(item: $eventDraft) { draft in
                EventEditor(draft: draft) { await reload() }
            }
            .task { await reload() }
            .errorAlert($errorMessage)
        }
    }

    private func dashboard(for business: Business) -> some View {
        List {
            Section {
                Label("Business Preview", systemImage: "storefront")
            } footer: {
                Text("Your changes are saved on this device. Preview events are not published to public discovery.")
            }
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 14) {
                        CategoryIcon(category: business.category, size: 48)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(business.name)
                                .font(.title3.bold())
                                .foregroundStyle(Theme.text)
                            Text(business.category.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(business.category.color)
                        }
                    }
                    if !business.description.isEmpty {
                        Text(business.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    VenueMapPreview(business: business)
                    Label(business.address, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Edit Venue", systemImage: "pencil") {
                        isEditingVenue = true
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .tint(business.category.color)
                    .disabled(isDeleting)
                }
                .padding(.vertical, 6)
            }
            .listRowBackground(Theme.surface)

            Section {
                if events.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Give your neighbors a reason to stop by.")
                            .font(.headline)
                            .foregroundStyle(Theme.text)
                        Text("A workshop, a tasting, or a casual get-together. Your next event starts here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Post an Event", systemImage: "plus") {
                            eventDraft = EventDraft(event: .draft(for: business), isNew: true)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Theme.surface)
                }
                ForEach(events) { event in
                    Button {
                        eventDraft = EventDraft(event: event, isNew: false)
                    } label: {
                        EventRow(event: event, tint: business.category.color)
                    }
                    .buttonStyle(.plain)
                    .disabled(isDeleting)
                    .deleteDisabled(isDeleting)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                }
                .onDelete(perform: deleteEvents)
            } header: {
                HStack {
                    Text("Upcoming events")
                    Spacer()
                    if isDeleting {
                        ProgressView().accessibilityLabel("Deleting event")
                    } else {
                        Text("\(events.count)")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .refreshable { await reload() }
    }

    private func reload() async {
        guard let businessID, !isDeleting else { return }
        loadGeneration += 1
        let generation = loadGeneration
        do {
            // Publish the venue and its events together so a failed request doesn't
            // leave the dashboard showing a mix of new and stale information.
            let loadedBusiness = try await repositories.businesses.business(id: businessID)
            let loadedEvents = try await repositories.events.upcomingEvents(for: businessID)
            try Task.checkCancellation()
            guard generation == loadGeneration else { return }
            business = loadedBusiness
            events = loadedEvents
            hasLoaded = true
            loadFailed = false
        } catch is CancellationError {
            return
        } catch {
            guard generation == loadGeneration else { return }
            if business == nil {
                loadFailed = true
            } else {
                errorMessage = "Couldn't refresh your venue. Pull down to try again."
            }
        }
    }

    private func deleteEvents(at offsets: IndexSet) {
        guard !isDeleting else { return }
        let ids = offsets.compactMap { events.indices.contains($0) ? events[$0].id : nil }
        guard !ids.isEmpty else { return }
        loadGeneration += 1
        isDeleting = true
        Task {
            defer { isDeleting = false }
            var failed = false
            for id in ids {
                do {
                    try await repositories.events.delete(id)
                    events.removeAll { $0.id == id }
                } catch {
                    failed = true
                }
            }
            if failed {
                errorMessage = "Some events couldn't be deleted. They are still in your list. Please try again."
            }
        }
    }
}
