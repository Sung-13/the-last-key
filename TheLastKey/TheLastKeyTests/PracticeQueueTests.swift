import XCTest
@testable import TheLastKey

final class PracticeQueueTests: XCTestCase {
    private struct Card: Identifiable {
        let id: Int
    }

    private func makeQueue(_ ids: Int...) -> PracticeQueue<Card> {
        PracticeQueue(ids.map(Card.init))
    }

    func test_rememberedCardIsCleared() {
        var queue = makeQueue(1, 2, 3)
        let flagged = queue.advance(remembered: true)
        XCTAssertFalse(flagged)
        XCTAssertEqual(queue.pending.map(\.id), [2, 3])
        XCTAssertEqual(queue.clearedCount, 1)
        XCTAssertEqual(queue.progress, 1.0 / 3.0, accuracy: 0.0001)
    }

    func test_missedCardRequeuesToBack() {
        var queue = makeQueue(1, 2)
        let flagged = queue.advance(remembered: false)
        XCTAssertTrue(flagged)
        XCTAssertEqual(queue.pending.map(\.id), [2, 1])
        XCTAssertEqual(queue.clearedCount, 0)
        XCTAssertEqual(queue.current?.id, 2)
    }

    func test_missedCardStaysFlaggedWhenRememberedLater() {
        var queue = makeQueue(1)
        XCTAssertTrue(queue.advance(remembered: false))
        XCTAssertEqual(queue.current?.id, 1)
        // Remembered on the second pass: cleared from today's stack, but
        // still flagged for a future session.
        XCTAssertTrue(queue.advance(remembered: true))
        XCTAssertTrue(queue.isDone)
    }

    func test_completionAfterAllCleared() {
        var queue = makeQueue(1, 2)
        queue.advance(remembered: true)
        XCTAssertFalse(queue.isDone)
        queue.advance(remembered: true)
        XCTAssertTrue(queue.isDone)
        XCTAssertEqual(queue.progress, 1)
    }

    func test_emptySession() {
        var queue = PracticeQueue<Card>([])
        XCTAssertTrue(queue.isDone)
        XCTAssertEqual(queue.progress, 1)
        XCTAssertFalse(queue.advance(remembered: true))
    }

    func test_positionLabelClampsToTotal() {
        var queue = makeQueue(1, 2)
        XCTAssertEqual(queue.position, 1)
        queue.advance(remembered: true)
        XCTAssertEqual(queue.position, 2)
        queue.advance(remembered: true)
        XCTAssertEqual(queue.position, 2)
    }
}
