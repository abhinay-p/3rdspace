import Foundation
import Testing
@testable import ThirdSpace

struct EventDisplayTests {
    @Test func aVenueDateCanBeDifferentFromTheUTCDate() throws {
        let event = try makeEvent(
            start: "2026-10-22T00:30:00Z", end: "2026-10-22T02:30:00Z", zone: "America/New_York")
        let style = Date.FormatStyle.dateTime.month(.abbreviated).day()
            .locale(Locale(identifier: "en_US"))

        #expect(event.displayTimeZone.identifier == "America/New_York")
        #expect(event.formatted(event.startTime, using: style) == "Oct 21")
    }

    @Test func anOvernightRangeIncludesTheNextVenueDate() throws {
        // Both instants fall on October 22 in UTC; the event crosses midnight
        // in New York, so just printing the two clock times is ambiguous.
        let event = try makeEvent(
            start: "2026-10-22T03:30:00Z", end: "2026-10-22T04:30:00Z", zone: "America/New_York")
        let endDate = event.formatted(event.endTime, using: .dateTime.month(.abbreviated).day())

        #expect(event.timeRangeText.contains(endDate))
    }

    @Test func aClockChangeShowsBothTimeZoneAbbreviations() throws {
        let event = try makeEvent(
            start: "2026-11-01T05:30:00Z", end: "2026-11-01T06:30:00Z", zone: "America/New_York")
        let startZone = try #require(event.displayTimeZone.abbreviation(for: event.startTime))
        let endZone = try #require(event.displayTimeZone.abbreviation(for: event.endTime))

        #expect(startZone != endZone)
        #expect(event.timeRangeText.contains(startZone))
        #expect(event.timeRangeText.contains(endZone))
        #expect(event.duration == 3600)
    }

    @Test func eventsFromAnotherTimeZoneIdentifyTheirLocalTime() throws {
        let zone = TimeZone.current.identifier == "America/New_York" ? "America/Los_Angeles" : "America/New_York"
        let event = try makeEvent(start: "2026-10-22T18:00:00Z", end: "2026-10-22T20:00:00Z", zone: zone)
        let abbreviation = try #require(event.displayTimeZone.abbreviation(for: event.startTime))

        #expect(event.startTimeText.contains(abbreviation))
        #expect(event.timeRangeText.contains(abbreviation))
    }

    @Test func olderSavedEventsDecodeWithoutATimeZone() throws {
        let event = try makeEvent(
            start: "2026-10-22T18:00:00Z", end: "2026-10-22T20:00:00Z", zone: "America/New_York")
        let encoded = try JSONEncoder().encode(event)
        var fields = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        fields["timeZoneID"] = nil
        let legacyData = try JSONSerialization.data(withJSONObject: fields)
        let decoded = try JSONDecoder().decode(Event.self, from: legacyData)

        #expect(decoded.id == event.id)
        #expect(decoded.startTime == event.startTime)
        #expect(decoded.timeZoneID == nil)
        #expect(decoded.displayTimeZone == .current)
    }

    @Test func invalidTimeZonesFallBackToTheDeviceTimeZone() throws {
        let event = try makeEvent(start: "2026-10-22T18:00:00Z", end: "2026-10-22T20:00:00Z", zone: "not-a-time-zone")
        #expect(event.displayTimeZone == .current)
    }

    private func makeEvent(start: String, end: String, zone: String?) throws -> Event {
        Event(
            id: UUID(), businessID: UUID(), title: "Neighborhood night", description: "",
            category: .communitySpace, startTime: try Date(start, strategy: .iso8601),
            endTime: try Date(end, strategy: .iso8601), capacity: nil, timeZoneID: zone)
    }
}
