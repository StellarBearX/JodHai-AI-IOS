import SwiftData
import Foundation

// @MainActor isolates ModelContext access to the main actor, satisfying Swift 6 strict concurrency.
@MainActor
final class ExpenseRepositoryImpl: ExpenseRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [Expense] {
        let descriptor = FetchDescriptor<ExpenseModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func fetch(by id: UUID) throws -> Expense? {
        let descriptor = FetchDescriptor<ExpenseModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func add(_ expense: Expense) throws {
        let model = ExpenseModel.from(expense)
        modelContext.insert(model)
        try modelContext.save()
    }

    func update(_ expense: Expense) throws {
        let id = expense.id
        let descriptor = FetchDescriptor<ExpenseModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try modelContext.fetch(descriptor).first else { return }
        model.amount = expense.amount
        model.category = expense.category
        model.note = expense.note
        model.date = expense.date
        model.receiptImageData = expense.receiptImageData
        try modelContext.save()
    }

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<ExpenseModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(model)
        try modelContext.save()
    }
}
