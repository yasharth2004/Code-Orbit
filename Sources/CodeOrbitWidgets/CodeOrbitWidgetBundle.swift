import WidgetKit
import SwiftUI

@main
struct CodeOrbitWidgetBundle: WidgetBundle {
    var body: some Widget {
        LeetCodeStreakWidget()
        LeetCodeProgressWidget()
        GitHubHeatmapWidget()
    }
}
