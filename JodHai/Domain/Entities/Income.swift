import Foundation

// MARK: - Source

enum IncomeSource: String, CaseIterable, Sendable {
    case salary     = "เงินเดือน"
    case freelance  = "Freelance"
    case business   = "ธุรกิจ"
    case investment = "ลงทุน"
    case other      = "อื่นๆ"

    var icon: String {
        switch self {
        case .salary:     return "banknote.fill"
        case .freelance:  return "laptopcomputer"
        case .business:   return "building.2.fill"
        case .investment: return "chart.xyaxis.line"
        case .other:      return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Entity

struct Income: Identifiable, Sendable {
    let id: UUID
    var amount: Double
    var source: String
    var note: String
    var date: Date

    init(id: UUID = UUID(), amount: Double,
         source: String = IncomeSource.salary.rawValue,
         note: String = "", date: Date = .now) {
        self.id = id; self.amount = amount
        self.source = source; self.note = note; self.date = date
    }
}
