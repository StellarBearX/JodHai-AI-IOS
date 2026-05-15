import AppIntents

/// Registers suggested Siri phrases for Jod-Hai.
/// Call `JodHaiShortcuts.updateAppShortcutParameters()` at app launch so the
/// system keeps the phrase list up to date.
struct JodHaiShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Log an expense in \(.applicationName)",
                "Add expense to \(.applicationName)",
                "Record spending in \(.applicationName)",
                "Track a purchase in \(.applicationName)",
                "New expense in \(.applicationName)",
            ],
            shortTitle: "Log Expense",
            systemImageName: "banknote.fill"
        )
    }
}
