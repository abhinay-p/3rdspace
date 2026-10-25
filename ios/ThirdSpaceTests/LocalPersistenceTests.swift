import Foundation
import Testing
@testable import ThirdSpace

struct LocalPersistenceTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func editsNewEventsAndDeletionsSurviveRelaunch() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "changes.json")
        let seed = SampleData.make(relativeTo: now)
        let repository = SampleRepository(data: seed, now: { now }, storageURL: url)
        var business = seed.businesses[0]
        business.name = "My updated venue"
        var editedEvent = seed.events[0]
        editedEvent.title = "My updated event"
        let deletedEvent = seed.events[1]
        let newEvent = Event(
            id: UUID(), businessID: business.id, title: "A new neighborhood event",
            description: "Everyone welcome", category: .communitySpace,
            startTime: now.addingTimeInterval(3600), endTime: now.addingTimeInterval(7200),
            capacity: 20)

        _ = try await repository.save(business)
        _ = try await repository.save(editedEvent)
        _ = try await repository.save(newEvent)
        try await repository.delete(deletedEvent.id)

        let restored = SampleRepository(data: seed, now: { now }, storageURL: url)
        #expect(restored.persistenceLoadError == nil)
        #expect(try await restored.business(id: business.id) == business)
        let events = try await restored.upcomingEvents(for: business.id)
        #expect(events.contains(editedEvent))
        #expect(events.contains(newEvent))
        let deletedBusinessEvents = try await restored.upcomingEvents(for: deletedEvent.businessID)
        #expect(!deletedBusinessEvents.contains { $0.id == deletedEvent.id })
    }

    @Test func refreshingDemoDatesPreservesOverridesAndDeletions() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "changes.json")
        let seed = SampleData.make(relativeTo: now)
        let repository = SampleRepository(data: seed, now: { now }, storageURL: url)
        var edited = seed.events[0]
        edited.title = "An event with a fixed date"
        _ = try await repository.save(edited)
        try await repository.delete(seed.events[1].id)

        let refreshedSeed = SampleData.make(relativeTo: now.addingTimeInterval(86400))
        let restored = SampleRepository(data: refreshedSeed, now: { now }, storageURL: url)
        #expect(try await restored.upcomingEvents(for: edited.businessID).contains(edited))
        let removed = seed.events[1]
        #expect(try await restored.upcomingEvents(for: removed.businessID).allSatisfy { $0.id != removed.id })
        let untouched = refreshedSeed.events[2]
        #expect(try await restored.upcomingEvents(for: untouched.businessID).contains(untouched))
    }

    @Test func aDeletedEventCanBeSavedAgain() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "changes.json")
        let seed = SampleData.make(relativeTo: now)
        let event = seed.events[0]
        let repository = SampleRepository(data: seed, now: { now }, storageURL: url)
        try await repository.delete(event.id)
        _ = try await repository.save(event)

        let restored = SampleRepository(data: seed, now: { now }, storageURL: url)
        #expect(try await restored.upcomingEvents(for: event.businessID).contains(event))
    }

    @Test func aFailedWriteDoesNotPublishVenueEventOrDeletionChanges() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let seed = SampleData.make(relativeTo: now)
        let repository = SampleRepository(data: seed, now: { now }, storageURL: nil)
        // The first read must see an absent store. Creating its parent as a file
        // afterwards simulates a disk failure during a later edit.
        let failingURL = directory.appending(path: "store/changes.json")
        let failing = SampleRepository(data: seed, now: { now }, storageURL: failingURL)
        try Data().write(to: failingURL.deletingLastPathComponent())
        var business = seed.businesses[0]
        business.name = "This should not be published"
        var event = seed.events[0]
        event.title = "This should not be published"

        await #expect(throws: (any Error).self) { try await failing.save(business) }
        await #expect(throws: (any Error).self) { try await failing.save(event) }
        await #expect(throws: (any Error).self) { try await failing.delete(event.id) }
        #expect(try await failing.business(id: business.id) == seed.businesses[0])
        let actualEvents = try await failing.upcomingEvents(for: event.businessID)
        let originalEvents = try await repository.upcomingEvents(for: event.businessID)
        #expect(actualEvents == originalEvents)
    }

    @Test func corruptStorageIsPreservedAndCannotBeOverwrittenByAnEdit() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "changes.json")
        let original = Data("This is not a valid changes file".utf8)
        try original.write(to: url)
        let seed = SampleData.make(relativeTo: now)
        let repository = SampleRepository(data: seed, now: { now }, storageURL: url)

        #expect(repository.persistenceLoadError != nil)
        await #expect(throws: (any Error).self) { try await repository.save(seed.businesses[0]) }
        #expect(try Data(contentsOf: url) == original)
        #expect(try await repository.business(id: seed.businesses[0].id) == seed.businesses[0])
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "3rdspace-tests-\(UUID().uuidString)")
    }
}
