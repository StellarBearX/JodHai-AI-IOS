import SwiftData
import Foundation

@Model
final class IncomeModel {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var source: String
    var note: String
    var date: Date

    init(id: UUID = UUID(), amount: Double, source: String, note: String = "", date: Date = .now) {
        self.id = id; self.amount = amount
        self.source = source; self.note = note; self.date = date
    }
}
