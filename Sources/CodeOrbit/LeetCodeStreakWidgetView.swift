import SwiftUI
import Combine

#if !WIDGET_EXTENSION
struct LeetCodeStreakWidgetView: View {
    @ObservedObject var state: AppState
    @State private var timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    var body: some View {
        LeetCodeStreakCardView(stats: state.leetCodeStats, isWidget: false)
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

public struct LeetCodeStreakCardView: View {
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
                // Widget dark container
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.11))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: isWidget ? 8 : 18) {
                // Top Header Row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: isWidget ? 2 : 4) {
                        HStack(alignment: .center, spacing: isWidget ? 7 : 9) {
                            // Flame Icon
                            if stats.streak > 0 {
                                // Active orange gradient flame
                                Image(systemName: "flame.fill")
                                    .font(.system(size: isWidget ? 24 : 32, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(red: 1.0, green: 0.68, blue: 0.18), Color(red: 1.0, green: 0.40, blue: 0.05)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            } else {
                                // Hollow flame outline with red exclamation badge (Image 2)
                                ZStack(alignment: .bottomTrailing) {
                                    Image(systemName: "flame")
                                        .font(.system(size: isWidget ? 24 : 32, weight: .medium))
                                        .foregroundStyle(Color(white: 0.65))

                                    ZStack {
                                        Circle()
                                            .fill(Color(red: 0.95, green: 0.22, blue: 0.35))
                                            .frame(width: isWidget ? 11 : 14, height: isWidget ? 11 : 14)
                                        Image(systemName: "exclamationmark")
                                            .font(.system(size: isWidget ? 6.5 : 8, weight: .heavy))
                                            .foregroundStyle(.white)
                                    }
                                    .offset(x: isWidget ? 2 : 3, y: isWidget ? 2 : 3)
                                }
                            }

                            // Streak Count & Days Label
                            HStack(alignment: .firstTextBaseline, spacing: isWidget ? 4 : 5) {
                                Text("\(stats.streak)")
                                    .font(.system(size: isWidget ? 24 : 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(stats.streak > 0 ? Color(red: 1.0, green: 0.62, blue: 0.12) : .white)

                                Text("Days")
                                    .font(.system(size: isWidget ? 15 : 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(stats.streak > 0 ? Color(red: 1.0, green: 0.62, blue: 0.12) : Color(white: 0.6))
                            }
                        }

                        // Subtitle: "Nicely done!" vs "Hurry up!"
                        Text(stats.streak > 0 ? "Nicely done!" : "Hurry up!")
                            .font(.system(size: isWidget ? 11.5 : 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(white: 0.45))
                            .padding(.leading, 2)
                    }

                    Spacer()

                    // Hexagonal monthly badge
                    HexagonBadgeView(isWidget: isWidget)
                }

                Spacer(minLength: 0)

                // Weekday Row (S, M, T, W, T, F, S)
                let days = currentWeekDays()
                VStack(spacing: isWidget ? 5 : 8) {
                    // Day Letters
                    HStack(spacing: 0) {
                        ForEach(days, id: \.date) { day in
                            Text(day.letter)
                                .font(.system(size: isWidget ? 10.5 : 13, weight: .bold, design: .rounded))
                                .foregroundStyle(day.isToday ? Color(red: 0.16, green: 0.88, blue: 0.45) : Color(white: 0.5))
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // Connected Status Capsules / Circles
                    HStack(spacing: 0) {
                        ForEach(Array(days.enumerated()), id: \.element.date) { index, day in
                            WeekDayCell(
                                day: day,
                                connectsLeft: index > 0 && days[index - 1].count > 0 && day.count > 0,
                                connectsRight: index < 6 && days[index + 1].count > 0 && day.count > 0,
                                isWidget: isWidget
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, isWidget ? 4 : 2)
                .padding(.bottom, isWidget ? 2 : 4)
            }
            .padding(.horizontal, isWidget ? 15 : 20)
            .padding(.vertical, isWidget ? 11 : 18)
        }
    }

    private func currentWeekDays() -> [StreakWeekDay] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today) // 1 = Sun, 7 = Sat
        guard let sunday = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else { return [] }

        let letters = ["S", "M", "T", "W", "T", "F", "S"]
        var days: [StreakWeekDay] = []

        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: sunday) {
                let startOfDay = calendar.startOfDay(for: date)
                let count = stats.submissionMap[startOfDay] ?? 0
                let isPast = startOfDay < today
                let isToday = startOfDay == today
                let isFuture = startOfDay > today

                days.append(StreakWeekDay(
                    letter: letters[i],
                    date: startOfDay,
                    isPast: isPast,
                    isToday: isToday,
                    isFuture: isFuture,
                    count: count
                ))
            }
        }

        return days
    }
}



struct StreakWeekDay {
    let letter: String
    let date: Date
    let isPast: Bool
    let isToday: Bool
    let isFuture: Bool
    let count: Int
}

struct WeekDayCell: View {
    let day: StreakWeekDay
    let connectsLeft: Bool
    let connectsRight: Bool
    var isWidget: Bool = false

    var body: some View {
        let cellSize: CGFloat = isWidget ? 26 : 34
        let iconSize: CGFloat = isWidget ? 11 : 15
        let markSize: CGFloat = isWidget ? 11 : 14

        ZStack {
            if day.count > 0 {
                // If isolated single day: perfect round circle (Day 1)
                // If 2 or more days: seamlessly connected elongated capsule segment
                if !connectsLeft && !connectsRight {
                    Circle()
                        .fill(Color(red: 0.16, green: 0.88, blue: 0.45))
                        .frame(width: cellSize, height: cellSize)
                } else {
                    ConnectedStreakSegment(connectsLeft: connectsLeft, connectsRight: connectsRight, cellSize: cellSize)
                        .fill(Color(red: 0.16, green: 0.88, blue: 0.45))
                        .frame(height: cellSize)
                }

                Image(systemName: "checkmark")
                    .font(.system(size: iconSize, weight: .heavy))
                    .foregroundStyle(.white)
            } else if day.isToday {
                // Today pending: dark circle with exclamationmark
                ZStack {
                    Circle()
                        .fill(Color(red: 0.22, green: 0.24, blue: 0.28))
                        .frame(width: cellSize, height: cellSize)

                    Image(systemName: "exclamationmark")
                        .font(.system(size: markSize, weight: .heavy))
                        .foregroundStyle(Color(white: 0.85))
                }
            } else if day.isPast {
                // Missed past day: dashed circle
                Circle()
                    .strokeBorder(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .frame(width: cellSize, height: cellSize)
            } else {
                // Future day: faint dashed circle
                Circle()
                    .strokeBorder(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .frame(width: cellSize, height: cellSize)
            }
        }
        .frame(height: cellSize)
    }
}

struct ConnectedStreakSegment: Shape {
    let connectsLeft: Bool
    let connectsRight: Bool
    let cellSize: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = cellSize / 2
        let midX = rect.midX
        let topY = rect.midY - radius
        let botY = rect.midY + radius
        let midY = rect.midY

        let leftX = connectsLeft ? rect.minX : (midX - radius)
        let rightX = connectsRight ? rect.maxX : (midX + radius)

        if !connectsLeft && connectsRight {
            // Start of streak: round semicircle cap on left, flat extension to right
            path.move(to: CGPoint(x: midX, y: topY))
            path.addLine(to: CGPoint(x: rightX, y: topY))
            path.addLine(to: CGPoint(x: rightX, y: botY))
            path.addLine(to: CGPoint(x: midX, y: botY))
            path.addArc(center: CGPoint(x: midX, y: midY), radius: radius, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
            path.closeSubpath()
        } else if connectsLeft && connectsRight {
            // Middle of streak: flat rectangle from left edge to right edge
            path.addRect(CGRect(x: leftX, y: topY, width: rightX - leftX, height: cellSize))
        } else if connectsLeft && !connectsRight {
            // End of streak: flat extension from left, round semicircle cap on right
            path.move(to: CGPoint(x: leftX, y: topY))
            path.addLine(to: CGPoint(x: midX, y: topY))
            path.addArc(center: CGPoint(x: midX, y: midY), radius: radius, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: leftX, y: botY))
            path.closeSubpath()
        } else {
            // Fallback: isolated circle
            path.addEllipse(in: CGRect(x: midX - radius, y: topY, width: cellSize, height: cellSize))
        }

        return path
    }
}

struct HexagonBadgeView: View {
    var isWidget: Bool = false

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: Date())
    }

    private var monthText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: Date()).uppercased()
    }

    private var badgeImageName: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 1, 2, 3: return "badge_base_jan"
        case 8, 10, 11: return "badge_base_aug"
        case 9: return "badge_base_sep"
        case 12: return "badge_base_dec"
        default: return "badge_base_aug"
        }
    }

    private var loadedImage: NSImage? {
        if let url = Bundle.main.url(forResource: badgeImageName, withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        for b in Bundle.allBundles + Bundle.allFrameworks {
            if let url = b.url(forResource: badgeImageName, withExtension: "png") {
                return NSImage(contentsOf: url)
            }
        }
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: badgeImageName, withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        if let url = Bundle.module.url(forResource: "badge_base_clean", withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        #endif
        return nil
    }

    var body: some View {
        let badgeSize: CGFloat = isWidget ? 60 : 80
        let daySize: CGFloat = isWidget ? 16 : 21
        let monthSize: CGFloat = isWidget ? 8.5 : 10

        ZStack {
            if let nsImage = loadedImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: badgeSize, height: badgeSize)

                // High-resolution metallic 3D typography
                HStack(alignment: .lastTextBaseline, spacing: isWidget ? 2 : 3) {
                    Text(dayNumber)
                        .font(.system(size: daySize, weight: .bold, design: .default))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(white: 0.95), Color(white: 0.75)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.85), radius: 1, x: 0.5, y: 1.5)

                    Text(monthText)
                        .font(.system(size: monthSize, weight: .heavy, design: .default))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(white: 0.90), Color(white: 0.70)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.85), radius: 1, x: 0.5, y: 1.5)
                }
                .offset(y: isWidget ? 1 : 1.5)
            }
        }
        .frame(width: badgeSize, height: badgeSize)
    }
}
