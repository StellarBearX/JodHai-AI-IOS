import SwiftUI

struct MainTabView: View {
    @State private var navState = AppNavigationState()
    @State private var langManager = LanguageManager()

    var body: some View {
        TabView {
            Tab(langManager.t("ภาพรวม", "Dashboard"), systemImage: "square.grid.2x2.fill") {
                DashboardView()
            }
            Tab(langManager.t("รายจ่าย", "Expenses"), systemImage: "list.bullet.rectangle.portrait.fill") {
                ExpenseListView()
                    .environment(navState)
            }
            Tab(langManager.t("งบประมาณ", "Budget"), systemImage: "chart.bar.xaxis.ascending") {
                BudgetView()
            }
            Tab(langManager.t("แชท", "Chat"), systemImage: "bubble.left.and.bubble.right.fill") {
                ChatView()
            }
            Tab(langManager.t("ตั้งค่า", "Settings"), systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .tint(.matchaGreen)
        .preferredColorScheme(.light)
        .environment(langManager)
        .onOpenURL { url in
            guard url.scheme == "jodhai", url.host == "add-expense" else { return }
            navState.openAddExpense = true
        }
    }
}
