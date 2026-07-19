import SwiftUI
import SwiftData

/// Edit your list: add actions and groups, rename, delete (which archives and
/// keeps history), and drag to reorder.
struct ManageView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Item.sortOrder) private var items: [Item]
    @AppStorage("remindersEnabled") private var remindersEnabled = true

    private var topLevel: [Item] {
        items
            .filter { $0.parent == nil && !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(topLevel) { item in
                    NavigationLink {
                        ItemEditView(item: item)
                    } label: {
                        HStack {
                            Image(systemName: item.isGroup ? "folder" : "circle")
                                .foregroundStyle(.secondary)
                            Text(item.name)
                            if item.isGroup {
                                Spacer()
                                Text("\(activeChildCount(item))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onMove(perform: move)
                .onDelete(perform: delete)

                Section {
                    Toggle("Daily reminder", isOn: $remindersEnabled)
                } footer: {
                    Text("A nudge around the time you usually check in. Skipped on days you've already shown up.")
                }
            }
            .onChange(of: remindersEnabled) { _, enabled in
                if enabled {
                    Reminders.requestAuthorizationIfNeeded()
                    Reminders.reschedule(shownUpToday: true)
                } else {
                    Reminders.disable()
                }
            }
            .navigationTitle("Edit list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            add(isGroup: false)
                        } label: {
                            Label("Add action", systemImage: "circle")
                        }
                        Button {
                            add(isGroup: true)
                        } label: {
                            Label("Add group", systemImage: "folder")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func activeChildCount(_ item: Item) -> Int {
        item.children.filter { !$0.isArchived }.count
    }

    private func add(isGroup: Bool) {
        let next = (topLevel.map(\.sortOrder).max() ?? -1) + 1
        context.insert(Item(name: isGroup ? "New group" : "New action", isGroup: isGroup, sortOrder: next))
    }

    private func move(from offsets: IndexSet, to destination: Int) {
        var arranged = topLevel
        arranged.move(fromOffsets: offsets, toOffset: destination)
        for (index, item) in arranged.enumerated() {
            item.sortOrder = index
        }
    }

    private func delete(at offsets: IndexSet) {
        let arranged = topLevel
        for index in offsets {
            let item = arranged[index]
            item.isArchived = true
            for child in item.children {
                child.isArchived = true
            }
        }
    }
}

/// Rename an item, and — if it's a group — manage the actions inside it.
struct ItemEditView: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: Item

    private var activeChildren: [Item] {
        item.children
            .filter { !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $item.name)
            }

            if item.isGroup {
                Section("Items in this group") {
                    ForEach(activeChildren) { child in
                        NavigationLink {
                            ItemEditView(item: child)
                        } label: {
                            Text(child.name)
                        }
                    }
                    .onMove(perform: moveChild)
                    .onDelete(perform: deleteChild)

                    Button {
                        addChild()
                    } label: {
                        Label("Add item", systemImage: "plus")
                    }
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if item.isGroup {
                EditButton()
            }
        }
    }

    private func addChild() {
        let next = (activeChildren.map(\.sortOrder).max() ?? -1) + 1
        context.insert(Item(name: "New item", sortOrder: next, parent: item))
    }

    private func moveChild(from offsets: IndexSet, to destination: Int) {
        var arranged = activeChildren
        arranged.move(fromOffsets: offsets, toOffset: destination)
        for (index, child) in arranged.enumerated() {
            child.sortOrder = index
        }
    }

    private func deleteChild(at offsets: IndexSet) {
        let arranged = activeChildren
        for index in offsets {
            arranged[index].isArchived = true
        }
    }
}
