import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var lang
    @State private var viewModel = ChatViewModel()
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            messageList
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    inputBar
                }
                .navigationTitle("Jod-Hai")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)
        }
        .background(Color(red: 0.91, green: 0.97, blue: 0.86))
        .sensoryFeedback(.success, trigger: viewModel.savedCount)
        .task {
            viewModel.configure(modelContext: modelContext)
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(
                            message: msg,
                            onConfirm: { Task { await viewModel.confirmSave() } },
                            onCancel:  { viewModel.cancelConfirm() }
                        )
                        .id(msg.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: msg.role == .user ? .trailing : .leading)
                                .combined(with: .opacity),
                            removal: .opacity.animation(.easeOut(duration: 0.15))
                        ))
                    }

                    if viewModel.isTyping {
                        TypingIndicator()
                            .id("typing")
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    if viewModel.showCategoryChips {
                        categoryChips
                            .id("chips")
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Color.clear.frame(height: 12).id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.messages.count)
                .animation(.spring(response: 0.3), value: viewModel.isTyping)
                .animation(.spring(response: 0.3), value: viewModel.showCategoryChips)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(red: 0.91, green: 0.97, blue: 0.86))
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.isTyping) { _, new in
                if new {
                    withAnimation(.spring(response: 0.3)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.showCategoryChips) { _, new in
                if new {
                    withAnimation(.spring(response: 0.3)) {
                        proxy.scrollTo("chips", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.categories, id: \.self) { cat in
                    let category = ExpenseCategory(rawValue: cat) ?? .other
                    Button {
                        Task { await viewModel.selectCategory(cat) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.caption.weight(.semibold))
                            Text(cat)
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(category.color)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(category.color.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(category.color.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(lang.t("พิมพ์ได้เลย... เช่น กาแฟ 65", "Type here... e.g. coffee 65"), text: $viewModel.inputText, axis: .vertical)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.matchaGreen.opacity(0.25), lineWidth: 1)
                )
                .focused($inputFocused)
                .lineLimit(1...4)
                .onSubmit {
                    guard !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    Task { await viewModel.send() }
                }
                .submitLabel(.send)

            Button {
                Task {
                    await viewModel.send()
                    // keep keyboard focused after send
                    inputFocused = true
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(
                        viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.secondary.opacity(0.3)
                            : Color.matchaGreen
                    )
                    .animation(.spring(response: 0.25), value: viewModel.inputText.isEmpty)
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider().opacity(0.3)
        }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        Group {
            switch message.kind {
            case .text(let text):
                textBubble(text: text, role: message.role)
            case .confirmExpense(let expense):
                confirmCard(expense: expense)
            case .savedExpense(let cat, let amount, let note):
                savedCard(category: cat, amount: amount, note: note)
            }
        }
        .frame(maxWidth: .infinity,
               alignment: message.role == .user ? .trailing : .leading)
    }

    // Plain text bubble
    private func textBubble(text: String, role: ChatRole) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(role == .user ? Color.white : Color.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                role == .user
                    ? Color.matchaGreen
                    : Color.white.opacity(0.9)
            )
            .clipShape(
                RoundedCornerShape(
                    radius: 18,
                    corners: role == .user
                        ? [.topLeft, .topRight, .bottomLeft]
                        : [.topLeft, .topRight, .bottomRight]
                )
            )
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            .frame(maxWidth: 280, alignment: role == .user ? .trailing : .leading)
    }

    // Confirmation card
    private func confirmCard(expense: ParsedExpense) -> some View {
        let isIncome    = expense.isIncome
        let amt         = expense.amount ?? 0
        let note        = expense.note
        let accentColor: Color = isIncome ? .blue : .matchaGreen

        let iconName: String
        let titleText: String
        if isIncome {
            let src  = IncomeSource(rawValue: expense.incomeSource ?? "") ?? .other
            iconName  = src.icon
            titleText = expense.incomeSource ?? "รายรับ"
        } else {
            let cat  = ExpenseCategory(rawValue: expense.category ?? "") ?? .other
            iconName  = cat.icon
            titleText = cat.rawValue
        }

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 42, height: 42)
                    .background(accentColor.opacity(0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        if isIncome {
                            Text("รายรับ")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                        Text(titleText).font(.subheadline.weight(.semibold))
                    }
                    if let note { Text(note).font(.caption).foregroundStyle(.secondary) }
                }
                Spacer()
                Text(amt.asCurrency())
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(accentColor)
                    .contentTransition(.numericText())
            }

            Divider()

            HStack(spacing: 10) {
                Button(action: onCancel) {
                    Text("ยกเลิก")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
                Button(action: onConfirm) {
                    Label("บันทึก", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(accentColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: accentColor.opacity(0.12), radius: 10, x: 0, y: 4)
        .frame(maxWidth: 300, alignment: .leading)
    }

    // Saved confirmation
    private func savedCard(category: String, amount: Double, note: String) -> some View {
        let incSrc      = IncomeSource(rawValue: category)
        let expCat      = ExpenseCategory(rawValue: category) ?? .other
        let isIncome    = incSrc != nil
        let iconName    = incSrc?.icon ?? expCat.icon
        let accentColor: Color = isIncome ? .blue : .matchaGreen

        return HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(accentColor)
                .symbolEffect(.bounce, value: true)
            VStack(alignment: .leading, spacing: 2) {
                Text(isIncome ? "บันทึกรายรับแล้ว! 💚" : "บันทึกแล้ว!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accentColor)
                Text("\(category) · \(amount.asCurrency())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: iconName).foregroundStyle(accentColor.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
        .frame(maxWidth: 300, alignment: .leading)
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.secondary.opacity(0.45))
                    .frame(width: 7, height: 7)
                    .offset(y: animating ? -4 : 0)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever()
                            .delay(Double(i) * 0.13),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedCornerShape(radius: 18, corners: [.topLeft, .topRight, .bottomRight]))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { animating = true }
    }
}

// MARK: - Rounded Corner Shape (individual corners)

private struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
