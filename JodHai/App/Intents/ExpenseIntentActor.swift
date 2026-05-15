import SwiftData
import Foundation

/// Swift 6-safe SwiftData access point for App Intents.
/// @ModelActor generates an actor backed by its own ModelContext so no
/// main-actor crossing occurs when the intent runs in a background context.
@ModelActor
actor ExpenseIntentActor {
    func addExpense(amount: Double, category: String, note: String, date: Date) throws {
        let model = ExpenseModel(amount: amount, category: category, note: note, date: date)
        modelContext.insert(model)
        try modelContext.save()
    }
}
