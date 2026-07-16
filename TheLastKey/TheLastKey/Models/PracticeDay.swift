import Foundation
import SwiftData

/// One row per calendar day on which the daily session was completed.
/// `date` is always startOfDay in the local calendar.
@Model
final class PracticeDay {
    @Attribute(.unique) var date: Date
    var sessionsCompleted: Int

    init(date: Date, sessionsCompleted: Int = 1) {
        self.date = date
        self.sessionsCompleted = sessionsCompleted
    }
}
