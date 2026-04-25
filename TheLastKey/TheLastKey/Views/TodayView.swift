import SwiftUI
import SwiftData

struct TodayView: View {
    @Query private var entries: [Entry]
    @AppStorage("dailySessionSize") private var dailySessionSize: Int = 5

    @State private var session: [Entry] = []
    @State private var showingPractice = false

    private var lastReviewedCaption: String {
        guard let mostRecent = entries.compactMap({ $0.dateLastSeen }).max() else {
            return "No sessions yet."
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Last reviewed \(formatter.localizedString(for: mostRecent, relativeTo: .now))"
    }

    private var previewedSession: [Entry] {
        SessionPicker.pick(from: entries, limit: dailySessionSize)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("The Last Key")
                    .font(.largeTitle.bold())

                Text("\(entries.count) sentence\(entries.count == 1 ? "" : "s") in your library")
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    let picked = SessionPicker.pick(from: entries, limit: dailySessionSize)
                    if !picked.isEmpty {
                        session = picked
                        showingPractice = true
                    }
                } label: {
                    Text(previewedSession.isEmpty
                         ? "Add some sentences first"
                         : "Start today's session (\(previewedSession.count) card\(previewedSession.count == 1 ? "" : "s"))")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(previewedSession.isEmpty ? Color.gray.opacity(0.3) : Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(previewedSession.isEmpty)
                .padding(.horizontal)

                Text(lastReviewedCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .navigationDestination(isPresented: $showingPractice) {
                PracticeView(session: session)
            }
        }
    }
}

#Preview("Seeded library") {
    TodayView()
        .modelContainer(PreviewSamples.modelContainer)
}

#Preview("Empty library") {
    TodayView()
        .modelContainer(for: Entry.self, inMemory: true)
}
