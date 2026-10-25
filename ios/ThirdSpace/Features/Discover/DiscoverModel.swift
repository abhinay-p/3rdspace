import Foundation

struct DiscoverQuery: Equatable {
    var bounds: MapBounds
    var category: Business.Category?
    var refresh: Int
    var searchText = ""
    var timeFilter: DiscoveryTimeFilter = .anytime
    var timeZoneID: String? = nil
    var usesVenueTimeZones = false
}

enum DiscoveryTimeFilter: String, CaseIterable, Identifiable {
    case anytime = "Anytime", today = "Today", thisWeek = "Next 7 days"
    var id: Self { self }

    func includes(_ event: Event, now: Date, calendar: Calendar) -> Bool {
        guard event.endTime > now else { return false }
        switch self {
        case .anytime: return true
        case .today:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
            return event.startTime < tomorrow
        case .thisWeek:
            return event.startTime < now.addingTimeInterval(7 * 24 * 60 * 60)
        }
    }
}

struct DiscoveryResults {
    let businesses: [Business]
    let events: [Event]

    init(businesses: [Business], events: [Event], query: DiscoverQuery,
         now: Date = .now, calendar: Calendar = .current) {
        var calendar = calendar
        if let id = query.timeZoneID, let timeZone = TimeZone(identifier: id) {
            calendar.timeZone = timeZone
        }
        let term = query.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        func matches(_ strings: String...) -> Bool {
            term.isEmpty || strings.contains { $0.localizedStandardContains(term) }
        }
        let eligibleBusinesses = businesses.filter { query.category == nil || $0.category == query.category }
        let matchingBusinessIDs = Set(eligibleBusinesses.filter {
            matches($0.name, $0.description, $0.address, $0.category.title)
        }.map(\.id))
        let businessIDs = Set(eligibleBusinesses.map(\.id))
        self.events = events.filter {
            businessIDs.contains($0.businessID)
                && query.timeFilter.includes($0, now: now, calendar: query.usesVenueTimeZones ? Self.venueCalendar(for: $0, base: calendar) : calendar)
                && (matchingBusinessIDs.contains($0.businessID) || matches($0.title, $0.description))
        }.sorted { $0.startTime == $1.startTime ? $0.title < $1.title : $0.startTime < $1.startTime }
        let eventBusinessIDs = Set(self.events.map(\.businessID))
        self.businesses = eligibleBusinesses.filter {
            (matchingBusinessIDs.contains($0.id) || eventBusinessIDs.contains($0.id))
                && (query.timeFilter == .anytime || eventBusinessIDs.contains($0.id))
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private static func venueCalendar(for event: Event, base: Calendar) -> Calendar {
        var calendar = base
        calendar.timeZone = event.displayTimeZone
        return calendar
    }
}

@Observable
final class DiscoverModel {
    private(set) var businesses: [Business] = []
    private(set) var events: [Event] = []
    private(set) var businessIDsWithEventsSoon: Set<Business.ID> = []
    private(set) var hasLoaded = false
    private(set) var loadFailed = false
    private(set) var isLoading = false
    private var requestID = 0

    func load(_ query: DiscoverQuery, from repositories: Repositories) async {
        requestID += 1
        let request = requestID
        isLoading = true
        do {
            let businesses = try await repositories.businesses.businesses(in: query.bounds, category: nil)
            let events = try await repositories.events.upcomingEvents(in: query.bounds)
            try Task.checkCancellation()
            guard request == requestID else { return }
            let results = DiscoveryResults(businesses: businesses, events: events, query: query)
            self.businesses = results.businesses
            self.events = results.events
            businessIDsWithEventsSoon = Set(results.events.filter {
                $0.isHappening(within: 7 * 24 * 60 * 60, from: .now)
            }.map(\.businessID))
            loadFailed = false
            hasLoaded = true
            isLoading = false
        } catch {
            guard request == requestID else { return }
            isLoading = false
            if !(error is CancellationError) { loadFailed = true }
        }
    }
}
