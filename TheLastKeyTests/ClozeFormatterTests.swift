import XCTest
@testable import TheLastKey

final class ClozeFormatterTests: XCTestCase {
    func test_singleWord() {
        XCTAssertEqual(ClozeFormatter.cue("albeit"), "a_____")
    }

    func test_multiWordSentence() {
        XCTAssertEqual(
            ClozeFormatter.cue("He had to bite the bullet."),
            "H_ h__ t_ b___ t__ b_____."
        )
    }

    func test_punctuation() {
        XCTAssertEqual(ClozeFormatter.cue("Wait, what?"), "W___, w___?")
    }

    func test_contractionWithStraightApostrophe() {
        XCTAssertEqual(ClozeFormatter.cue("don't"), "d___'_")
    }

    func test_contractionWithCurlyApostrophe() {
        XCTAssertEqual(ClozeFormatter.cue("don\u{2019}t"), "d___\u{2019}_")
    }

    func test_capitalisationPreserved() {
        XCTAssertEqual(ClozeFormatter.cue("Hello"), "H____")
    }

    func test_numeralsLeftAsIs() {
        XCTAssertEqual(ClozeFormatter.cue("I have 5 apples."), "I h___ 5 a_____.")
    }

    func test_emptyString() {
        XCTAssertEqual(ClozeFormatter.cue(""), "")
    }
}
