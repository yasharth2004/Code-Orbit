import SwiftUI

struct WidgetSelectionView: View {
    @ObservedObject var state: AppState
    @State private var selectedType: WidgetGraphType = .leetcodeHeatmap
    @State private var usernameInput: String = ""
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.08, blue: 0.10)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose Widget Graph")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Select which graph you would like this desktop widget to display.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(white: 0.55))
                }

                // 3 Options
                VStack(spacing: 9) {
                    WidgetTypeCard(
                        type: .leetcodeHeatmap,
                        isSelected: selectedType == .leetcodeHeatmap,
                        badgeColor: Color(red: 0.16, green: 0.88, blue: 0.45)
                    ) {
                        selectType(.leetcodeHeatmap)
                    }

                    WidgetTypeCard(
                        type: .leetcodeStreak,
                        isSelected: selectedType == .leetcodeStreak,
                        badgeColor: Color(red: 1.0, green: 0.58, blue: 0.12)
                    ) {
                        selectType(.leetcodeStreak)
                    }

                    WidgetTypeCard(
                        type: .githubHeatmap,
                        isSelected: selectedType == .githubHeatmap,
                        badgeColor: Color(red: 0.24, green: 0.88, blue: 0.52)
                    ) {
                        selectType(.githubHeatmap)
                    }
                }

                // Username input
                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedType == .githubHeatmap ? "GITHUB USERNAME" : "LEETCODE USERNAME")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(white: 0.5))

                    TextField("Enter username", text: $usernameInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background(Color.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .focused($isFieldFocused)
                        .onSubmit {
                            confirmSelection()
                        }
                }

                // Action button
                HStack {
                    Text("You can change this graph anytime by right-clicking the widget.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(white: 0.45))

                    Spacer()

                    Button("Display Widget") {
                        confirmSelection()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.16, green: 0.88, blue: 0.45))
                    .disabled(usernameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(22)
        }
        .frame(width: 480, height: 420)
        .onAppear {
            if let current = state.selectedGraphType {
                selectedType = current
            }
            usernameInput = state.username.isEmpty ? selectedType.defaultUsername : state.username
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFieldFocused = true
            }
        }
    }

    private func selectType(_ type: WidgetGraphType) {
        selectedType = type
        if usernameInput.isEmpty || usernameInput == WidgetGraphType.leetcodeHeatmap.defaultUsername || usernameInput == WidgetGraphType.githubHeatmap.defaultUsername {
            usernameInput = type.defaultUsername
        }
    }

    private func confirmSelection() {
        let trimmed = usernameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.applyConfiguration(type: selectedType, username: trimmed)
    }
}

private struct WidgetTypeCard: View {
    let type: WidgetGraphType
    let isSelected: Bool
    let badgeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(badgeColor.opacity(isSelected ? 0.25 : 0.12))
                        .frame(width: 36, height: 36)

                    Image(systemName: type.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(badgeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(type.subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color(white: 0.55))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? badgeColor : Color(white: 0.3))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.white.opacity(0.09) : Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? badgeColor.opacity(0.8) : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
