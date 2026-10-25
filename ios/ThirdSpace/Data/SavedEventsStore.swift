import Foundation
import SwiftUI

/// A private, on-device collection. Saving an event does not reserve a place.
@Observable
final class SavedEventsStore {
    private(set) var ids: Set<Event.ID>
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key: String

    init(defaults: UserDefaults = .standard, key: String = "thirdspace.saved-event-ids") {
        self.defaults = defaults
        self.key = key
        ids = Set((defaults.stringArray(forKey: key) ?? []).compactMap(UUID.init(uuidString:)))
    }

    func contains(_ eventID: Event.ID) -> Bool {
        ids.contains(eventID)
    }

    func toggle(_ eventID: Event.ID) {
        if ids.contains(eventID) {
            ids.remove(eventID)
        } else {
            ids.insert(eventID)
        }
        persist()
    }

    func remove(_ eventID: Event.ID) {
        ids.remove(eventID)
        persist()
    }

    private func persist() {
        defaults.set(ids.map(\.uuidString).sorted(), forKey: key)
    }
}

extension EnvironmentValues {
    @Entry var savedEventsStore: SavedEventsStore = SavedEventsStore()
}
