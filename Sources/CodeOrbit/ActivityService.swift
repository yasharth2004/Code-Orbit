import Foundation

public struct LeetCodeStats: Sendable {
    public let totalSolved: Int
    public let totalQuestions: Int
    public let easySolved: Int
    public let easyTotal: Int
    public let mediumSolved: Int
    public let mediumTotal: Int
    public let hardSolved: Int
    public let hardTotal: Int
    public let submissionMap: [Date: Int]
    public let streak: Int
    public let totalActiveDays: Int

    public static var placeholder: LeetCodeStats {
        LeetCodeStats(
            totalSolved: 0,
            totalQuestions: 4082,
            easySolved: 0,
            easyTotal: 971,
            mediumSolved: 0,
            mediumTotal: 2128,
            hardSolved: 0,
            hardTotal: 983,
            submissionMap: [:],
            streak: 0,
            totalActiveDays: 0
        )
    }
}

public final class ActivityService: Sendable {
    public static let shared = ActivityService()
    private init() {}

    public func fetchLeetCodeStats(username: String) async throws -> LeetCodeStats {
        let cleanUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUser.isEmpty else {
            throw ActivityError.invalidUsername
        }

        guard let url = URL(string: "https://leetcode.com/graphql") else {
            throw ActivityError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://leetcode.com", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")

        let query = """
        query userLeetCodeData($username: String!) {
          allQuestionsCount {
            difficulty
            count
          }
          matchedUser(username: $username) {
            submitStats: submitStatsGlobal {
              acSubmissionNum {
                difficulty
                count
              }
            }
            userCalendar {
              streak
              totalActiveDays
              submissionCalendar
            }
          }
        }
        """

        let payload: [String: Any] = [
            "query": query,
            "variables": ["username": cleanUser]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ActivityError.networkError("LeetCode service unavailable")
        }

        struct ResponseData: Decodable {
            struct DifficultyCount: Decodable {
                let difficulty: String
                let count: Int
            }
            struct MatchedUser: Decodable {
                struct SubmitStats: Decodable {
                    let acSubmissionNum: [DifficultyCount]
                }
                struct CalendarData: Decodable {
                    let streak: Int?
                    let totalActiveDays: Int?
                    let submissionCalendar: String?
                }
                let submitStats: SubmitStats?
                let userCalendar: CalendarData?
            }
            struct Container: Decodable {
                let allQuestionsCount: [DifficultyCount]?
                let matchedUser: MatchedUser?
            }
            let data: Container?
        }

        let decoded = try JSONDecoder().decode(ResponseData.self, from: data)

        guard let matchedUser = decoded.data?.matchedUser else {
            throw ActivityError.userNotFound("LeetCode user \"\(cleanUser)\" not found.")
        }

        var allQuestions: [String: Int] = [:]
        for item in decoded.data?.allQuestionsCount ?? [] {
            allQuestions[item.difficulty] = item.count
        }

        var acStats: [String: Int] = [:]
        for item in matchedUser.submitStats?.acSubmissionNum ?? [] {
            acStats[item.difficulty] = item.count
        }

        let totalQuestions = allQuestions["All"] ?? 4082
        let easyTotal = allQuestions["Easy"] ?? 971
        let mediumTotal = allQuestions["Medium"] ?? 2128
        let hardTotal = allQuestions["Hard"] ?? 983

        let totalSolved = acStats["All"] ?? 0
        let easySolved = acStats["Easy"] ?? 0
        let mediumSolved = acStats["Medium"] ?? 0
        let hardSolved = acStats["Hard"] ?? 0

        let totalActiveDays = matchedUser.userCalendar?.totalActiveDays ?? 0

        var submissionMap: [Date: Int] = [:]
        var utcSubmissionMap: [Date: Int] = [:]

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let localCalendar = Calendar.current

        if let calStr = matchedUser.userCalendar?.submissionCalendar,
           let calData = calStr.data(using: .utf8),
           let jsonMap = try? JSONSerialization.jsonObject(with: calData) as? [String: Int] {
            for (tsStr, count) in jsonMap {
                if let ts = TimeInterval(tsStr) {
                    let date = Date(timeIntervalSince1970: ts)
                    let localDay = localCalendar.startOfDay(for: date)
                    let utcDay = utcCalendar.startOfDay(for: date)
                    submissionMap[localDay, default: 0] += count
                    utcSubmissionMap[utcDay, default: 0] += count
                }
            }
        }

        let currentStreak = Self.computeCurrentStreak(submissionMap: submissionMap, utcSubmissionMap: utcSubmissionMap)

        return LeetCodeStats(
            totalSolved: totalSolved,
            totalQuestions: totalQuestions,
            easySolved: easySolved,
            easyTotal: easyTotal,
            mediumSolved: mediumSolved,
            mediumTotal: mediumTotal,
            hardSolved: hardSolved,
            hardTotal: hardTotal,
            submissionMap: submissionMap,
            streak: currentStreak,
            totalActiveDays: totalActiveDays
        )
    }

    public static func computeCurrentStreak(submissionMap: [Date: Int], utcSubmissionMap: [Date: Int]) -> Int {
        let localStreak = streakFromMap(submissionMap, calendar: .current)
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let utcStreak = streakFromMap(utcSubmissionMap, calendar: utcCal)
        return max(localStreak, utcStreak)
    }

    private static func streakFromMap(_ map: [Date: Int], calendar: Calendar) -> Int {
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        let hasToday = (map[today] ?? 0) > 0
        let hasYesterday = (map[yesterday] ?? 0) > 0

        if hasToday {
            var streak = 0
            var cursor = today
            while (map[cursor] ?? 0) > 0 {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
                cursor = prev
            }
            return streak
        } else if hasYesterday {
            var streak = 0
            var cursor = yesterday
            while (map[cursor] ?? 0) > 0 {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
                cursor = prev
            }
            return streak
        } else {
            return 0
        }
    }

    public func fetchGitHub(username: String) async throws -> [DailyActivity] {
        let cleanUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUser.isEmpty else {
            throw ActivityError.invalidUsername
        }

        guard let url = URL(string: "https://github-contributions-api.jogruber.de/v4/\(cleanUser)?y=last") else {
            throw ActivityError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("CodeOrbit-macOS/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ActivityError.networkError("Invalid server response")
        }

        if httpResponse.statusCode == 404 {
            throw ActivityError.userNotFound("GitHub user \"\(cleanUser)\" not found.")
        }

        struct Response: Decodable {
            struct Contribution: Decodable {
                let date: String
                let count: Int
                let level: Int?
            }
            let contributions: [Contribution]?
            let error: String?
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)

        if let error = decoded.error {
            throw ActivityError.userNotFound(error)
        }

        guard let contributions = decoded.contributions, !contributions.isEmpty else {
            throw ActivityError.noData
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        var activities: [DailyActivity] = []
        for item in contributions {
            if let date = dateFormatter.date(from: item.date) {
                activities.append(DailyActivity(
                    date: date,
                    count: item.count,
                    metric: "contributions",
                    platform: .github
                ))
            }
        }

        return activities.sorted(by: { $0.date < $1.date })
    }
}

public enum ActivityError: LocalizedError {
    case invalidUsername
    case invalidURL
    case userNotFound(String)
    case networkError(String)
    case noData

    public var errorDescription: String? {
        switch self {
        case .invalidUsername: return "Please enter a valid username."
        case .invalidURL: return "Invalid service URL."
        case .userNotFound(let message): return message
        case .networkError(let message): return message
        case .noData: return "No activity found for this user."
        }
    }
}
