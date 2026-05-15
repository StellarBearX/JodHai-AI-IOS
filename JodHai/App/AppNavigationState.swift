import Observation

/// Shared navigation signal passed through the SwiftUI environment.
/// Views observe it to react to deep links (e.g. from the widget).
@Observable
final class AppNavigationState {
    var openAddExpense = false
}
