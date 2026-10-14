# CodeOrbit 🪐

**CodeOrbit** is a native macOS developer companion and WidgetKit suite designed to keep your coding momentum front and center on your desktop and Notification Center. It delivers pixel-perfect, authentic widgets for **LeetCode Daily Streaks**, **LeetCode Progress & Heatmap**, and **GitHub Activity**.

---

## 📸 Widgets Included

CodeOrbit installs directly into macOS's native Widget Gallery with three dedicated widgets:

### 1. ⚡️ LeetCode Daily Streak
- **Active Flame & Streak Count**: Dynamic flame with gradient glow for active streaks and a reminder state for pending days.
- **Authentic Weekly Tracker**:
  - **Single Day Streak**: Renders as a crisp green circular pill with a white checkmark.
  - **Consecutive Multi-Day Streaks**: Seamlessly connects adjacent days into an elongated rounded capsule across the week.
  - **Present Day Indicator**: Highlights the current day with an exclamation mark (`!`) until submitted.
- **3D Metallic Monthly Badge**: Rendered with authentic metallic typography displaying the current day and month.
- **Configurable**: Right-click to set your custom LeetCode username.

### 2. 📊 LeetCode Progress & Heatmap
- **Solved Counter**: Displays total solved problems out of the total problem database.
- **Concentric Category Rings**:
  - 🟢 **Easy** (Green ring)
  - 🟡 **Medium** (Yellow ring)
  - 🔴 **Hard** (Red ring)
- **6-Month Heatmap**: Visual breakdown of your problem-solving frequency over the last half-year with monthly column markers.
- **Configurable**: Right-click to set your custom LeetCode username.

### 3. 🟩 GitHub Activity Heatmap
- **Full Contribution Grid**: Authentic 21-week contribution matrix rendered to fit macOS medium widget dimensions.
- **GitHub Dark Palette**: Dynamically colored cells based on commit density and contribution counts.
- **Configurable**: Right-click to set your custom GitHub username.

---

## 🖥️ Desktop Companion App

In addition to macOS widgets, CodeOrbit includes a standalone floating desktop dashboard:
- Live graph previews and interactive switcher.
- Auto-fetches live data directly from official LeetCode and GitHub endpoints.
- Auto-refreshes every **5 minutes** in the app and immediately whenever brought to focus.

---

## ⏱️ Refresh Rates

| Target | Refresh Interval | Trigger Events |
| :--- | :--- | :--- |
| **macOS Widgets** | Every **15 minutes** | WidgetKit timeline policy, widget configuration change, or app launch |
| **Desktop App** | Every **5 minutes** | Timer auto-refresh, window focus, or app activation |

---

## 🛠️ Prerequisites

- **macOS**: macOS 14.0 (Sonoma) or macOS 15.0 (Sequoia)
- **Xcode**: Full Xcode installation (Xcode 15 or 16) in `/Applications/Xcode.app`
- **XcodeGen**: Project generator (`brew install xcodegen`)

---

## 🚀 Installation

Run the included automated installer script from the project root:

```bash
cd "/Users/yasharthkesarwani/Downloads/Macbook Widget"
./install.sh
```

### What `install.sh` does:
1. Generates the Xcode project (`CodeOrbit.xcodeproj`) with all entitlements and AppIntents metadata bindings via XcodeGen.
2. Compiles both the macOS App (`CodeOrbit`) and WidgetKit Extension (`CodeOrbitWidgets.appex`) with local code signing.
3. Installs `CodeOrbit.app` directly into `~/Applications/CodeOrbit.app`.
4. Registers the app and widget plugin with macOS LaunchServices and PlugInKit.
5. Flushes `NotificationCenter` and `chronod` (macOS widget daemon) so new widgets appear immediately in the gallery.

---

## 🪄 How to Add Widgets to Your Desktop

1. Right-click on an empty area of your macOS Desktop (or open **Notification Center**).
2. Click **Edit Widgets...** to open the macOS widget picker.
3. Search for or select **CodeOrbit** in the left sidebar.
4. Drag your preferred widget (**LeetCode Daily Streak**, **LeetCode Progress & Heatmap**, or **GitHub Activity Heatmap**) onto your desktop.
5. **To change the username**: Right-click on the placed widget, select **Edit "CodeOrbit..."**, type your username, and click **Done**.

---

## 🏗️ Architecture & Project Structure

```
Macbook Widget/
├── Sources/
│   ├── CodeOrbit/                      # Host macOS Application
│   │   ├── App.swift                   # Main SwiftUI App entry & timeline reload
│   │   ├── ActivityService.swift       # Live async network fetching (LeetCode / GitHub)
│   │   ├── Models.swift                # Normalized activity and stats models
│   │   ├── LeetCodeStreakWidgetView.swift # LeetCode Streak UI & ConnectedStreakSegment
│   │   ├── LeetCodeWidgetView.swift    # Concentric rings & 6-month heatmap
│   │   ├── GitHubHeatmapWidgetView.swift  # 21-week GitHub commit grid
│   │   ├── DashboardView.swift         # Floating desktop companion dashboard
│   │   ├── WidgetSelectionView.swift   # Desktop app widget picker
│   │   └── Resources/                  # Metallic badge assets & artwork
│   │
│   └── CodeOrbitWidgets/               # WidgetKit Extension
│       ├── CodeOrbitWidgetBundle.swift # @main WidgetBundle registration
│       ├── CodeOrbitWidget.swift       # Widget timeline providers & dedicated entries
│       └── WidgetIntents.swift         # AppIntents for per-widget username configuration
│
├── project.yml                         # XcodeGen specification for multi-target build
├── Package.swift                       # Swift Package Manager manifest
├── install.sh                          # Automated build, install & daemon refresh script
└── README.md                           # Documentation
```

---

## 🧪 Testing and CLI Building

To verify code syntax or test changes without installing to macOS:

```bash
# Build with Swift Package Manager
swift build

# Run the desktop app standalone via SPM
swift run CodeOrbit
```

---

## 📄 License

CodeOrbit is released under the [MIT License](LICENSE).

Copyright (c) 2026 Yasharth Kesarwani.
