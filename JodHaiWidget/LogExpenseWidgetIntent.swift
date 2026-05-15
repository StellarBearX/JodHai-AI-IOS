import AppIntents

/// Tapping the widget's "+" button opens the app directly to the Add Expense sheet
/// via the jodhai://add-expense deep link.
struct LogExpenseWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Expense"
    static let description = IntentDescription("Opens Jod-Hai to quickly log a new expense.")
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // The app handles navigation once foregrounded via onOpenURL.
        .result()
    }
}
