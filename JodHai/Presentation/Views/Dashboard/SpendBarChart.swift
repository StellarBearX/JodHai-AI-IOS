import Charts
import SwiftUI

struct SpendBarChart: View {
    let data: [DailySpend]
    let average: Double
    let weekTotal: Double

    @State private var animated = false
    @State private var selectedDay: DailySpend?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            chartHeader
            chart
                .frame(height: 164)
            if let day = selectedDay {
                selectionLabel(for: day)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .glassCard()
        .onAppear { triggerAnimation() }
        .onChange(of: data) { _, _ in
            animated = false
            triggerAnimation()
        }
    }

    // MARK: - Header

    private var chartHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Label("Last 7 Days", systemImage: "calendar.badge.clock")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(weekTotal.asCurrency())
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.matchaGreenBright)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: weekTotal)
            }
            Spacer()
            if average > 0 {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Daily avg")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tertiary)
                    Text(average.asCurrency())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            // Average rule line
            if average > 0 {
                RuleMark(y: .value("Average", average))
                    .foregroundStyle(Color.matchaGreen.opacity(0.45))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .annotation(position: .top, alignment: .trailing, spacing: 4) {
                        Text("avg")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.matchaGreen.opacity(0.8))
                    }
            }

            // Bars
            ForEach(data) { day in
                BarMark(
                    x: .value("Day", day.shortDay),
                    y: .value("Spend", animated ? day.amount : 0)
                )
                .foregroundStyle(barGradient(for: day))
                .clipShape(.rect(cornerRadius: 9, style: .continuous))
                // Highlight selection
                .opacity(selectedDay == nil || selectedDay?.id == day.id ? 1 : 0.4)
            }

            // Selection indicator
            if let day = selectedDay {
                RuleMark(x: .value("Selected", day.shortDay))
                    .foregroundStyle(Color.white.opacity(0.1))
                    .lineStyle(StrokeStyle(lineWidth: 28))
                    .annotation(position: .top, spacing: 6) {
                        Text(day.amount.asCurrency())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.matchaGreenBright)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
        }
        .chartYAxis(.hidden)
        .chartPlotStyle { plot in
            plot.background(Color.white.opacity(0.03))
                .clipShape(.rect(cornerRadius: 12, style: .continuous))
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let origin = geo[proxy.plotFrame!].origin
                                let location = CGPoint(
                                    x: value.location.x - origin.x,
                                    y: value.location.y - origin.y
                                )
                                if let label: String = proxy.value(atX: location.x) {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedDay = data.first { $0.shortDay == label }
                                    }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.3)) {
                                    selectedDay = nil
                                }
                            }
                    )
            }
        }
        .animation(
            .spring(response: 0.65, dampingFraction: 0.72).delay(0.08),
            value: animated
        )
    }

    // MARK: - Selection Label

    private func selectionLabel(for day: DailySpend) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.matchaGreen)
                .frame(width: 6, height: 6)
            Text(day.date.formatted(.dateTime.weekday(.wide).day().month()))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func barGradient(for day: DailySpend) -> LinearGradient {
        if day.isToday {
            return LinearGradient(
                colors: [Color.matchaGreen, Color.matchaGreenBright],
                startPoint: .bottom, endPoint: .top
            )
        }
        return LinearGradient(
            colors: [Color.matchaGreen.opacity(0.35), Color.matchaGreen.opacity(0.65)],
            startPoint: .bottom, endPoint: .top
        )
    }

    private func triggerAnimation() {
        withAnimation(.spring(response: 0.65, dampingFraction: 0.72).delay(0.12)) {
            animated = true
        }
    }
}
