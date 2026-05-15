import Foundation

protocol BudgetRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [Budget]
    func save(_ budget: Budget) async throws
    func delete(category: String) async throws
}
