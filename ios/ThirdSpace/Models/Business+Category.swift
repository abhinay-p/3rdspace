extension Business {
    // Raw values are the wire format shared with the API.
    nonisolated enum Category: String, CaseIterable, Codable, Identifiable {
        case cafe = "CAFE"
        case restaurant = "RESTAURANT"
        case bar = "BAR"
        case shop = "SHOP"
        case artsStudio = "ARTS_STUDIO"
        case fitness = "FITNESS"
        case communitySpace = "COMMUNITY_SPACE"
        case services = "SERVICES"
        case other = "OTHER"

        var id: Self { self }

        var title: String {
            switch self {
            case .cafe: "Café"
            case .restaurant: "Restaurant"
            case .bar: "Bar"
            case .shop: "Shop"
            case .artsStudio: "Arts & Studio"
            case .fitness: "Fitness"
            case .communitySpace: "Community Space"
            case .services: "Services"
            case .other: "Other"
            }
        }

        var symbolName: String {
            switch self {
            case .cafe: "cup.and.saucer.fill"
            case .restaurant: "fork.knife"
            case .bar: "wineglass.fill"
            case .shop: "bag.fill"
            case .artsStudio: "paintpalette.fill"
            case .fitness: "figure.run"
            case .communitySpace: "person.3.fill"
            case .services: "wrench.and.screwdriver.fill"
            case .other: "sparkles"
            }
        }
    }
}
