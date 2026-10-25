import Foundation
import Testing
@testable import ThirdSpace

struct SampleRepositoryTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let bounds = MapBounds(minLatitude: 9, maxLatitude: 11, minLongitude: 9, maxLongitude: 11)

    private func makeBusiness(_ name: String, _ category: Business.Category, _ latitude: Double, _ longitude: Double) -> Business {
        Business(
            id: UUID(), name: name, category: category, description: "",
            address: "", latitude: latitude, longitude: longitude)
    }

    private func makeEvent(for business: Business, startingIn hours: Double) -> Event {
        let start = now.addingTimeInterval(hours * 3600)
        return Event(
            id: UUID(), businessID: business.id, title: "", description: "",
            category: business.category, startTime: start,
            endTime: start.addingTimeInterval(3600), capacity: nil)
    }

    private func makeRepository(businesses: [Business], events: [Event] = []) -> SampleRepository {
        let now = now
        return SampleRepository(data: SampleData(businesses: businesses, events: events), now: { now })
    }

    @Test func filtersBusinessesByBoundsAndCategory() async throws {
        let cafe = makeBusiness("Cafe", .cafe, 10, 10)
        let bar = makeBusiness("Bar", .bar, 10.5, 10.5)
        let farAway = makeBusiness("Far Away", .cafe, 50, 50)
        let repository = makeRepository(businesses: [cafe, bar, farAway])

        #expect(try await repository.businesses(in: bounds, category: nil) == [bar, cafe])
        #expect(try await repository.businesses(in: bounds, category: .cafe) == [cafe])
    }

    @Test func findsBusinessByID() async throws {
        let cafe = makeBusiness("Cafe", .cafe, 10, 10)
        let repository = makeRepository(businesses: [cafe])

        #expect(try await repository.business(id: cafe.id) == cafe)
        #expect(try await repository.business(id: UUID()) == nil)
    }

    @Test func upcomingEventsInBoundsOnlyIncludeVisibleBusinesses() async throws {
        let nearby = makeBusiness("Nearby", .cafe, 10, 10)
        let farAway = makeBusiness("Far Away", .bar, 50, 50)
        let nearbyEvent = makeEvent(for: nearby, startingIn: 2)
        let farAwayEvent = makeEvent(for: farAway, startingIn: 1)
        let endedEvent = makeEvent(for: nearby, startingIn: -3)
        let repository = makeRepository(
            businesses: [nearby, farAway], events: [nearbyEvent, farAwayEvent, endedEvent])

        #expect(try await repository.upcomingEvents(in: bounds) == [nearbyEvent])
    }

    @Test func upcomingEventsSkipEndedEventsAndSortByStart() async throws {
        let cafe = makeBusiness("Cafe", .cafe, 10, 10)
        let ended = makeEvent(for: cafe, startingIn: -3)
        let inProgress = makeEvent(for: cafe, startingIn: -0.5)
        let soon = makeEvent(for: cafe, startingIn: 2)
        let later = makeEvent(for: cafe, startingIn: 48)
        let repository = makeRepository(businesses: [cafe], events: [later, ended, soon, inProgress])

        #expect(try await repository.upcomingEvents(for: cafe.id) == [inProgress, soon, later])
    }

    @Test func saveUpdatesExistingRecordsAndDeleteRemovesEvents() async throws {
        var cafe = makeBusiness("Cafe", .cafe, 10, 10)
        var event = makeEvent(for: cafe, startingIn: 2)
        let repository = makeRepository(businesses: [cafe], events: [event])

        cafe.name = "Renamed Cafe"
        event.title = "Renamed Event"
        _ = try await repository.save(cafe)
        _ = try await repository.save(event)
        #expect(try await repository.businesses(in: bounds, category: nil) == [cafe])
        #expect(try await repository.upcomingEvents(for: cafe.id) == [event])

        try await repository.delete(event.id)
        #expect(try await repository.upcomingEvents(for: cafe.id).isEmpty)
    }
}
