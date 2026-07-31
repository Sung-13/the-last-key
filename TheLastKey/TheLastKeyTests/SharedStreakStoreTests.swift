import XCTest
@testable import TheLastKey

final class SharedStreakStoreTests: XCTestCase {

    // A private suite so tests never touch the real App Group container.
    private let testSuite = "SharedStreakStoreTests.scratch"

    override func setUp() {
        super.setUp()
        UserDefaults(suiteName: testSuite)?.removePersistentDomain(forName: testSuite)
    }

    override func tearDown() {
        UserDefaults(suiteName: testSuite)?.removePersistentDomain(forName: testSuite)
        super.tearDown()
    }

    private func day(_ offset: Int) -> Date {
        Date(timeIntervalSinceReferenceDate: TimeInterval(offset) * 86_400)
    }

    func test_roundTrip() {
        let days = [day(1), day(2), day(3)]
        SharedStreakStore.save(days, suiteName: testSuite)
        XCTAssertEqual(SharedStreakStore.load(suiteName: testSuite), Set(days))
    }

    func test_saveCapsAtLatest400() {
        let days = (0..<450).map(day)
        SharedStreakStore.save(days.shuffled(), suiteName: testSuite)

        let loaded = SharedStreakStore.load(suiteName: testSuite)
        XCTAssertEqual(loaded.count, 400)
        XCTAssertEqual(loaded, Set(days.suffix(400)), "Must keep the newest 400 days")
    }

    func test_saveOverwritesPreviousPayload() {
        SharedStreakStore.save([day(1), day(2)], suiteName: testSuite)
        SharedStreakStore.save([day(9)], suiteName: testSuite)
        XCTAssertEqual(SharedStreakStore.load(suiteName: testSuite), [day(9)])
    }

    func test_loadFromEmptySuiteReturnsEmptySet() {
        XCTAssertTrue(SharedStreakStore.load(suiteName: testSuite).isEmpty)
    }

    func test_loadIgnoresWrongTypePayload() {
        UserDefaults(suiteName: testSuite)?
            .set(["not", "dates"], forKey: "completedDayStarts")
        XCTAssertTrue(SharedStreakStore.load(suiteName: testSuite).isEmpty)
    }
}
