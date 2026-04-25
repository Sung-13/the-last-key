import SwiftUI
import SwiftData

struct EntryEditView: View {
    let entry: Entry?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var meaning = ""
    @State private var note = ""

    private var isValid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sentence / expression") {
                    TextField("e.g. He had to bite the bullet.", text: $text, axis: .vertical)
                        .lineLimit(2...5)
                }
                Section("Korean meaning") {
                    TextField("e.g. 어려운 일을 감내하다", text: $meaning, axis: .vertical)
                        .lineLimit(1...3)
                }
                Section("Note (optional)") {
                    TextField("Source, context, or usage tip", text: $note, axis: .vertical)
                        .lineLimit(1...5)
                }
            }
            .navigationTitle(entry == nil ? "New entry" : "Edit entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                if let entry {
                    text = entry.text
                    meaning = entry.meaning
                    note = entry.note ?? ""
                }
            }
        }
    }

    private func save() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMeaning = meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedNote = trimmedNote.isEmpty ? nil : trimmedNote

        if let entry {
            entry.text = trimmedText
            entry.meaning = trimmedMeaning
            entry.note = resolvedNote
        } else {
            let newEntry = Entry(
                text: trimmedText,
                meaning: trimmedMeaning,
                note: resolvedNote
            )
            context.insert(newEntry)
        }
        try? context.save()
        dismiss()
    }
}

#Preview("New entry") {
    EntryEditView(entry: nil)
        .modelContainer(PreviewSamples.modelContainer)
}

#Preview("Edit existing") {
    EntryEditView(
        entry: Entry(
            text: "He had to bite the bullet.",
            meaning: "어려운 일을 감내하다",
            note: "Idiom — accept something difficult."
        )
    )
    .modelContainer(PreviewSamples.modelContainer)
}
