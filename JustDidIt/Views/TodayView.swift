import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: \Item.sortOrder) private var items: [Item]
    // Query the CheckMarks directly: inserting/deleting one reliably refreshes this
    // view, which reading a relationship (item.checkMarks) does not.
    @Query private var allMarks: [CheckMark]
    @Environment(\.scenePhase) private var scenePhase
    @State private var date = Date()
    @State private var showManage = false
    /// Groups currently expanded inline (dropdown style).
    @State private var expandedGroups: Set<PersistentIdentifier> = []
    /// The calendar day this view last believed was "today". Lets us tell
    /// "midnight passed" apart from "the user is browsing an old day".
    @State private var lastKnownDay = Calendar.current.startOfDay(for: Date())

    private var day: Date { Calendar.current.startOfDay(for: date) }

    private var topLevel: [Item] {
        items
            .filter { $0.parent == nil && !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// IDs of the items marked done on the currently-viewed day.
    private var doneItemIDs: Set<PersistentIdentifier> {
        Set(
            allMarks
                .filter { Calendar.current.startOfDay(for: $0.day) == day }
                .compactMap { $0.item?.persistentModelID }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(topLevel) { item in
                        if item.isGroup {
                            groupSection(item)
                        } else {
                            ActionButton(
                                item: item,
                                isDone: doneItemIDs.contains(item.persistentModelID),
                                day: day
                            )
                        }
                    }
                }
                .padding()
            }
            .safeAreaInset(edge: .top) {
                DateHeader(date: $date)
            }
            .navigationTitle("Just Did It")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showManage = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showManage) {
                ManageView()
            }
            // Keep "today" honest: the app can sit open (or suspended) across
            // midnight, and `date` would otherwise stay stuck on yesterday.
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { rollDayIfNeeded() }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
                    .receive(on: DispatchQueue.main)
            ) { _ in
                rollDayIfNeeded()
            }
        }
    }

    /// If a new calendar day has begun, advance the view to it — but only when
    /// the user was parked on the old "today". Someone deliberately browsing a
    /// past day is left alone.
    private func rollDayIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        guard today != lastKnownDay else { return }
        if Calendar.current.startOfDay(for: date) == lastKnownDay {
            date = Date()
        }
        lastKnownDay = today
    }

    private func anyChildDone(_ group: Item) -> Bool {
        group.children.contains { doneItemIDs.contains($0.persistentModelID) }
    }

    /// A group rendered as a dropdown: the key toggles open/closed, its
    /// sub-actions expand inline right below it — everything stays on one page.
    @ViewBuilder
    private func groupSection(_ group: Item) -> some View {
        let isExpanded = expandedGroups.contains(group.persistentModelID)

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if isExpanded {
                    expandedGroups.remove(group.persistentModelID)
                } else {
                    expandedGroups.insert(group.persistentModelID)
                }
            }
        } label: {
            HardwareFace(
                title: group.name,
                isOn: false,
                showChevron: true,
                chevronDown: isExpanded,
                indicatorLit: !isExpanded && anyChildDone(group)
            )
        }
        .buttonStyle(PushButtonStyle(isOn: false))

        if isExpanded {
            ForEach(children(of: group)) { child in
                ActionButton(
                    item: child,
                    isDone: doneItemIDs.contains(child.persistentModelID),
                    day: day,
                    height: 56
                )
                .padding(.leading, 24)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func children(of group: Item) -> [Item] {
        group.children
            .filter { !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
}

/// A single toggleable action rendered as a big physical button.
struct ActionButton: View {
    @Environment(\.modelContext) private var context
    let item: Item
    let isDone: Bool
    /// Start-of-day for the day being viewed.
    let day: Date
    /// Key height — sub-actions inside an expanded group use a shorter key.
    var height: CGFloat = 66

    var body: some View {
        Button(action: toggle) {
            HardwareFace(title: item.name, isOn: isDone)
        }
        .buttonStyle(PushButtonStyle(isOn: isDone, height: height))
    }

    private func toggle() {
        if let mark = item.checkMarks.first(where: { Calendar.current.startOfDay(for: $0.day) == day }) {
            context.delete(mark)
            Haptics.off()
        } else {
            context.insert(CheckMark(day: day, item: item))
            Haptics.on()
        }
    }
}

/// Header that shows which day you're viewing and lets you step back to past
/// days (to backfill) but never into the future.
struct DateHeader: View {
    @Binding var date: Date

    private let cal = Calendar.current
    private var isToday: Bool { cal.isDateInToday(date) }

    var body: some View {
        HStack {
            Button { shift(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .padding(8)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(date, format: .dateTime.weekday(.wide).month().day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button { shift(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .padding(8)
            }
            .disabled(isToday)
            .opacity(isToday ? 0.3 : 1)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var title: String {
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    private func shift(_ days: Int) {
        guard let candidate = cal.date(byAdding: .day, value: days, to: date) else { return }
        // Never step into the future.
        if days > 0 && cal.startOfDay(for: candidate) > cal.startOfDay(for: Date()) { return }
        withAnimation(.easeInOut(duration: 0.15)) { date = candidate }
    }
}
