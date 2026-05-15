import Foundation

enum ChatRole: Sendable {
    case user
    case assistant
}

enum MessageKind: Sendable {
    case text(String)
    case confirmExpense(ParsedExpense)
    case savedExpense(category: String, amount: Double, note: String)
}

struct ChatMessage: Identifiable, Sendable {
    let id: UUID
    let role: ChatRole
    let kind: MessageKind
    let timestamp: Date

    init(role: ChatRole, text: String) {
        self.id = UUID(); self.role = role
        self.kind = .text(text); self.timestamp = .now
    }

    init(role: ChatRole, expense: ParsedExpense) {
        self.id = UUID(); self.role = role
        self.kind = .confirmExpense(expense); self.timestamp = .now
    }

    init(saved category: String, amount: Double, note: String) {
        self.id = UUID(); self.role = .assistant
        self.kind = .savedExpense(category: category, amount: amount, note: note); self.timestamp = .now
    }
}
