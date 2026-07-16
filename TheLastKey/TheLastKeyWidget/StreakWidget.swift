import SwiftUI
import WidgetKit

// The widget can't see the app target's asset catalog — these hex literals
// mirror the Dawn Warm palette (DawnAmber / DawnCoral light values).
private enum Dawn {
    static let amber = Color(red: 0xF5 / 255, green: 0x9E / 255, blue: 0x0B / 255)
    static let coral = Color(red: 0xF4 / 255, green: 0x71 / 255, blue: 0x5F / 255)
    static let sunrise = LinearGradient(colors: [amber, coral],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing)
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let todayDone: Bool
    /// Last 14 days, oldest first.
    let recentDays: [Bool]

    static let sample = StreakEntry(
        date: .now, streak: 5, todayDone: false,
        recentDays: [true, true, false, true, true, true, false,
                     true, true, true, true, true, true, false]
    )
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(context.isPreview ? .sample : entry(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let midnight = calendar.date(byAdding: .day, value: 1,
                                     to: calendar.startOfDay(for: now))!
        // The midnight entry flips "done today" off and recomputes the streak
        // even if WidgetKit defers the requested reload.
        completion(Timeline(entries: [entry(at: now), entry(at: midnight)],
                            policy: .after(midnight)))
    }

    private func entry(at date: Date) -> StreakEntry {
        let calendar = Calendar.current
        let days = SharedStreakStore.load()
        let dayStart = calendar.startOfDay(for: date)
        let recent = (0..<14).reversed().map { offset in
            days.contains(calendar.date(byAdding: .day, value: -offset, to: dayStart)!)
        }
        return StreakEntry(
            date: date,
            streak: StreakCalculator.currentStreak(completedDays: days,
                                                   today: date,
                                                   calendar: calendar),
            todayDone: days.contains(dayStart),
            recentDays: recent
        )
    }
}

struct StreakWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StreakEntry

    var body: some View {
        Group {
            if family == .systemMedium {
                HStack(alignment: .center, spacing: 16) {
                    streakColumn
                    Spacer()
                    daysStrip
                }
            } else {
                streakColumn
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .containerBackground(for: .widget) { Dawn.sunrise }
    }

    private var streakColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(.title3, weight: .semibold))
                Text("\(entry.streak)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)

            Text("day streak")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))

            statusPill
                .padding(.top, 4)
        }
    }

    private var statusPill: some View {
        Text(entry.todayDone ? "Done today ✓" : "Not yet today")
            .font(.system(.caption2, design: .rounded).weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(.white.opacity(entry.todayDone ? 0.30 : 0.18), in: Capsule())
    }

    /// Last two weeks as two rows of squares, today outlined bottom-right.
    private var daysStrip: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(.white.opacity(entry.recentDays[index] ? 0.95 : 0.25))
                            .frame(width: 13, height: 13)
                            .overlay {
                                if index == 13 {
                                    RoundedRectangle(cornerRadius: 2.5)
                                        .strokeBorder(.white, lineWidth: 1.2)
                                }
                            }
                    }
                }
            }
        }
    }
}

struct StreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StreakWidget", provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Practice streak")
        .description("Your streak and whether today's five expressions are done.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
