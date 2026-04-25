import SwiftUI

struct CardView: View {
    let entry: Entry
    let onComplete: (_ remembered: Bool) -> Void

    @State private var revealed = false
    @State private var speech = SpeechService()

    var body: some View {
        VStack(spacing: 24) {
            Text(entry.meaning)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Divider()

            Text(revealed ? entry.text : ClozeFormatter.cue(entry.text))
                .font(.title2)
                .monospaced()
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

            if revealed, let note = entry.note, !note.isEmpty {
                Text(note)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if revealed {
                Button {
                    speech.speak(entry.text)
                } label: {
                    Label("Listen", systemImage: "play.circle.fill")
                        .font(.title3)
                }
            }

            Spacer().frame(height: 8)

            if !revealed {
                Button {
                    withAnimation {
                        revealed = true
                    }
                    speech.speak(entry.text)
                } label: {
                    Text("Reveal")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            } else {
                HStack(spacing: 12) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        revealed = false
                        onComplete(false)
                    } label: {
                        Text("Review again")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        revealed = false
                        onComplete(true)
                    } label: {
                        Text("Got it")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
            }
        }
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
