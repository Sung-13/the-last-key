import SwiftUI
import SwiftData

struct ContentView: View {
    enum Tab: Hashable {
        case today, library, settings
    }

    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("didSeedInitialEntries") private var didSeed = false

    @State private var selectedTab: Tab = .today
    @State private var showingAddEntry = false
    @State private var rollover = DayRollover.Tracker()
    @State private var dayRolloverID = TodayView.noRollover

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(dayRolloverID: dayRolloverID, onAddSentences: {
                selectedTab = .library
                showingAddEntry = true
            })
            .tabItem { Label("Today", systemImage: "sun.max.fill") }
            .tag(Tab.today)

            LibraryView(showingAdd: $showingAddEntry)
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }
                .tag(Tab.library)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .task {
            seedIfNeeded()
            // Anchor the tracker at launch: `onChange(of: scenePhase)` is not
            // guaranteed to fire for the initial transition to .active, and an
            // unanchored first day reads as "no previous day", which would skip
            // the reset on the very first overnight resume.
            rollover = DayRollover.Tracker(launchedAt: .now)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                StreakRecorder.mirrorToWidget(in: context)
            }
            // A cold launch always opens on Today, but iOS keeps the app
            // suspended overnight on an idle phone, so the morning alarm
            // automation can otherwise resume straight into last night's tab.
            if rollover.record(phase: phase, now: .now) {
                selectedTab = .today
                dayRolloverID = UUID()
            }
        }
    }

    private func seedIfNeeded() {
        guard !didSeed else { return }
        let descriptor = FetchDescriptor<Entry>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else {
            didSeed = true
            return
        }
        for entry in InitialSeed.entries() {
            context.insert(entry)
        }
        try? context.save()
        didSeed = true
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSamples.modelContainer)
}
