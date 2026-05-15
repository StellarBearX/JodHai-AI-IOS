import SwiftData
import Foundation

@MainActor
final class BudgetRepositoryImpl: BudgetRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [Budget] {
        let descriptor = FetchDescriptor<BudgetModel>()
        return try modelContext.fetch(descriptor).map {
            Budget(id: $0.category, category: $0.category, monthlyLimit: $0.monthlyLimit)
        }
    }

    func save(_ budget: Budget) throws {
        let category = budget.category
        let descriptor = FetchDescriptor<BudgetModel>(
            predicate: #Predicate { $0.category == category }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.monthlyLimit = budget.monthlyLimit
        } else {
            modelContext.insert(BudgetModel(category: budget.category, monthlyLimit: budget.monthlyLimit))
        }
        try modelContext.save()
    }

    func delete(category: String) throws {
        let descriptor = FetchDescriptor<BudgetModel>(
            predicate: #Predicate { $0.category == category }
        )
        guard let model = try? modelContext.fetch(descriptor).first else { return }
        modelContext.delete(model)
        try modelContext.save()
    }
}
