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
        XCTAssertEqual(ClozeFormatter.cue("don't"), "d__'_")
    }

    func test_contractionWithCurlyApostrophe() {
        XCTAssertEqual(ClozeFormatter.cue("don\u{2019}t"), "d__\u{2019}_")
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

    // MARK: - keywordCue

    func test_keyword_hidesContentWordsOnly() {
        XCTAssertEqual(
            ClozeFormatter.keywordCue("He had to bite the bullet."),
            "He had to b___ the b_____."
        )
    }

    func test_keyword_functionWordsAndDigitsPreserved() {
        XCTAssertEqual(
            ClozeFormatter.keywordCue("I have 5 apples."),
            "I have 5 a_____."
        )
    }

    func test_keyword_contractionStopwordStaysVisible() {
        XCTAssertEqual(
            ClozeFormatter.keywordCue("I don't know what to say."),
            "I don't k___ what to s__."
        )
    }

    func test_keyword_curlyContractionStopwordStaysVisible() {
        XCTAssertEqual(
            ClozeFormatter.keywordCue("I don\u{2019}t know."),
            "I don\u{2019}t k___."
        )
    }

    func test_keyword_singleContentWord() {
        XCTAssertEqual(ClozeFormatter.keywordCue("albeit"), "a_____")
    }

    func test_keyword_allStopwordsFallsBackToFullCue() {
        XCTAssertEqual(
            ClozeFormatter.keywordCue("It is what it is."),
            "I_ i_ w___ i_ i_."
        )
    }

    func test_keyword_repeatedContentWordHiddenEachTime() {
        XCTAssertEqual(
            ClozeFormatter.keywordCue("Practice makes practice easier."),
            "P_______ m____ p_______ e_____."
        )
    }

    func test_keyword_contentContraction() {
        XCTAssertEqual(
            ClozeFormatter.keywordCue("She wasn't gonna quit."),
            "She wasn't g____ q___."
        )
    }

    func test_keyword_emptyString() {
        XCTAssertEqual(ClozeFormatter.keywordCue(""), "")
    }
}
