import SwiftUI
import SwiftData

struct PracticeView: View {
    let session: [Entry]

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var index = 0

    var body: some View {
        Group {
            if session.isEmpty {
                ContentUnavailableView("Nothing to practice", systemImage: "books.vertical")
            } else if index >= session.count {
                VStack(spacing: 20) {
                    Spacer()
                    Text("Done — see you tomorrow ☀️")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Button("Close") { dismiss() }
                        .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .padding()
            } else {
                VStack(spacing: 16) {
                    ProgressDots(total: session.count, current: index)
                        .padding(.top)

                    CardView(entry: session[index]) { remembered in
                        let entry = session[index]
                        entry.dateLastSeen = .now
                        entry.seenCount += 1
                        entry.needsReview = !remembered
                        try? context.save()

                        withAnimation {
                            index += 1
                        }
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden(false)
    }
}

private struct ProgressDots: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i < current ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview("Mid-session") {
    NavigationStack {
        PracticeView(session: Array(PreviewSamples.makeEntries().prefix(3)))
    }
    .modelContainer(PreviewSamples.modelContainer)
}

#Preview("Empty") {
    NavigationStack {
        PracticeView(session: [])
    }
    .modelContainer(PreviewSamples.modelContainer)
}
