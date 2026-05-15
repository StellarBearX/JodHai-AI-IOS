import Foundation

protocol ExpenseRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [Expense]
    func fetch(by id: UUID) async throws -> Expense?
    func add(_ expense: Expense) async throws
    func update(_ expense: Expense) async throws
    func delete(id: UUID) async throws
}
