import SwiftUI
import SwiftData

/// History tab: a "Showing up" section at the top (app-wide — did you open the
/// app / log anything that day), then a per-action contribution graph for each
/// action, GitHub style. No streaks, no resets — showing up only ever adds.
struct HistoryView: View {
    @Query(sort: \Item.sortOrder) private var items: [Item]
    @Query private var visits: [Visit]
    @Query private var allMarks: [CheckMark]

    private let cal = Calendar.current

    private var actions: [Item] {
        items
            .filter { !$0.isGroup && !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Days you opened the app or logged something — "showed up".
    private var shownUpDays: Set<Date> {
        Set(visits.map { cal.startOfDay(for: $0.day) })
            .union(allMarks.map { cal.startOfDay(for: $0.day) })
    }

    /// Days with at least one action checked off.
    private var actionDays: Set<Date> {
        Set(allMarks.map { cal.startOfDay(for: $0.day) })
    }

    /// Shown-up days within the last 30 (including today).
    private var last30Count: Int {
        let today = cal.startOfDay(for: Date())
        guard let cutoff = cal.date(byAdding: .day, value: -29, to: today) else { return 0 }
        return shownUpDays.filter { $0 >= cutoff && $0 <= today }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Shown up \(shownUpDays.count) \(shownUpDays.count == 1 ? "day" : "days")")
                                .font(.headline)
                            Spacer()
                            Text("\(last30Count) of the last 30")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            ContributionGraph { day in
                                if actionDays.contains(day) { return 1 }
                                if shownUpDays.contains(day) { return 0.35 }
                                return 0
                            }
                        }
                        Text("Solid = did something · faint = showed up")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text("Showing up")
                }

                if actions.isEmpty {
                    ContentUnavailableView(
                        "No actions yet",
                        systemImage: "square.grid.3x3",
                        description: Text("Add actions on the Today tab to start seeing your history.")
                    )
                }
                ForEach(actions) { action in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(action.name).font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            ActionGraph(action: action)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("History")
        }
    }
}

/// Wrapper that renders one action's checkmarks through the generic graph.
private struct ActionGraph: View {
    let action: Item
    private let cal = Calendar.current

    private var doneDays: Set<Date> {
        Set(action.checkMarks.map { cal.startOfDay(for: $0.day) })
    }

    var body: some View {
        ContributionGraph { day in
            doneDays.contains(day) ? 1 : 0
        }
    }
}

/// A GitHub-contribution-style grid. What fills each cell is supplied by the
/// caller as a per-day level: 0 = empty, up to 1 = fully filled (intermediate
/// values render as a fainter accent).
struct ContributionGraph: View {
    /// Level for a given start-of-day date, 0...1.
    let level: (Date) -> CGFloat

    private let weeks = 16
    private let cell: CGFloat = 14
    private let gap: CGFloat = 3
    private let gutter: CGFloat = 30      // width reserved for weekday labels
    private let cal = Calendar.current

    /// Sunday of the earliest visible week.
    private var gridStart: Date {
        let today = cal.startOfDay(for: Date())
        let weekdayIndex = cal.component(.weekday, from: today) - 1 // 0 = Sunday
        let startOfThisWeek = cal.date(byAdding: .day, value: -weekdayIndex, to: today)!
        return cal.date(byAdding: .day, value: -7 * (weeks - 1), to: startOfThisWeek)!
    }

    var body: some View {
        VStack(alignment: .leading, spacing: gap) {
            monthLabels
            HStack(alignment: .top, spacing: gap) {
                weekdayLabels
                ForEach(0..<weeks, id: \.self) { week in
                    VStack(spacing: gap) {
                        ForEach(0..<7, id: \.self) { dayOfWeek in
                            cell(for: date(week: week, day: dayOfWeek))
                        }
                    }
                }
            }
        }
    }

    // MARK: Labels

    private var monthLabels: some View {
        HStack(spacing: gap) {
            Color.clear.frame(width: gutter, height: 12)
            ForEach(0..<weeks, id: \.self) { week in
                Text(monthLabel(week: week))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .fixedSize()                                  // natural width…
                    .frame(width: cell, alignment: .leading)      // …overflowing its column

            }
        }
    }

    private var weekdayLabels: some View {
        VStack(spacing: gap) {
            ForEach(0..<7, id: \.self) { row in
                Text(weekdayLabel(row: row))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .frame(width: gutter, height: cell, alignment: .trailing)
            }
        }
    }

    /// Show a month label above the first week that falls in a new month.
    /// Include the year when it changes (or on the very first column).
    private func monthLabel(week: Int) -> String {
        let start = date(week: week, day: 0)
        let month = cal.component(.month, from: start)
        let year = cal.component(.year, from: start)

        let showThisWeek: Bool
        if week == 0 {
            showThisWeek = true
        } else {
            let prev = date(week: week - 1, day: 0)
            showThisWeek = cal.component(.month, from: prev) != month
        }
        guard showThisWeek else { return "" }

        let yearChanged = week == 0 || cal.component(.year, from: date(week: week - 1, day: 0)) != year
        return yearChanged
            ? start.formatted(.dateTime.month(.abbreviated).year(.twoDigits))
            : start.formatted(.dateTime.month(.abbreviated))
    }

    /// GitHub labels only Mon / Wed / Fri to avoid clutter. Rows: 0=Sun … 6=Sat.
    private func weekdayLabel(row: Int) -> String {
        switch row {
        case 1: return "Mon"
        case 3: return "Wed"
        case 5: return "Fri"
        default: return ""
        }
    }

    // MARK: Cells

    private func date(week: Int, day: Int) -> Date {
        cal.date(byAdding: .day, value: week * 7 + day, to: gridStart)!
    }

    @ViewBuilder
    private func cell(for date: Date) -> some View {
        let today = cal.startOfDay(for: Date())
        let isFuture = date > today
        let value = isFuture ? 0 : level(date)

        RoundedRectangle(cornerRadius: 3)
            .fill(fillColor(isFuture: isFuture, level: value))
            .frame(width: cell, height: cell)
            .opacity(isFuture ? 0.4 : 1)
    }

    private func fillColor(isFuture: Bool, level: CGFloat) -> Color {
        if isFuture { return Color(.systemGray6) }
        guard level > 0 else { return Color(.systemGray5) }
        return Color.accentColor.opacity(level)
    }
}
