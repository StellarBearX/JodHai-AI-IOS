import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppNavigationState.self) private var navState
    @Environment(LanguageManager.self) private var lang
    @State private var viewModel = ExpenseListViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.91, green: 0.97, blue: 0.86)
                    .ignoresSafeArea()

                if viewModel.expenses.isEmpty && !viewModel.isAddSheetPresented {
                    emptyState
                } else {
                    List {
                        ForEach(viewModel.expenses) { expense in
                            ExpenseRow(expense: expense)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(
                                    EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20)
                                )
                                .swipeActions(edge: .leading) {
                                    Button {
                                        viewModel.startEditing(expense)
                                    } label: {
                                        Label("แก้ไข", systemImage: "pencil")
                                    }
                                    .tint(Color.matchaGreen)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task { await viewModel.delete(expense: expense) }
                                    } label: {
                                        Label("ลบ", systemImage: "trash.fill")
                                    }
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .refreshable { await viewModel.load() }
                }
            }
            .navigationTitle(lang.t("รายจ่าย", "Expenses"))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isAddSheetPresented = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.matchaGreenBright)
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: viewModel.isAddSheetPresented)
                }
            }
            .sheet(isPresented: $viewModel.isAddSheetPresented) {
                AddExpenseSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isEditSheetPresented) {
                AddExpenseSheet(viewModel: viewModel)
            }
        }
        // Haptics wired to monotonic counters — fire once per event, not on re-render
        .sensoryFeedback(.success, trigger: viewModel.savedExpenseCount)
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.deletedExpenseCount)
        .task {
            viewModel.configure(modelContext: modelContext)
            await viewModel.load()
        }
        // Deep-link from widget: auto-open Add sheet
        .onChange(of: navState.openAddExpense) { _, should in
            guard should else { return }
            viewModel.isAddSheetPresented = true
            navState.openAddExpense = false
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "tray.fill")
                .font(.system(size: 52))
                .foregroundStyle(.quaternary)
                .symbolRenderingMode(.hierarchical)
            VStack(spacing: 6) {
                Text(lang.t("ยังไม่มีรายจ่าย", "No Expenses Yet"))
                    .font(.title3.bold())
                    .foregroundStyle(.secondary)
                Text(lang.t("แตะ + เพื่อบันทึกรายจ่ายแรก", "Tap + to log your first expense"))
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Row

struct ExpenseRow: View {
    let expense: Expense

    private var category: ExpenseCategory { ExpenseCategory.from(expense.category) }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: category.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(category.color)
                .frame(width: 40, height: 40)
                .background(category.color.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.note.isEmpty ? expense.category : expense.note)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(expense.date.formatted(.dateTime.day().month(.abbreviated).year()))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(expense.amount.asCurrency())
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.matchaGreenBright)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.35), value: expense.amount)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 18)
    }
}
