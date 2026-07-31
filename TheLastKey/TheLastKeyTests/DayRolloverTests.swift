import XCTest
import SwiftUI
@testable import TheLastKey

final class DayRolloverTests: XCTestCase {
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return cal
    }()

    private func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day,
                                           hour: hour, minute: minute))!
    }

    private func crossed(from lastActive: Date?, to now: Date) -> Bool {
        DayRollover.crossedIntoNewDay(lastActive: lastActive, now: now, calendar: calendar)
    }

    // MARK: - crossedIntoNewDay

    func test_noPreviousActivityIsNotARollover() {
        XCTAssertFalse(crossed(from: nil, to: at(2026, 7, 31, 7, 0)))
    }

    func test_sameDayIsNotARollover() {
        XCTAssertFalse(crossed(from: at(2026, 7, 31, 9, 15), to: at(2026, 7, 31, 9, 20)))
    }

    func test_sameDayAcrossManyHoursIsNotARollover() {
        XCTAssertFalse(crossed(from: at(2026, 7, 31, 0, 1), to: at(2026, 7, 31, 23, 59)))
    }

    func test_overnightIntoTheMorningIsARollover() {
        XCTAssertTrue(crossed(from: at(2026, 7, 30, 23, 30), to: at(2026, 7, 31, 7, 0)))
    }

    func test_justPastMidnightIsARollover() {
        XCTAssertTrue(crossed(from: at(2026, 7, 30, 23, 59), to: at(2026, 7, 31, 0, 1)))
    }

    func test_severalDaysAwayIsARollover() {
        XCTAssertTrue(crossed(from: at(2026, 7, 25, 8, 0), to: at(2026, 7, 31, 8, 0)))
    }

    func test_clockMovedBackwardsCountsAsARollover() {
        // Westward travel: a different calendar day still resets, which is the
        // benign direction to err in.
        XCTAssertTrue(crossed(from: at(2026, 7, 31, 8, 0), to: at(2026, 7, 30, 18, 0)))
    }

    // MARK: - Tracker, driven with real scenePhase sequences

    /// Feeds a phase sequence through the tracker and returns the resets it asked for.
    private func resets(launchedAt: Date?,
                        _ steps: [(ScenePhase, Date)]) -> [Date] {
        var tracker = DayRollover.Tracker(launchedAt: launchedAt)
        return steps.compactMap { phase, now in
            tracker.record(phase: phase, now: now, calendar: calendar) ? now : nil
        }
    }

    func test_theMorningRitual_resumeNextDayResetsOnce() {
        // Left the app on Library last night, alarm-stopped resume this morning.
        // A resume arrives as .background -> .inactive -> .active.
        let fired = resets(launchedAt: at(2026, 7, 30, 21, 0), [
            (.inactive, at(2026, 7, 30, 22, 0)),
            (.background, at(2026, 7, 30, 22, 0)),
            (.inactive, at(2026, 7, 31, 7, 0)),
            (.active, at(2026, 7, 31, 7, 0)),
        ])
        XCTAssertEqual(fired, [at(2026, 7, 31, 7, 0)])
    }

    func test_inactiveOnTheWayBackDoesNotEraseTheStamp() {
        // Regression: stamping the day on .inactive too would re-stamp it to the
        // new day just before .active compares, silently disabling the reset.
        let fired = resets(launchedAt: at(2026, 7, 30, 23, 58), [
            (.inactive, at(2026, 7, 30, 23, 59)),
            (.background, at(2026, 7, 30, 23, 59)),
            (.inactive, at(2026, 7, 31, 0, 1)),
            (.active, at(2026, 7, 31, 0, 1)),
        ])
        XCTAssertEqual(fired.count, 1, "a resume onto a new day must still reset")
    }

    func test_sameDayResumeDoesNotReset() {
        // Stepping out to another app and coming straight back.
        let fired = resets(launchedAt: at(2026, 7, 31, 9, 0), [
            (.inactive, at(2026, 7, 31, 9, 5)),
            (.background, at(2026, 7, 31, 9, 5)),
            (.active, at(2026, 7, 31, 9, 8)),
        ])
        XCTAssertTrue(fired.isEmpty)
    }

    func test_transientInterruptionAcrossMidnightDoesNotReset() {
        // Control Centre / an incoming call / the app switcher at 00:01 while a
        // practice session is running: .inactive without ever reaching
        // .background. Must not pop the live session.
        let fired = resets(launchedAt: at(2026, 7, 30, 23, 58), [
            (.inactive, at(2026, 7, 31, 0, 1)),
            (.active, at(2026, 7, 31, 0, 2)),
        ])
        XCTAssertTrue(fired.isEmpty, "a transient interruption is not an absence")
    }

    func test_foregroundAcrossMidnightDoesNotReset() {
        // Practising straight through midnight sends no phase change at all.
        XCTAssertTrue(resets(launchedAt: at(2026, 7, 30, 23, 50), []).isEmpty)
    }

    func test_firstActivationAfterLaunchDoesNotReset() {
        // A cold launch already opens on Today; nothing to reset, and the
        // launch itself must not be mistaken for a return from absence.
        let fired = resets(launchedAt: at(2026, 7, 31, 7, 0), [
            (.active, at(2026, 7, 31, 7, 0)),
        ])
        XCTAssertTrue(fired.isEmpty)
    }

    func test_resetFiresOncePerResumeNotRepeatedly() {
        // Two same-day resumes after the rollover must stay quiet.
        let fired = resets(launchedAt: at(2026, 7, 30, 22, 0), [
            (.background, at(2026, 7, 30, 22, 0)),
            (.active, at(2026, 7, 31, 7, 0)),
            (.background, at(2026, 7, 31, 7, 30)),
            (.active, at(2026, 7, 31, 8, 0)),
        ])
        XCTAssertEqual(fired, [at(2026, 7, 31, 7, 0)])
    }
}
