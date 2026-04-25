import Foundation

enum ClozeFormatter {
    /// Returns a first-letter cued version of `sentence`. Each word's first
    /// letter is preserved; subsequent letters become `_`. Whitespace,
    /// punctuation, and digits are preserved as-is. Apostrophes (straight or
    /// curly) inside a word do not reset the first-letter state, so contractions
    /// like "don't" become "d___'_".
    static func cue(_ sentence: String) -> String {
        var result = ""
        var firstLetterSeen = false

        for ch in sentence {
            if ch.isLetter {
                if firstLetterSeen {
                    result.append("_")
                } else {
                    result.append(ch)
                    firstLetterSeen = true
                }
            } else if ch == "'" || ch == "\u{2019}" || ch == "\u{2018}" {
                result.append(ch)
            } else {
                result.append(ch)
                firstLetterSeen = false
            }
        }

        return result
    }
}
