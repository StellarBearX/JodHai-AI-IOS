import SwiftData
import Foundation

@MainActor
final class IncomeRepositoryImpl: IncomeRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) { self.modelContext = modelContext }

    func fetchAll() throws -> [Income] {
        let descriptor = FetchDescriptor<IncomeModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map {
            Income(id: $0.id, amount: $0.amount, source: $0.source, note: $0.note, date: $0.date)
        }
    }

    func add(_ income: Income) throws {
        modelContext.insert(
            IncomeModel(id: income.id, amount: income.amount,
                        source: income.source, note: income.note, date: income.date)
        )
        try modelContext.save()
    }

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<IncomeModel>(predicate: #Predicate { $0.id == id })
        guard let model = try? modelContext.fetch(descriptor).first else { return }
        modelContext.delete(model)
        try modelContext.save()
    }
}
