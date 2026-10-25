import Foundation
import Testing
@testable import ThirdSpace

struct DiscoveryResultsTests {
    // Noon on a fixed day avoids dependence on the simulator's current date or zone.
    private let now = Date(timeIntervalSince1970: 1_767_614_400)
    private let hour: TimeInterval = 3_600
    private let bounds = MapBounds(minLatitude: 9, maxLatitude: 11, minLongitude: 9, maxLongitude: 11)

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func business(_ name: String, category: Business.Category = .cafe,
                          about: String = "", address: String = "Valencia Street") -> Business {
        Business(id: UUID(), name: name, category: category, description: about,
                 address: address, latitude: 10, longitude: 10)
    }

    private func event(_ title: String, at venue: Business, startingIn hours: Double = 1,
                       lasting duration: TimeInterval = 3_600, about: String = "") -> Event {
        let start = now.addingTimeInterval(hours * hour)
        return Event(id: UUID(), businessID: venue.id, title: title, description: about,
                     category: venue.category, startTime: start,
                     endTime: start.addingTimeInterval(duration), capacity: nil)
    }

    private func query(category: Business.Category? = nil, search: String = "",
                       time: DiscoveryTimeFilter = .anytime) -> DiscoverQuery {
        DiscoverQuery(bounds: bounds, category: category, refresh: 0,
                      searchText: search, timeFilter: time)
    }

    private func results(_ venues: [Business], _ events: [Event],
                         matching query: DiscoverQuery) -> DiscoveryResults {
        DiscoveryResults(businesses: venues, events: events, query: query, now: now, calendar: calendar)
    }

    @Test func combinesCategorySearchAndDateInsteadOfTreatingThemAsAlternatives() {
        let cafe = business("Corner Coffee")
        let studio = business("The Clay Room", category: .artsStudio)
        let today = event("Clay & Coffee", at: cafe)
        let later = event("Clay & Coffee Next Week", at: cafe, startingIn: 48)
        let wrongCategory = event("Clay Workshop", at: studio)
        let unrelated = event("Coffee Tasting", at: cafe)
        let filtered = results([cafe, studio], [later, wrongCategory, unrelated, today],
                               matching: query(category: .cafe, search: "clay", time: .today))

        #expect(filtered.businesses == [cafe])
        #expect(filtered.events == [today])
    }

    @Test func searchIgnoresCaseDiacriticsAndSurroundingWhitespace() {
        let cafe = business("Café Lune")
        let event = event("Morning Meetup", at: cafe)
        let filtered = results([cafe], [event], matching: query(search: "  CAFE LUNE\n"))

        #expect(filtered.businesses == [cafe])
        #expect(filtered.events == [event])
    }

    @Test func searchFindsVenueAddressAndDescription() {
        let cafe = business("Corner Coffee", about: "A quiet neighborhood gathering place", address: "Valencia Street")
        let event = event("Morning Meetup", at: cafe)

        #expect(results([cafe], [event], matching: query(search: "VALENCIA")).businesses == [cafe])
        #expect(results([cafe], [event], matching: query(search: "gathering")).events == [event])
    }

    @Test func matchingEventDescriptionKeepsItsVenueInTheResults() {
        let cafe = business("Corner Coffee")
        let other = business("Other Coffee")
        let target = event("Workshop", at: cafe, about: "Make a ceramic bowl")
        let unrelated = event("Tasting", at: other)
        let filtered = results([cafe, other], [target, unrelated], matching: query(search: "CERAMIC"))

        #expect(filtered.events == [target])
        #expect(filtered.businesses == [cafe])
    }

    @Test func todayIncludesOngoingEventsAndExcludesEndedOrTomorrowEvents() {
        let cafe = business("Corner Coffee")
        let ongoing = event("Overnight gathering", at: cafe, startingIn: -18, lasting: 24 * hour)
        let ended = event("Just ended", at: cafe, startingIn: -1)
        let today = event("Later today", at: cafe, startingIn: 1)
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        let tomorrowHours = tomorrowStart.timeIntervalSince(now) / hour
        let tomorrow = event("At tomorrow's boundary", at: cafe, startingIn: tomorrowHours)
        let filtered = results([cafe], [tomorrow, ended, today, ongoing], matching: query(time: .today))

        #expect(filtered.events == [ongoing, today])
    }

    @Test func nextSevenDaysUsesAnExclusiveUpperBoundaryAndIncludesOngoingEvents() {
        let cafe = business("Corner Coffee")
        let ongoing = event("Still happening", at: cafe, startingIn: -1, lasting: 2 * hour)
        let beforeBoundary = event("In six days", at: cafe, startingIn: 167)
        let atBoundary = event("Exactly seven days away", at: cafe, startingIn: 168)
        let ended = event("Finished", at: cafe, startingIn: -2)
        let filtered = results([cafe], [atBoundary, ended, beforeBoundary, ongoing], matching: query(time: .thisWeek))

        #expect(filtered.events == [ongoing, beforeBoundary])
    }

    @Test func anytimeRetainsVenuesWithoutEventsButDateFiltersDoNot() {
        let cafe = business("Quiet Coffee")
        let venueWithEvent = business("Busy Coffee")
        let upcoming = event("Meetup", at: venueWithEvent)

        #expect(results([cafe, venueWithEvent], [upcoming], matching: query()).businesses.count == 2)
        #expect(results([cafe, venueWithEvent], [upcoming], matching: query(time: .today)).businesses == [venueWithEvent])
    }

    @Test func ignoresEventsWhoseVenueIsNotInTheVisibleResults() {
        let visible = business("Visible Coffee")
        let outside = business("Outside Coffee")
        let orphan = event("Outside event", at: outside)
        let filtered = results([visible], [orphan], matching: query())

        #expect(filtered.businesses == [visible])
        #expect(filtered.events.isEmpty)
    }

    @Test func sortsEventsChronologicallyAndUsesTitlesToBreakTies() {
        let cafe = business("Corner Coffee")
        let later = event("Later", at: cafe, startingIn: 3)
        let alpha = event("Alpha", at: cafe)
        let zulu = event("Zulu", at: cafe)
        let filtered = results([cafe], [later, zulu, alpha], matching: query())

        #expect(filtered.events == [alpha, zulu, later])
    }

    @Test func todayUsesTheSuppliedNeighborhoodCalendar() {
        let cafe = business("Corner Coffee")
        // In New York this event is tomorrow; in Los Angeles it is still today.
        let lateNight = Date(timeIntervalSince1970: 1_767_673_800)
        var newYork = calendar
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        var losAngeles = calendar
        losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let afterNewYorkMidnight = Event(
            id: UUID(), businessID: cafe.id, title: "After midnight", description: "", category: .cafe,
            startTime: lateNight.addingTimeInterval(3_600),
            endTime: lateNight.addingTimeInterval(7_200), capacity: nil)

        #expect(!DiscoveryTimeFilter.today.includes(afterNewYorkMidnight, now: lateNight, calendar: newYork))
        #expect(DiscoveryTimeFilter.today.includes(afterNewYorkMidnight, now: lateNight, calendar: losAngeles))
    }

    @Test func sampleNeighborhoodsHaveUniqueNamesAndValidTimeZones() {
        let neighborhoods = DiscoveryNeighborhood.all
        #expect(neighborhoods.count == 52)
        #expect(Set(neighborhoods.map(\.id)).count == neighborhoods.count)
        #expect(neighborhoods.allSatisfy { TimeZone(identifier: $0.timeZoneID) != nil })
        for neighborhood in neighborhoods {
            let region = MapBounds(region: neighborhood.region)
            #expect(region.contains(latitude: neighborhood.latitude, longitude: neighborhood.longitude))
        }
    }
}
