import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var lang
    @State private var viewModel = BudgetViewModel()
    @State private var isSmartBudgetExpanded = false
    @Query(sort: \ExpenseModel.date, order: .reverse) private var allExpenses: [ExpenseModel]

    private var monthExpenses: [ExpenseModel] {
        let start = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: .now)
        ) ?? .distantPast
        return allExpenses.filter { $0.date >= start }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.91, green: 0.97, blue: 0.86).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        incomeCard
                        if viewModel.monthlyIncome > 0 {
                            smartBudgetCard
                        }
                        summaryBanner
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            BudgetCategoryRow(
                                status: statusFor(cat), category: cat,
                                onEdit: { viewModel.startEditing(category: cat.rawValue) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(lang.t("งบประมาณ", "Budget"))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .sheet(isPresented: $viewModel.isEditSheet) {
                BudgetEditSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isIncomeSheet) {
                IncomeAddSheet(viewModel: viewModel)
            }
        }
        .task {
            viewModel.configure(modelContext: modelContext)
            await viewModel.loadAll(monthExpenses: monthExpenses)
        }
        .onChange(of: allExpenses) { _, _ in
            viewModel.recalculate(monthExpenses: monthExpenses)
        }
    }

    // MARK: - Income Card

    private var incomeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(lang.t("รายรับเดือนนี้", "Income This Month"), systemImage: "arrow.down.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.matchaGreen)
                Spacer()
                Button {
                    viewModel.isIncomeSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.matchaGreen)
                }
            }

            Text(viewModel.monthlyIncome.asCurrency())
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Color.matchaGreenBright)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4), value: viewModel.monthlyIncome)

            if !viewModel.incomes.isEmpty {
                Divider()
                ForEach(viewModel.incomes.filter {
                    let start = Calendar.current.date(
                        from: Calendar.current.dateComponents([.year, .month], from: .now)
                    ) ?? .distantPast
                    return $0.date >= start
                }) { income in
                    HStack {
                        let src = IncomeSource(rawValue: income.source) ?? .other
                        Image(systemName: src.icon)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.matchaGreen)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(income.source)
                                .font(.caption.weight(.medium))
                            if !income.note.isEmpty {
                                Text(income.note)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        Text(income.amount.asCurrency())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.matchaGreen)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await viewModel.deleteIncome(income) }
                        } label: {
                            Image(systemName: "trash.fill")
                        }
                    }
                }
            } else {
                Text("แตะ + เพื่อเพิ่มรายรับ")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassCard(cornerRadius: 20)
    }

    // MARK: - Smart Budget Card (Collapsible)

    private var smartBudgetCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isSmartBudgetExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Color.matchaGreen.opacity(0.15)).frame(width: 36, height: 36)
                        Image(systemName: "sparkles")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.matchaGreen)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lang.t("ตั้งงบอัจฉริยะ", "Smart Budget"))
                            .font(.subheadline.weight(.semibold))
                        Text("\(lang.t("อิงจากรายรับ", "Based on income")) \(viewModel.monthlyIncome.asCurrency())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.matchaGreen)
                        .rotationEffect(.degrees(isSmartBudgetExpanded ? 180 : 0))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(.primary)

            if isSmartBudgetExpanded {
                Divider().padding(.horizontal, 18)
                VStack(alignment: .leading, spacing: 10) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(Array(viewModel.smartSuggestions.sorted { $0.value > $1.value }), id: \.key) { cat, amt in
                            HStack(spacing: 6) {
                                let category = ExpenseCategory.from(cat)
                                Image(systemName: category.icon)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(category.color)
                                Text(cat)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(amt.asCurrency())
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Color.matchaGreen)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    Button {
                        Task { await viewModel.applySmartBudgets() }
                    } label: {
                        Label("ใช้งบอัจฉริยะนี้", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.matchaGreen)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
            }
        }
        .glassCard(cornerRadius: 20)
    }

    // MARK: - Alert Banner

    @ViewBuilder
    private var summaryBanner: some View {
        let overs = viewModel.overBudgetCategories
        let nears = viewModel.nearLimitCategories
        if !overs.isEmpty || !nears.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                if !overs.isEmpty {
                    Label("\(overs.map(\.category).joined(separator: ", ")) — เกินงบแล้ว",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.red)
                }
                if !nears.isEmpty {
                    Label("\(nears.map(\.category).joined(separator: ", ")) — งบใกล้เต็ม",
                          systemImage: "bell.fill")
                        .font(.subheadline.weight(.medium)).foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 18)
        }
    }

    private func statusFor(_ cat: ExpenseCategory) -> BudgetStatus {
        viewModel.statuses.first { $0.category == cat.rawValue }
            ?? BudgetStatus(id: cat.rawValue, category: cat.rawValue, limit: 0, spent: 0)
    }
}

// MARK: - Category Row

private struct BudgetCategoryRow: View {
    let status: BudgetStatus
    let category: ExpenseCategory
    let onEdit: () -> Void

    private var progressColor: Color {
        status.isOverBudget ? .red : status.isNearLimit ? .orange : .matchaGreen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(category.color)
                    .frame(width: 38, height: 38)
                    .background(category.color.opacity(0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue).font(.subheadline.weight(.semibold))
                    if status.limit > 0 {
                        HStack(spacing: 4) {
                            Text(status.spent.asCurrency()).font(.caption.weight(.medium))
                                .foregroundStyle(progressColor)
                            Text("/").font(.caption).foregroundStyle(.tertiary)
                            Text(status.limit.asCurrency()).font(.caption).foregroundStyle(.secondary)
                        }
                    } else {
                        Text("ยังไม่ได้ตั้งงบ").font(.caption).foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                Button(action: onEdit) {
                    Image(systemName: status.limit > 0 ? "pencil.circle.fill" : "plus.circle.fill")
                        .font(.title3).symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.matchaGreen)
                }
            }

            if status.limit > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.12)).frame(height: 7)
                        Capsule().fill(progressColor)
                            .frame(width: geo.size.width * status.progress, height: 7)
                            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: status.progress)
                    }
                }.frame(height: 7)

                if status.isOverBudget {
                    Label("เกินงบ \((status.spent - status.limit).asCurrency())",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold)).foregroundStyle(.red)
                } else if status.isNearLimit {
                    Label("ใช้ไป \(Int(status.progress * 100))% — เหลือ \(status.remaining.asCurrency())",
                          systemImage: "bell.badge.fill")
                        .font(.caption.weight(.medium)).foregroundStyle(.orange)
                } else {
                    Text("เหลือ \(status.remaining.asCurrency())")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .glassCard(cornerRadius: 18)
    }
}

// MARK: - Budget Edit Sheet

private struct BudgetEditSheet: View {
    @Bindable var viewModel: BudgetViewModel
    @Environment(LanguageManager.self) private var lang
    @FocusState private var focused: Bool

    private var cat: ExpenseCategory {
        ExpenseCategory(rawValue: viewModel.editCategory) ?? .other
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Image(systemName: cat.icon)
                    .font(.system(size: 44)).foregroundStyle(cat.color)
                    .frame(width: 88, height: 88)
                    .background(cat.color.opacity(0.12)).clipShape(Circle())
                    .padding(.top, 20)

                Text(viewModel.editCategory).font(.title2.weight(.bold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("งบประมาณต่อเดือน (บาท)")
                        .font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                    HStack {
                        Text("฿").font(.title2.weight(.semibold)).foregroundStyle(Color.matchaGreen)
                        TextField("0", text: $viewModel.editLimitText)
                            .font(.title2.weight(.semibold)).keyboardType(.numberPad).focused($focused)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.matchaGreen.opacity(0.3), lineWidth: 1))
                    Text("เว้นว่างหรือใส่ 0 เพื่อลบงบ")
                        .font(.caption).foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 24)
                Spacer()
            }
            .navigationTitle(lang.t("ตั้งงบ", "Set Budget")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("ยกเลิก") { viewModel.isEditSheet = false }.foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("บันทึก") { Task { await viewModel.saveEdit() } }
                        .fontWeight(.semibold).foregroundStyle(Color.matchaGreen)
                }
            }
        }
        .presentationDetents([.medium]).presentationCornerRadius(28)
        .onAppear { focused = true }
    }
}

// MARK: - Income Add Sheet

private struct IncomeAddSheet: View {
    @Bindable var viewModel: BudgetViewModel
    @Environment(LanguageManager.self) private var lang
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Label("จำนวนเงิน", systemImage: "banknote.fill")
                            .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("฿").font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.matchaGreenBright)
                            TextField("0", text: $viewModel.newIncomeAmount)
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .keyboardType(.decimalPad).focused($focused)
                                .tint(Color.matchaGreen)
                        }
                        .padding(.horizontal, 20).padding(.vertical, 16)
                        .glassCard()
                    }

                    // Source picker
                    VStack(alignment: .leading, spacing: 10) {
                        Label("แหล่งรายรับ", systemImage: "tag.fill")
                            .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(IncomeSource.allCases, id: \.self) { src in
                                    let isSelected = viewModel.newIncomeSource == src.rawValue
                                    Button {
                                        withAnimation(.spring(response: 0.3)) {
                                            viewModel.newIncomeSource = src.rawValue
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: src.icon).font(.caption.weight(.bold))
                                            Text(src.rawValue).font(.caption.weight(.semibold))
                                        }
                                        .padding(.horizontal, 14).padding(.vertical, 9)
                                        .background(isSelected ? Color.matchaGreen : Color.white.opacity(0.07))
                                        .foregroundStyle(isSelected ? .white : .secondary)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.horizontal, -20)
                    }

                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Label("หมายเหตุ", systemImage: "pencil")
                            .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        TextField("เพิ่มโน้ต (ไม่บังคับ)", text: $viewModel.newIncomeNote)
                            .padding(.horizontal, 18).padding(.vertical, 16)
                            .glassCard(cornerRadius: 16)
                    }

                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Label("วันที่", systemImage: "calendar")
                            .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        DatePicker("", selection: $viewModel.newIncomeDate,
                                   displayedComponents: [.date])
                            .datePickerStyle(.compact).labelsHidden()
                            .tint(Color.matchaGreen)
                            .padding(.horizontal, 18).padding(.vertical, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassCard(cornerRadius: 16)
                    }

                    Button {
                        Task { await viewModel.addIncome() }
                    } label: {
                        Text("บันทึกรายรับ")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
                    .tint(Color.matchaGreen)
                    .disabled(Double(viewModel.newIncomeAmount) == nil)
                    .shadow(color: Color.matchaGreen.opacity(0.4), radius: 14, x: 0, y: 6)
                }
                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 32)
            }
            .navigationTitle(lang.t("เพิ่มรายรับ", "Add Income")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("ยกเลิก") { viewModel.isIncomeSheet = false }.foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.ultraThinMaterial)
        .presentationCornerRadius(32)
        .onAppear { focused = true }
    }
}
