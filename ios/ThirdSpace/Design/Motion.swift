import SwiftUI

/// Shared, interruptible motion for the controls we own. Native scrolling and sheets
/// keep their system gestures, momentum, and rubber banding.
enum Motion {
    static func reduceMotionRequested(systemPreference: Bool) -> Bool {
        systemPreference || ProcessInfo.processInfo.arguments.contains("-reduce-motion")
    }

    static func animation(reduceMotion: Bool) -> Animation? {
        reduceMotionRequested(systemPreference: reduceMotion) ? nil : .smooth(duration: 0.35)
    }

    static func selectionAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotionRequested(systemPreference: reduceMotion) ? nil : .snappy(duration: 0.25, extraBounce: 0)
    }
}
