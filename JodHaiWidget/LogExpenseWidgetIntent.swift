import AppIntents

/// Tapping the widget's "+" button opens the app directly to the Add Expense sheet
/// via the jodhai://add-expense deep link.
struct LogExpenseWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Expense"
    static var description = IntentDescription("Opens Jod-Hai to quickly log a new expense.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // The app handles navigation once foregrounded via onOpenURL.
        .result()
    }
}
