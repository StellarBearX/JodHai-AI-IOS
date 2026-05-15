import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DashboardViewModel()
    @State private var animateGradient = false

    var body: some View {
        NavigationStack {
            ZStack {
                meshBackground
                ScrollView {
                    VStack(spacing: 20) {
                        totalSpendCard
                        thisMonthCard
                        chartSection
                        smartInsightsSection
                        if !viewModel.topCategories.isEmpty {
                            categoriesSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Jod-Hai")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .overlay(loadingOverlay)
        }
        .task {
            viewModel.configure(modelContext: modelContext)
            await viewModel.load()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }

    // MARK: - Animated MeshGradient Background

    private var meshBackground: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5],
                [animateGradient ? 0.58 : 0.42, animateGradient ? 0.42 : 0.58],
                [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                Color(red: 0.04, green: 0.07, blue: 0.03),
                Color(red: 0.06, green: 0.10, blue: 0.04),
                Color(red: 0.03, green: 0.05, blue: 0.02),
                Color(red: 0.08, green: 0.14, blue: 0.05),
                Color(red: 0.15, green: 0.26, blue: 0.10),
                Color(red: 0.07, green: 0.12, blue: 0.04),
                Color(red: 0.02, green: 0.04, blue: 0.01),
                Color(red: 0.05, green: 0.09, blue: 0.03),
                Color(red: 0.03, green: 0.06, blue: 0.02),
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Total Spend Card

    private var totalSpendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Total Spend", systemImage: "chart.line.uptrend.xyaxis")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(viewModel.totalSpend.asCurrency())
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.totalSpend)

            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.matchaGreenBright)
                Text(viewModel.expenses.count, format: .number)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: viewModel.expenses.count)
                Text("transactions total")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .glassCard()
    }

    // MARK: - This Month Card

    private var thisMonthCard: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Label("This Month", systemImage: "calendar")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(viewModel.thisMonthTotal.asCurrency())
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.matchaGreenBright)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: viewModel.thisMonthTotal)
            }
            Spacer()
            Divider()
                .frame(height: 44)
                .opacity(0.3)
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Label("Count", systemImage: "number")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("\(viewModel.thisMonthExpenses.count)")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: viewModel.thisMonthExpenses.count)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .glassCard()
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        SpendBarChart(
            data: viewModel.last7DaysData,
            average: viewModel.last7DaysAverage,
            weekTotal: viewModel.last7DaysTotal
        )
    }

    // MARK: - Smart Insights Section

    private var smartInsightsSection: some View {
        SmartInsightsCard(insightText: viewModel.smartInsightText)
    }

    // MARK: - Top Categories

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Categories")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 10) {
                ForEach(viewModel.topCategories, id: \.category) { item in
                    let cat = ExpenseCategory.from(item.category)
                    HStack(spacing: 14) {
                        Image(systemName: cat.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(cat.color)
                            .frame(width: 38, height: 38)
                            .background(cat.color.opacity(0.14))
                            .clipShape(Circle())

                        Text(item.category)
                            .font(.subheadline.weight(.medium))

                        Spacer()

                        Text(item.total.asCurrency())
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.matchaGreenBright)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.4), value: item.total)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .glassCard(cornerRadius: 18)
                }
            }
        }
    }

    // MARK: - Loading

    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(Color.matchaGreen)
                .scaleEffect(1.2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial.opacity(0.4))
        }
    }
}
