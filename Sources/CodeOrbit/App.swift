import SwiftUI
import AppKit
import WidgetKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        WidgetCenter.shared.reloadAllTimelines()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            configureWindow(window)
        }
    }

    func configureWindow(_ window: NSWindow) {
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        window.makeKeyAndOrderFront(nil)
    }
}

@main
struct CodeOrbitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var state = AppState()

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            WidgetContainerView(state: state)
                .background(Color.clear)
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                    for window in NSApp.windows {
                        window.titleVisibility = .hidden
                        window.titlebarAppearsTransparent = true
                        window.isOpaque = false
                        window.backgroundColor = .clear
                        window.styleMask.insert(.fullSizeContentView)
                        window.isMovableByWindowBackground = true
                        window.makeKeyAndOrderFront(nil)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

struct WidgetContainerView: View {
    @ObservedObject var state: AppState

    var body: some View {
        Group {
            if let type = state.selectedGraphType {
                widgetContent(for: type)
                    .contextMenu {
                        Button("Change Graph Style") {
                            state.openChooser()
                        }
                        Button("Refresh Now") {
                            state.refreshCurrentWidget()
                        }
                    }
            } else {
                WidgetSelectionView(state: state)
            }
        }
    }

    @ViewBuilder
    private func widgetContent(for type: WidgetGraphType) -> some View {
        switch type {
        case .leetcodeHeatmap:
            LeetCodeWidgetView(state: state)
        case .leetcodeStreak:
            LeetCodeStreakWidgetView(state: state)
        case .githubHeatmap:
            GitHubHeatmapWidgetView(state: state)
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var selectedGraphType: WidgetGraphType? = nil
    @Published var username: String = ""
    @Published var leetCodeStats: LeetCodeStats = .placeholder
    @Published var gitHubSubmissionMap: [Date: Int] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    init() {
        // Read saved choice
        if let savedTypeRaw = UserDefaults.standard.string(forKey: "selectedWidgetType"),
           let savedType = WidgetGraphType(rawValue: savedTypeRaw) {
            let savedUser = UserDefaults.standard.string(forKey: "widgetUsername") ?? savedType.defaultUsername
            self.selectedGraphType = savedType
            self.username = savedUser
            refreshCurrentWidget()
        } else {
            // First time launching: asks user what type of graph to display
            self.selectedGraphType = nil
            self.username = "yasharth1509"
        }
    }

    func applyConfiguration(type: WidgetGraphType, username: String) {
        let cleanUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        self.selectedGraphType = type
        self.username = cleanUser
        UserDefaults.standard.set(type.rawValue, forKey: "selectedWidgetType")
        UserDefaults.standard.set(cleanUser, forKey: "widgetUsername")
        refreshCurrentWidget()
    }

    func openChooser() {
        selectedGraphType = nil
    }

    func refreshCurrentWidget() {
        guard let type = selectedGraphType else { return }
        switch type {
        case .leetcodeHeatmap, .leetcodeStreak:
            refreshLeetCodeStats()
        case .githubHeatmap:
            refreshGitHubActivity()
        }
    }

    func refreshLeetCodeStats() {
        guard !username.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        let userToFetch = username
        Task {
            do {
                let stats = try await ActivityService.shared.fetchLeetCodeStats(username: userToFetch)
                self.leetCodeStats = stats
                self.isLoading = false
                self.errorMessage = nil
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func refreshGitHubActivity() {
        guard !username.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        let userToFetch = username
        Task {
            do {
                let activities = try await ActivityService.shared.fetchGitHub(username: userToFetch)
                let calendar = Calendar.current
                var map: [Date: Int] = [:]
                for act in activities {
                    let day = calendar.startOfDay(for: act.date)
                    map[day, default: 0] += act.count
                }
                self.gitHubSubmissionMap = map
                self.isLoading = false
                self.errorMessage = nil
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
