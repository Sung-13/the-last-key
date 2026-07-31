import Foundation
import SwiftUI

/// Detects that the app has come back to the foreground on a later calendar
/// day than it was last used on.
///
/// The morning ritual (alarm stopped → Shortcuts "Open App") depends on
/// landing on Today. A phone idle on a charger overnight is under no memory
/// pressure, so iOS usually keeps the app suspended rather than terminating
/// it — and a resume restores last night's tab instead of Today.
enum DayRollover {
    /// True when `now` and `lastActive` fall on different calendar days.
    ///
    /// Compared for inequality rather than "is later" on purpose: a clock
    /// moved backwards (westward travel, manual change) should still count as
    /// a rollover. Resetting when we needn't only ever lands the user on
    /// Today — the app's default screen — whereas missing a rollover costs
    /// them the morning ritual.
    static func crossedIntoNewDay(lastActive: Date?,
                                  now: Date,
                                  calendar: Calendar = .current) -> Bool {
        guard let lastActive else { return false }
        return calendar.startOfDay(for: now) != calendar.startOfDay(for: lastActive)
    }

    /// Folds a stream of `scenePhase` transitions into "should we reset to
    /// Today?". Sequencing here is fiddly enough to be worth testing directly:
    /// a resume arrives as .background → .inactive → .active, so anything that
    /// re-stamps the day on .inactive erases the evidence before .active can
    /// compare it, silently disabling the reset.
    struct Tracker {
        private var lastActive: Date?
        /// Only a real departure counts. .inactive alone is a transient
        /// interruption the user never chose — Control Centre, the app
        /// switcher, an incoming call — and must not read as an absence.
        private var didLeave = false

        init(launchedAt: Date? = nil) {
            lastActive = launchedAt
        }

        /// Records a phase transition. Returns true when this one is a resume
        /// onto a new day, i.e. the caller should reset to Today.
        mutating func record(phase: ScenePhase,
                             now: Date,
                             calendar: Calendar = .current) -> Bool {
            switch phase {
            case .background:
                didLeave = true
                lastActive = now
                return false
            case .active:
                defer { lastActive = now; didLeave = false }
                guard didLeave else { return false }
                return DayRollover.crossedIntoNewDay(lastActive: lastActive,
                                                     now: now,
                                                     calendar: calendar)
            default:
                return false
            }
        }
    }
}
