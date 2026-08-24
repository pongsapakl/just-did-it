import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var allItems: [Item]
    @Query private var visits: [Visit]

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "checkmark.circle") }
            HistoryView()
                .tabItem { Label("History", systemImage: "square.grid.3x3.fill") }
        }
        .task {
            seedIfNeeded()
            handleAppOpen()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { handleAppOpen() }
        }
    }

    /// Everything that should happen when the app comes to the foreground:
    /// count today as "shown up", learn the open time, and refresh reminders.
    private func handleAppOpen() {
        let today = Calendar.current.startOfDay(for: Date())

        // Opening the app = showing up. One Visit per day.
        if !visits.contains(where: { Calendar.current.startOfDay(for: $0.day) == today }) {
            context.insert(Visit(day: today))
        }

        Reminders.recordOpen()
        Reminders.requestAuthorizationIfNeeded()
        // Shown up is now always true here (we just visited), so today's
        // reminder is skipped — the schedule covers the days ahead.
        Reminders.reschedule(shownUpToday: true)
    }

    /// On the very first launch, give the list a few sensible starter items
    /// (including a Drink group) so it isn't empty. Everything is editable.
    private func seedIfNeeded() {
        guard allItems.isEmpty else { return }

        let exercise = Item(name: "Exercise", sortOrder: 0)
        let read = Item(name: "Read", sortOrder: 1)
        let drink = Item(name: "Drink", isGroup: true, sortOrder: 2)
        context.insert(exercise)
        context.insert(read)
        context.insert(drink)

        context.insert(Item(name: "Coffee", sortOrder: 0, parent: drink))
        context.insert(Item(name: "Tea", sortOrder: 1, parent: drink))
        context.insert(Item(name: "Water", sortOrder: 2, parent: drink))
    }
}
