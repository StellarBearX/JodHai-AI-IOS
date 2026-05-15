import SwiftUI

// MARK: - Brand Colors

extension Color {
    /// Deep matcha green — primary accent throughout the app.
    static let matchaGreen = Color(red: 0.302, green: 0.502, blue: 0.200)
    /// Brighter matcha for dark-mode text and highlights.
    static let matchaGreenBright = Color(red: 0.420, green: 0.700, blue: 0.290)
    /// Subtle white border for glass layers.
    static let glassStroke = Color.white.opacity(0.11)
}

// MARK: - Category Model

enum ExpenseCategory: String, CaseIterable, Sendable {
    case food           = "Food"
    case transport      = "Transport"
    case shopping       = "Shopping"
    case health         = "Health"
    case entertainment  = "Entertainment"
    case bills          = "Bills"
    case other          = "Other"

    var icon: String {
        switch self {
        case .food:          return "fork.knife"
        case .transport:     return "car.fill"
        case .shopping:      return "bag.fill"
        case .health:        return "heart.fill"
        case .entertainment: return "popcorn.fill"
        case .bills:         return "doc.text.fill"
        case .other:         return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food:          return .orange
        case .transport:     return .blue
        case .shopping:      return .pink
        case .health:        return .red
        case .entertainment: return .purple
        case .bills:         return .yellow
        case .other:         return .gray
        }
    }

    static func from(_ string: String) -> ExpenseCategory {
        ExpenseCategory(rawValue: string) ?? .other
    }
}

// MARK: - Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.glassStroke, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 8)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 24) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Currency Formatting

extension Double {
    func asCurrency(code: String = "THB") -> String {
        formatted(.currency(code: code).precision(.fractionLength(0...2)))
    }
}
