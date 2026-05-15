import SwiftData
import Foundation

@Model
final class BudgetModel {
    @Attribute(.unique) var category: String
    var monthlyLimit: Double

    init(category: String, monthlyLimit: Double) {
        self.category = category
        self.monthlyLimit = monthlyLimit
    }
}
