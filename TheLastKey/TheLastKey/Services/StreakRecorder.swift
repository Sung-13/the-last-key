import Foundation
import SwiftData
import WidgetKit

/// Records "today's session was completed" as a PracticeDay row — one per
/// calendar day, incremented on repeat sessions the same day.
enum StreakRecorder {
    @discardableResult
    static func recordCompletion(in context: ModelContext,
                                 now: Date = .now,
                                 calendar: Calendar = .current) -> PracticeDay {
        let day = calendar.startOfDay(for: now)
        let predicate = #Predicate<PracticeDay> { $0.date == day }
        let record: PracticeDay
        if let existing = try? context.fetch(FetchDescriptor(predicate: predicate)).first {
            existing.sessionsCompleted += 1
            record = existing
        } else {
            record = PracticeDay(date: day)
            context.insert(record)
        }
        mirrorToWidget(in: context)
        return record
    }

    /// Mirrors all completed days into the App Group store and refreshes the
    /// widget. Also called when the app becomes active, so the widget heals
    /// after being added late or after a reinstall.
    static func mirrorToWidget(in context: ModelContext) {
        let days = (try? context.fetch(FetchDescriptor<PracticeDay>()))?.map(\.date) ?? []
        SharedStreakStore.save(days)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
