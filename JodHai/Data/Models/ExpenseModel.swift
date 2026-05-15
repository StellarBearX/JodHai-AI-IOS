import SwiftData
import Foundation

@Model
final class ExpenseModel {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var category: String
    var note: String
    var date: Date
    @Attribute(.externalStorage) var receiptImageData: Data?

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

extension ExpenseModel {
    func toDomain() -> Expense {
        Expense(
            id: id,
            amount: amount,
            category: category,
            note: note,
            date: date,
            receiptImageData: receiptImageData
        )
    }

    static func from(_ expense: Expense) -> ExpenseModel {
        ExpenseModel(
            id: expense.id,
            amount: expense.amount,
            category: expense.category,
            note: expense.note,
            date: expense.date,
            receiptImageData: expense.receiptImageData
        )
    }
}
