protocol BusinessRepository {
    func businesses(in bounds: MapBounds, category: Business.Category?) async throws -> [Business]
    func business(id: Business.ID) async throws -> Business?
    func save(_ business: Business) async throws -> Business
}
