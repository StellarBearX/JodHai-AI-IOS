import Foundation

struct PeriodSummary: Sendable {
    let total: Double
    let expenseCount: Int
    let byCategory: [String: Double]
    let expenses: [Expense]
}

struct CalculatePeriodSummaryUseCase: Sendable {
    let repository: any ExpenseRepositoryProtocol

    func execute(from startDate: Date, to endDate: Date) async throws -> PeriodSummary {
        let all = try await repository.fetchAll()
        let filtered = all.filter { $0.date >= startDate && $0.date <= endDate }
        let total = filtered.reduce(0) { $0 + $1.amount }
        let byCategory = Dictionary(grouping: filtered, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        return PeriodSummary(
            total: total,
            expenseCount: filtered.count,
            byCategory: byCategory,
            expenses: filtered
        )
    }
}
