import SwiftUI

/// Streak counter + GitHub-style day squares: one column per week (oldest
/// left), one row per weekday, amber-filled on days a session was completed.
struct StreakView: View {
    let days: [PracticeDay]

    private static let weeksShown = 15
    private let calendar = Calendar.current

    private var completedDays: Set<Date> { Set(days.map(\.date)) }

    private var todayStart: Date { calendar.startOfDay(for: .now) }

    private var streak: Int {
        StreakCalculator.currentStreak(completedDays: completedDays, calendar: calendar)
    }

    private var doneToday: Bool { completedDays.contains(todayStart) }

    private var weekStarts: [Date] {
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: .now)!.start
        return (0..<Self.weeksShown).map {
            calendar.date(byAdding: .weekOfYear,
                          value: $0 - (Self.weeksShown - 1),
                          to: currentWeekStart)!
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(streak > 0
                                     ? AnyShapeStyle(Theme.sunrise)
                                     : AnyShapeStyle(Theme.amber.opacity(0.35)))
                Text(streak > 0 ? "\(streak)-day streak" : "Start your streak today")
                    .font(.system(.headline, design: .rounded).bold())
                Spacer()
                if doneToday {
                    Label("Done today", systemImage: "checkmark.circle.fill")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.amberDeep)
                }
            }

            grid
                .frame(maxWidth: .infinity)
        }
        .padding(16)
        .dawnCard()
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("streakCard")
        .accessibilityLabel(accessibilitySummary)
    }

    private var grid: some View {
        HStack(spacing: 3) {
            ForEach(weekStarts, id: \.self) { weekStart in
                VStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { offset in
                        daySquare(calendar.date(byAdding: .day, value: offset, to: weekStart)!)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func daySquare(_ date: Date) -> some View {
        let isToday = date == todayStart
        RoundedRectangle(cornerRadius: 3)
            .fill(squareColor(for: date))
            .frame(width: 12, height: 12)
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Theme.amberDeep, lineWidth: 1.5)
                }
            }
    }

    private func squareColor(for date: Date) -> Color {
        if date > todayStart {
            .clear
        } else if completedDays.contains(date) {
            Theme.amber
        } else {
            Theme.amber.opacity(0.13)
        }
    }

    private var accessibilitySummary: String {
        let streakPart = streak > 0 ? "\(streak)-day streak" : "No streak yet"
        return doneToday ? "\(streakPart); practiced today" : streakPart
    }
}

#Preview {
    VStack {
        StreakView(days: PreviewSamples.makePracticeDays())
        StreakView(days: [])
    }
    .padding(24)
    .background(Theme.background)
}
