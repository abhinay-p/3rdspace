import Foundation
import Testing
@testable import ThirdSpace

struct EventPublishingTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func event(startingIn offset: TimeInterval = 3_600) -> Event {
        let start = now.addingTimeInterval(offset)
        return Event(
            id: UUID(), businessID: UUID(), title: "Neighborhood supper", description: "",
            category: .restaurant, startTime: start,
            endTime: start.addingTimeInterval(7_200), capacity: nil)
    }

    @Test func rejectsBlankTitlesAndNonpositiveCapacity() {
        var draft = event()
        draft.title = " \n\t "
        #expect(!draft.canPublish(at: now))
        draft.title = "Supper"
        draft.capacity = 0
        #expect(!draft.canPublish(at: now))
        draft.capacity = 1
        #expect(draft.canPublish(at: now))
    }

    @Test func rejectsEndedAndZeroLengthEventsButAllowsOngoingEvents() {
        var draft = event(startingIn: -7_200)
        #expect(!draft.canPublish(at: now))
        draft = event(startingIn: -3_600)
        #expect(draft.canPublish(at: now))
        draft.endTime = draft.startTime
        #expect(!draft.canPublish(at: now))
    }

    @Test func movingStartPastOriginalEndPreservesDuration() {
        var draft = event()
        let newStart = draft.endTime.addingTimeInterval(86_400)
        let originalDuration = draft.duration
        draft.reschedule(startingAt: newStart)
        #expect(draft.startTime == newStart)
        #expect(draft.duration == originalDuration)
        #expect(draft.canPublish(at: now))
    }

    @Test func movingStartEarlierPreservesDurationAndIdentity() {
        var draft = event()
        let id = draft.id
        let businessID = draft.businessID
        let originalDuration = draft.duration
        draft.reschedule(startingAt: now)
        #expect(draft.duration == originalDuration)
        #expect(draft.id == id)
        #expect(draft.businessID == businessID)
    }
}
