import SwiftUI
import SwiftData

struct ContentView: View {
    enum Tab: Hashable {
        case today, library, settings
    }

    @Environment(\.modelContext) private var context
    @AppStorage("didSeedInitialEntries") private var didSeed = false

    @State private var selectedTab: Tab = .today
    @State private var showingAddEntry = false

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(onAddSentences: {
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
        .task { seedIfNeeded() }
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
