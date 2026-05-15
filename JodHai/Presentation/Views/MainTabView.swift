import SwiftUI

struct MainTabView: View {
    @State private var navState = AppNavigationState()

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "square.grid.2x2.fill") {
                DashboardView()
            }
            Tab("Expenses", systemImage: "list.bullet.rectangle.portrait.fill") {
                ExpenseListView()
                    .environment(navState)
            }
        }
        .tint(.matchaGreen)
        .onOpenURL { url in
            guard url.scheme == "jodhai", url.host == "add-expense" else { return }
            navState.openAddExpense = true
        }
    }
}
