import SwiftUI
import SwiftData

struct LibraryView: View {
    /// Owned by ContentView so the Today tab's empty-state CTA can open
    /// the add sheet after switching tabs.
    @Binding var showingAdd: Bool

    @Environment(\.modelContext) private var context
    @Query(sort: \Entry.dateAdded, order: .reverse) private var entries: [Entry]

    @State private var editingEntry: Entry?
    @State private var searchText = ""

    private static let lastSeenFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    private var filteredEntries: [Entry] {
        guard !searchText.isEmpty else { return entries }
        let q = searchText.lowercased()
        return entries.filter {
            $0.text.lowercased().contains(q) ||
            $0.meaning.lowercased().contains(q) ||
            ($0.note ?? "").lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredEntries) { entry in
                    Button {
                        editingEntry = entry
                    } label: {
                        row(for: entry)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Theme.surface)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            delete(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            editingEntry = entry
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(Theme.amber)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .searchable(text: $searchText)
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                EntryEditView(entry: nil)
            }
            .sheet(item: $editingEntry) { entry in
                EntryEditView(entry: entry)
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No sentences yet",
                        systemImage: "key.fill",
                        description: Text("Tap + to add your first sentence.")
                    )
                }
            }
        }
    }

    private func row(for entry: Entry) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.text)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(entry.meaning)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(lastSeenCaption(for: entry))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)

            if entry.needsReview {
                Circle()
                    .fill(Theme.amber)
                    .frame(width: 9, height: 9)
                    .padding(.top, 6)
                    .accessibilityLabel("Needs review")
            }
        }
        .contentShape(Rectangle())
    }

    private func lastSeenCaption(for entry: Entry) -> String {
        guard let lastSeen = entry.dateLastSeen else { return "Not practiced yet" }
        let relative = Self.lastSeenFormatter.localizedString(for: lastSeen, relativeTo: .now)
        return "Practiced \(relative)"
    }

    private func delete(_ entry: Entry) {
        context.delete(entry)
        try? context.save()
    }
}

#Preview("Seeded library") {
    LibraryView(showingAdd: .constant(false))
        .modelContainer(PreviewSamples.modelContainer)
}

#Preview("Empty library") {
    LibraryView(showingAdd: .constant(false))
        .modelContainer(for: Entry.self, inMemory: true)
}
