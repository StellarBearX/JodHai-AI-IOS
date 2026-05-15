import SwiftUI
import PhotosUI

struct AddExpenseSheet: View {
    @Bindable var viewModel: ExpenseListViewModel
    @FocusState private var amountFocused: Bool
    @State private var scanPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    amountField
                    categoryPicker
                    noteField
                    dateField
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.isAddSheetPresented = false
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.ultraThinMaterial)
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        .presentationCornerRadius(32)
        .onAppear { amountFocused = true }
        .onChange(of: scanPhotoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await viewModel.scanReceipt(imageData: data)
                }
                scanPhotoItem = nil
            }
        }
        .alert(
            "Scan Failed",
            isPresented: Binding(
                get: { viewModel.scanErrorMessage != nil },
                set: { if !$0 { viewModel.scanErrorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.scanErrorMessage = nil }
        } message: {
            Text(viewModel.scanErrorMessage ?? "")
        }
    }

    // MARK: - Amount

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Amount", systemImage: "banknote.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                scanButton
            }

            ZStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("฿")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.matchaGreenBright)

                    TextField("0.00", text: $viewModel.newAmount)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .keyboardType(.decimalPad)
                        .focused($amountFocused)
                        .tint(Color.matchaGreen)
                        .minimumScaleFactor(0.6)
                }
                .opacity(viewModel.isScanning ? 0.3 : 1)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isScanning)

                if viewModel.isScanning {
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(Color.matchaGreenBright)
                            .scaleEffect(1.3)
                        Text("Reading receipt…")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.matchaGreenBright)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .glassCard()
            .animation(.spring(response: 0.35), value: viewModel.isScanning)
        }
    }

    // MARK: - Scan Button

    private var scanButton: some View {
        PhotosPicker(
            selection: $scanPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            HStack(spacing: 5) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 13, weight: .semibold))
                Text("Scan Receipt")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color.matchaGreenBright)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.matchaGreen.opacity(0.14))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.matchaGreen.opacity(0.3), lineWidth: 0.5)
            )
        }
        .disabled(viewModel.isScanning)
    }

    // MARK: - Category

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Category", systemImage: "tag.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.categories, id: \.self) { cat in
                        let category = ExpenseCategory.from(cat)
                        let isSelected = viewModel.newCategory == cat

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.newCategory = cat
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: category.icon)
                                    .font(.caption.weight(.bold))
                                Text(cat)
                                    .font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(isSelected ? Color.matchaGreen : Color.white.opacity(0.07))
                            .foregroundStyle(isSelected ? Color.white : Color.secondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(
                                    isSelected ? Color.matchaGreenBright.opacity(0.5) : Color.clear,
                                    lineWidth: 1
                                )
                            )
                            .shadow(
                                color: isSelected ? Color.matchaGreen.opacity(0.4) : .clear,
                                radius: 8, x: 0, y: 4
                            )
                        }
                        .sensoryFeedback(.selection, trigger: viewModel.newCategory)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    // MARK: - Note

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Note", systemImage: "pencil")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Add a note (optional)", text: $viewModel.newNote)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .glassCard(cornerRadius: 16)
        }
    }

    // MARK: - Date

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Date", systemImage: "calendar")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            DatePicker("", selection: $viewModel.newDate, displayedComponents: [.date])
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(Color.matchaGreen)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(cornerRadius: 16)
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            Task { await viewModel.addExpense() }
        } label: {
            Text("Save Expense")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(Color.matchaGreen)
        .disabled(!viewModel.isFormValid || viewModel.isScanning)
        .opacity(viewModel.isFormValid ? 1 : 0.4)
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.isFormValid)
        .shadow(
            color: viewModel.isFormValid ? Color.matchaGreen.opacity(0.45) : .clear,
            radius: 16, x: 0, y: 6
        )
        .animation(.easeInOut(duration: 0.2), value: viewModel.isFormValid)
    }
}
