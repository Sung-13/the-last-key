import SwiftUI
import SwiftData

/// Identity-stable wrapper for a running practice session. Pushing via
/// `navigationDestination(item:)` keyed on this id keeps the PracticeView's
/// state alive across TodayView re-evaluations — with the plain
/// `isPresented:` variant, a @Query update mid-session (every card grade
/// saves) could pop and re-push the destination, silently restarting the
/// session with a fresh queue.
struct PracticeRoute: Identifiable, Hashable {
    let id = UUID()
    let entries: [Entry]

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct TodayView: View {
    /// Stable stand-in for "no rollover has happened yet". A `static let` is
    /// created once, so a defaulted `dayRolloverID` never spuriously changes
    /// between body evaluations the way an inline `UUID()` default would.
    static let noRollover = UUID()

    /// Changed by ContentView when the app returns to the foreground on a new
    /// calendar day. A session abandoned last night must not resume this
    /// morning — the new day gets a freshly picked queue.
    var dayRolloverID: UUID = TodayView.noRollover

    /// Invoked from the empty-library CTA; the parent switches to the
    /// Library tab and opens the add sheet.
    var onAddSentences: () -> Void = {}

    @Query private var entries: [Entry]
    @Query(sort: \PracticeDay.date) private var practiceDays: [PracticeDay]
    @AppStorage("dailySessionSize") private var dailySessionSize: Int = 5

    @State private var practiceRoute: PracticeRoute?

    private var greeting: (text: String, symbol: String) {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: ("Good morning", "sun.and.horizon.fill")
        case 12..<18: ("Good afternoon", "sun.max.fill")
        default: ("Good evening", "moon.stars.fill")
        }
    }

    private var reviewCount: Int {
        entries.filter(\.needsReview).count
    }

    private var lastReviewedCaption: String {
        guard let mostRecent = entries.compactMap({ $0.dateLastSeen }).max() else {
            return "No sessions yet."
        }
        guard Date.now.timeIntervalSince(mostRecent) >= 60 else {
            return "Last reviewed just now"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Last reviewed \(formatter.localizedString(for: mostRecent, relativeTo: .now))"
    }

    private var previewedSession: [Entry] {
        SessionPicker.pick(from: entries, limit: dailySessionSize)
    }

    private var doneToday: Bool {
        let todayStart = Calendar.current.startOfDay(for: .now)
        return practiceDays.contains { $0.date == todayStart }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header

                        heroCard

                        if !previewedSession.isEmpty {
                            TodaySessionPreview(entries: previewedSession,
                                                isDoneToday: doneToday)
                        }

                        if !entries.isEmpty {
                            StreakView(days: practiceDays)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    if previewedSession.isEmpty {
                        Button("Add your first sentence") {
                            onAddSentences()
                        }
                        .buttonStyle(DawnPrimaryButtonStyle())
                    } else {
                        Button {
                            practiceRoute = PracticeRoute(entries: previewedSession)
                        } label: {
                            Text("Start today's session · \(previewedSession.count) card\(previewedSession.count == 1 ? "" : "s")")
                        }
                        .buttonStyle(DawnPrimaryButtonStyle())
                    }

                    Text(lastReviewedCaption)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .background(Theme.background)
            }
            .navigationDestination(item: $practiceRoute) { route in
                PracticeView(session: route.entries)
            }
            .onChange(of: dayRolloverID) { _, _ in
                practiceRoute = nil
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: greeting.symbol)
                    .foregroundStyle(Theme.sunrise)
                Text(greeting.text)
                    .foregroundStyle(.secondary)
            }
            .font(.system(.subheadline, design: .rounded).weight(.medium))

            Text("The Last Key")
                .font(.system(.title, design: .rounded).bold())
        }
    }

    private var heroCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entries.count)")
                    .font(.system(.title, design: .rounded).bold())
                Text(entries.count == 1 ? "sentence in your library" : "sentences in your library")
                    .font(.system(.footnote, design: .rounded))
                    .opacity(0.92)
            }

            Spacer()

            if reviewCount > 0 {
                Text("\(reviewCount) to review")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.22), in: Capsule())
            }

            Image(systemName: "key.fill")
                .font(.system(size: 40))
                .rotationEffect(.degrees(-28))
                .foregroundStyle(.white.opacity(0.18))
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(Theme.sunrise, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Theme.coral.opacity(0.3), radius: 16, y: 8)
    }
}

#Preview("Seeded library") {
    TodayView()
        .modelContainer(PreviewSamples.modelContainer)
}

#Preview("Empty library") {
    TodayView()
        .modelContainer(for: [Entry.self, PracticeDay.self], inMemory: true)
}
