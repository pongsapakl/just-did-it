import UIKit

/// Physical "click-clack" feedback for the toggle.
/// A firmer thunk when turning something on, a lighter tick when turning it off,
/// so done vs undone feel distinct in your hand.
enum Haptics {
    static func on() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred(intensity: 1.0)
    }

    static func off() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred(intensity: 0.6)
    }
}
