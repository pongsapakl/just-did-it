import Foundation
import SwiftData

/// A record that a given action was done on a given day.
/// Presence of a CheckMark = "done". Toggling off deletes it.
@Model
final class CheckMark {
    /// Normalized to the start of the day (local midnight).
    var day: Date
    var item: Item?

    init(day: Date, item: Item?) {
        self.day = day
        self.item = item
    }
}
