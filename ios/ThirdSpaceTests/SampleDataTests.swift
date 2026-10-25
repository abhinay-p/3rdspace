import Foundation
import Testing
@testable import ThirdSpace

struct SampleDataTests {
    private static let generatedAt = Date(timeIntervalSince1970: 1_800_000_000)
    private let data = SampleData.make(relativeTo: generatedAt)

    @Test func coversEveryCategory() {
        #expect(Set(data.businesses.map(\.category)) == Set(Business.Category.allCases))
    }

    @Test func ownedBusinessIsOneOfTheSampleBusinesses() throws {
        let ownedID = try #require(data.ownedBusinessID)
        #expect(data.businesses.contains { $0.id == ownedID })
    }

    @Test func everyEventBelongsToABusinessAndIsUpcoming() {
        let businessIDs = Set(data.businesses.map(\.id))
        for event in data.events {
            #expect(businessIDs.contains(event.businessID))
            #expect(event.startTime > Self.generatedAt)
            #expect(event.endTime > event.startTime)
        }
    }

    @Test func sampleEventsCarryTheirVenuesTimeZones() {
        for city in SampleCity.all {
            let cityBusinesses = Set(city.places.map { $0.business(in: city).id })
            let cityEvents = data.events.filter { cityBusinesses.contains($0.businessID) }
            #expect(!cityEvents.isEmpty)
            #expect(cityEvents.allSatisfy { $0.timeZoneID == city.timeZoneID })
        }
    }

    @Test func sampleIdentitiesSurviveRelaunchAndDateRefresh() {
        let tomorrow = SampleData.make(relativeTo: Self.generatedAt.addingTimeInterval(24 * 3600))

        #expect(data.businesses.map(\.id) == tomorrow.businesses.map(\.id))
        #expect(data.events.map(\.id) == tomorrow.events.map(\.id))
        #expect(data.ownedBusinessID == tomorrow.ownedBusinessID)
        #expect(Set(data.businesses.map(\.id)).count == data.businesses.count)
        #expect(Set(data.events.map(\.id)).count == data.events.count)
        #expect(zip(data.events, tomorrow.events).allSatisfy { $0.startTime < $1.startTime })
    }
}
