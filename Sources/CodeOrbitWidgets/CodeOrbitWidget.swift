import WidgetKit
import SwiftUI
import AppIntents

// MARK: - 1. Dedicated LeetCode Streak Widget

// MARK: - 2. Dedicated LeetCode Streak Widget

struct DedicatedStreakEntry: TimelineEntry {
    let date: Date
    let stats: LeetCodeStats
    let isPreview: Bool
}

struct DedicatedStreakTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = DedicatedStreakEntry
    typealias Intent = ConfigureUsernameIntent

    func placeholder(in context: Context) -> DedicatedStreakEntry {
        DedicatedStreakEntry(date: Date(), stats: .placeholder, isPreview: true)
    }

    func snapshot(for configuration: ConfigureUsernameIntent, in context: Context) async -> DedicatedStreakEntry {
        let stats = await fetchStats(username: configuration.username ?? "")
        return DedicatedStreakEntry(date: Date(), stats: stats, isPreview: context.isPreview)
    }

    func timeline(for configuration: ConfigureUsernameIntent, in context: Context) async -> Timeline<DedicatedStreakEntry> {
        let stats = await fetchStats(username: configuration.username ?? "")
        let entry = DedicatedStreakEntry(date: Date(), stats: stats, isPreview: false)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchStats(username: String) async -> LeetCodeStats {
        let clean = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let user = clean.isEmpty ? "yasharth1509" : clean
        return (try? await ActivityService.shared.fetchLeetCodeStats(username: user)) ?? .placeholder
    }
}

struct LeetCodeStreakWidget: Widget {
    let kind: String = "LeetCodeStreakWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigureUsernameIntent.self,
            provider: DedicatedStreakTimelineProvider()
        ) { entry in
            LeetCodeStreakCardView(stats: entry.stats, isWidget: true)
                .containerBackground(for: .widget) {
                    Color(red: 0.08, green: 0.09, blue: 0.11)
                }
        }
        .configurationDisplayName("LeetCode Daily Streak")
        .description("Track your flame, streak days, weekly tracker pills, and 3D monthly badge.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - 3. Dedicated LeetCode Progress Widget

struct DedicatedProgressEntry: TimelineEntry {
    let date: Date
    let stats: LeetCodeStats
    let isPreview: Bool
}

struct DedicatedProgressTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = DedicatedProgressEntry
    typealias Intent = ConfigureUsernameIntent

    func placeholder(in context: Context) -> DedicatedProgressEntry {
        DedicatedProgressEntry(date: Date(), stats: .placeholder, isPreview: true)
    }

    func snapshot(for configuration: ConfigureUsernameIntent, in context: Context) async -> DedicatedProgressEntry {
        let stats = await fetchStats(username: configuration.username ?? "")
        return DedicatedProgressEntry(date: Date(), stats: stats, isPreview: context.isPreview)
    }

    func timeline(for configuration: ConfigureUsernameIntent, in context: Context) async -> Timeline<DedicatedProgressEntry> {
        let stats = await fetchStats(username: configuration.username ?? "")
        let entry = DedicatedProgressEntry(date: Date(), stats: stats, isPreview: false)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchStats(username: String) async -> LeetCodeStats {
        let clean = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let user = clean.isEmpty ? "yasharth1509" : clean
        return (try? await ActivityService.shared.fetchLeetCodeStats(username: user)) ?? .placeholder
    }
}

struct LeetCodeProgressWidget: Widget {
    let kind: String = "LeetCodeProgressWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigureUsernameIntent.self,
            provider: DedicatedProgressTimelineProvider()
        ) { entry in
            LeetCodeProgressCardView(stats: entry.stats, isWidget: true)
                .containerBackground(for: .widget) {
                    Color(red: 0.08, green: 0.09, blue: 0.11)
                }
        }
        .configurationDisplayName("LeetCode Progress & Heatmap")
        .description("Total solved problems, 3 concentric rings, and 6-month calendar heatmap.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - 4. Dedicated GitHub Heatmap Widget

struct DedicatedGitHubEntry: TimelineEntry {
    let date: Date
    let submissions: [Date: Int]
    let isPreview: Bool
}

struct DedicatedGitHubTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = DedicatedGitHubEntry
    typealias Intent = ConfigureUsernameIntent

    func placeholder(in context: Context) -> DedicatedGitHubEntry {
        DedicatedGitHubEntry(date: Date(), submissions: [:], isPreview: true)
    }

    func snapshot(for configuration: ConfigureUsernameIntent, in context: Context) async -> DedicatedGitHubEntry {
        let map = await fetchSubmissions(username: configuration.username ?? "")
        return DedicatedGitHubEntry(date: Date(), submissions: map, isPreview: context.isPreview)
    }

    func timeline(for configuration: ConfigureUsernameIntent, in context: Context) async -> Timeline<DedicatedGitHubEntry> {
        let map = await fetchSubmissions(username: configuration.username ?? "")
        let entry = DedicatedGitHubEntry(date: Date(), submissions: map, isPreview: false)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchSubmissions(username: String) async -> [Date: Int] {
        let clean = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let user = clean.isEmpty ? "yasharth2004" : clean
        guard let activities = try? await ActivityService.shared.fetchGitHub(username: user) else { return [:] }
        let calendar = Calendar.current
        var map: [Date: Int] = [:]
        for act in activities {
            let start = calendar.startOfDay(for: act.date)
            map[start, default: 0] += act.count
        }
        return map
    }
}

struct GitHubHeatmapWidget: Widget {
    let kind: String = "GitHubHeatmapWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigureUsernameIntent.self,
            provider: DedicatedGitHubTimelineProvider()
        ) { entry in
            GitHubHeatmapCardView(submissionMap: entry.submissions, isWidget: true)
                .containerBackground(for: .widget) {
                    Color(red: 0.08, green: 0.09, blue: 0.11)
                }
        }
        .configurationDisplayName("GitHub Activity Heatmap")
        .description("Track your GitHub contributions in a clean, full-width activity grid.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}
