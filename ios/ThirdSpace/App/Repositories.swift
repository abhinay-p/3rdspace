import SwiftUI

struct Repositories {
    let businesses: any BusinessRepository
    let events: any EventRepository
}

extension Repositories {
    init(sampleData: SampleData, storageURL: URL? = nil) {
        let store = SampleRepository(data: sampleData, storageURL: storageURL)
        self.init(businesses: store, events: store)
    }
}

extension EnvironmentValues {
    @Entry var previewRepositories: Repositories = Repositories(sampleData: .make())
    @Entry var publicEvents: PublicEventsRepository? = nil
    @Entry var repositories: Repositories = Repositories(sampleData: .make())
    @Entry var ownedBusinessID: Business.ID? = nil
}
