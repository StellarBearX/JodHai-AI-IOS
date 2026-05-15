import Foundation

// MARK: - Parsed Result

struct ParsedExpense: Sendable {
    var amount: Double?
    var category: String?
    var note: String?
    var date: Date = .now
    var isIncome: Bool = false
    var incomeSource: String?
}

// MARK: - Parser

struct NLPExpenseParser: Sendable {

    // MARK: - Category keywords (Thai + EN, longest/most specific first)

    private static let categoryKeywords: [String: [String]] = [
        "Food": [
            "ข้าวมันไก่", "ก๋วยเตี๋ยว", "สตาร์บัคส์", "ราดหน้า", "ต้มยำ", "ปิ้งย่าง",
            "ไก่ทอด", "ชาบู", "หมูกระทะ", "บุฟเฟ่",
            "กาแฟ", "อาหาร", "ขนม", "ร้านอาหาร", "คาเฟ่", "เบเกอรี่",
            "กิน", "ข้าว", "ชา", "นม", "ผัด", "แกง",
            "breakfast", "lunch", "dinner", "coffee", "tea", "snack", "meal",
            "restaurant", "café", "cafe", "pizza", "burger", "sushi", "ramen",
            "noodle", "rice", "steak", "mcd", "kfc", "food",
        ],
        "Transport": [
            "แท็กซี่", "ค่าเดินทาง", "น้ำมัน", "รถไฟ", "รถบัส", "จอดรถ", "ทางด่วน",
            "บขส", "แอร์พอร์ตลิ้งค์", "ค่ารถ",
            "bts", "mrt", "grab", "taxi", "uber", "bolt",
            "รถ", "เรือ", "เดินทาง",
            "transport", "bus", "train", "ferry", "fuel", "parking", "toll",
        ],
        "Shopping": [
            "ของขวัญ", "เสื้อผ้า", "รองเท้า", "กระเป๋า", "เครื่องสำอาง",
            "ไอคอนสยาม", "ซื้อของ",
            "lazada", "shopee", "central", "สยาม", "ห้าง", "ตลาด",
            "amazon", "ช็อป", "ของใช้",
            "shop", "market", "clothes", "shoes", "bag", "cosmetic", "fashion",
        ],
        "Health": [
            "โรงพยาบาล", "หมอฟัน", "สมิติเวช", "วิตามิน", "ซื้อยา", "คลินิก",
            "ฟิตเนส", "ออกกำลัง", "หมอ", "ยา", "ฟัน",
            "gym", "โยคะ", "yoga",
            "doctor", "hospital", "pharmacy", "medicine", "clinic",
            "health", "dental", "supplement", "fitness",
        ],
        "Entertainment": [
            "คอนเสิร์ต", "คาราโอเกะ", "สวนสนุก", "ดูหนัง",
            "karaoke", "bowling", "netflix", "spotify", "disney",
            "หนัง", "เกม", "เที่ยว",
            "movie", "game", "concert", "entertainment", "travel",
        ],
        "Bills": [
            "ค่าโทรศัพท์", "ค่าเช่า", "ค่าเน็ต", "ค่าไฟ", "ค่าน้ำ",
            "ประกัน", "dtac", "true", "ais",
            "wifi", "internet", "electricity", "water", "phone",
            "rent", "insurance", "subscription", "bill",
        ],
    ]

    // Thai digit → Arabic digit
    private static let thaiDigits: [Character: Character] = [
        "๐": "0", "๑": "1", "๒": "2", "๓": "3", "๔": "4",
        "๕": "5", "๖": "6", "๗": "7", "๘": "8", "๙": "9",
    ]

    // Thai multiplier words → value
    private static let thaiMultipliers: [(keyword: String, value: Double)] = [
        ("ล้าน",    1_000_000),
        ("แสน",       100_000),
        ("หมื่น",      10_000),
        ("พัน",         1_000),
        ("ร้อย",          100),
        ("สิบ",            10),
    ]

    // Thai number prefixes (1-9)
    private static let thaiNumbers: [(keyword: String, value: Double)] = [
        ("สิบเอ็ด", 11), ("สิบสอง", 12), ("สิบสาม", 13), ("สิบสี่", 14),
        ("สิบห้า", 15), ("สิบหก", 16), ("สิบเจ็ด", 17), ("สิบแปด", 18), ("สิบเก้า", 19),
        ("หนึ่ง", 1), ("นึง", 1), ("สอง", 2), ("สาม", 3), ("สี่", 4),
        ("ห้า", 5), ("หก", 6), ("เจ็ด", 7), ("แปด", 8), ("เก้า", 9), ("สิบ", 10),
    ]

    // Income keywords
    private static let incomeKeywords: [String] = [
        "รับเงินเดือน", "ได้รับเงินเดือน", "เงินเดือนออก",
        "ค่าจ้าง", "รายได้", "ค่าตอบแทน", "รับค่า",
        "ได้รับ", "รับเงิน",
        "income", "salary", "got paid", "freelance payment",
    ]

    private static let greetings: [String] = [
        "สวัสดี", "หวัดดี", "ดีครับ", "ดีค่ะ", "hello", "hi", "hey",
        "ขอบคุณ", "ขอบใจ", "thanks", "thank you", "bye", "ลาก่อน",
    ]

    // MARK: - Public

    func parse(_ text: String) -> ParsedExpense {
        let normalised = normalise(text)
        var result = ParsedExpense()
        result.isIncome     = isIncome(normalised)
        result.incomeSource = result.isIncome ? extractIncomeSource(normalised) : nil
        result.amount       = extractAmount(from: normalised)
        result.category     = result.isIncome ? nil : extractCategory(from: normalised)
        result.note         = extractNote(from: text)        // use original for note
        result.date         = extractDate(from: normalised)
        return result
    }

    func isGreeting(_ text: String) -> Bool {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return Self.greetings.contains { lower.contains($0) } && extractAmount(from: lower) == nil
    }

    func isIncome(_ text: String) -> Bool {
        let lower = text.lowercased()
        return Self.incomeKeywords.contains { lower.contains($0) }
    }

    func extractIncomeSource(_ text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("เงินเดือน") || lower.contains("salary")       { return IncomeSource.salary.rawValue }
        if lower.contains("freelance") || lower.contains("ค่าจ้าง")      { return IncomeSource.freelance.rawValue }
        if lower.contains("ธุรกิจ")   || lower.contains("business")      { return IncomeSource.business.rawValue }
        if lower.contains("ลงทุน")    || lower.contains("investment")    { return IncomeSource.investment.rawValue }
        return IncomeSource.other.rawValue
    }

    // MARK: - Amount Extraction

    func extractAmount(from text: String) -> Double? {
        // 1. Try Thai digit normalisation first
        let converted = convertThaiDigits(text)

        // 2. k/K shorthand: 2k, 1.5k
        if let k = extractKShorthand(from: converted) { return k }

        // 3. Thai word numbers: สองพัน, ห้าร้อย
        if let w = extractThaiWordAmount(from: converted) { return w }

        // 4. Numeric patterns: ฿1,234.50 | 1234 | 99.9
        return extractNumericAmount(from: converted)
    }

    private func extractKShorthand(from text: String) -> Double? {
        let pattern = #"(\d+(?:\.\d+)?)\s*[kK]"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let m = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r = Range(m.range(at: 1), in: text),
              let n = Double(text[r]) else { return nil }
        return n * 1000
    }

    private func extractThaiWordAmount(from text: String) -> Double? {
        var lower = text.lowercased()
        var total: Double = 0
        var found = false

        // Replace known Thai number prefixes
        var multiplied: [(value: Double, mult: Double)] = []
        for (kw, val) in Self.thaiNumbers {
            if lower.contains(kw) {
                lower = lower.replacingOccurrences(of: kw, with: "__\(Int(val))__")
            }
        }

        // Walk through multipliers
        for (kw, mult) in Self.thaiMultipliers {
            guard lower.contains(kw) else { continue }
            // Find the digit token before this multiplier
            let parts = lower.components(separatedBy: kw)
            if parts.count >= 1 {
                let before = parts[0]
                // last __N__ token before the multiplier
                let numPattern = #"__(\d+)__"#
                if let regex = try? NSRegularExpression(pattern: numPattern),
                   let m = regex.matches(in: before,
                       range: NSRange(before.startIndex..., in: before)).last,
                   let r = Range(m.range(at: 1), in: before),
                   let n = Double(before[r]) {
                    multiplied.append((value: n, mult: mult))
                    total += n * mult
                    found = true
                } else if !before.trimmingCharacters(in: .whitespacesAndNewlines)
                                   .hasSuffix("__") {
                    total += mult
                    found = true
                }
            }
            lower = lower.replacingOccurrences(of: kw, with: " ")
        }
        return found ? total : nil
    }

    private func extractNumericAmount(from text: String) -> Double? {
        // Simplified pattern: prefer longest matches (greedy)
        let pattern = #"(?:฿\s*)?(\d+(?:,\d{3})*(?:\.\d{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = text as NSString
        let results = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        let amounts = results.compactMap { m -> Double? in
            let r = m.range(at: 1)
            guard r.location != NSNotFound else { return nil }
            return Double(ns.substring(with: r).replacingOccurrences(of: ",", with: ""))
        }
        return amounts.max()
    }

    // MARK: - Category

    private func extractCategory(from text: String) -> String? {
        var scores: [String: Int] = [:]
        for (cat, keywords) in Self.categoryKeywords {
            scores[cat] = keywords.filter { text.contains($0) }.count
        }
        guard let best = scores.max(by: { $0.value < $1.value }), best.value > 0 else { return nil }
        return best.key
    }

    // MARK: - Note

    func extractNote(from text: String) -> String? {
        var s = text
        // Remove numeric patterns
        let numPat = #"(?:฿\s*)?\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?"#
        s = s.replacingOccurrences(of: numPat, with: " ", options: .regularExpression)
        // Remove currency/date words
        let removals = ["บาท", "baht", "thb", "฿",
                        "เมื่อวาน", "วานซืน", "เมื่อกี้", "เช้านี้",
                        "yesterday", "today"]
        for word in removals {
            s = s.replacingOccurrences(of: word, with: " ",
                                       options: .caseInsensitive)
        }
        // Remove income keywords so they don't pollute note
        for kw in Self.incomeKeywords {
            s = s.replacingOccurrences(of: kw, with: " ", options: .caseInsensitive)
        }
        let cleaned = s.split(separator: " ").filter { !$0.isEmpty }.joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    // MARK: - Date Hints

    func extractDate(from text: String) -> Date {
        let lower = text.lowercased()
        let cal = Calendar.current
        if lower.contains("เมื่อวาน") || lower.contains("yesterday") {
            return cal.date(byAdding: .day, value: -1, to: .now) ?? .now
        }
        if lower.contains("วานซืน") {
            return cal.date(byAdding: .day, value: -2, to: .now) ?? .now
        }
        return .now
    }

    // MARK: - Helpers

    private func normalise(_ text: String) -> String {
        convertThaiDigits(text.lowercased())
    }

    private func convertThaiDigits(_ text: String) -> String {
        String(text.map { Self.thaiDigits[$0] ?? $0 })
    }
}
