import SwiftUI

/// The sentences picked for today's session, shown on Today before practice.
/// Full text is deliberately visible — pre-exposure is an extra study pass;
/// the real test is first-letter production minutes later.
struct TodaySessionPreview: View {
    let entries: [Entry]
    let isDoneToday: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("Today's cards")
                    .font(.system(.headline, design: .rounded).bold())
                Spacer()
                if isDoneToday {
                    Label("Done today", systemImage: "checkmark.circle.fill")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.amberDeep)
                }
            }

            VStack(spacing: 10) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    row(index: index, entry: entry)
                }
            }
            .opacity(isDoneToday ? 0.55 : 1)
        }
        .padding(16)
        .dawnCard()
        .accessibilityIdentifier("todayCardsPreview")
    }

    private func row(index: Int, entry: Entry) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(index + 1)")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.amberDeep)
                .frame(width: 22, height: 22)
                .background(Theme.amber.opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(entry.text)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .lineLimit(2)
                    if entry.needsReview {
                        Circle()
                            .fill(Theme.coral)
                            .frame(width: 7, height: 7)
                    }
                }
                Text(entry.meaning)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview("Pending") {
    TodaySessionPreview(entries: Array(PreviewSamples.makeEntries().prefix(5)),
                        isDoneToday: false)
        .padding(24)
        .background(Theme.background)
}

#Preview("Done today") {
    TodaySessionPreview(entries: Array(PreviewSamples.makeEntries().prefix(5)),
                        isDoneToday: true)
        .padding(24)
        .background(Theme.background)
}
