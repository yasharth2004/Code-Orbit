import Foundation

public enum HeatmapIntensity {
    public static func level(for count: Int) -> Int {
        switch count {
        case 0: return 0
        case 1: return 1
        case 2...3: return 2
        case 4...7: return 3
        default: return 4
        }
    }
}

public enum StreakCalculator {
    public static func calculate(from activities: [DailyActivity], calendar: Calendar = .current) -> StreakSummary {
        let valuesByDay = activities
            .filter { $0.isKnown }
            .reduce(into: [Date: Int]()) { result, activity in
                let day = calendar.startOfDay(for: activity.date)
                result[day, default: 0] += activity.count
            }

        let activeDates = valuesByDay
            .filter { $0.value > 0 }
            .keys
            .sorted()

        guard !activeDates.isEmpty else {
            return StreakSummary(current: 0, longest: 0, activeDates: [], lastUpdated: Date())
        }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        let currentStreak: Int = {
            if activeDates.contains(today) {
                var cursor = today
                var streak = 0
                while activeDates.contains(cursor) {
                    streak += 1
                    guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
                    cursor = previous
                }
                return streak
            }

            if activeDates.contains(yesterday) {
                var cursor = yesterday
                var streak = 0
                while activeDates.contains(cursor) {
                    streak += 1
                    guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
                    cursor = previous
                }
                return streak
            }

            return 0
        }()

        var longestStreak = 1
        var currentRun = 1
        var previousDate: Date?

        for date in activeDates {
            if let previous = previousDate {
                let diff = calendar.dateComponents([.day], from: previous, to: date).day ?? 0
                if diff == 1 {
                    currentRun += 1
                    longestStreak = max(longestStreak, currentRun)
                } else {
                    currentRun = 1
                }
            }
            previousDate = date
        }

        return StreakSummary(current: currentStreak, longest: longestStreak, activeDates: activeDates, lastUpdated: Date())
    }
}

public enum HeatmapCalculator {
    public static func grid(from activities: [DailyActivity], calendar: Calendar = .current, months: Int = 5) -> [HeatmapCell] {
        let endDate = calendar.startOfDay(for: Date())
        let rawStartDate = calendar.date(byAdding: .day, value: -(months * 35), to: endDate) ?? endDate
        let weekday = calendar.component(.weekday, from: rawStartDate)
        let daysFromFirstWeekday = (weekday - calendar.firstWeekday + 7) % 7
        let startDate = calendar.date(byAdding: .day, value: -daysFromFirstWeekday, to: rawStartDate) ?? rawStartDate
        let dayCount = max(1, (calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1)

        let valuesByDay = activities.reduce(into: [Date: (count: Int, isKnown: Bool)]()) { result, activity in
            let day = calendar.startOfDay(for: activity.date)
            let existing = result[day] ?? (count: 0, isKnown: true)
            result[day] = (
                count: existing.count + activity.count,
                isKnown: existing.isKnown && activity.isKnown
            )
        }

        var cells: [HeatmapCell] = []
        for offset in 0..<dayCount {
            let date = calendar.date(byAdding: .day, value: offset, to: startDate) ?? endDate
            let startOfDay = calendar.startOfDay(for: date)
            let activity = valuesByDay[startOfDay]
            let count = activity?.count ?? 0
            let isKnown = activity?.isKnown ?? true
            cells.append(HeatmapCell(date: startOfDay, count: count, intensity: HeatmapIntensity.level(for: count), isKnown: isKnown))
        }
        return cells
    }
}
