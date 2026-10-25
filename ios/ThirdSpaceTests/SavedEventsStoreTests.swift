import Foundation
import Testing
@testable import ThirdSpace

struct SavedEventsStoreTests {
    @Test func bookmarksSurviveANewStoreAndCanBeRemoved() throws {
        let suite = "thirdspace-tests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let eventID = UUID()
        let anotherID = UUID()
        let firstLaunch = SavedEventsStore(defaults: defaults)

        firstLaunch.toggle(eventID)
        firstLaunch.toggle(anotherID)
        let secondLaunch = SavedEventsStore(defaults: defaults)
        #expect(secondLaunch.contains(eventID))
        #expect(secondLaunch.ids.count == 2)

        secondLaunch.toggle(eventID)
        let thirdLaunch = SavedEventsStore(defaults: defaults)
        #expect(!thirdLaunch.contains(eventID))
        #expect(thirdLaunch.ids == [anotherID])
        thirdLaunch.remove(anotherID)
        #expect(SavedEventsStore(defaults: defaults).ids.isEmpty)
    }

    @Test func invalidAndDuplicateStoredIDsDoNotBreakValidBookmarks() throws {
        let suite = "thirdspace-tests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let eventID = UUID()
        defaults.set(["invalid", eventID.uuidString, eventID.uuidString], forKey: "saved")

        let store = SavedEventsStore(defaults: defaults, key: "saved")
        #expect(store.ids == [eventID])
        store.toggle(eventID)
        #expect(defaults.stringArray(forKey: "saved") == [])
    }
}
