import Foundation

/// Order-preserving queue for a practice session. "Got it" clears the card;
/// "Review again" sends it to the back of today's stack until it is
/// remembered once. A card missed at any point in the session stays flagged
/// for a future session even if it is remembered on a later pass today.
struct PracticeQueue<Card: Identifiable> {
    private(set) var pending: [Card]
    private(set) var clearedCount = 0
    private var missedIDs: Set<Card.ID> = []

    /// Number of distinct cards in the session.
    let total: Int

    init(_ cards: [Card]) {
        pending = cards
        total = cards.count
    }

    var current: Card? { pending.first }
    var isDone: Bool { pending.isEmpty }

    /// Fraction of the session's cards cleared so far (0…1).
    var progress: Double {
        total == 0 ? 1 : Double(clearedCount) / Double(total)
    }

    /// 1-based position for a "Card X of N" label, clamped to `total`.
    var position: Int { min(clearedCount + 1, total) }

    /// Grades the current card and advances. Returns true when the card
    /// should stay flagged as needing review in a future session.
    @discardableResult
    mutating func advance(remembered: Bool) -> Bool {
        guard let card = pending.first else { return false }
        pending.removeFirst()
        if remembered {
            clearedCount += 1
            return missedIDs.contains(card.id)
        } else {
            missedIDs.insert(card.id)
            pending.append(card)
            return true
        }
    }
}
