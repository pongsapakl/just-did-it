import SwiftUI
import SwiftData

@main
struct JustDidItApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Item.self, CheckMark.self, Visit.self])
    }
}
