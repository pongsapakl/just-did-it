import Foundation
import SwiftData

/// A single thing you track. Either a standalone action (e.g. "Exercise"),
/// a group heading (e.g. "Drink"), or a child action inside a group (e.g. "Coffee").
///
/// - A group has `isGroup == true` and is only a label — you don't check it off.
/// - Its children point back to it via `parent`.
/// - Deleting archives (hides) the item instead of erasing it, so past history is kept.
@Model
final class Item {
    var name: String
    var isGroup: Bool
    var sortOrder: Int
    var isArchived: Bool
    var createdAt: Date

    var parent: Item?

    @Relationship(deleteRule: .cascade, inverse: \Item.parent)
    var children: [Item]

    @Relationship(deleteRule: .cascade, inverse: \CheckMark.item)
    var checkMarks: [CheckMark]

    init(name: String, isGroup: Bool = false, sortOrder: Int = 0, parent: Item? = nil) {
        self.name = name
        self.isGroup = isGroup
        self.sortOrder = sortOrder
        self.isArchived = false
        self.createdAt = Date()
        self.parent = parent
        self.children = []
        self.checkMarks = []
    }
}
