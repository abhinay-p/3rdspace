import MapKit
import SwiftUI

private enum DiscoverySection: String, CaseIterable, Identifiable {
    case events = "Events", places = "Places"
    var id: Self { self }
}

private struct DiscoveryEventDestination: Hashable {
    let event: Event
    let business: Business
}

struct DiscoverView: View {
    @Environment(\.repositories) private var repositories
    @Environment(\.publicEvents) private var publicEvents
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = DiscoverModel()
    @State private var locationProvider = LocationProvider()
    @State private var neighborhood = DiscoveryNeighborhood.all[0]
    @State private var position: MapCameraPosition = .region(USMapArea.mainland.region)
    @State private var visibleRegion = USMapArea.mainland.region
    @State private var overview: USMapArea? = .mainland
    @State private var mapArea: USMapArea = .mainland
    @State private var mapErrorMessage: String?
    @State private var category: Business.Category?
    @State private var searchText = ""
    @State private var timeFilter: DiscoveryTimeFilter = .anytime
    @State private var section: DiscoverySection = .events
    @State private var showsMap = false
    @State private var showsAreaPicker = false
    @State private var showsSources = false
    @State private var selectedBusinessID: Business.ID?
    @State private var selectedBusiness: Business?
    @State private var refreshCount = 0
    @State private var visibleEventLimit = 24
    @State private var usesCurrentLocation = false
    @State private var isRequestingCurrentLocation = false
    @State private var isExploringMapArea = false
    @FocusState private var searchIsFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !showsMap {
                    Picker("Explore", selection: $section) {
                        ForEach(DiscoverySection.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                    .accessibilityIdentifier("discovery-section")
                }
                CategoryChips(selection: $category)
                if showsMap {
                    discoveryMap.transition(.opacity)
                } else {
                    feed.transition(.opacity)
                }
            }
            .background(Theme.background)
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(showsMap ? .inline : .large)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search events and places")
            .searchFocused($searchIsFocused)
            .onSubmit(of: .search) { searchIsFocused = false }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showsAreaPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            if isRequestingCurrentLocation { ProgressView().controlSize(.mini) }
                            else { Image(systemName: usesCurrentLocation ? "location.fill" : "mappin") }
                            Text(areaTitle).lineLimit(1).truncationMode(.tail)
                                .frame(maxWidth: showsMap ? 110 : 180, alignment: .leading)
                            Image(systemName: "chevron.down").font(.caption2.weight(.semibold))
                        }.font(.subheadline.weight(.semibold))
                    }
                    .accessibilityLabel("Choose area, \(areaTitle)")
                    .accessibilityIdentifier("neighborhood-picker")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Picker("When", selection: $timeFilter) {
                            ForEach(DiscoveryTimeFilter.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Label(timeFilter.rawValue, systemImage: timeFilter == .anytime ? "calendar" : "calendar.badge.checkmark")
                    }
                    .accessibilityIdentifier("time-filter")
                    Button {
                        withAnimation(Motion.animation(reduceMotion: reduceMotion)) { showsMap.toggle() }
                    } label: {
                        Label(showsMap ? "List" : "Map", systemImage: showsMap ? "list.bullet" : "map")
                    }
                    .accessibilityIdentifier("discovery-mode")
                }
            }
            .navigationDestination(for: DiscoveryEventDestination.self) { destination in
                EventDetailView(event: destination.event, business: destination.business)
            }
            .task(id: query) { await model.load(query, from: repositories) }
            .task { await publicEvents?.refresh() }
            .onChange(of: publicEvents?.revision) { _, _ in refreshCount += 1 }
            .onAppear { refreshCount += 1 }
            .onChange(of: searchText) { _, _ in visibleEventLimit = 24 }
            .onChange(of: category) { _, _ in visibleEventLimit = 24 }
            .onChange(of: timeFilter) { _, _ in visibleEventLimit = 24 }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    refreshCount += 1
                    Task { await publicEvents?.refresh() }
                }
            }
            .onChange(of: locationProvider.location) { _, location in
                guard isRequestingCurrentLocation, let location else { return }
                isRequestingCurrentLocation = false
                guard USMapGeometry.contains(location.coordinate) else {
                    mapErrorMessage = "3rdSpace is available in the United States for now. Choose a US area to explore."
                    return
                }
                overview = nil
                isExploringMapArea = false
                mapArea = .containing(location.coordinate)
                usesCurrentLocation = true
                moveMap(to: MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000))
            }
            .onChange(of: locationProvider.errorMessage) { _, message in
                if message != nil { isRequestingCurrentLocation = false }
            }
            .onChange(of: selectedBusinessID) { _, id in
                if let business = model.businesses.first(where: { $0.id == id }) {
                    selectedBusiness = business
                } else if id == nil && showsMap {
                    selectedBusiness = nil
                }
            }
            .alert("Location unavailable", isPresented: Binding(isPresent: $locationProvider.errorMessage)) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(locationProvider.errorMessage ?? "")
            }
            .errorAlert($mapErrorMessage)
            .sheet(item: $selectedBusiness, onDismiss: { selectedBusinessID = nil }) { business in
                BusinessSheet(business: business)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            }
            .sheet(isPresented: $showsAreaPicker) {
                DiscoveryAreaPicker { selection in
                    switch selection {
                    case .region(let area): choose(area)
                    case .city(let place): choose(place)
                    case .currentLocation:
                        isRequestingCurrentLocation = true
                        locationProvider.requestAccess()
                    }
                }
            }
            .sheet(isPresented: $showsSources) {
                PublicEventSourcesView()
            }
        }
    }

    private var areaTitle: String {
        isRequestingCurrentLocation ? "Locating…" : (isExploringMapArea ? "Map Area" : (usesCurrentLocation ? "Nearby" : (overview?.rawValue ?? neighborhood.name)))
    }

    private var query: DiscoverQuery {
        let bounds = !showsMap && overview == .mainland && !isExploringMapArea
            ? MapBounds(minLatitude: -90, maxLatitude: 90, minLongitude: -180, maxLongitude: 180)
            : MapBounds(region: visibleRegion)
        return DiscoverQuery(bounds: bounds, category: category, refresh: refreshCount,
                             searchText: searchText, timeFilter: timeFilter,
                             timeZoneID: usesCurrentLocation || overview != nil || isExploringMapArea ? nil : neighborhood.timeZoneID,
                             usesVenueTimeZones: overview != nil || isExploringMapArea)
    }

    private var feed: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(section == .events ? "Upcoming events" : "Places to explore")
                            .font(.title2.bold()).foregroundStyle(Theme.text)
                        Text(isExploringMapArea ? "In the visible map area" : (usesCurrentLocation ? "Around your current location" : (overview?.rawValue ?? neighborhood.city)))
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if timeFilter != .anytime {
                        Text(timeFilter.rawValue).font(.caption.weight(.medium))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .accessibilityAddTraits(.isHeader)

                if model.loadFailed {
                    unavailableState(title: "Unable to load", message: "Try loading this area again.", symbol: "wifi.exclamationmark")
                } else if model.isLoading && !model.hasLoaded {
                    ProgressView("Loading nearby…").frame(maxWidth: .infinity).padding(40)
                } else if model.hasLoaded && (section == .events ? model.events.isEmpty : model.businesses.isEmpty) {
                    unavailableState(title: "No matches nearby",
                                     message: "Try another search, change your filters, or explore another area.", symbol: "magnifyingglass")
                } else if section == .events {
                    ForEach(model.events.prefix(visibleEventLimit)) { event in
                        if let business = model.businesses.first(where: { $0.id == event.businessID }) {
                            NavigationLink(value: DiscoveryEventDestination(event: event, business: business)) {
                                DiscoveryEventCard(event: event, business: business)
                            }.buttonStyle(.plain)
                        }
                    }
                    if model.events.count > visibleEventLimit {
                        Button {
                            visibleEventLimit += 24
                        } label: {
                            Text("Show more events").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ForEach(model.businesses) { business in
                        Button { selectedBusiness = business } label: {
                            DiscoveryPlaceRow(business: business,
                                              hasEvent: model.businessIDsWithEventsSoon.contains(business.id))
                        }.buttonStyle(.plain)
                    }
                }
                if let publicEvents {
                    Button { showsSources = true } label: {
                        Label(publicEvents.sourceSummary, systemImage: "info.circle")
                            .font(.footnote).foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .accessibilityLabel("About these events. \(publicEvents.sourceSummary)")
                }
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollBounceBehavior(.basedOnSize)
        .refreshable {
            await publicEvents?.refresh(force: true)
            await model.load(query, from: repositories)
        }
    }

    private var discoveryMap: some View {
        Map(position: $position, bounds: mapArea.cameraBounds, interactionModes: [.pan, .zoom], selection: $selectedBusinessID) {
            MapPolygon(USMapGeometry.outsideMask)
                .foregroundStyle(Theme.background).mapOverlayLevel(level: .aboveLabels)
            if usesCurrentLocation { UserAnnotation() }
            ForEach(MapPlaceCluster.make(businesses: model.businesses, latitudeDelta: visibleRegion.span.latitudeDelta)) { cluster in
                if cluster.businesses.count == 1, let business = cluster.businesses.first {
                    Annotation(business.name, coordinate: business.coordinate, anchor: .bottom) {
                        BusinessPin(category: business.category, isSelected: selectedBusinessID == business.id,
                                    hasEventSoon: model.businessIDsWithEventsSoon.contains(business.id))
                    }
                    .annotationTitles(.hidden).tag(business.id)
                } else {
                    Annotation("\(cluster.businesses.count) places", coordinate: .init(latitude: cluster.latitude, longitude: cluster.longitude)) {
                        Button {
                            zoomInto(cluster)
                        } label: {
                            Text(cluster.businesses.count, format: .number)
                                .font(.subheadline.weight(.semibold)).monospacedDigit()
                                .foregroundStyle(.white)
                                .frame(minWidth: 44, minHeight: 44)
                                .background(Theme.accent, in: Circle())
                                .overlay { Circle().strokeBorder(.white, lineWidth: 2) }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(cluster.businesses.count) places. Zoom in")
                        .accessibilityIdentifier("map-cluster")
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControls { MapCompass() }
        .onMapCameraChange(frequency: .onEnd) { context in
            if showsMap {
                visibleRegion = context.region
                if position.positionedByUser {
                    isExploringMapArea = true
                    usesCurrentLocation = false
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Picker("Map region", selection: Binding(get: { mapArea }, set: { choose($0) })) {
                Text("Mainland").tag(USMapArea.mainland)
                Text("Alaska").tag(USMapArea.alaska)
                Text("Hawaii").tag(USMapArea.hawaii)
            }
            .pickerStyle(.segmented)
            .padding(12)
            .background(.regularMaterial)
            .accessibilityIdentifier("map-region")
        }
        .overlay(alignment: .bottom) {
            if model.loadFailed {
                Button("Unable to load. Try again.") { refreshCount += 1 }
                    .font(.subheadline).padding().background(.regularMaterial, in: Capsule()).padding()
            } else if model.hasLoaded && model.businesses.isEmpty {
                StatusPill(text: "No matches in this area.", symbolName: "magnifyingglass")
            }
        }
        .sensoryFeedback(.selection, trigger: selectedBusinessID)
    }

    private func unavailableState(title: String, message: String, symbol: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(message)
        } actions: {
            Button(model.loadFailed ? "Try again" : "Clear filters") {
                searchText = ""
                category = nil
                timeFilter = .anytime
                refreshCount += 1
            }.buttonStyle(.bordered)
            if !model.loadFailed {
                Button("Choose another area") { showsAreaPicker = true }
            }
        }
    }

    private func choose(_ area: USMapArea) {
        overview = area
        mapArea = area
        resetLocationRequest()
        moveMap(to: area.region)
    }

    private func choose(_ place: DiscoveryNeighborhood) {
        neighborhood = place
        overview = nil
        mapArea = .containing(.init(latitude: place.latitude, longitude: place.longitude))
        resetLocationRequest()
        searchText = ""
        moveMap(to: place.region)
    }

    private func resetLocationRequest() {
        usesCurrentLocation = false
        isExploringMapArea = false
        isRequestingCurrentLocation = false
        locationProvider.cancelRequest()
        visibleEventLimit = 24
    }

    private func moveMap(to region: MKCoordinateRegion) {
        visibleRegion = region
        withAnimation(Motion.animation(reduceMotion: reduceMotion)) { position = .region(region) }
    }

    private func zoomInto(_ cluster: MapPlaceCluster) {
        isExploringMapArea = true
        usesCurrentLocation = false
        moveMap(to: cluster.zoomRegion)
    }
}
