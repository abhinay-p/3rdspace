import Foundation
import Testing
@testable import ThirdSpace

@MainActor
struct PublicEventRepositoryTests {
    private let now = ISO8601DateFormatter().date(from: "2026-10-25T12:00:00Z")!

    @Test func cachedListingsKeepTheirOriginalCheckedDateAndFilterEndedEvents() async throws {
        let business = Business(id: UUID(), name: "Publisher venue", category: .communitySpace,
                                description: "", address: "", latitude: 38.888, longitude: -77.004)
        let future = Event(id: UUID(), businessID: business.id, title: "Upcoming", description: "",
                           category: .communitySpace, startTime: now.addingTimeInterval(3600),
                           endTime: now.addingTimeInterval(7200), capacity: nil)
        var ended = future
        ended = Event(id: UUID(), businessID: business.id, title: "Ended", description: "",
                      category: .communitySpace, startTime: now.addingTimeInterval(-7200),
                      endTime: now.addingTimeInterval(-3600), capacity: nil)
        let checked = now.addingTimeInterval(-3 * 24 * 60 * 60)
        let catalog = PublicEventCatalog(businesses: [business], events: [future, ended], fetchedAt: checked,
                                         isComplete: false)
        let repository = PublicEventsRepository(cacheURL: nil, bundledCatalogs: ["nps": catalog], now: { now })
        #expect(repository.lastUpdated == checked)
        #expect(repository.sourceSummary.hasPrefix("Selected public listings"))
        #expect(!repository.hasCompleteEventCoverage)
        let events = try await repository.upcomingEvents(for: business.id)
        #expect(events.map(\.id) == [future.id])
    }

    @Test func venueSnapshotFreshnessCannotMasqueradeAsAnEventCalendarCheck() {
        let checked = now.addingTimeInterval(-2 * 24 * 60 * 60)
        let repository = PublicEventsRepository(cacheURL: nil, bundledCatalogs: [
            "nps": PublicEventCatalog(businesses: [], events: [], fetchedAt: checked, isComplete: false),
            "npsPlaces": PublicEventCatalog(businesses: [], events: [], fetchedAt: now, isComplete: true)
        ], now: { now })
        #expect(repository.lastUpdated == checked)
        #expect(!repository.hasCompleteEventCoverage)
    }

    @Test func corruptDiskCacheDoesNotReplaceBundledPublisherData() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = directory.appending(path: "public-events.json")
        try Data("{broken".utf8).write(to: cache)
        let repository = PublicEventsRepository(cacheURL: cache, bundledCatalogs: [
            "loc": PublicEventCatalog(businesses: [], events: [], fetchedAt: now, isComplete: true)
        ], now: { now })
        #expect(repository.lastUpdated == now)
    }

    @Test func newerDiskCacheWinsWithoutChangingItsTimestamp() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = directory.appending(path: "public-events.json")
        let recent = PublicEventCatalog(businesses: [], events: [], fetchedAt: now, isComplete: false)
        try JSONEncoder().encode(["nps": recent]).write(to: cache)
        let repository = PublicEventsRepository(cacheURL: cache, bundledCatalogs: [
            "nps": PublicEventCatalog(businesses: [], events: [], fetchedAt: now.addingTimeInterval(-1000))
        ], now: { now })
        #expect(repository.lastUpdated == now)
        #expect(!repository.hasCompleteEventCoverage)
    }
}
