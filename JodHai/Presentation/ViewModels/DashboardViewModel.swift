import SwiftData
import Foundation
import Observation

// MARK: - Chart Model

struct DailySpend: Identifiable, Equatable, Sendable {
    let id: String         // "yyyy-MM-dd" for stable identity
    let date: Date
    let amount: Double

    var shortDay: String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class DashboardViewModel {
    var expenses: [Expense] = []
    var isLoading = false

    private var repository: (any ExpenseRepositoryProtocol)?

    func configure(modelContext: ModelContext) {
        guard repository == nil else { return }
        repository = ExpenseRepositoryImpl(modelContext: modelContext)
    }

    func load() async {
        guard let repository else { return }
        isLoading = true
        defer { isLoading = false }
        expenses = (try? await repository.fetchAll()) ?? []
    }

    // MARK: - Summary

    var totalSpend: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var thisMonthExpenses: [Expense] {
        let start = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: .now)
        ) ?? .distantPast
        return expenses.filter { $0.date >= start }
    }

    var thisMonthTotal: Double {
        thisMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    var previousMonthTotal: Double {
        let cal = Calendar.current
        let now = Date.now
        guard
            let startOfThisMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)),
            let startOfLastMonth = cal.date(byAdding: .month, value: -1, to: startOfThisMonth)
        else { return 0 }
        return expenses
            .filter { $0.date >= startOfLastMonth && $0.date < startOfThisMonth }
            .reduce(0) { $0 + $1.amount }
    }

    var topCategories: [(category: String, total: Double)] {
        Dictionary(grouping: expenses, by: \.category)
            .map { (category: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
            .prefix(4)
            .map { $0 }
    }

    // MARK: - 7-Day Chart Data

    var last7DaysData: [DailySpend] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<7).reversed().compactMap { offset -> DailySpend? in
            guard let date = cal.date(byAdding: .day, value: -offset, to: today),
                  let nextDay = cal.date(byAdding: .day, value: 1, to: date)
            else { return nil }
            let total = expenses
                .filter { $0.date >= date && $0.date < nextDay }
                .reduce(0) { $0 + $1.amount }
            return DailySpend(
                id: date.formatted(.iso8601.year().month().day()),
                date: date,
                amount: total
            )
        }
    }

    var last7DaysTotal: Double {
        last7DaysData.reduce(0) { $0 + $1.amount }
    }

    var last7DaysAverage: Double {
        let nonZero = last7DaysData.filter { $0.amount > 0 }
        guard !nonZero.isEmpty else { return 0 }
        return nonZero.reduce(0) { $0 + $1.amount } / Double(nonZero.count)
    }

    // MARK: - Smart Insight

    var smartInsightText: String {
        guard !expenses.isEmpty else {
            return "Start logging expenses to unlock personalized spending insights powered by Apple Intelligence."
        }
        guard thisMonthTotal > 0 else {
            let top = topCategories.first?.category ?? "General"
            return "No expenses logged yet this month. Your all-time top category is \(top)."
        }
        let top = topCategories.first?.category ?? "General"
        let changeText: String
        if previousMonthTotal > 0 {
            let pct = (thisMonthTotal - previousMonthTotal) / previousMonthTotal * 100
            if pct > 5 {
                changeText = "up \(Int(pct))% from last month"
            } else if pct < -5 {
                changeText = "down \(Int(abs(pct)))% from last month"
            } else {
                changeText = "on par with last month"
            }
        } else {
            changeText = "no prior month data to compare"
        }
        return "You've spent **\(thisMonthTotal.asCurrency())** this month — \(changeText). **\(top)** is your biggest category this period."
    }
}
