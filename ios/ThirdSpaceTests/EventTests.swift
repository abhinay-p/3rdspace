import Foundation
import Testing
@testable import ThirdSpace

struct EventTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 24 * 60 * 60

    private func makeEvent(startingIn start: TimeInterval, lasting length: TimeInterval) -> Event {
        let startTime = now.addingTimeInterval(start)
        return Event(
            id: UUID(), businessID: UUID(), title: "", description: "", category: .cafe,
            startTime: startTime, endTime: startTime.addingTimeInterval(length), capacity: nil)
    }

    @Test func durationIsTimeFromStartToEnd() {
        #expect(makeEvent(startingIn: 0, lasting: 7200).duration == 7200)
    }

    nonisolated private static let weekCases: [(hoursFromNow: Double, expected: Bool)] = [
        (-2, false),   // already over
        (-0.5, true),  // underway right now
        (72, true),    // in a few days
        (192, false),  // after the window closes
    ]

    @Test(arguments: weekCases)
    func isHappeningWithinAWeek(hoursFromNow: Double, expected: Bool) {
        let event = makeEvent(startingIn: hoursFromNow * 3600, lasting: 3600)
        #expect(event.isHappening(within: 7 * day, from: now) == expected)
    }
}
