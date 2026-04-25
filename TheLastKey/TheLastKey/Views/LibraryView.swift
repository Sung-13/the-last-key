import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Entry.dateAdded, order: .reverse) private var entries: [Entry]

    @State private var showingAdd = false
    @State private var editingEntry: Entry?
    @State private var searchText = ""

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
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.text)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                            Text(entry.meaning)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: delete)
            }
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
                        systemImage: "text.book.closed",
                        description: Text("Tap + to add your first sentence.")
                    )
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(filteredEntries[index])
        }
        try? context.save()
    }
}

#Preview("Seeded library") {
    LibraryView()
        .modelContainer(PreviewSamples.modelContainer)
}

#Preview("Empty library") {
    LibraryView()
        .modelContainer(for: Entry.self, inMemory: true)
}
