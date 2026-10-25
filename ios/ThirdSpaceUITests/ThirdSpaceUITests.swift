import XCTest

nonisolated final class ThirdSpaceUITests: XCTestCase {
    @MainActor func testSearchSaveAndUnsaveAcrossRelaunch() {
        let app = launchApp()
        search("Pub Quiz", in: app)
        let event = button(containing: "Pub Quiz Night", in: app)
        XCTAssertTrue(event.waitForExistence(timeout: 10))
        event.tap()
        let save = app.buttons["save-event"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()
        XCTAssertEqual(save.label, "Unsave event")
        snapshot("event-detail-saved", of: app)

        app.terminate()
        app.launchArguments = ["-ui-testing", "-preserve-saved-events"]
        app.launch()
        app.buttons["Saved"].tap()
        let saved = button(containing: "Pub Quiz Night", in: app)
        XCTAssertTrue(saved.waitForExistence(timeout: 10))
        snapshot("saved-events", of: app)
        saved.tap()
        app.buttons["save-event"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Something to look forward to"].waitForExistence(timeout: 5))
    }

    @MainActor func testSearchEmptyStateAndRecovery() {
        let app = launchApp()
        search("no-such-neighborhood-event-92471", in: app)
        XCTAssertTrue(app.staticTexts["No matches nearby"].waitForExistence(timeout: 5))
        app.buttons["Clear filters"].tap()
        XCTAssertTrue(app.staticTexts["Upcoming events"].waitForExistence(timeout: 5))
        snapshot("discover-feed", of: app)
    }

    @MainActor func testUSMapRegionsAndListSwitch() {
        let app = launchApp()
        app.buttons["discovery-mode"].tap()
        let regions = app.segmentedControls["map-region"]
        XCTAssertTrue(regions.waitForExistence(timeout: 10))
        snapshot("us-mainland-map", of: app)
        regions.buttons["Alaska"].tap()
        XCTAssertTrue(regions.buttons["Hawaii"].exists)
        snapshot("us-alaska-map", of: app)
        regions.buttons["Hawaii"].tap()
        snapshot("us-hawaii-map", of: app)
        app.buttons["discovery-mode"].tap()
        XCTAssertTrue(app.staticTexts["Upcoming events"].waitForExistence(timeout: 5))
    }

    @MainActor func testChooseAreaAndPlacesFlow() {
        let app = launchApp()
        app.buttons["neighborhood-picker"].tap()
        XCTAssertTrue(app.navigationBars["Choose Area"].waitForExistence(timeout: 5))
        let citySearch = app.searchFields["Search cities"]
        citySearch.tap()
        citySearch.typeText("Mission District")
        let city = button(containing: "Mission District", in: app)
        XCTAssertTrue(city.waitForExistence(timeout: 5))
        city.tap()
        app.segmentedControls["discovery-section"].buttons["Places"].tap()
        let place = button(containing: "Casa Nopal", in: app)
        XCTAssertTrue(place.waitForExistence(timeout: 5))
        place.tap()
        XCTAssertTrue(app.navigationBars["Place"].waitForExistence(timeout: 5))
        snapshot("place-sheet", of: app)
        app.buttons["Close"].tap()
        XCTAssertTrue(app.staticTexts["Places to explore"].waitForExistence(timeout: 5))
    }

    @MainActor func testRapidMapListSwitchWithReducedMotion() {
        let app = launchApp(extraArguments: ["-reduce-motion"])
        for _ in 0..<3 {
            app.buttons["discovery-mode"].tap()
            XCTAssertTrue(app.segmentedControls["map-region"].waitForExistence(timeout: 5))
            app.buttons["discovery-mode"].tap()
            XCTAssertTrue(app.segmentedControls["discovery-section"].waitForExistence(timeout: 5))
        }
        snapshot("reduce-motion-discover", of: app)
    }

    @MainActor func testClusterZoomPreservesMapAreaInList() {
        let app = launchApp()
        app.buttons["discovery-mode"].tap()
        XCTAssertTrue(app.segmentedControls["map-region"].waitForExistence(timeout: 5))
        let cluster = app.descendants(matching: .any).matching(identifier: "map-cluster").firstMatch
        XCTAssertTrue(cluster.waitForExistence(timeout: 10))
        cluster.tap()
        let area = app.buttons["neighborhood-picker"]
        let focusedArea = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@", "Map Area"), object: area)
        XCTAssertEqual(XCTWaiter.wait(for: [focusedArea], timeout: 5), .completed)
        snapshot("cluster-zoom", of: app)
        app.buttons["discovery-mode"].tap()
        XCTAssertTrue(app.staticTexts["In the visible map area"].waitForExistence(timeout: 5))
    }

    @MainActor func testMyBusinessFlow() {
        let app = launchApp()
        app.buttons["My Business"].tap()
        XCTAssertTrue(app.buttons["Edit Venue"].waitForExistence(timeout: 5))
        snapshot("my-business", of: app)
        app.buttons["New Event"].tap()
        let title = app.textFields["Title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Save"].isEnabled)
        title.tap()
        title.typeText("Latte Art Night")
        app.buttons["Save"].tap()
        XCTAssertTrue(button(containing: "Latte Art Night", in: app).waitForExistence(timeout: 5))
        snapshot("event-posted", of: app)
    }

    @MainActor func testVenueAddressSearch() throws {
        guard ProcessInfo.processInfo.environment["THIRDSPACE_RUN_NETWORK_TESTS"] == "1" else {
            throw XCTSkip("Opt-in test requires Apple's live address search service.")
        }
        let app = launchApp()
        app.buttons["My Business"].tap()
        app.buttons["Edit Venue"].tap()
        let search = app.textFields["Search for your address"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("600 Valencia St")
        let suggestion = button(containing: "Valencia", in: app)
        XCTAssertTrue(suggestion.waitForExistence(timeout: 20))
        suggestion.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "600 Valencia")).firstMatch.waitForExistence(timeout: 10))
    }

    @MainActor private func launchApp(extraArguments: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"] + extraArguments
        app.launch()
        return app
    }

    @MainActor private func search(_ query: String, in app: XCUIApplication) {
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(query + "\n")
    }

    @MainActor private func button(containing text: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    @MainActor private func snapshot(_ name: String, of app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
