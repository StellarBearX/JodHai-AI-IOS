import SwiftData
import Foundation
import Observation

// MARK: - Budget Status

struct BudgetStatus: Identifiable, Sendable {
    let id: String
    let category: String
    let limit: Double
    let spent: Double

    var progress: Double    { limit > 0 ? min(spent / limit, 1.0) : 0 }
    var remaining: Double   { max(limit - spent, 0) }
    var isOverBudget: Bool  { limit > 0 && spent > limit }
    var isNearLimit: Bool   { progress >= 0.8 && !isOverBudget }
}

// MARK: - Smart Allocation (50/30/20 adapted for Thailand)

private let smartRatios: [String: Double] = [
    "Food":          0.20,
    "Transport":     0.10,
    "Bills":         0.15,
    "Health":        0.05,
    "Shopping":      0.12,
    "Entertainment": 0.08,
    "Other":         0.10,
    // 20% left → savings (not a category, just not allocated)
]

// MARK: - ViewModel

@MainActor
@Observable
final class BudgetViewModel {

    // Budget
    var statuses: [BudgetStatus] = []
    var isEditSheet   = false
    var editCategory  = ExpenseCategory.food.rawValue
    var editLimitText = ""

    // Income
    var incomes: [Income] = []
    var isIncomeSheet    = false
    var newIncomeAmount  = ""
    var newIncomeSource  = IncomeSource.salary.rawValue
    var newIncomeNote    = ""
    var newIncomeDate    = Date.now

    var monthlyIncome: Double {
        let start = monthStart
        return incomes.filter { $0.date >= start }.reduce(0) { $0 + $1.amount }
    }

    var smartSuggestions: [String: Double] {
        guard monthlyIncome > 0 else { return [:] }
        return smartRatios.mapValues { ($0 * monthlyIncome).rounded() }
    }

    private var budgets: [Budget] = []
    private var budgetRepo: (any BudgetRepositoryProtocol)?
    private var incomeRepo: (any IncomeRepositoryProtocol)?

    private var monthStart: Date {
        Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: .now)
        ) ?? .distantPast
    }

    // MARK: - Setup

    func configure(modelContext: ModelContext) {
        if budgetRepo == nil { budgetRepo = BudgetRepositoryImpl(modelContext: modelContext) }
        if incomeRepo == nil { incomeRepo = IncomeRepositoryImpl(modelContext: modelContext) }
    }

    func loadAll(monthExpenses: [ExpenseModel]) async {
        budgets = (try? await budgetRepo?.fetchAll()) ?? []
        incomes = (try? await incomeRepo?.fetchAll()) ?? []
        recalculate(monthExpenses: monthExpenses)
    }

    // MARK: - Budget CRUD

    func startEditing(category: String) {
        editCategory  = category
        let current   = budgets.first { $0.category == category }?.monthlyLimit ?? 0
        editLimitText = current > 0 ? String(format: "%.0f", current) : ""
        isEditSheet   = true
    }

    func saveEdit() async {
        isEditSheet = false
        if let limit = Double(editLimitText), limit > 0 {
            await upsertBudget(category: editCategory, limit: limit)
            await NotificationService.shared.requestPermission()
        } else if editLimitText.isEmpty {
            try? await budgetRepo?.delete(category: editCategory)
            budgets.removeAll { $0.category == editCategory }
        }
    }

    // MARK: - Smart Budget

    func applySmartBudgets() async {
        guard monthlyIncome > 0 else { return }
        for (cat, limit) in smartSuggestions {
            await upsertBudget(category: cat, limit: limit)
        }
        await NotificationService.shared.requestPermission()
    }

    // MARK: - Income CRUD

    func addIncome() async {
        guard let amount = Double(newIncomeAmount), amount > 0 else { return }
        let income = Income(amount: amount, source: newIncomeSource,
                            note: newIncomeNote, date: newIncomeDate)
        try? await incomeRepo?.add(income)
        incomes.append(income)
        newIncomeAmount = ""; newIncomeNote = ""
        isIncomeSheet = false
    }

    func deleteIncome(_ income: Income) async {
        try? await incomeRepo?.delete(id: income.id)
        incomes.removeAll { $0.id == income.id }
    }

    // MARK: - Recalculate

    func recalculate(monthExpenses: [ExpenseModel]) {
        statuses = ExpenseCategory.allCases.map { cat in
            let limit = budgets.first { $0.category == cat.rawValue }?.monthlyLimit ?? 0
            let spent = monthExpenses
                .filter { $0.category == cat.rawValue }
                .reduce(0) { $0 + $1.amount }
            return BudgetStatus(id: cat.rawValue, category: cat.rawValue, limit: limit, spent: spent)
        }
        for s in statuses where s.limit > 0 {
            NotificationService.shared.checkBudget(
                category: s.category, spent: s.spent, limit: s.limit
            )
        }
    }

    var overBudgetCategories: [BudgetStatus]  { statuses.filter(\.isOverBudget) }
    var nearLimitCategories:  [BudgetStatus]  { statuses.filter(\.isNearLimit) }

    // MARK: - Private

    private func upsertBudget(category: String, limit: Double) async {
        let b = Budget(id: category, category: category, monthlyLimit: limit)
        try? await budgetRepo?.save(b)
        if let idx = budgets.firstIndex(where: { $0.category == category }) {
            budgets[idx] = b
        } else {
            budgets.append(b)
        }
    }
}
