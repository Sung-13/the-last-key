import XCTest
import SwiftData
@testable import TheLastKey

final class StreakCalculatorTests: XCTestCase {
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return cal
    }()

    private func day(_ year: Int, _ month: Int, _ dayOfMonth: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: dayOfMonth))!
    }

    private func streak(_ days: Set<Date>, today: Date) -> Int {
        StreakCalculator.currentStreak(completedDays: days, today: today, calendar: calendar)
    }

    func test_noCompletedDaysIsZero() {
        XCTAssertEqual(streak([], today: day(2026, 7, 16)), 0)
    }

    func test_onlyTodayDoneCountsOne() {
        XCTAssertEqual(streak([day(2026, 7, 16)], today: day(2026, 7, 16)), 1)
    }

    func test_runEndingToday() {
        let days: Set = [day(2026, 7, 14), day(2026, 7, 15), day(2026, 7, 16)]
        XCTAssertEqual(streak(days, today: day(2026, 7, 16)), 3)
    }

    func test_pendingTodayDoesNotBreakRun() {
        // 3-day run ending yesterday; today not (yet) done.
        let days: Set = [day(2026, 7, 13), day(2026, 7, 14), day(2026, 7, 15)]
        XCTAssertEqual(streak(days, today: day(2026, 7, 16)), 3)
    }

    func test_gapTwoDaysAgoResetsStreak() {
        let days: Set = [day(2026, 7, 12), day(2026, 7, 13), day(2026, 7, 15)]
        XCTAssertEqual(streak(days, today: day(2026, 7, 16)), 1)
    }

    func test_missedYesterdayAndTodayIsZero() {
        XCTAssertEqual(streak([day(2026, 7, 13)], today: day(2026, 7, 16)), 0)
    }

    func test_streakAnchoredOnTodayWhenDone() {
        // Yesterday missed, today done: streak restarts at 1.
        let days: Set = [day(2026, 7, 13), day(2026, 7, 14), day(2026, 7, 16)]
        XCTAssertEqual(streak(days, today: day(2026, 7, 16)), 1)
    }

    func test_longestStreakAcrossMultipleRuns() {
        let days: Set = [
            day(2026, 6, 1), day(2026, 6, 2),
            day(2026, 6, 10), day(2026, 6, 11), day(2026, 6, 12), day(2026, 6, 13),
            day(2026, 7, 1),
        ]
        XCTAssertEqual(StreakCalculator.longestStreak(completedDays: days, calendar: calendar), 4)
    }

    func test_isDoneNormalizesToStartOfDay() {
        let morning = calendar.date(from: DateComponents(year: 2026, month: 7, day: 16,
                                                         hour: 7, minute: 30))!
        XCTAssertTrue(StreakCalculator.isDone(on: morning,
                                              completedDays: [day(2026, 7, 16)],
                                              calendar: calendar))
    }

    func test_runAcrossDSTTransitionStillCounts() {
        // BST began 2026-03-29; a run across the transition must stay intact.
        var london = Calendar(identifier: .gregorian)
        london.timeZone = TimeZone(identifier: "Europe/London")!
        let days = Set([27, 28, 29, 30].map {
            london.date(from: DateComponents(year: 2026, month: 3, day: $0))!
        })
        let today = london.date(from: DateComponents(year: 2026, month: 3, day: 30))!
        XCTAssertEqual(StreakCalculator.currentStreak(completedDays: days,
                                                      today: today,
                                                      calendar: london), 4)
    }
}

@MainActor
final class StreakRecorderTests: XCTestCase {
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return cal
    }()

    // The container must stay alive for the test body — a ModelContext does
    // not keep its container alive, and using it afterwards traps.
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: PracticeDay.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int,
                      _ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day,
                                           hour: hour, minute: minute))!
    }

    func test_firstCompletionInsertsStartOfDayRow() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let now = date(2026, 7, 16, 7, 30)
        StreakRecorder.recordCompletion(in: context, now: now, calendar: calendar)

        let rows = try context.fetch(FetchDescriptor<PracticeDay>())
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.date, calendar.startOfDay(for: now))
        XCTAssertEqual(rows.first?.sessionsCompleted, 1)
    }

    func test_secondSessionSameDayIncrementsSingleRow() throws {
        let container = try makeContainer()
        let context = container.mainContext
        StreakRecorder.recordCompletion(in: context, now: date(2026, 7, 16, 7, 30),
                                        calendar: calendar)
        StreakRecorder.recordCompletion(in: context, now: date(2026, 7, 16, 21, 0),
                                        calendar: calendar)

        let rows = try context.fetch(FetchDescriptor<PracticeDay>())
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.sessionsCompleted, 2)
    }

    func test_dayBoundaryProducesSeparateRows() throws {
        let container = try makeContainer()
        let context = container.mainContext
        StreakRecorder.recordCompletion(in: context, now: date(2026, 7, 15, 23, 59),
                                        calendar: calendar)
        StreakRecorder.recordCompletion(in: context, now: date(2026, 7, 16, 0, 1),
                                        calendar: calendar)

        let rows = try context.fetch(FetchDescriptor<PracticeDay>())
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(Set(rows.map(\.date)),
                       [calendar.startOfDay(for: date(2026, 7, 15, 12, 0)),
                        calendar.startOfDay(for: date(2026, 7, 16, 12, 0))])
    }
}
