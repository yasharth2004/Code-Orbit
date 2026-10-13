import SwiftUI
import Combine

#if !WIDGET_EXTENSION
struct GitHubHeatmapWidgetView: View {
    @ObservedObject var state: AppState
    @State private var timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    var body: some View {
        GitHubHeatmapCardView(submissionMap: state.gitHubSubmissionMap, isWidget: false)
            .frame(width: 440, height: 215)
            .onAppear {
                state.refreshGitHubActivity()
            }
            .onReceive(timer) { _ in
                state.refreshGitHubActivity()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                state.refreshGitHubActivity()
            }
    }
}
#endif

public struct GitHubHeatmapCardView: View {
    public let submissionMap: [Date: Int]
    public let isWidget: Bool
    private let calendar = Calendar.current

    public init(submissionMap: [Date: Int], isWidget: Bool = false) {
        self.submissionMap = submissionMap
        self.isWidget = isWidget
    }

    public var body: some View {
        ZStack {
            if !isWidget {
                // Widget dark container
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.11))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }

            // Pure Heatmap Grid matching Image 1
            let spacing: CGFloat = isWidget ? 3.5 : 4.5
            let cellSize: CGFloat = isWidget ? 10.5 : 13
            let numWeeks = isWidget ? 21 : 23

            HStack(spacing: spacing) {
                ForEach(Array(computedWeeks(numberOfWeeks: numWeeks).enumerated()), id: \.offset) { _, week in
                    VStack(spacing: spacing) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, cell in
                            RoundedRectangle(cornerRadius: isWidget ? 2.2 : 3, style: .continuous)
                                .fill(colorForCount(cell.count, isFuture: cell.isFuture))
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
            .padding(.horizontal, isWidget ? 12 : 16)
            .padding(.vertical, isWidget ? 12 : 16)
        }
    }

    private func computedWeeks(numberOfWeeks: Int) -> [[GridDay]] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today) // 1 = Sun, 7 = Sat
        guard let thisSaturday = calendar.date(byAdding: .day, value: (7 - weekday), to: today) else { return [] }

        var allWeeks: [[GridDay]] = []

        for weekOffset in (0..<numberOfWeeks).reversed() {
            guard let weekEnd = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: thisSaturday),
                  let weekStart = calendar.date(byAdding: .day, value: -6, to: weekEnd) else { continue }

            var weekDays: [GridDay] = []
            for dayOffset in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                    let startOfDay = calendar.startOfDay(for: date)
                    let count = submissionMap[startOfDay] ?? 0
                    let isFuture = startOfDay > today
                    weekDays.append(GridDay(date: startOfDay, count: count, isFuture: isFuture))
                }
            }
            allWeeks.append(weekDays)
        }

        return allWeeks
    }

    private func colorForCount(_ count: Int, isFuture: Bool) -> Color {
        if isFuture {
            return Color(red: 0.14, green: 0.15, blue: 0.18).opacity(0.3)
        }
        if count >= 6 {
            return Color(red: 0.24, green: 0.95, blue: 0.48)
        } else if count >= 3 {
            return Color(red: 0.18, green: 0.78, blue: 0.42)
        } else if count >= 1 {
            return Color(red: 0.14, green: 0.58, blue: 0.34)
        } else {
            return Color(red: 0.16, green: 0.17, blue: 0.20)
        }
    }
}

public struct GridDay {
    public let date: Date
    public let count: Int
    public let isFuture: Bool

    public init(date: Date, count: Int, isFuture: Bool) {
        self.date = date
        self.count = count
        self.isFuture = isFuture
    }
}
