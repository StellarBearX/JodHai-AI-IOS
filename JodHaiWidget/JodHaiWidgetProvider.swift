import WidgetKit
import SwiftData
import Foundation

// MARK: - Timeline Entry

struct JodHaiWidgetEntry: TimelineEntry {
    let date: Date
    let todayTotal: Double
    let recentItems: [WidgetExpenseItem]
    let monthTotal: Double
}

struct WidgetExpenseItem: Identifiable {
    let id: UUID
    let amount: Double
    let category: String
    let note: String

    var displayTitle: String { note.isEmpty ? category : note }

    var categoryIcon: String {
        switch category.lowercased() {
        case "food":          return "fork.knife"
        case "transport":     return "car.fill"
        case "shopping":      return "bag.fill"
        case "health":        return "heart.fill"
        case "entertainment": return "popcorn.fill"
        case "bills":         return "doc.text.fill"
        default:              return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Provider

struct JodHaiWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> JodHaiWidgetEntry {
        JodHaiWidgetEntry(
            date: .now,
            todayTotal: 1_250,
            recentItems: [
                WidgetExpenseItem(id: UUID(), amount: 450, category: "Food", note: "Lunch"),
                WidgetExpenseItem(id: UUID(), amount: 800, category: "Transport", note: "BTS"),
            ],
            monthTotal: 12_400
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (JodHaiWidgetEntry) -> Void) {
        Task { @MainActor in
            completion(await fetchEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JodHaiWidgetEntry>) -> Void) {
        Task { @MainActor in
            let entry = await fetchEntry()
            // Refresh at the top of the next hour so totals stay current.
            let nextUpdate = Calendar.current.nextDate(
                after: .now,
                matching: DateComponents(minute: 0),
                matchingPolicy: .nextTime
            ) ?? Date(timeIntervalSinceNow: 3600)
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    // MARK: - SwiftData fetch
    // NOTE: Both the app and widget extension must belong to the same App Group
    // and ModelContainer must be configured with the shared group URL for live data.
    @MainActor
    private func fetchEntry() async -> JodHaiWidgetEntry {
        guard let container = try? ModelContainer(for: ExpenseModel.self) else {
            return placeholder(in: .init(family: .systemSmall, isPreview: false))
        }
        let ctx = container.mainContext

        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: .now)
        let tomorrowStart = cal.date(byAdding: .day, value: 1, to: todayStart) ?? .distantFuture
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: .now)) ?? .distantPast

        let allDescriptor = FetchDescriptor<ExpenseModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let all = (try? ctx.fetch(allDescriptor)) ?? []

        let todayTotal = all
            .filter { $0.date >= todayStart && $0.date < tomorrowStart }
            .reduce(0) { $0 + $1.amount }

        let monthTotal = all
            .filter { $0.date >= monthStart }
            .reduce(0) { $0 + $1.amount }

        let recentItems = all.prefix(3).map {
            WidgetExpenseItem(id: $0.id, amount: $0.amount, category: $0.category, note: $0.note)
        }

        return JodHaiWidgetEntry(
            date: .now,
            todayTotal: todayTotal,
            recentItems: Array(recentItems),
            monthTotal: monthTotal
        )
    }
}

// Expose ExpenseModel to the widget extension (separate target shares the same file)
// by importing it from a shared framework, or by adding Data/Models/ExpenseModel.swift
// to the widget extension target in Xcode.
