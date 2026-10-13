import XCTest
@testable import CodeOrbit

final class StreakAndHeatmapTests: XCTestCase {
    func testCurrentStreakCountsTodayAndYesterday() {
        let calendar = Calendar(identifier: .gregorian)
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        let activity = [
            DailyActivity(date: yesterday, count: 3, metric: "accepted submissions", platform: .leetcode),
            DailyActivity(date: today, count: 2, metric: "accepted submissions", platform: .leetcode),
            DailyActivity(date: twoDaysAgo, count: 1, metric: "accepted submissions", platform: .leetcode)
        ]

        let result = StreakCalculator.calculate(from: activity, calendar: calendar)
        XCTAssertEqual(result.current, 3)
        XCTAssertEqual(result.longest, 3)
    }

    func testStreakBreaksWhenGapExists() {
        let calendar = Calendar(identifier: .gregorian)
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: today)!

        let activity = [
            DailyActivity(date: fourDaysAgo, count: 2, metric: "accepted submissions", platform: .leetcode),
            DailyActivity(date: threeDaysAgo, count: 4, metric: "accepted submissions", platform: .leetcode),
            DailyActivity(date: yesterday, count: 1, metric: "accepted submissions", platform: .leetcode)
        ]

        let result = StreakCalculator.calculate(from: activity, calendar: calendar)
        XCTAssertEqual(result.current, 1)
        XCTAssertEqual(result.longest, 2)
    }

    func testHeatmapBuildsExpectedGridStructure() {
        let calendar = Calendar(identifier: .gregorian)
        let today = Date()
        let start = calendar.date(byAdding: .day, value: -45, to: today)!

        let activity = (0..<20).compactMap { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: start)
            return DailyActivity(date: date!, count: offset % 4 == 0 ? 2 : 0, metric: "contributions", platform: .github)
        }

        let grid = HeatmapCalculator.grid(from: activity, calendar: calendar, months: 3)
        XCTAssertGreaterThanOrEqual(grid.count, 7)
        XCTAssertTrue(grid.allSatisfy { $0.count >= 0 })
    }
}
