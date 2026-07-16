import Foundation

/// Pure streak math over startOfDay-normalized dates. Days are walked with
/// `calendar.date(byAdding:)` so DST transitions never break a run.
enum StreakCalculator {
    /// Consecutive completed days ending today or yesterday. Today counts as
    /// pending until it's over: an unfinished today never breaks the run.
    static func currentStreak(completedDays: Set<Date>,
                              today: Date = .now,
                              calendar: Calendar = .current) -> Int {
        let todayStart = calendar.startOfDay(for: today)
        var cursor = completedDays.contains(todayStart)
            ? todayStart
            : calendar.date(byAdding: .day, value: -1, to: todayStart)!
        var streak = 0
        while completedDays.contains(cursor) {
            streak += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }

    static func longestStreak(completedDays: Set<Date>,
                              calendar: Calendar = .current) -> Int {
        var longest = 0
        for day in completedDays {
            // Only count forward from run heads.
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day),
                  !completedDays.contains(previous) else { continue }
            var length = 0
            var cursor = day
            while completedDays.contains(cursor) {
                length += 1
                cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
            }
            longest = max(longest, length)
        }
        return longest
    }

    static func isDone(on date: Date,
                       completedDays: Set<Date>,
                       calendar: Calendar = .current) -> Bool {
        completedDays.contains(calendar.startOfDay(for: date))
    }
}
