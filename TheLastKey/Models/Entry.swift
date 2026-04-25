import Foundation
import SwiftData

@Model
final class Entry {
    @Attribute(.unique) var id: UUID
    var text: String
    var meaning: String
    var note: String?
    var dateAdded: Date
    var dateLastSeen: Date?
    var needsReview: Bool
    var seenCount: Int

    init(
        id: UUID = UUID(),
        text: String,
        meaning: String,
        note: String? = nil,
        dateAdded: Date = .now,
        dateLastSeen: Date? = nil,
        needsReview: Bool = false,
        seenCount: Int = 0
    ) {
        self.id = id
        self.text = text
        self.meaning = meaning
        self.note = note
        self.dateAdded = dateAdded
        self.dateLastSeen = dateLastSeen
        self.needsReview = needsReview
        self.seenCount = seenCount
    }
}
