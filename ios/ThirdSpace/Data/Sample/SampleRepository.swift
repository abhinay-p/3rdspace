import Foundation

final class SampleRepository: BusinessRepository, EventRepository {
    private var businessesByID: [Business.ID: Business]
    private var eventsByID: [Event.ID: Event]
    private let now: () -> Date
    private let storageURL: URL?
    private var changes = LocalChanges()
    private(set) var persistenceLoadError: (any Error)?

    init(data: SampleData, now: @escaping () -> Date = { .now }, storageURL: URL? = nil) {
        businessesByID = Dictionary(uniqueKeysWithValues: data.businesses.map { ($0.id, $0) })
        eventsByID = Dictionary(uniqueKeysWithValues: data.events.map { ($0.id, $0) })
        self.now = now
        self.storageURL = storageURL

        guard let storageURL else { return }
        do {
            let contents: Data
            do {
                contents = try Data(contentsOf: storageURL)
            } catch CocoaError.fileReadNoSuchFile {
                return
            }
            let saved = try JSONDecoder().decode(LocalChanges.self, from: contents)
            guard saved.version == 1 else { throw StorageError.unsupportedVersion }
            changes = saved
            businessesByID.merge(saved.businesses) { _, edited in edited }
            eventsByID.merge(saved.events) { _, edited in edited }
            for id in saved.deletedEventIDs {
                eventsByID[id] = nil
            }
        } catch {
            // Preserve unreadable data rather than silently replacing someone's
            // changes with the demo defaults on their next edit.
            persistenceLoadError = error
        }
    }

    func businesses(in bounds: MapBounds, category: Business.Category?) async throws -> [Business] {
        businessesByID.values
            .filter { business in
                bounds.contains(latitude: business.latitude, longitude: business.longitude)
                    && (category == nil || business.category == category)
            }
            .sorted { $0.name < $1.name }
    }

    func business(id: Business.ID) async throws -> Business? {
        businessesByID[id]
    }

    func save(_ business: Business) async throws -> Business {
        var next = changes
        next.businesses[business.id] = business
        try persist(next)
        changes = next
        businessesByID[business.id] = business
        return business
    }

    func upcomingEvents(for businessID: Business.ID) async throws -> [Event] {
        upcomingEvents { $0.businessID == businessID }
    }

    func upcomingEvents(in bounds: MapBounds) async throws -> [Event] {
        upcomingEvents { event in
            guard let business = businessesByID[event.businessID] else { return false }
            return bounds.contains(latitude: business.latitude, longitude: business.longitude)
        }
    }

    func save(_ event: Event) async throws -> Event {
        var next = changes
        next.events[event.id] = event
        next.deletedEventIDs.remove(event.id)
        try persist(next)
        changes = next
        eventsByID[event.id] = event
        return event
    }

    func delete(_ eventID: Event.ID) async throws {
        var next = changes
        next.events[eventID] = nil
        next.deletedEventIDs.insert(eventID)
        try persist(next)
        changes = next
        eventsByID[eventID] = nil
    }

    private func persist(_ next: LocalChanges) throws {
        if let persistenceLoadError { throw persistenceLoadError }
        guard let storageURL else { return }
        let contents = try JSONEncoder().encode(next)
        try FileManager.default.createDirectory(
            at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: storageURL, options: .atomic)
    }

    private func upcomingEvents(where isIncluded: (Event) -> Bool) -> [Event] {
        let cutoff = now()
        return eventsByID.values
            .filter { $0.endTime > cutoff && isIncluded($0) }
            .sorted { $0.startTime < $1.startTime }
    }
}

private struct LocalChanges: Codable {
    var version = 1
    var businesses: [Business.ID: Business] = [:]
    var events: [Event.ID: Event] = [:]
    var deletedEventIDs: Set<Event.ID> = []
}

private enum StorageError: Error {
    case unsupportedVersion
}
