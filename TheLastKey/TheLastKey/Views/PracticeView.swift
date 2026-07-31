import SwiftUI
import SwiftData

struct PracticeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var queue: PracticeQueue<Entry>
    @State private var sunGlow = false

    init(session: [Entry]) {
        _queue = State(initialValue: PracticeQueue(session))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if queue.total == 0 {
                ContentUnavailableView("Nothing to practice", systemImage: "books.vertical")
            } else if queue.isDone {
                completion
            } else if let entry = queue.current {
                VStack(spacing: 20) {
                    progressHeader
                        .padding(.top, 8)

                    CardView(entry: entry) { remembered in
                        grade(entry, remembered: remembered)
                    }
                    .id(entry.id)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding()
            }
        }
        .onDisappear { SpeechService.shared.stop() }
    }

    private func grade(_ entry: Entry, remembered: Bool) {
        entry.dateLastSeen = .now
        entry.seenCount += 1
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            entry.needsReview = queue.advance(remembered: remembered)
        }
        if queue.isDone {
            // `advance` empties the queue exactly once per session, so this
            // records the completed day exactly once (unlike the completion
            // view's .onAppear, which re-fires on re-render).
            StreakRecorder.recordCompletion(in: context)
        }
        try? context.save()
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            Text("Card \(queue.position) of \(queue.total)")
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.amber.opacity(0.18))
                    Capsule()
                        .fill(Theme.sunrise)
                        .frame(width: queue.progress > 0
                               ? max(geo.size.width * queue.progress, 12)
                               : 0)
                }
            }
            .frame(height: 6)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: queue.progress)
        }
    }

    private var completion: some View {
        VStack(spacing: 20) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 72))
                .foregroundStyle(Theme.sunrise)
                .scaleEffect(sunGlow ? 1.08 : 0.94)
                .shadow(color: Theme.amber.opacity(0.5), radius: sunGlow ? 28 : 12)
                .onAppear {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                        sunGlow = true
                    }
                }

            Text("All done — see you tomorrow")
                .font(.system(.title2, design: .rounded).bold())
                .multilineTextAlignment(.center)

            Text("You worked through \(queue.total) card\(queue.total == 1 ? "" : "s") today.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)

            Button("Close") { dismiss() }
                .buttonStyle(DawnPrimaryButtonStyle())
                .frame(maxWidth: 220)
                .padding(.top, 8)
        }
        .padding(32)
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
