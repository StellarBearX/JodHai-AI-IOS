import Foundation

struct Budget: Identifiable, Sendable {
    let id: String      // = category (one budget per category)
    let category: String
    let monthlyLimit: Double
}
