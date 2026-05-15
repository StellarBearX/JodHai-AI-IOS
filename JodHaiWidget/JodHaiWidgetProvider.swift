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
                WidgetExpenseItem(id: UUID(), amount: 450, category: "Food",      note: "Lunch"),
                WidgetExpenseItem(id: UUID(), amount: 800, category: "Transport", note: "BTS"),
            ],
            monthTotal: 12_400
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (JodHaiWidgetEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : buildEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JodHaiWidgetEntry>) -> Void) {
        let entry = buildEntry()
        let nextHour = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(minute: 0),
            matchingPolicy: .nextTime
        ) ?? Date(timeIntervalSinceNow: 3600)
        completion(Timeline(entries: [entry], policy: .after(nextHour)))
    }

    // MARK: - Synchronous SwiftData read
    // ModelContext(container) is not actor-isolated, so it can be used on any
    // thread — avoiding the Task / sending issue entirely in Swift 6.
    // NOTE: App Group entitlement required so the widget reads the app's store.

    private func buildEntry() -> JodHaiWidgetEntry {
        guard let container = try? ModelContainer(for: ExpenseModel.self) else {
            return JodHaiWidgetEntry(date: .now, todayTotal: 0, recentItems: [], monthTotal: 0)
        }
        let ctx = ModelContext(container)

        let cal = Calendar.current
        let todayStart    = cal.startOfDay(for: .now)
        let tomorrowStart = cal.date(byAdding: .day, value: 1, to: todayStart) ?? .distantFuture
        let monthStart    = cal.date(from: cal.dateComponents([.year, .month], from: .now)) ?? .distantPast

        let descriptor = FetchDescriptor<ExpenseModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let all = (try? ctx.fetch(descriptor)) ?? []

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
