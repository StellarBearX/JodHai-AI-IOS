import Foundation

struct Expense: Identifiable, Sendable, Hashable {
    let id: UUID
    var amount: Double
    var category: String
    var note: String
    var date: Date
    var receiptImageData: Data?

    init(
        id: UUID = UUID(),
        amount: Double,
        category: String,
        note: String = "",
        date: Date = .now,
        receiptImageData: Data? = nil
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.note = note
        self.date = date
        self.receiptImageData = receiptImageData
    }
}
