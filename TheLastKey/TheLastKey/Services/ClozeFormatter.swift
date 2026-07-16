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
            } else if isApostrophe(ch) {
                result.append(ch)
            } else {
                result.append(ch)
                firstLetterSeen = false
            }
        }

        return result
    }

    /// Returns `sentence` with only its key words first-letter cued: content
    /// words (not in the stopword list) become `b___`-style cues while
    /// function words (the, to, he, had…) stay fully visible. Falls back to
    /// `cue(_:)` when the sentence contains no content words at all, so
    /// there is always something to recall.
    static func keywordCue(_ sentence: String) -> String {
        var result = ""
        var cuedAnything = false
        var word = ""

        func flushWord() {
            guard !word.isEmpty else { return }
            if isStopword(word) {
                result += word
            } else {
                result += cue(word)
                cuedAnything = true
            }
            word = ""
        }

        for ch in sentence {
            if ch.isLetter || isApostrophe(ch) {
                word.append(ch)
            } else {
                flushWord()
                result.append(ch)
            }
        }
        flushWord()

        return cuedAnything ? result : cue(sentence)
    }

    private static func isApostrophe(_ ch: Character) -> Bool {
        ch == "'" || ch == "\u{2019}" || ch == "\u{2018}"
    }

    private static func isStopword(_ word: String) -> Bool {
        // Curly apostrophes normalised so "don’t" matches "don't".
        let normalized = word.lowercased()
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{2018}", with: "'")
        return stopwords.contains(normalized)
    }

    /// English function words left visible by `keywordCue`.
    private static let stopwords: Set<String> = [
        // Articles & determiners
        "a", "an", "the", "this", "that", "these", "those", "each", "every",
        "some", "any", "no", "all", "both", "few", "more", "most", "other",
        "such", "own", "same",
        // Pronouns
        "i", "you", "he", "she", "it", "we", "they", "me", "him", "her", "us",
        "them", "my", "your", "his", "its", "our", "their", "mine", "yours",
        "hers", "ours", "theirs", "myself", "yourself", "himself", "herself",
        "itself", "ourselves", "themselves", "who", "whom", "whose", "which",
        "what", "someone", "something", "anyone", "anything",
        // Be / have / do and modals
        "am", "is", "are", "was", "were", "be", "been", "being", "have",
        "has", "had", "having", "do", "does", "did", "will", "would", "shall",
        "should", "can", "could", "may", "might", "must",
        // Conjunctions & particles
        "and", "or", "but", "nor", "so", "yet", "if", "then", "than",
        "because", "while", "although", "though", "when", "where", "why",
        "how", "as", "not",
        // Prepositions
        "of", "to", "in", "on", "at", "by", "for", "with", "from", "up",
        "down", "out", "off", "over", "under", "again", "into", "about",
        "between", "through", "during", "before", "after", "above", "below",
        "once", "there", "here",
        // Common contractions
        "it's", "that's", "there's", "here's", "what's", "who's", "let's",
        "i'm", "i've", "i'll", "i'd", "you're", "you've", "you'll", "you'd",
        "he's", "he'll", "he'd", "she's", "she'll", "she'd", "we're", "we've",
        "we'll", "we'd", "they're", "they've", "they'll", "they'd", "isn't",
        "aren't", "wasn't", "weren't", "don't", "doesn't", "didn't", "won't",
        "wouldn't", "can't", "couldn't", "shouldn't", "mustn't", "haven't",
        "hasn't", "hadn't",
    ]
}
