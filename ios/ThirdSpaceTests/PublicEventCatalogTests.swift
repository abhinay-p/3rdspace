import Foundation
import Testing
@testable import ThirdSpace

struct PublicEventCatalogTests {
    private let now = ISO8601DateFormatter().date(from: "2026-10-25T00:00:00Z")!

    @Test func meetingPointsAreNeverBorrowedFromAnotherEventAtTheSamePark() throws {
        let located = npsRecord(id: "located")
        var unlocated = npsRecord(id: "unlocated")
        unlocated["latitude"] = ""
        unlocated["longitude"] = ""
        let catalog = try PublicEventMapper.nps(npsData([located, unlocated]), now: now)
        #expect(catalog.events.count == 1)
        #expect(catalog.events.first?.id == PublicEventCatalog.stableID("nps:located:2026-10-25:07:00 PM"))
    }

    @Test func cancelledOccurrencesAndUnknownTimeZonesAreOmitted() throws {
        var cancelled = npsRecord(id: "cancelled")
        cancelled["cancelleddatelist"] = ["2026-10-25"]
        var unknownZone = npsRecord(id: "unknown")
        unknownZone["sitecode"] = "unknown-site"
        let catalog = try PublicEventMapper.nps(npsData([cancelled, unknownZone]), now: now)
        #expect(catalog.events.isEmpty)
        #expect(catalog.businesses.isEmpty)
    }

    @Test func overnightProgramsKeepTheirPublishedDurationAndZeroLengthIsNotAllDay() throws {
        var overnight = npsRecord(id: "night")
        overnight["times"] = [["timestart": "10:00 PM", "timeend": "01:00 AM"]]
        var zeroLength = npsRecord(id: "zero")
        zeroLength["times"] = [["timestart": "07:00 PM", "timeend": "07:00 PM"]]
        let catalog = try PublicEventMapper.nps(npsData([overnight, zeroLength]), now: now)
        #expect(catalog.events.count == 1)
        let event = try #require(catalog.events.first)
        let threeHours: TimeInterval = 3 * 60 * 60
        #expect(event.duration == threeHours)
        #expect(event.timeZoneID == "America/Los_Angeles")
    }

    @Test func publisherErrorPayloadCannotBecomeAnEmptySuccessfulCalendar() throws {
        let data = try JSONSerialization.data(withJSONObject: ["data": [], "errors": [["message": "Rate limit reached"]]])
        #expect(throws: PublicEventFeedError.self) {
            _ = try PublicEventMapper.nps(data, now: now)
        }
    }

    @Test func partialPublisherResponsesRemainExplicitlyPartial() throws {
        let data = try JSONSerialization.data(withJSONObject: [
            "data": [npsRecord(id: "one")], "pagesize": "50", "pagenumber": "1", "total": "500", "errors": []
        ])
        let catalog = try PublicEventMapper.nps(data, now: now)
        #expect(catalog.isComplete == false)
        let response = try JSONDecoder().decode(NPSEventResponse.self, from: data)
        #expect(response.hasMorePages)
    }

    @Test func officialPlaceInventoryIncludesRealCoordinatesWithoutInventingEvents() throws {
        let url = try #require(Bundle.main.url(forResource: "nps-places-snapshot", withExtension: "json"))
        let catalog = try PublicEventMapper.npsPlaces(Data(contentsOf: url), fetchedAt: now)
        #expect(catalog.businesses.count > 700)
        #expect(catalog.events.isEmpty)
        #expect(catalog.businesses.allSatisfy { USMapGeometry.contains($0.coordinate) })
        #expect(catalog.businesses.contains { $0.latitude > 55 && $0.longitude < -130 })
        #expect(catalog.businesses.contains { $0.latitude < 23 && $0.longitude < -150 })
        #expect(catalog.businesses.allSatisfy { $0.description.contains("National Park Service") })
        #expect(Set(catalog.businesses.map(\.id)).count == catalog.businesses.count)
    }

    private func npsData(_ records: [[String: Any]]) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["data": records, "errors": []])
    }

    private func npsRecord(id: String) -> [String: Any] {
        ["id": id, "sitecode": "yose", "parkfullname": "Yosemite National Park",
         "title": "Evening ranger program", "description": "<p>Meet a ranger.</p>",
         "location": "Yosemite Valley", "latitude": "37.745", "longitude": "-119.59",
         "date": "2026-10-25", "dates": ["2026-10-25"], "cancelleddatelist": [],
         "times": [["timestart": "07:00 PM", "timeend": "08:00 PM"]], "infourl": "", "types": ["Talk"]]
    }
}
