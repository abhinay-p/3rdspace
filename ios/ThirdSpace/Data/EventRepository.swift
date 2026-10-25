protocol EventRepository {
    func upcomingEvents(for businessID: Business.ID) async throws -> [Event]
    func upcomingEvents(in bounds: MapBounds) async throws -> [Event]
    func save(_ event: Event) async throws -> Event
    func delete(_ eventID: Event.ID) async throws
}
