import CryptoKit
import Foundation

struct SampleData {
    let businesses: [Business]
    let events: [Event]
    var ownedBusinessID: Business.ID? = nil
}

extension SampleData {
    static func make(relativeTo now: Date = .now) -> SampleData {
        var businesses: [Business] = []
        var events: [Event] = []
        var ownedBusinessID: Business.ID?

        for city in SampleCity.all {
            let calendar = city.calendar
            let today = calendar.startOfDay(for: now)
            for place in city.places {
                let business = place.business(in: city)
                businesses.append(business)
                events += place.events.map { $0.event(for: business, from: today, calendar: calendar) }
                if place.isYours {
                    ownedBusinessID = business.id
                }
            }
        }

        return SampleData(businesses: businesses, events: events, ownedBusinessID: ownedBusinessID)
    }
}

struct SampleCity {
    let name: String
    let state: String
    let timeZoneID: String
    let places: [SamplePlace]

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneID)!
        return calendar
    }
}

struct SamplePlace {
    let name: String
    let category: Business.Category
    let street: String
    let latitude: Double
    let longitude: Double
    let about: String
    let isYours: Bool
    let events: [SampleEvent]

    init(
        _ name: String, _ category: Business.Category,
        street: String, _ latitude: Double, _ longitude: Double,
        about: String, isYours: Bool = false, events: [SampleEvent]
    ) {
        self.name = name
        self.category = category
        self.street = street
        self.latitude = latitude
        self.longitude = longitude
        self.about = about
        self.isYours = isYours
        self.events = events
    }

    func business(in city: SampleCity) -> Business {
        Business(
            id: SampleIdentity.id(for: "business:\(city.name):\(name)"),
            name: name,
            category: category,
            description: about,
            address: "\(street), \(city.name), \(city.state)",
            latitude: latitude,
            longitude: longitude
        )
    }
}

struct SampleEvent {
    let title: String
    let dayOffset: Int
    let startHour: Double
    let hours: Double
    let capacity: Int?
    let category: Business.Category?
    let about: String

    init(
        _ title: String,
        day dayOffset: Int, at startHour: Double, hours: Double,
        capacity: Int? = nil, category: Business.Category? = nil,
        about: String
    ) {
        self.title = title
        self.dayOffset = dayOffset
        self.startHour = startHour
        self.hours = hours
        self.capacity = capacity
        self.category = category
        self.about = about
    }

    func event(for business: Business, from today: Date, calendar: Calendar) -> Event {
        let day = calendar.date(byAdding: .day, value: dayOffset, to: today)!
        let minutes = Int(startHour * 60)
        let start = calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day)!
        return Event(
            id: SampleIdentity.id(for: "event:\(business.id.uuidString):\(title)"),
            businessID: business.id,
            title: title,
            description: about,
            category: category ?? business.category,
            startTime: start,
            endTime: start.addingTimeInterval(hours * 3600),
            capacity: capacity,
            timeZoneID: calendar.timeZone.identifier
        )
    }
}

// Demo records keep their identity across launches while their dates stay relative
// to today. This lets local edits and bookmarks refer to the same records.
private enum SampleIdentity {
    static func id(for key: String) -> UUID {
        var bytes = Array(SHA256.hash(data: Data("3rdspace:sample:\(key)".utf8)).prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x80
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}
