import AppIntents
import SwiftData
import Foundation

struct AddExpenseIntent: AppIntent {

    static var title: LocalizedStringResource = "Log an Expense"
    static var description = IntentDescription(
        "Quickly log a new expense to Jod-Hai without opening the app.",
        categoryName: "Finance"
    )
    // Background execution — no need to launch the app UI.
    static var openAppWhenRun: Bool = false

    // MARK: - Parameters

    @Parameter(
        title: "Amount",
        description: "How much did you spend?",
        controlStyle: .field,
        requestValueDialog: IntentDialog("How much did you spend?")
    )
    var amount: Double

    @Parameter(
        title: "Category",
        description: "Which category does this expense belong to?",
        default: .food,
        requestValueDialog: IntentDialog("What category was this expense?")
    )
    var category: ExpenseCategoryAppEnum

    @Parameter(
        title: "Note",
        description: "An optional description for the expense."
    )
    var note: String?

    // MARK: - Perform

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: ExpenseModel.self)
        let actor = ExpenseIntentActor(modelContainer: container)

        try await actor.addExpense(
            amount: amount,
            category: category.rawValue,
            note: note ?? "",
            date: .now
        )

        let formattedAmount = amount.asCurrency()
        return .result(
            dialog: IntentDialog(
                "Done! I've logged a **\(category.rawValue)** expense of \(formattedAmount) in Jod-Hai."
            )
        )
    }
}

// MARK: - Currency helper (mirrors DesignSystem — available here without UI import)

private extension Double {
    func asCurrency(code: String = "THB") -> String {
        formatted(.currency(code: code).precision(.fractionLength(0...2)))
    }
}
