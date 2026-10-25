import MapKit

@Observable
final class AddressSearch: NSObject, MKLocalSearchCompleterDelegate {
    private(set) var suggestions: [MKLocalSearchCompletion] = []
    private(set) var errorMessage: String?
    private var hasQuery = false
    @ObservationIgnored private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func update(query: String) {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        hasQuery = !query.isEmpty
        errorMessage = nil
        if query.isEmpty {
            completer.cancel()
            suggestions = []
        } else {
            completer.queryFragment = query
        }
    }

    func resolve(_ suggestion: MKLocalSearchCompletion) async throws -> (address: String, coordinate: CLLocationCoordinate2D)? {
        let response = try await MKLocalSearch(request: MKLocalSearch.Request(completion: suggestion)).start()
        guard let item = response.mapItems.first else { return nil }
        let address = [suggestion.title, suggestion.subtitle]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        return (address, item.placemark.coordinate)
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = hasQuery ? Array(completer.results.prefix(5)) : []
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        suggestions = []
        if hasQuery {
            errorMessage = "Address suggestions aren't available. Check your connection and try again."
        }
    }
}
