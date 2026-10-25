import SwiftUI

struct RootView: View {
    @Environment(\.previewRepositories) private var previewRepositories
    var body: some View {
        TabView {
            Tab("Discover", systemImage: "map.fill") {
                DiscoverView()
            }
            Tab("Saved", systemImage: "bookmark.fill") {
                SavedEventsView()
            }
            Tab("My Business", systemImage: "storefront.fill") {
                MyBusinessView()
                    .environment(\.repositories, previewRepositories)
            }
        }
        .tint(Theme.accent)
    }
}
