import SwiftUI

struct SavedEventsView: View {
    @Environment(\.repositories) private var repositories
    @Environment(\.publicEvents) private var publicEvents
    @Environment(\.savedEventsStore) private var savedEvents
    @Environment(\.scenePhase) private var scenePhase
    @State private var entries: [SavedEventEntry] = []
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var selectedEntry: SavedEventEntry?
    @State private var loadRevision = 0
    @State private var resolvedIDs: Set<Event.ID>?

    var body: some View {
        NavigationStack {
            Group {
                if savedEvents.ids.isEmpty {
                    ContentUnavailableView(
                        "Something to look forward to",
                        systemImage: "bookmark",
                        description: Text("Save an event while exploring. Your next neighborhood plan will be waiting here."))
                } else if (isLoading || publicEvents?.isRefreshing == true) && visibleEntries.isEmpty {
                    ProgressView("Finding your saved events…")
                } else if loadFailed && visibleEntries.isEmpty {
                    ContentUnavailableView {
                        Label("Couldn't load your plans", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text("Your saved events are still here. Try loading them again.")
                    } actions: {
                        Button("Try again") { Task { await refresh() } }
                            .buttonStyle(.borderedProminent)
                    }
                } else if visibleEntries.isEmpty {
                    ContentUnavailableView {
                        Label(publicEvents == nil ? "A little room for new plans" : "Your saves are still here",
                              systemImage: publicEvents == nil ? "calendar" : "bookmark")
                    } description: {
                        if publicEvents == nil {
                            Text("Your saved events have ended or are no longer available. Discover something new nearby.")
                        } else {
                            Text("These events aren’t in the current listings. They may have ended, or their source may be unavailable. Your saves are kept on this device.")
                        }
                    } actions: {
                        if canClearUnavailableSaves {
                            Button("Clear unavailable saves", action: clearUnavailableSaves)
                                .buttonStyle(.bordered)
                        } else if publicEvents != nil {
                            Button("Refresh events") { Task { await refresh() } }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    savedList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
            .navigationTitle("Saved")
            .navigationDestination(item: $selectedEntry) { entry in
                EventDetailView(event: entry.event, business: entry.business)
            }
            .task(id: loadKey) { await load() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await load() } }
            }
            .onDisappear {
                // Invalidate retry and foreground tasks as well as the view's structured task.
                loadRevision += 1
                isLoading = false
            }
        }
    }

    private var savedList: some View {
        List {
            if loadFailed || publicEvents?.refreshFailed == true {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Couldn’t refresh your plans", systemImage: "wifi.exclamationmark")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Try again") { Task { await refresh() } }
                            .disabled(isLoading || publicEvents?.isRefreshing == true)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                ForEach(visibleEntries) { entry in
                    Button {
                        selectedEntry = entry
                    } label: {
                        SavedEventRow(event: entry.event, business: entry.business)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens event details")
                    .swipeActions {
                        Button("Unsave", systemImage: "bookmark.slash", role: .destructive) {
                            savedEvents.remove(entry.id)
                        }
                    }
                }
            } header: {
                Text("Your next plans")
            } footer: {
                Text("Saved on this device. Saving doesn't reserve a spot. Only upcoming events appear here.")
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await refresh() }
    }

    private var visibleEntries: [SavedEventEntry] {
        entries.filter { savedEvents.contains($0.id) }
    }

    private var loadKey: SavedEventsLoadKey {
        SavedEventsLoadKey(ids: savedEvents.ids, catalogRevision: publicEvents?.revision ?? 0)
    }

    private var canClearUnavailableSaves: Bool {
        // Public calendars contain a window of events, not a complete history.
        // A missing listing must never be treated as proof that a save is invalid.
        publicEvents == nil && !isLoading && !loadFailed && visibleEntries.isEmpty
            && resolvedIDs == savedEvents.ids
    }

    private func clearUnavailableSaves() {
        // Only the complete local repository can establish unavailability.
        guard canClearUnavailableSaves,
              let resolvedIDs, resolvedIDs == savedEvents.ids else { return }
        for eventID in resolvedIDs {
            savedEvents.remove(eventID)
        }
    }

    private func refresh() async {
        await publicEvents?.refresh(force: true)
        await load()
    }

    private func load() async {
        loadRevision += 1
        let revision = loadRevision
        let requestedIDs = savedEvents.ids
        guard !requestedIDs.isEmpty else {
            entries = []
            isLoading = false
            loadFailed = false
            resolvedIDs = []
            return
        }
        isLoading = true
        defer {
            if revision == loadRevision { isLoading = false }
        }
        do {
            let world = MapBounds(minLatitude: -90, maxLatitude: 90, minLongitude: -180, maxLongitude: 180)
            let events = try await repositories.events.upcomingEvents(in: world)
            var loaded: [SavedEventEntry] = []
            var businesses: [Business.ID: Business] = [:]
            for event in events where requestedIDs.contains(event.id) {
                let business: Business?
                if let cached = businesses[event.businessID] {
                    business = cached
                } else {
                    business = try await repositories.businesses.business(id: event.businessID)
                }
                if let business {
                    businesses[business.id] = business
                    loaded.append(SavedEventEntry(event: event, business: business))
                }
            }
            try Task.checkCancellation()
            guard revision == loadRevision, requestedIDs == savedEvents.ids else { return }
            entries = loaded.sorted { $0.event.startTime < $1.event.startTime }
            resolvedIDs = requestedIDs
            loadFailed = false
        } catch is CancellationError {
            return
        } catch {
            guard revision == loadRevision, requestedIDs == savedEvents.ids else { return }
            loadFailed = true
        }
    }
}

private struct SavedEventsLoadKey: Hashable {
    let ids: Set<Event.ID>
    let catalogRevision: Int
}

private struct SavedEventEntry: Identifiable, Hashable {
    let event: Event
    let business: Business
    var id: Event.ID { event.id }
}

private struct SavedEventRow: View {
    let event: Event
    let business: Business

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(business.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label("\(event.formatted(event.startTime, using: .dateTime.weekday(.abbreviated).month(.abbreviated).day())) · \(event.startTimeText)", systemImage: "calendar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                EventTimingLabel(event: event)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
