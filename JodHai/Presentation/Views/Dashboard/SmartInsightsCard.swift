import SwiftUI

struct SmartInsightsCard: View {
    let insightText: String
    @State private var shimmer = false

    private var attributedInsight: AttributedString {
        (try? AttributedString(markdown: insightText)) ?? AttributedString(insightText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader
            Divider()
                .background(Color.glassStroke)
            insightBody
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .glassCard()
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }

    // MARK: - Header

    private var cardHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.matchaGreen.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.matchaGreenBright)
                    .scaleEffect(shimmer ? 1.1 : 1.0)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Smart Insights")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Powered by Apple Intelligence")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text("Beta")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.matchaGreen)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.matchaGreen.opacity(0.15))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.matchaGreen.opacity(0.3), lineWidth: 0.5)
                )
        }
    }

    // MARK: - Insight Body

    private var insightBody: some View {
        Group {
            if insightText.contains("Start logging") {
                emptyStateInsight
            } else {
                Text(attributedInsight)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var emptyStateInsight: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 28))
                .foregroundStyle(.quaternary)
                .symbolRenderingMode(.hierarchical)
            Text(insightText)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .lineSpacing(4)
        }
    }
}
