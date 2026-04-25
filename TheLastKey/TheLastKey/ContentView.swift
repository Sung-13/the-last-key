import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeedInitialEntries") private var didSeed = false

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }

            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
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
