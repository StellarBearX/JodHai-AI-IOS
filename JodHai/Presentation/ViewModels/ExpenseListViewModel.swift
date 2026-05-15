import SwiftData
import Foundation
import Observation

@MainActor
@Observable
final class ExpenseListViewModel {
    var expenses: [Expense] = []
    var isAddSheetPresented = false
    var isEditSheetPresented = false
    var editingExpense: Expense?

    // New-expense form fields
    var newAmount: String = ""
    var newCategory: String = ExpenseCategory.food.rawValue
    var newNote: String = ""
    var newDate: Date = .now

    // Receipt scanning state
    var isScanning = false
    var scanErrorMessage: String?

    // Monotonic counters — views attach .sensoryFeedback triggers to these
    // so haptics fire on the exact event rather than on state-value equality.
    var savedExpenseCount: Int = 0
    var deletedExpenseCount: Int = 0

    let categories = ExpenseCategory.allCases.map(\.rawValue)

    private var repository: (any ExpenseRepositoryProtocol)?

    func configure(modelContext: ModelContext) {
        guard repository == nil else { return }
        repository = ExpenseRepositoryImpl(modelContext: modelContext)
    }

    func load() async {
        expenses = (try? await repository?.fetchAll()) ?? []
    }

    var isFormValid: Bool {
        guard let amount = Double(newAmount) else { return false }
        return amount > 0
    }

    func addExpense() async {
        guard let repository, let amount = Double(newAmount), amount > 0 else { return }
        let expense = Expense(amount: amount, category: newCategory, note: newNote, date: newDate)
        try? await repository.add(expense)
        expenses.insert(expense, at: 0)
        savedExpenseCount += 1
        isAddSheetPresented = false
        resetForm()
    }

    func startEditing(_ expense: Expense) {
        editingExpense = expense
        newAmount   = String(format: "%.2f", expense.amount)
        newCategory = expense.category
        newNote     = expense.note
        newDate     = expense.date
        isEditSheetPresented = true
    }

    func updateExpense() async {
        guard let repository, let expense = editingExpense,
              let amount = Double(newAmount), amount > 0 else { return }
        var updated = expense
        updated.amount = amount; updated.category = newCategory
        updated.note = newNote;  updated.date = newDate
        try? await repository.update(updated)
        if let idx = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[idx] = updated
        }
        savedExpenseCount += 1
        isEditSheetPresented = false
        resetForm()
    }

    func cancelEdit() {
        isEditSheetPresented = false
        resetForm()
    }

    func delete(expense: Expense) async {
        try? await repository?.delete(id: expense.id)
        expenses.removeAll { $0.id == expense.id }
        deletedExpenseCount += 1
    }

    // MARK: - Receipt Scanning

    func scanReceipt(imageData: Data) async {
        isScanning = true
        scanErrorMessage = nil
        defer { isScanning = false }

        let service = VisionScannerService()
        let useCase = ExtractReceiptDataUseCase(scanner: service)

        do {
            let result = try await useCase.execute(imageData: imageData)
            if let amount = result.amount {
                newAmount = String(format: "%.2f", amount)
            } else {
                scanErrorMessage = "No amount found on receipt. Please enter manually."
            }
        } catch {
            scanErrorMessage = error.localizedDescription
        }
    }

    private func resetForm() {
        newAmount = ""; newCategory = ExpenseCategory.food.rawValue
        newNote = ""; newDate = .now; editingExpense = nil
    }
}
