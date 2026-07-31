import Foundation

/// App Group-shared mirror of the completed practice days. The app writes it
/// after recording a completion (and on foreground); the widget reads it and
/// recomputes the streak with StreakCalculator. The SwiftData store itself is
/// never shared — this keeps the widget read-only and migration-free.
struct SharedStreakStore {
    static let suiteName = "group.com.sung13.TheLastKey"
    private static let key = "completedDayStarts"

    /// `days` must be startOfDay-normalized. Bounded — the widget only ever
    /// looks back weeks, not years. `suiteName` is overridable for tests so
    /// they don't touch the real App Group container.
    static func save(_ days: [Date], suiteName: String = SharedStreakStore.suiteName) {
        UserDefaults(suiteName: suiteName)?
            .set(Array(days.sorted().suffix(400)), forKey: key)
    }

    static func load(suiteName: String = SharedStreakStore.suiteName) -> Set<Date> {
        Set((UserDefaults(suiteName: suiteName)?.array(forKey: key) as? [Date]) ?? [])
    }
}
