import Foundation

public enum WidgetGraphType: String, CaseIterable, Codable {
    case leetcodeHeatmap = "leetcode_heatmap"
    case leetcodeStreak = "leetcode_streak"
    case githubHeatmap = "github_heatmap"

    public var title: String {
        switch self {
        case .leetcodeHeatmap: return "LeetCode Progress & Heatmap"
        case .leetcodeStreak: return "LeetCode Daily Streak"
        case .githubHeatmap: return "GitHub Activity Heatmap"
        }
    }

    public var subtitle: String {
        switch self {
        case .leetcodeHeatmap: return "Solved count, 3 rings & 6-month heatmap"
        case .leetcodeStreak: return "Flame badge, streak days & weekly checkmarks"
        case .githubHeatmap: return "Pure commit contribution grid"
        }
    }

    public var icon: String {
        switch self {
        case .leetcodeHeatmap: return "circle.hexagongrid.fill"
        case .leetcodeStreak: return "flame.fill"
        case .githubHeatmap: return "square.grid.3x3.fill"
        }
    }

    public var defaultUsername: String {
        switch self {
        case .leetcodeHeatmap, .leetcodeStreak: return "yasharth1509"
        case .githubHeatmap: return "yasharth2004"
        }
    }
}

public enum PlatformKind: String, CaseIterable, Codable {
    case overview
    case github
    case leetcode

    public var label: String {
        switch self {
        case .overview: return "Overview"
        case .github: return "GitHub"
        case .leetcode: return "LeetCode"
        }
    }
}

public struct DailyActivity: Identifiable, Codable, Hashable {
    public let date: Date
    public let count: Int
    public let metric: String
    public let platform: PlatformKind
    public let isKnown: Bool

    public var id: String {
        "\(platform.rawValue)-\(date.timeIntervalSince1970)"
    }

    public init(date: Date, count: Int, metric: String, platform: PlatformKind, isKnown: Bool = true) {
        self.date = date
        self.count = max(0, count)
        self.metric = metric
        self.platform = platform
        self.isKnown = isKnown
    }
}

public struct HeatmapCell: Identifiable, Hashable {
    public let date: Date
    public let count: Int
    public let intensity: Int
    public let isKnown: Bool

    public var id: String {
        "\(date.timeIntervalSince1970)"
    }
}

public struct StreakSummary: Hashable {
    public let current: Int
    public let longest: Int
    public let activeDates: [Date]
    public let lastUpdated: Date?
}
