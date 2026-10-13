import SwiftUI
import Combine

#if !WIDGET_EXTENSION
struct LeetCodeWidgetView: View {
    @ObservedObject var state: AppState
    @State private var timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        LeetCodeProgressCardView(stats: state.leetCodeStats, isWidget: false)
            .frame(width: 440, height: 215)
            .onAppear {
                state.refreshLeetCodeStats()
            }
            .onReceive(timer) { _ in
                state.refreshLeetCodeStats()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                state.refreshLeetCodeStats()
            }
    }
}
#endif

public struct LeetCodeProgressCardView: View {
    public let stats: LeetCodeStats
    public let isWidget: Bool
    private let calendar = Calendar.current

    public init(stats: LeetCodeStats, isWidget: Bool = false) {
        self.stats = stats
        self.isWidget = isWidget
    }

    public var body: some View {
        ZStack {
            if !isWidget {
                // Widget dark card background for desktop app window
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.11))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: isWidget ? 6 : 14) {
                // Top Header Row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Progress")
                            .font(.system(size: isWidget ? 12.5 : 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.16, green: 0.88, blue: 0.45))

                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("\(stats.totalSolved)")
                                .font(.system(size: isWidget ? 22 : 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("/\(stats.totalQuestions)")
                                .font(.system(size: isWidget ? 12 : 15, weight: .medium, design: .rounded))
                                .foregroundStyle(Color(white: 0.45))
                        }
                    }

                    Spacer()

                    // Triple Progress Rings: Green (Easy), Yellow (Medium), Red (Hard)
                    LeetCodeProgressRings(
                        easySolved: stats.easySolved,
                        easyTotal: stats.easyTotal,
                        mediumSolved: stats.mediumSolved,
                        mediumTotal: stats.mediumTotal,
                        hardSolved: stats.hardSolved,
                        hardTotal: stats.hardTotal,
                        isWidget: isWidget
                    )
                }

                Spacer(minLength: 0)

                // Bottom 6 Months Heatmap
                HStack(alignment: .top, spacing: isWidget ? 7 : 11) {
                    ForEach(recentMonths(), id: \.self) { monthDate in
                        MonthBlockView(
                            monthDate: monthDate,
                            submissionMap: stats.submissionMap,
                            calendar: calendar,
                            isWidget: isWidget
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, isWidget ? 15 : 18)
            .padding(.vertical, isWidget ? 11 : 16)
        }
    }

    private func recentMonths() -> [Date] {
        let today = Date()
        var months: [Date] = []
        for offset in (0..<6).reversed() {
            if let date = calendar.date(byAdding: .month, value: -offset, to: today) {
                months.append(date)
            }
        }
        return months
    }
}

// MARK: - Concentric Rings
struct LeetCodeProgressRings: View {
    let easySolved: Int
    let easyTotal: Int
    let mediumSolved: Int
    let mediumTotal: Int
    let hardSolved: Int
    let hardTotal: Int
    var isWidget: Bool = false

    var body: some View {
        let outerD: CGFloat = isWidget ? 42 : 54
        let middleD: CGFloat = isWidget ? 30 : 39
        let innerD: CGFloat = isWidget ? 18 : 24
        let lineW: CGFloat = isWidget ? 3.5 : 4.5

        ZStack {
            // Outer Ring: Easy (Green)
            RingCircle(
                diameter: outerD,
                lineWidth: lineW,
                progress: fraction(solved: easySolved, total: easyTotal),
                color: Color(red: 0.16, green: 0.88, blue: 0.45)
            )

            // Middle Ring: Medium (Yellow)
            RingCircle(
                diameter: middleD,
                lineWidth: lineW,
                progress: fraction(solved: mediumSolved, total: mediumTotal),
                color: Color(red: 1.0, green: 0.73, blue: 0.0)
            )

            // Inner Ring: Hard (Red)
            RingCircle(
                diameter: innerD,
                lineWidth: lineW,
                progress: fraction(solved: hardSolved, total: hardTotal),
                color: Color(red: 0.95, green: 0.28, blue: 0.28)
            )
        }
        .frame(width: isWidget ? 44 : 58, height: isWidget ? 44 : 58)
    }

    private func fraction(solved: Int, total: Int) -> Double {
        guard total > 0, solved > 0 else { return 0.0 }
        let raw = Double(solved) / Double(total)
        return min(max(raw, 0.02), 1.0)
    }
}

private struct RingCircle: View {
    let diameter: CGFloat
    let lineWidth: CGFloat
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(color.opacity(0.18), lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)

            // Active progress arc
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Month Column Block
struct MonthBlockView: View {
    let monthDate: Date
    let submissionMap: [Date: Int]
    let calendar: Calendar
    var isWidget: Bool = false

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: monthDate).uppercased()
    }

    private var weeks: [[DayCell?]] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate),
              let monthRange = calendar.range(of: .day, in: .month, for: monthDate) else {
            return []
        }

        let firstDay = monthInterval.start
        let today = calendar.startOfDay(for: Date())
        let firstWeekday = calendar.component(.weekday, from: firstDay) // 1 = Sun, 7 = Sat

        var result: [[DayCell?]] = []
        var currentWeek: [DayCell?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                let startOfDay = calendar.startOfDay(for: date)
                let count = submissionMap[startOfDay] ?? 0
                let isFuture = startOfDay > today
                currentWeek.append(DayCell(count: count, isFuture: isFuture))

                if currentWeek.count == 7 {
                    result.append(currentWeek)
                    currentWeek = []
                }
            }
        }

        if !currentWeek.isEmpty {
            while currentWeek.count < 7 {
                currentWeek.append(nil)
            }
            result.append(currentWeek)
        }

        return result
    }

    var body: some View {
        let cellSize: CGFloat = isWidget ? 5.8 : 7.5
        let cellSpacing: CGFloat = isWidget ? 2.0 : 2.5
        let cornerR: CGFloat = isWidget ? 1.4 : 1.8

        VStack(spacing: isWidget ? 4 : 6) {
            HStack(alignment: .top, spacing: cellSpacing) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: cellSpacing) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, cell in
                            if let cell = cell {
                                RoundedRectangle(cornerRadius: cornerR, style: .continuous)
                                    .fill(cellColor(cell))
                                    .frame(width: cellSize, height: cellSize)
                            } else {
                                Color.clear
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }

            Text(monthLabel)
                .font(.system(size: isWidget ? 8.5 : 9.5, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(white: 0.55))
        }
    }

    private func cellColor(_ cell: DayCell) -> Color {
        if cell.isFuture {
            return Color(red: 0.14, green: 0.15, blue: 0.17).opacity(0.4)
        }
        if cell.count > 0 {
            if cell.count >= 6 {
                return Color(red: 0.18, green: 0.90, blue: 0.45)
            } else if cell.count >= 3 {
                return Color(red: 0.16, green: 0.80, blue: 0.40)
            } else {
                return Color(red: 0.14, green: 0.65, blue: 0.35)
            }
        }
        return Color(red: 0.18, green: 0.19, blue: 0.22)
    }
}

struct DayCell {
    let count: Int
    let isFuture: Bool
}
