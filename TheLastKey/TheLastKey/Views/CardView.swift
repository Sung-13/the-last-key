import SwiftUI

struct CardView: View {
    let entry: Entry
    let onComplete: (_ remembered: Bool) -> Void

    @State private var revealed = false

    var body: some View {
        VStack(spacing: 24) {
            Text(entry.meaning)
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            sentenceCard

            if revealed, let note = entry.note, !note.isEmpty {
                Text(note)
                    .font(.system(.subheadline, design: .rounded))
                    .italic()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if revealed {
                Button {
                    SpeechService.shared.speak(entry.text)
                } label: {
                    Label("Listen", systemImage: "speaker.wave.2.fill")
                        .font(.system(.callout, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.amberDeep)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Theme.amber.opacity(0.16), in: Capsule())
                }
            }

            Spacer().frame(height: 4)

            if !revealed {
                Button("Reveal") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        revealed = true
                    }
                    SpeechService.shared.speak(entry.text)
                }
                .buttonStyle(DawnPrimaryButtonStyle())
                .padding(.horizontal)
            } else {
                HStack(spacing: 12) {
                    Button("Review again") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        revealed = false
                        onComplete(false)
                    }
                    .buttonStyle(DawnSecondaryButtonStyle())

                    Button("Got it") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        revealed = false
                        onComplete(true)
                    }
                    .buttonStyle(DawnPrimaryButtonStyle())
                }
                .padding(.horizontal)
            }
        }
    }

    private var sentenceCard: some View {
        ZStack {
            if revealed {
                Text(entry.text)
                    .transition(.blurReplace)
            } else {
                Text(cueText)
                    .transition(.blurReplace)
            }
        }
        .font(.system(.title2, design: .rounded).weight(.medium))
        .lineSpacing(6)
        .multilineTextAlignment(.center)
        .padding(.vertical, 36)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .dawnCard()
        .padding(.horizontal)
    }

    /// Keyword cloze with the blanks tinted amber and slightly spread, so
    /// hidden words read as distinct letter slots rather than one long rule.
    private var cueText: AttributedString {
        var attributed = AttributedString(ClozeFormatter.keywordCue(entry.text))
        var index = attributed.startIndex
        while index < attributed.endIndex {
            let next = attributed.characters.index(after: index)
            if attributed.characters[index] == "_" {
                attributed[index..<next].foregroundColor = Theme.amberDeep
                attributed[index..<next].kern = 1.5
            }
            index = next
        }
        return attributed
    }
}

#Preview("Cued (with note)") {
    CardView(
        entry: Entry(
            text: "He had to bite the bullet.",
            meaning: "어려운 일을 감내하다",
            note: "Idiom — accept something difficult."
        ),
        onComplete: { _ in }
    )
    .padding()
}

#Preview("Cued (single word)") {
    CardView(
        entry: Entry(text: "albeit", meaning: "비록 ~이긴 하지만"),
        onComplete: { _ in }
    )
    .padding()
}
