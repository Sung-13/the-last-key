#if DEBUG
import Foundation
import SwiftData

enum PreviewSamples {
    static func makeEntries() -> [Entry] {
        let now = Date.now
        let day: TimeInterval = 86_400
        return [
            Entry(
                text: "He had to bite the bullet.",
                meaning: "어려운 일을 감내하다",
                note: "Idiom — accept something difficult.",
                dateAdded: now.addingTimeInterval(-day * 7)
            ),
            Entry(
                text: "I don't know what to say.",
                meaning: "뭐라고 말해야 할지 모르겠다",
                dateAdded: now.addingTimeInterval(-day * 6),
                dateLastSeen: now.addingTimeInterval(-day),
                seenCount: 2
            ),
            Entry(
                text: "albeit",
                meaning: "비록 ~이긴 하지만",
                note: "Formal conjunction.",
                dateAdded: now.addingTimeInterval(-day * 5)
            ),
            Entry(
                text: "I have 5 apples.",
                meaning: "사과 5개가 있다",
                dateAdded: now.addingTimeInterval(-day * 4)
            ),
            Entry(
                text: "Let's call it a day.",
                meaning: "오늘은 이만 마치자",
                dateAdded: now.addingTimeInterval(-day * 3),
                dateLastSeen: now.addingTimeInterval(-3_600 * 12),
                needsReview: true,
                seenCount: 1
            ),
            Entry(
                text: "Hello, world!",
                meaning: "안녕, 세상!",
                dateAdded: now.addingTimeInterval(-day * 2)
            ),
            Entry(
                text: "She took it with a grain of salt.",
                meaning: "그녀는 그것을 곧이곧대로 받아들이지 않았다",
                note: "Skeptical reception.",
                dateAdded: now.addingTimeInterval(-day)
            ),
        ]
    }

    @MainActor
    static let modelContainer: ModelContainer = {
        let schema = Schema([Entry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        for entry in makeEntries() {
            container.mainContext.insert(entry)
        }
        return container
    }()
}
#endif
