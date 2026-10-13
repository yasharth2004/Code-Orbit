import SwiftUI

struct DashboardView: View {
    @ObservedObject var state: AppState

    var body: some View {
        LeetCodeWidgetView(state: state)
    }
}
