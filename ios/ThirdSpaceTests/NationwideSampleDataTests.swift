import Foundation
import Testing
@testable import ThirdSpace

struct NationwideSampleDataTests {
    private static let statesAndDistrict = Set(
        "AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY DC"
            .split(separator: " ").map(String.init))

    @Test func everyStateAndDCHasAtLeastTwoDiscoverableVenues() {
        let data = SampleData.make(relativeTo: Date(timeIntervalSince1970: 1_800_000_000))
        let grouped = Dictionary(grouping: data.businesses) { business in
            business.address.components(separatedBy: ", ").last ?? ""
        }

        #expect(Set(grouped.keys) == Self.statesAndDistrict)
        for state in Self.statesAndDistrict {
            #expect((grouped[state]?.count ?? 0) >= 2, "Missing venues for \(state)")
        }
    }

    @Test func nationwideAdditionHasFortyFiveCitiesAndNinetyVenuesWithEvents() {
        let cities = SampleCity.nationwideAdditions
        let venues = cities.flatMap(\.places)
        #expect(cities.count == 45)
        #expect(Set(cities.map(\.state)).count == 45)
        #expect(venues.count == 90)
        #expect(venues.allSatisfy { !$0.events.isEmpty })
        #expect(venues.flatMap(\.events).allSatisfy { (1...10).contains($0.dayOffset) })
        #expect(cities.allSatisfy { TimeZone(identifier: $0.timeZoneID) != nil })
    }

    @Test func nationwideRecordsHaveUniqueIDsAndNoOrphanedEvents() {
        let data = SampleData.make(relativeTo: Date(timeIntervalSince1970: 1_800_000_000))
        let businessIDs = Set(data.businesses.map(\.id))
        #expect(businessIDs.count == data.businesses.count)
        #expect(Set(data.events.map(\.id)).count == data.events.count)
        #expect(data.events.allSatisfy { businessIDs.contains($0.businessID) })
        #expect(data.businesses.allSatisfy {
            (-90...90).contains($0.latitude) && (-180...180).contains($0.longitude)
        })
    }
}
