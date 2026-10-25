import Foundation
import MapKit
import Testing
@testable import ThirdSpace

struct PublicEventsTests {
    private let now = ISO8601DateFormatter().date(from: "2026-10-22T05:41:00Z")!

    @Test func bundledPublicListingsHaveRealSourcesAndFixedDates() throws {
        let url = try #require(Bundle.main.url(forResource: "nps-events-snapshot", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let catalog = try PublicEventMapper.nps(data, now: now)
        #expect(!catalog.events.isEmpty)
        #expect(catalog.events.allSatisfy { $0.endTime > now && $0.sourceURL?.host() == "www.nps.gov" })
        #expect(catalog.events.allSatisfy { !$0.title.localizedCaseInsensitiveContains("closed") })
        let venueIDs = Set(catalog.businesses.map(\.id))
        #expect(catalog.events.allSatisfy { venueIDs.contains($0.businessID) })
        let later = try PublicEventMapper.nps(data, now: now.addingTimeInterval(365 * 24 * 60 * 60))
        #expect(Set(later.events.map(\.id)).isDisjoint(with: Set(catalog.events.map(\.id))))
        let again = try PublicEventMapper.nps(data, now: now)
        #expect(Set(catalog.events.map(\.id)) == Set(again.events.map(\.id)))
    }

    @Test func libraryFeedExcludesOnlineOnlyEventsAndLinksToOrganizer() throws {
        let url = try #require(Bundle.main.url(forResource: "loc-events-snapshot", withExtension: "json"))
        let catalog = try PublicEventMapper.libraryOfCongress(Data(contentsOf: url), now: now)
        #expect(!catalog.events.isEmpty)
        #expect(!catalog.events.contains { $0.title == "An Introduction to Congress.gov" })
        #expect(catalog.events.allSatisfy { $0.sourceURL?.host() == "www.loc.gov" && $0.timeZoneID == "America/New_York" })
    }

    @Test func countryGeometryIncludesAllUSRegionsAndExcludesForeignCities() {
        #expect(!USMapGeometry.polygons.isEmpty)
        #expect(USMapGeometry.contains(.init(latitude: 40.7128, longitude: -74.0060)))
        #expect(USMapGeometry.contains(.init(latitude: 61.2181, longitude: -149.9003)))
        #expect(USMapGeometry.contains(.init(latitude: 21.3099, longitude: -157.8581)))
        #expect(!USMapGeometry.contains(.init(latitude: 43.6532, longitude: -79.3832)))
        #expect(!USMapGeometry.contains(.init(latitude: 19.4326, longitude: -99.1332)))
        #expect(!USMapGeometry.contains(.init(latitude: 51.5074, longitude: -0.1278)))
    }

    @Test func publisherHTMLIsReadablePlainText() {
        #expect(PublicEventCatalog.plainText("<p>Meet &amp; greet</p> <br> Free") == "Meet & greet Free")
    }
}
