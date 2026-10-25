import SwiftUI

@main
struct ThirdSpaceApp: App {
    private let repositories: Repositories
    private let previewRepositories: Repositories
    private let publicEventRepository: PublicEventsRepository?
    private let ownedBusinessID: Business.ID?
    @State private var storageErrorMessage: String?
    @State private var savedEvents: SavedEventsStore

    init() {
        let sampleData = SampleData.make()
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains("-ui-testing")
        let defaults = isUITesting ? UserDefaults(suiteName: "thirdspace.ui-tests")! : .standard
        if isUITesting && !arguments.contains("-preserve-saved-events") {
            defaults.removePersistentDomain(forName: "thirdspace.ui-tests")
        }
        _savedEvents = State(initialValue: SavedEventsStore(defaults: defaults))
        let storageURL = isUITesting ? nil
            : URL.applicationSupportDirectory.appending(path: "3rdSpace/changes.json")
        let store = SampleRepository(data: sampleData, storageURL: storageURL)
        previewRepositories = Repositories(businesses: store, events: store)
        let publicRepository = isUITesting ? nil : PublicEventsRepository()
        publicEventRepository = publicRepository
        repositories = publicRepository.map { Repositories(businesses: $0, events: $0) }
            ?? previewRepositories
        ownedBusinessID = sampleData.ownedBusinessID
        _storageErrorMessage = State(initialValue: store.persistenceLoadError == nil ? nil
            : "Your saved venue and event changes couldn't be loaded. You can browse sample places, but editing is unavailable right now.")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.repositories, repositories)
                .environment(\.previewRepositories, previewRepositories)
                .environment(\.publicEvents, publicEventRepository)
                .environment(\.ownedBusinessID, ownedBusinessID)
                .environment(\.savedEventsStore, savedEvents)
                .errorAlert($storageErrorMessage)
        }
    }
}
