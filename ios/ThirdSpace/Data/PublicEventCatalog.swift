import CryptoKit
import Foundation

nonisolated struct PublicEventCatalog: Codable {
    var businesses: [Business]
    var events: [Event]
    var fetchedAt: Date
    // Nil preserves caches written before publisher pagination was tracked.
    var isComplete: Bool? = nil

    static func stableID(_ text: String) -> UUID {
        let bytes = Array(SHA256.hash(data: Data(text.utf8)))
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }

    static func plainText(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&rsquo;", with: "’")
            .replacingOccurrences(of: "&ldquo;", with: "“")
            .replacingOccurrences(of: "&rdquo;", with: "”")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct NPSEventResponse: Decodable {
    let data: [NPSEventRecord]
    let pagesize: String?
    let pagenumber: String?
    let total: String?
    private let errors: EmptyPublisherErrors?

    var hasMorePages: Bool {
        guard let total = total.flatMap(Int.init),
              let page = pagenumber.flatMap(Int.init),
              let size = pagesize.flatMap(Int.init), size > 0 else { return false }
        return page * size < total
    }
}

private struct EmptyPublisherErrors: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.unkeyedContainer()
        guard values.isAtEnd else { throw PublicEventFeedError.publisherReportedError }
    }
}

enum PublicEventFeedError: Error { case publisherReportedError, invalidPagination }

struct NPSEventRecord: Decodable {
    let id: String
    let sitecode: String
    let parkfullname: String
    let title: String
    let description: String
    let location: String
    let latitude: String
    let longitude: String
    let date: String
    let dates: [String]?
    let times: [NPSEventTime]
    let cancelleddatelist: [String]?
    let infourl: String
    let types: [String]
}

struct NPSEventTime: Decodable {
    let timestart: String
    let timeend: String
}

enum PublicEventMapper {
    static func npsPlaces(_ data: Data, fetchedAt: Date) throws -> PublicEventCatalog {
        let response = try JSONDecoder().decode(NPSPlacesResponse.self, from: data)
        let businesses = response.features.compactMap { feature -> Business? in
            let place = feature.properties
            guard let name = place.POINAME, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let coordinates = feature.geometry?.coordinates, coordinates.count >= 2,
                  coordinates[0].isFinite, coordinates[1].isFinite,
                  USMapGeometry.contains(.init(latitude: coordinates[1], longitude: coordinates[0])),
                  !["no", "false"].contains(place.OPENTOPUBLIC?.lowercased() ?? ""),
                  !(place.POISTATUS?.localizedCaseInsensitiveContains("closed") ?? false),
                  !(place.POISTATUS?.localizedCaseInsensitiveContains("removed") ?? false) else { return nil }
            let kind = place.POITYPE ?? "Public place"
            let park = place.UNITNAME ?? "National Park Service"
            let category: Business.Category = kind == "Cafe" ? .cafe : .communitySpace
            return Business(id: PublicEventCatalog.stableID("nps-poi:\(place.OBJECTID)"),
                            name: PublicEventCatalog.plainText(name), category: category,
                            description: "\(kind) listed by the National Park Service at \(park). Check current hours and public access with the park before visiting.",
                            address: park, latitude: coordinates[1], longitude: coordinates[0])
        }
        return PublicEventCatalog(businesses: businesses, events: [], fetchedAt: fetchedAt, isComplete: true)
    }

    // Geographic time zones were resolved from the official NPS public POI
    // coordinates. Units spanning more than one zone are intentionally omitted.
    static let siteZones: [String: String] = {
        let bundled: [String: String]
        if let url = Bundle.main.url(forResource: "nps-park-timezones", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let zones = try? JSONDecoder().decode([String: String].self, from: data) {
            bundled = zones
        } else { bundled = [:] }
        return bundled.merging([
        "thri": "America/New_York", "gosp": "America/Denver", "cabr": "America/Los_Angeles",
        "cham": "America/Los_Angeles", "chis": "America/Los_Angeles", "goga": "America/Los_Angeles",
        "fopo": "America/Los_Angeles", "alca": "America/Los_Angeles", "yose": "America/Los_Angeles",
        "oxhi": "America/New_York", "keaq": "America/New_York", "kemo": "America/New_York",
        "malu": "America/New_York", "saan": "America/Chicago", "puho": "Pacific/Honolulu",
        "aplic": "America/Anchorage", "alpl": "America/Anchorage", "jela": "America/Chicago",
        "lyjo": "America/Chicago", "brca": "America/Denver", "bicy": "America/New_York",
        "pipe": "America/Chicago", "okci": "America/Chicago"
        ], uniquingKeysWith: { first, _ in first })
    }()

    static func nps(_ data: Data, now: Date) throws -> PublicEventCatalog {
        let response = try JSONDecoder().decode(NPSEventResponse.self, from: data)
        var businesses: [Business.ID: Business] = [:]
        var events: [Event.ID: Event] = [:]
        let horizon = now.addingTimeInterval(60 * 24 * 60 * 60)
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "yyyy-MM-dd hh:mm a"

        for record in response.data {
            let lowerTitle = record.title.lowercased()
            guard !lowerTitle.contains("closed"), !lowerTitle.contains("closure"),
                  !lowerTitle.contains("cancel"), !record.parkfullname.isEmpty,
                  let zoneID = siteZones[record.sitecode.lowercased()], let zone = TimeZone(identifier: zoneID),
                  let lat = Double(record.latitude), let lon = Double(record.longitude),
                  lat.isFinite, lon.isFinite, (-90...90).contains(lat), (-180...180).contains(lon) else { continue }
            // Never borrow a different event's meeting point, even within one park.
            guard USMapGeometry.contains(.init(latitude: lat, longitude: lon)) else { continue }
            dayFormatter.timeZone = zone
            timeFormatter.timeZone = zone
            let businessID = PublicEventCatalog.stableID("nps:\(record.sitecode):\(lat):\(lon)")
            let category: Business.Category = record.types.contains { $0.localizedCaseInsensitiveContains("walk") || $0.localizedCaseInsensitiveContains("hike") } ? .fitness : .communitySpace
            let business = Business(id: businessID, name: record.parkfullname, category: category,
                description: "Public programs at \(record.parkfullname). Exact meeting points and access information are on the organizer’s event page.",
                address: PublicEventCatalog.plainText(record.location.isEmpty ? record.parkfullname : record.location),
                latitude: lat, longitude: lon)
            let publishedDates = record.dates?.isEmpty == false ? record.dates! : [record.date]
            let cancellations = Set(record.cancelleddatelist ?? [])
            for day in publishedDates where !cancellations.contains(day) {
                guard let date = dayFormatter.date(from: day), date < horizon,
                      date.addingTimeInterval(24 * 60 * 60) > now else { continue }
                for time in record.times {
                    guard let start = timeFormatter.date(from: "\(day) \(time.timestart)"),
                          var end = timeFormatter.date(from: "\(day) \(time.timeend)") else { continue }
                    if end < start {
                        var calendar = Calendar(identifier: .gregorian)
                        calendar.timeZone = zone
                        end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
                    }
                    guard end > start, end > now, start < horizon else { continue }
                    let id = PublicEventCatalog.stableID("nps:\(record.id):\(day):\(time.timestart)")
                    let url = URL(string: "https://www.nps.gov/planyourvisit/event-details.htm?id=\(record.id)")
                    events[id] = Event(id: id, businessID: businessID,
                        title: PublicEventCatalog.plainText(record.title),
                        description: PublicEventCatalog.plainText(record.description),
                        category: category, startTime: start, endTime: end, capacity: nil,
                        timeZoneID: zoneID, sourceName: "National Park Service", sourceURL: url)
                    businesses[businessID] = business
                }
            }
        }
        return PublicEventCatalog(businesses: Array(businesses.values), events: Array(events.values), fetchedAt: now,
                                  isComplete: !response.hasMorePages)
    }

    static func libraryOfCongress(_ data: Data, now: Date) throws -> PublicEventCatalog {
        let root = try JSONDecoder().decode(LOCResponse.self, from: data)
        let iso = ISO8601DateFormatter()
        let fractionalISO = ISO8601DateFormatter()
        fractionalISO.formatOptions.insert(.withFractionalSeconds)
        var businesses: [Business.ID: Business] = [:]
        var events: [Event] = []
        for record in root.results {
            guard record.item.online_only != true,
                  !["cancelled", "canceled", "postponed"].contains(record.item.event_status?.lowercased() ?? ""),
                  let rawCoordinates = record.item.venue?.building_coordinates else { continue }
            let coordinates = rawCoordinates.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
            guard coordinates.count == 2,
                  USMapGeometry.contains(.init(latitude: coordinates[0], longitude: coordinates[1])),
                  let start = iso.date(from: record.item.event_start_utc) ?? fractionalISO.date(from: record.item.event_start_utc),
                  let end = iso.date(from: record.item.event_end_utc) ?? fractionalISO.date(from: record.item.event_end_utc),
                  end > now, end > start else { continue }
            let venue = record.item.venue!
            let businessID = PublicEventCatalog.stableID("loc:\(rawCoordinates)")
            let address = venue.building_address
            businesses[businessID] = Business(id: businessID, name: venue.building ?? "Library of Congress",
                category: .communitySpace, description: "Public events hosted by the Library of Congress.",
                address: [address?.street_address, address?.city, address?.state].compactMap { $0 }.joined(separator: ", "),
                latitude: coordinates[0], longitude: coordinates[1])
            let sourceURL = URL(string: record.id.replacingOccurrences(of: "http://", with: "https://"))
            guard sourceURL?.scheme == "https", sourceURL?.host() == "www.loc.gov" else { continue }
            events.append(Event(id: PublicEventCatalog.stableID("loc:\(record.id):\(record.item.event_start_utc)"),
                businessID: businessID, title: record.title,
                description: PublicEventCatalog.plainText(record.description.joined(separator: " ")),
                category: .communitySpace, startTime: start, endTime: end, capacity: nil,
                timeZoneID: "America/New_York", sourceName: "Library of Congress", sourceURL: sourceURL))
        }
        return PublicEventCatalog(businesses: Array(businesses.values), events: events, fetchedAt: now,
                                  isComplete: root.pagination?.next == nil)
    }

    struct LOCResponse: Decodable {
        let results: [LOCRecord]
        let pagination: LOCPagination?
    }
    struct LOCPagination: Decodable { let next: String? }
    struct LOCRecord: Decodable {
        let id: String
        let title: String
        let description: [String]
        let item: LOCItem
    }
    struct LOCItem: Decodable {
        let event_start_utc: String
        let event_end_utc: String
        let event_status: String?
        let online_only: Bool?
        let venue: LOCVenue?
    }
    struct LOCVenue: Decodable {
        let building: String?
        let building_coordinates: String?
        let building_address: LOCAddress?
    }
    struct LOCAddress: Decodable {
        let street_address: String?
        let city: String?
        let state: String?
    }

    private struct NPSPlacesResponse: Decodable { let features: [NPSPlaceFeature] }
    private struct NPSPlaceFeature: Decodable {
        let properties: NPSPlaceProperties
        let geometry: NPSPlaceGeometry?
    }
    private struct NPSPlaceGeometry: Decodable { let coordinates: [Double] }
    private struct NPSPlaceProperties: Decodable {
        let OBJECTID: Int
        let POINAME: String?
        let POITYPE: String?
        let UNITNAME: String?
        let OPENTOPUBLIC: String?
        let POISTATUS: String?
    }
}
