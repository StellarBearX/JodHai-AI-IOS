import SwiftUI
import SwiftData

@main
struct JodHaiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    JodHaiShortcuts.updateAppShortcutParameters()
                }
        }
        .modelContainer(for: ExpenseModel.self)
    }
}
