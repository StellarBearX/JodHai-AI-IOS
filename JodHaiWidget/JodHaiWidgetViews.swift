import SwiftUI
import WidgetKit

// MARK: - Small Widget

struct JodHaiSmallWidgetView: View {
    let entry: JodHaiWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(matchaGreenBright)
                Text("Jod-Hai")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.bottom, 8)

            Text("Today")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)

            Text(entry.todayTotal.widgetCurrency())
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(matchaGreenBright)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Spacer()

            // Quick-log button
            Button(intent: LogExpenseWidgetIntent()) {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Log")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(matchaGreen)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            ZStack {
                Color(red: 0.04, green: 0.07, blue: 0.03)
                // Subtle gradient blob
                RadialGradient(
                    colors: [Color(red: 0.14, green: 0.24, blue: 0.10).opacity(0.6), .clear],
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: 120
                )
            }
        }
    }
}

// MARK: - Medium Widget

struct JodHaiMediumWidgetView: View {
    let entry: JodHaiWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left column — totals
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(matchaGreenBright)
                    Text("Jod-Hai")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text(entry.todayTotal.widgetCurrency())
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(matchaGreenBright)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("This Month")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text(entry.monthTotal.widgetCurrency())
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }

                Spacer()

                Button(intent: LogExpenseWidgetIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("Quick Log")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(matchaGreen)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(maxHeight: .infinity)

            Divider()
                .background(Color.white.opacity(0.1))

            // Right column — recent expenses
            VStack(alignment: .leading, spacing: 6) {
                Text("Recent")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)

                if entry.recentItems.isEmpty {
                    Spacer()
                    Text("No expenses yet")
                        .font(.system(size: 11))
                        .foregroundStyle(.quaternary)
                    Spacer()
                } else {
                    ForEach(entry.recentItems) { item in
                        HStack(spacing: 6) {
                            Image(systemName: item.categoryIcon)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(matchaGreenBright)
                                .frame(width: 18, height: 18)
                                .background(matchaGreen.opacity(0.15))
                                .clipShape(Circle())
                            Text(item.displayTitle)
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Text(item.amount.widgetCurrency())
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(matchaGreenBright)
                        }
                    }
                    Spacer()
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            ZStack {
                Color(red: 0.04, green: 0.07, blue: 0.03)
                RadialGradient(
                    colors: [Color(red: 0.14, green: 0.24, blue: 0.10).opacity(0.5), .clear],
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: 160
                )
            }
        }
    }
}

// MARK: - Accessory (Lock Screen)

struct JodHaiAccessoryWidgetView: View {
    let entry: JodHaiWidgetEntry

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 12, weight: .bold))
            Text(entry.todayTotal.widgetCurrency())
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
            Text("today")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - Shared colour constants (mirrors DesignSystem without importing SwiftUI views)

private let matchaGreen      = Color(red: 0.302, green: 0.502, blue: 0.200)
private let matchaGreenBright = Color(red: 0.420, green: 0.700, blue: 0.290)

// MARK: - Currency helper (widget extension can't see DesignSystem.swift without a shared module)

private extension Double {
    func widgetCurrency(code: String = "THB") -> String {
        formatted(.currency(code: code).precision(.fractionLength(0...0)))
    }
}
