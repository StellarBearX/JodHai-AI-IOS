import Foundation

protocol IncomeRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [Income]
    func add(_ income: Income) async throws
    func delete(id: UUID) async throws
}
