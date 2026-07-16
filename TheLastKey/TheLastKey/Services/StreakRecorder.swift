import Foundation
import SwiftData

/// Records "today's session was completed" as a PracticeDay row — one per
/// calendar day, incremented on repeat sessions the same day.
enum StreakRecorder {
    @discardableResult
    static func recordCompletion(in context: ModelContext,
                                 now: Date = .now,
                                 calendar: Calendar = .current) -> PracticeDay {
        let day = calendar.startOfDay(for: now)
        let predicate = #Predicate<PracticeDay> { $0.date == day }
        if let existing = try? context.fetch(FetchDescriptor(predicate: predicate)).first {
            existing.sessionsCompleted += 1
            return existing
        }
        let record = PracticeDay(date: day)
        context.insert(record)
        return record
    }
}
