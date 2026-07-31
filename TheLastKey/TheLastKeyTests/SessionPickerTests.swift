import XCTest
import SwiftData
@testable import TheLastKey

@MainActor
final class SessionPickerTests: XCTestCase {

    // The container must stay alive for the test body — a ModelContext does
    // not keep its container alive, and using it afterwards traps.
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Entry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func day(_ offset: Int) -> Date {
        Date(timeIntervalSinceReferenceDate: TimeInterval(offset) * 86_400)
    }

    private func insert(_ entries: [Entry], into container: ModelContainer) {
        for entry in entries { container.mainContext.insert(entry) }
    }

    func test_reviewAgainComesFirst() throws {
        let container = try makeContainer()
        let review = Entry(text: "review", meaning: "복습",
                           dateAdded: day(0), dateLastSeen: day(9), needsReview: true)
        let unseen = Entry(text: "unseen", meaning: "새것", dateAdded: day(1))
        let seen = Entry(text: "seen", meaning: "본것",
                         dateAdded: day(0), dateLastSeen: day(2))
        insert([seen, unseen, review], into: container)

        let picked = SessionPicker.pick(from: [seen, unseen, review], limit: 5)
        XCTAssertEqual(picked.map(\.text), ["review", "unseen", "seen"])
    }

    func test_reviewAgainOrderedByOldestLastSeen() throws {
        let container = try makeContainer()
        let older = Entry(text: "older", meaning: "-",
                          dateAdded: day(0), dateLastSeen: day(3), needsReview: true)
        let newer = Entry(text: "newer", meaning: "-",
                          dateAdded: day(0), dateLastSeen: day(7), needsReview: true)
        // Flagged but never seen: nil coalesces to .distantPast, so it leads.
        let neverSeen = Entry(text: "never", meaning: "-",
                              dateAdded: day(0), needsReview: true)
        insert([newer, older, neverSeen], into: container)

        let picked = SessionPicker.pick(from: [newer, older, neverSeen], limit: 5)
        XCTAssertEqual(picked.map(\.text), ["never", "older", "newer"])
    }

    func test_unseenOrderedByDateAdded() throws {
        let container = try makeContainer()
        let addedLater = Entry(text: "later", meaning: "-", dateAdded: day(5))
        let addedFirst = Entry(text: "first", meaning: "-", dateAdded: day(1))
        insert([addedLater, addedFirst], into: container)

        let picked = SessionPicker.pick(from: [addedLater, addedFirst], limit: 5)
        XCTAssertEqual(picked.map(\.text), ["first", "later"])
    }

    func test_seenOrderedByLeastRecentlySeen() throws {
        let container = try makeContainer()
        let recent = Entry(text: "recent", meaning: "-",
                           dateAdded: day(0), dateLastSeen: day(8))
        let stale = Entry(text: "stale", meaning: "-",
                          dateAdded: day(0), dateLastSeen: day(2))
        insert([recent, stale], into: container)

        let picked = SessionPicker.pick(from: [recent, stale], limit: 5)
        XCTAssertEqual(picked.map(\.text), ["stale", "recent"])
    }

    func test_limitCapsResult() throws {
        let container = try makeContainer()
        let entries = (0..<6).map {
            Entry(text: "e\($0)", meaning: "-", dateAdded: day($0))
        }
        insert(entries, into: container)

        let picked = SessionPicker.pick(from: entries, limit: 4)
        XCTAssertEqual(picked.map(\.text), ["e0", "e1", "e2", "e3"])
    }

    func test_limitLargerThanPoolReturnsAll() throws {
        let container = try makeContainer()
        let entries = (0..<3).map {
            Entry(text: "e\($0)", meaning: "-", dateAdded: day($0))
        }
        insert(entries, into: container)

        XCTAssertEqual(SessionPicker.pick(from: entries, limit: 15).count, 3)
    }

    func test_emptyPoolReturnsEmpty() {
        XCTAssertTrue(SessionPicker.pick(from: [], limit: 5).isEmpty)
    }
}
