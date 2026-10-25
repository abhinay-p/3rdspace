import Foundation

@Observable
final class PublicEventsRepository: BusinessRepository, EventRepository {
    private(set) var revision = 0
    private(set) var isRefreshing = false
    private(set) var refreshFailed = false
    private(set) var lastUpdated: Date?
    private var catalogs: [String: PublicEventCatalog] = [:]
    @ObservationIgnored private var lastAttempt: Date?
    @ObservationIgnored private var lastNPSAttempt: Date?
    @ObservationIgnored private var failedSources: Set<String> = []
    @ObservationIgnored private let cacheURL: URL?
    @ObservationIgnored private let session: URLSession
    @ObservationIgnored private let now: () -> Date

    init(cacheURL: URL? = URL.cachesDirectory.appending(path: "3rdSpace/public-events.json"),
         session: URLSession = .shared,
         bundledCatalogs: [String: PublicEventCatalog]? = nil,
         now: @escaping () -> Date = { .now }) {
        self.cacheURL = cacheURL
        self.session = session
        self.now = now
        catalogs = bundledCatalogs ?? Self.loadBundledCatalogs(now: now())
        if let cacheURL, let data = try? Data(contentsOf: cacheURL),
           let cached = try? JSONDecoder().decode([String: PublicEventCatalog].self, from: data) {
            for (source, catalog) in cached where catalog.fetchedAt > (catalogs[source]?.fetchedAt ?? .distantPast) {
                catalogs[source] = catalog
            }
        }
        // DEMO_KEY is public and shared. Avoid exhausting its low request quota.
        lastNPSAttempt = catalogs["nps"]?.fetchedAt
        updateTimestamp()
    }

    var sourceSummary: String {
        if isRefreshing { return "Checking public event calendars…" }
        let coverage = catalogs.filter { $0.key != "npsPlaces" }.values.contains { $0.isComplete == false }
            ? "Selected public listings" : "Public listings"
        if refreshFailed {
            return "\(coverage) saved \(lastUpdated?.formatted(date: .abbreviated, time: .omitted) ?? "earlier") · refresh unavailable"
        }
        if let lastUpdated {
            return "\(coverage) · checked \(lastUpdated.formatted(.relative(presentation: .named)))"
        }
        return "Public event calendars"
    }

    var hasCompleteEventCoverage: Bool {
        !isRefreshing && !refreshFailed
            && ["nps", "loc"].allSatisfy { catalogs[$0]?.isComplete == true }
    }

    func refresh(force: Bool = false) async {
        guard !isRefreshing, !Task.isCancelled else { return }
        let startedAt = now()
        let minimumInterval: TimeInterval = force ? 60 : 15 * 60
        guard lastAttempt.map({ startedAt.timeIntervalSince($0) >= minimumInterval }) ?? true else { return }
        lastAttempt = startedAt
        isRefreshing = true
        defer { isRefreshing = false }
        // Four pages per six hours keeps DEMO_KEY usage bounded. The feed records
        // incomplete coverage explicitly instead of implying a nationwide census.
        let shouldFetchNPS = lastNPSAttempt.map { startedAt.timeIntervalSince($0) >= 6 * 60 * 60 } ?? true
        if shouldFetchNPS { lastNPSAttempt = startedAt }
        async let nps: Result<PublicEventCatalog, Error>? = shouldFetchNPS ? fetchNPS(at: startedAt) : nil
        async let loc = fetchLibraryOfCongress(at: startedAt)
        let results = await (nps, loc)
        guard !Task.isCancelled else {
            // Cancellation is not a publisher outage, and a retry should remain available.
            lastAttempt = nil
            if shouldFetchNPS { lastNPSAttempt = nil }
            return
        }
        if let nps = results.0 {
            switch nps {
            case .success(let catalog):
                catalogs["nps"] = catalog
                failedSources.remove("nps")
            case .failure: failedSources.insert("nps")
            }
        }
        switch results.1 {
        case .success(let catalog):
            catalogs["loc"] = catalog
            failedSources.remove("loc")
        case .failure: failedSources.insert("loc")
        }
        refreshFailed = !failedSources.isEmpty
        updateTimestamp()
        revision += 1
        persist()
    }

    func businesses(in bounds: MapBounds, category: Business.Category?) async throws -> [Business] {
        allBusinesses.filter {
            bounds.contains(latitude: $0.latitude, longitude: $0.longitude)
                && (category == nil || $0.category == category)
        }.sorted { $0.name < $1.name }
    }

    func business(id: Business.ID) async throws -> Business? {
        allBusinesses.first { $0.id == id }
    }

    func upcomingEvents(for businessID: Business.ID) async throws -> [Event] {
        allEvents.filter { $0.businessID == businessID && $0.endTime > now() }.sorted { $0.startTime < $1.startTime }
    }

    func upcomingEvents(in bounds: MapBounds) async throws -> [Event] {
        let ids = Set(allBusinesses.filter { bounds.contains(latitude: $0.latitude, longitude: $0.longitude) }.map(\.id))
        return allEvents.filter { ids.contains($0.businessID) && $0.endTime > now() }.sorted { $0.startTime < $1.startTime }
    }

    func save(_ business: Business) async throws -> Business { throw PublicListingError.readOnly }
    func save(_ event: Event) async throws -> Event { throw PublicListingError.readOnly }
    func delete(_ eventID: Event.ID) async throws { throw PublicListingError.readOnly }

    private var allBusinesses: [Business] {
        Array(Dictionary(catalogs.values.flatMap(\.businesses).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }).values)
    }
    private var allEvents: [Event] {
        Array(Dictionary(catalogs.values.flatMap(\.events).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }).values)
    }

    private func fetchNPS(at fetchedAt: Date) async -> Result<PublicEventCatalog, Error> {
        do {
            let day = DateFormatter()
            day.locale = Locale(identifier: "en_US_POSIX")
            day.timeZone = TimeZone(secondsFromGMT: 0)
            day.dateFormat = "yyyy-MM-dd"
            var pages: [PublicEventCatalog] = []
            for page in 1...4 {
                try Task.checkCancellation()
                var components = URLComponents(string: "https://developer.nps.gov/api/v1/events")!
                components.queryItems = [
                    .init(name: "api_key", value: "DEMO_KEY"),
                    .init(name: "dateStart", value: day.string(from: fetchedAt)),
                    .init(name: "dateEnd", value: day.string(from: fetchedAt.addingTimeInterval(60 * 24 * 60 * 60))),
                    .init(name: "pageSize", value: "50"),
                    .init(name: "pageNumber", value: String(page)),
                    .init(name: "expandRecurring", value: "false")
                ]
                let data = try await fetch(components.url!)
                let response = try JSONDecoder().decode(NPSEventResponse.self, from: data)
                guard response.pagenumber.flatMap(Int.init) == page else { throw PublicEventFeedError.invalidPagination }
                pages.append(try PublicEventMapper.nps(data, now: fetchedAt))
                if !response.hasMorePages { break }
            }
            return .success(Self.merge(pages, fetchedAt: fetchedAt))
        } catch { return .failure(error) }
    }

    private func fetchLibraryOfCongress(at fetchedAt: Date) async -> Result<PublicEventCatalog, Error> {
        do {
            var next: URL? = URL(string: "https://www.loc.gov/events/?fo=json&c=100&at=results,pagination")
            var pages: [PublicEventCatalog] = []
            var visited: Set<URL> = []
            for _ in 0..<4 {
                try Task.checkCancellation()
                guard let url = next else { break }
                guard url.scheme == "https", url.host() == "www.loc.gov", url.path == "/events/",
                      visited.insert(url).inserted else { throw PublicEventFeedError.invalidPagination }
                let data = try await fetch(url)
                let response = try JSONDecoder().decode(PublicEventMapper.LOCResponse.self, from: data)
                pages.append(try PublicEventMapper.libraryOfCongress(data, now: fetchedAt))
                if let rawNext = response.pagination?.next {
                    guard let resolved = URL(string: rawNext, relativeTo: url)?.absoluteURL else {
                        throw PublicEventFeedError.invalidPagination
                    }
                    next = resolved
                } else { next = nil }
            }
            return .success(Self.merge(pages, fetchedAt: fetchedAt))
        } catch { return .failure(error) }
    }

    private func fetch(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 25
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private static func merge(_ pages: [PublicEventCatalog], fetchedAt: Date) -> PublicEventCatalog {
        let businesses = Dictionary(pages.flatMap(\.businesses).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let events = Dictionary(pages.flatMap(\.events).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return PublicEventCatalog(businesses: Array(businesses.values), events: Array(events.values),
                                  fetchedAt: fetchedAt, isComplete: pages.last?.isComplete ?? true)
    }

    private func updateTimestamp() {
        // Venue geography has its own provenance and must not make event checks look stale.
        lastUpdated = catalogs.filter { $0.key != "npsPlaces" }.values.map(\.fetchedAt).min()
    }

    private func persist() {
        guard let cacheURL, let data = try? JSONEncoder().encode(catalogs) else { return }
        do {
            try FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: cacheURL, options: .atomic)
        } catch {
            // A failed cache write must never discard a successfully loaded public feed.
        }
    }

    private static func loadBundledCatalogs(now: Date) -> [String: PublicEventCatalog] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let metadata: [String: SnapshotMetadata]
        if let url = Bundle.main.url(forResource: "public-source-metadata", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? decoder.decode([String: SnapshotMetadata].self, from: data) {
            metadata = decoded
        } else { metadata = [:] }
        var catalogs: [String: PublicEventCatalog] = [:]
        for (source, filename) in [("nps", "nps-events-snapshot"), ("loc", "loc-events-snapshot"), ("npsPlaces", "nps-places-snapshot")] {
            guard let stamp = metadata[source],
                  let url = Bundle.main.url(forResource: filename, withExtension: "json"),
                  let data = try? Data(contentsOf: url) else { continue }
            var catalog: PublicEventCatalog?
            switch source {
            case "nps": catalog = try? PublicEventMapper.nps(data, now: now)
            case "loc": catalog = try? PublicEventMapper.libraryOfCongress(data, now: now)
            default: catalog = try? PublicEventMapper.npsPlaces(data, fetchedAt: stamp.fetchedAt)
            }
            if var catalog {
                catalog.fetchedAt = stamp.fetchedAt
                catalog.isComplete = stamp.isComplete
                catalogs[source] = catalog
            }
        }
        return catalogs
    }

    private struct SnapshotMetadata: Decodable {
        let fetchedAt: Date
        let isComplete: Bool
    }
    private enum PublicListingError: Error { case readOnly }
}
