import Foundation

enum SessionPicker {
    /// Returns up to `limit` entries for today's session.
    /// Order: review-again items first (oldest dateLastSeen first), then
    /// unseen entries (oldest dateAdded first), then least-recently-seen.
    static func pick(from entries: [Entry], limit: Int) -> [Entry] {
        let reviewAgain = entries
            .filter { $0.needsReview }
            .sorted { ($0.dateLastSeen ?? .distantPast) < ($1.dateLastSeen ?? .distantPast) }

        let unseen = entries
            .filter { !$0.needsReview && $0.dateLastSeen == nil }
            .sorted { $0.dateAdded < $1.dateAdded }

        let seen = entries
            .filter { !$0.needsReview && $0.dateLastSeen != nil }
            .sorted { ($0.dateLastSeen ?? .distantPast) < ($1.dateLastSeen ?? .distantPast) }

        return Array((reviewAgain + unseen + seen).prefix(limit))
    }
}
