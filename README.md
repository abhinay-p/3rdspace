# 3rdSpace

A native iPhone app for discovering places and public events across the United States.

## Run

Requires Xcode 26 or later, targeting iOS 18+.

1. Open ios/ThirdSpace.xcodeproj.
2. Select an iPhone simulator and run.
3. Browse **Events** or **Places**, search, choose an area, or switch to **Map**. The map has separate mainland, Alaska, and Hawaii controls.
4. Save events to return to them in **Saved**. No account is needed.

Discover and Saved use real National Park Service and Library of Congress listings. Bundled publisher snapshots allow browsing before the first network refresh. Dates are never moved forward to make an old event appear upcoming. Organizer links provide current registration, fees, meeting points, and schedule changes.

Coverage is deliberately described as **selected public listings**, not every event in the United States. Public API quotas limit refreshes; unavailable refreshes retain the last listings and their original timestamps. See [data sources and limitations](DATA_SOURCES.md).

**My Business** is a separate local preview workspace. Venue edits, event creation, and deletion persist on this device; they are not published to public discovery.

## Interface and motion

The interface uses SwiftUI navigation stacks, native search, segmented controls, system typography and colors, grouped lists, and native sheets and swipe actions. Map and list preserve the area the user is exploring.

Design/Motion.swift centralizes calm, interruptible springs. Native scrolling, sheet dragging, and overscroll keep system momentum and rubber banding. Owned animations skip motion when Reduce Motion is enabled. Motion guidance follows [apple-motion](https://github.com/oJaqob/standards/blob/main/skills/apple-motion/SKILL.md).

## Tests

Run the ThirdSpace scheme with Command-U, or:

    xcodebuild -project ios/ThirdSpace.xcodeproj \
      -scheme ThirdSpace \
      -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
      test CODE_SIGNING_ALLOWED=NO

Unit tests cover event timing and time zones, discovery filtering, persistent local edits, bookmarks, map geography, publisher parsing, pagination metadata, cache freshness, and corrupt-cache recovery.

UI tests cover native search, area selection, Places, mainland/Alaska/Hawaii switching, rapid map/list changes, saving across relaunch, unsaving, and business event creation. Tests launch with isolated sample data and bookmarks. The optional address autocomplete test requires Apple's network service; enable THIRDSPACE_RUN_NETWORK_TESTS=1 in the UI test scheme to run it.

## Structure

- App/ — app entry, repositories, native tabs
- Design/ — semantic theme, shared motion, view helpers
- Features/Discover/ — browsing, search, US map, area picker, details
- Features/Saved/ — saved upcoming plans
- Features/MyBusiness/ — local business preview and editors
- Components/ — reusable event/place rows, pins, map previews
- Data/ — repositories, public source adapters, bookmarks, preview persistence
- Resources/ — publisher snapshots, provenance, time zones, US boundary
- ThirdSpaceTests/, ThirdSpaceUITests/ — unit and UI coverage

The Xcode project is generated from ios/project.yml with XcodeGen. Sources use synchronized folders, so new Swift files are discovered automatically. After changing project settings, run xcodegen generate inside ios/.

No third-party runtime packages are required.
