import Foundation

enum InitialSeed {
    static func entries() -> [Entry] {
        [
            Entry(
                text: "He had to bite the bullet.",
                meaning: "어려운 일을 감내하다",
                note: "Idiom — accept something difficult."
            ),
            Entry(
                text: "Let's call it a day.",
                meaning: "오늘은 이만 마치자"
            ),
            Entry(
                text: "She took it with a grain of salt.",
                meaning: "그녀는 그것을 곧이곧대로 받아들이지 않았다",
                note: "Skeptical reception."
            ),
            Entry(
                text: "I don't know what to say.",
                meaning: "뭐라고 말해야 할지 모르겠다"
            ),
            Entry(
                text: "albeit",
                meaning: "비록 ~이긴 하지만",
                note: "Formal conjunction."
            ),
            Entry(
                text: "Hello, world!",
                meaning: "안녕, 세상!"
            ),
            Entry(
                text: "I have 5 apples.",
                meaning: "사과 5개가 있다"
            ),
        ]
    }
}
