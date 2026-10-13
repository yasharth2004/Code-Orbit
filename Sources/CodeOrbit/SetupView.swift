import SwiftUI

struct SetupView: View {
    @ObservedObject var state: AppState

    var body: some View {
        WidgetSelectionView(state: state)
    }
}
