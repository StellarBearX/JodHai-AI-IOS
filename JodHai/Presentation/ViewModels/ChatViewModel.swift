import SwiftData
import Foundation
import Observation

// MARK: - Conversation State

private enum ChatState: Sendable {
    case idle
    case collectingAmount(ParsedExpense)
    case collectingCategory(ParsedExpense)
    case confirming(ParsedExpense)
}

// MARK: - ViewModel

@MainActor
@Observable
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var inputText  = ""
    var isTyping   = false
    var savedCount = 0

    var showCategoryChips: Bool {
        if case .collectingCategory(let p) = state { return !p.isIncome }
        return false
    }
    var isConfirming: Bool {
        if case .confirming = state { return true }
        return false
    }

    let categories = ExpenseCategory.allCases.map(\.rawValue)

    private var state: ChatState = .idle
    private let parser  = NLPExpenseParser()
    private var expRepo: (any ExpenseRepositoryProtocol)?
    private var incRepo: (any IncomeRepositoryProtocol)?

    // MARK: - Setup

    func configure(modelContext: ModelContext) {
        guard expRepo == nil else { return }
        expRepo = ExpenseRepositoryImpl(modelContext: modelContext)
        incRepo = IncomeRepositoryImpl(modelContext: modelContext)
        greet()
    }

    // MARK: - User Actions

    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        append(.init(role: .user, text: text))
        await process(text)
    }

    func selectCategory(_ category: String) async {
        guard case .collectingCategory(var partial) = state else { return }
        partial.category = category
        append(.init(role: .user, text: category))
        await showConfirm(partial)
    }

    func confirmSave() async {
        guard case .confirming(let expense) = state else { return }
        state = .idle
        removeLastConfirmCard()

        let amount = expense.amount ?? 0
        if expense.isIncome {
            let income = Income(
                amount: amount,
                source: expense.incomeSource ?? IncomeSource.other.rawValue,
                note: expense.note ?? "",
                date: expense.date
            )
            try? await incRepo?.add(income)
            append(.init(saved: expense.incomeSource ?? "รายรับ", amount: amount, note: expense.note ?? ""))
        } else {
            let e = Expense(amount: amount, category: expense.category ?? "Other",
                            note: expense.note ?? "", date: expense.date)
            try? await expRepo?.add(e)
            append(.init(saved: expense.category ?? "Other", amount: amount, note: expense.note ?? ""))
        }
        savedCount += 1

        await delayedReply(ms: 550, text: randomFollowUp())
    }

    func cancelConfirm() {
        guard case .confirming = state else { return }
        state = .idle
        removeLastConfirmCard()
        append(.init(role: .assistant, text: "โอเค ยกเลิกแล้ว มีอะไรอื่นให้บันทึกไหมครับ?"))
    }

    // MARK: - Processing Pipeline

    private func process(_ text: String) async {
        switch state {

        case .idle:
            await processIdle(text)

        case .collectingAmount(var partial):
            if let amt = parser.extractAmount(from: text.lowercased()) ?? Double(text.trimmingCharacters(in: .whitespaces)) {
                partial.amount = amt
                if !partial.isIncome && partial.category == nil {
                    state = .collectingCategory(partial)
                    await delayedReply(ms: 350, text: "อยู่ในหมวดไหนครับ?")
                } else {
                    await showConfirm(partial)
                }
            } else {
                await delayedReply(ms: 300, text: "ลองพิมพ์แค่ตัวเลขได้เลยครับ เช่น \"150\" หรือ \"1,500\" 🙂")
            }

        case .collectingCategory(var partial):
            let reParsed = parser.parse(text)
            if let cat = reParsed.category {
                partial.category = cat
                await showConfirm(partial)
            } else {
                await delayedReply(ms: 300, text: "เลือกหมวดหมู่จากด้านบนได้เลยครับ 👆")
            }

        case .confirming:
            let lower = text.lowercased()
            let yes: [String] = ["ใช่", "ยืนยัน", "ได้เลย", "โอเค", "ok", "ได้", "บันทึก", "yes", "เลย"]
            let no:  [String] = ["ไม่", "ยกเลิก", "cancel", "เลิก", "no", "เปลี่ยน"]
            if yes.contains(where: { lower.contains($0) }) {
                await confirmSave()
            } else if no.contains(where: { lower.contains($0) }) {
                cancelConfirm()
            } else {
                // New input while confirming → cancel old, restart
                cancelConfirm()
                await processIdle(text)
            }
        }
    }

    private func processIdle(_ text: String) async {
        // Greeting
        if parser.isGreeting(text) {
            await delayedReply(ms: 300, text: randomGreeting())
            return
        }

        let parsed = parser.parse(text)

        // Can't understand
        if parsed.amount == nil && parsed.category == nil && !parsed.isIncome {
            await delayedReply(ms: 400, text:
                "บอกฉันว่าจ่ายหรือรับอะไรได้เลยครับ 😊\nตัวอย่าง:\n• \"กาแฟ 65 บาท\"\n• \"ค่า BTS 44\"\n• \"รับเงินเดือน 30,000\"\n• \"ซื้อยา 200 เมื่อวาน\""
            )
            return
        }

        if parsed.amount == nil {
            state = .collectingAmount(parsed)
            let hint = parsed.note.map { " (\($0))" } ?? ""
            await delayedReply(ms: 350, text: "จ่ายไปเท่าไหร่\(hint)ครับ?")
        } else if !parsed.isIncome && parsed.category == nil {
            state = .collectingCategory(parsed)
            await delayedReply(ms: 350, text: "อยู่ในหมวดไหนครับ?")
        } else {
            await showConfirm(parsed)
        }
    }

    // MARK: - Confirmation

    private func showConfirm(_ expense: ParsedExpense) async {
        state = .confirming(expense)
        isTyping = true
        try? await Task.sleep(nanoseconds: 400_000_000)
        isTyping = false
        append(.init(role: .assistant, expense: expense))
    }

    // MARK: - Helpers

    private func greet() {
        append(.init(role: .assistant, text:
            "สวัสดีครับ! 👋 บอกฉันว่าจ่ายหรือรับอะไรไปได้เลย\n\nตัวอย่าง:\n• \"กาแฟ 65\" → รายจ่ายอาหาร\n• \"ค่า BTS 44 บาท\" → ค่าเดินทาง\n• \"รับเงินเดือน 30,000\" → รายรับ\n• \"สองพัน ซื้อของ\" → ช็อปปิ้ง"
        ))
    }

    private func delayedReply(ms: UInt64, text: String) async {
        isTyping = true
        try? await Task.sleep(nanoseconds: ms * 1_000_000)
        isTyping = false
        append(.init(role: .assistant, text: text))
    }

    private func removeLastConfirmCard() {
        messages.removeAll {
            if case .confirmExpense = $0.kind { return true }
            return false
        }
    }

    private func append(_ msg: ChatMessage) { messages.append(msg) }

    private func randomGreeting() -> String {
        ["สวัสดีครับ! 😄 จ่ายอะไรไปบ้างวันนี้?",
         "ยินดีต้อนรับครับ! มีอะไรให้บันทึกไหม?",
         "ขอบคุณครับ! พิมพ์รายการที่ต้องการบันทึกได้เลย"].randomElement()!
    }

    private func randomFollowUp() -> String {
        ["บันทึกเรียบร้อย! มีอะไรอีกไหมครับ? 😊",
         "โอเคครับ ✅ จะบันทึกอะไรเพิ่มอีกไหม?",
         "เสร็จแล้วครับ! มีรายการอื่นอีกไหม?"].randomElement()!
    }
}
