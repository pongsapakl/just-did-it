import Foundation
import SwiftData

/// A record that you opened the app on a given day — i.e. you *showed up*.
///
/// This is deliberately separate from `CheckMark`: showing up is the thing the
/// app rewards ("reward showing up, not performance"), so a day you open the app
/// but log nothing (a rest day) still counts. One `Visit` per calendar day.
@Model
final class Visit {
    /// Normalized to the start of the day (local midnight).
    var day: Date

    init(day: Date) {
        self.day = day
    }
}
