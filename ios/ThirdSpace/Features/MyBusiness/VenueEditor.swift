import MapKit
import SwiftUI

struct VenueEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.repositories) private var repositories
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var business: Business
    @State private var addressSearch = AddressSearch()
    @State private var addressQuery = ""
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var isResolvingAddress = false
    @State private var addressTask: Task<Void, Never>?
    @FocusState private var isSearchingAddress: Bool
    private let onSave: () async -> Void

    init(business: Business, onSave: @escaping () async -> Void) {
        _business = State(initialValue: business)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("About") {
                    TextField("Business name", text: $business.name)
                    CategoryPicker(selection: $business.category)
                    TextField("What makes it special?", text: $business.description, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section {
                    TextField("Search for your address", text: $addressQuery)
                        .textContentType(.fullStreetAddress)
                        .autocorrectionDisabled()
                        .focused($isSearchingAddress)
                    ForEach(addressSearch.suggestions, id: \.self) { suggestion in
                        Button {
                            guard !isResolvingAddress else { return }
                            isResolvingAddress = true
                            addressTask = Task { await choose(suggestion) }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.title)
                                    .foregroundStyle(Theme.text)
                                Text(suggestion.subtitle)
                                    .font(.footnote)
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    }
                    if isResolvingAddress {
                        ProgressView("Finding this address")
                    }
                    if let message = addressSearch.errorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    VenueMapPreview(business: business)
                        .listRowInsets(EdgeInsets())
                    Label(business.address, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Location")
                } footer: {
                    Text("Search for your address, then check the pin sits on your front door.")
                }
            }
            .disabled(isSaving || isResolvingAddress)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Your Venue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView().accessibilityLabel("Saving venue")
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(business.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving || isResolvingAddress)
                }
            }
            .onChange(of: addressQuery) { _, query in
                addressSearch.update(query: query)
            }
            .errorAlert($errorMessage)
            .interactiveDismissDisabled(isSaving)
            .onDisappear { addressTask?.cancel() }
        }
    }

    private func choose(_ suggestion: MKLocalSearchCompletion) async {
        defer {
            isResolvingAddress = false
            addressTask = nil
        }
        do {
            guard let place = try await addressSearch.resolve(suggestion) else {
                errorMessage = "Couldn't find that address. Try another suggestion."
                return
            }
            try Task.checkCancellation()
            isSearchingAddress = false
            withAnimation(Motion.animation(reduceMotion: reduceMotion)) {
                business.address = place.address
                business.latitude = place.coordinate.latitude
                business.longitude = place.coordinate.longitude
                addressQuery = ""
            }
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "Couldn't find that address. Try another suggestion."
        }
    }

    private func save() async {
        guard !isSaving, !isResolvingAddress,
              !business.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSaving = true
        defer { isSaving = false }
        business.name = business.name.trimmingCharacters(in: .whitespacesAndNewlines)
        business.description = business.description.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            _ = try await repositories.businesses.save(business)
            await onSave()
            dismiss()
        } catch {
            errorMessage = "Your changes couldn't be saved. Please try again."
        }
    }
}
