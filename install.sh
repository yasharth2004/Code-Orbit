#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "⚙️  Generating Xcode project..."
xcodegen generate

echo "🔨 Building CodeOrbit & WidgetKit extension..."
xcodebuild -project CodeOrbit.xcodeproj -scheme CodeOrbit -configuration Debug build

DERIVED_APP=$(find ~/Library/Developer/Xcode/DerivedData/CodeOrbit-* -name "CodeOrbit.app" -type d | head -n 1)

if [ -z "$DERIVED_APP" ]; then
    echo "❌ Error: Could not find built CodeOrbit.app"
    exit 1
fi

echo "📦 Installing to ~/Applications/CodeOrbit.app..."
mkdir -p ~/Applications
rm -rf ~/Applications/CodeOrbit.app
cp -R "$DERIVED_APP" ~/Applications/CodeOrbit.app

echo "🔄 Registering with macOS LaunchServices and PlugInKit..."
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R -trusted ~/Applications/CodeOrbit.app
pluginkit -a ~/Applications/CodeOrbit.app/Contents/PlugIns/CodeOrbitWidgets.appex 2>/dev/null || true

echo "🔄 Restarting NotificationCenter and widget daemons..."
killall NotificationCenter 2>/dev/null || true
killall chronod 2>/dev/null || true

echo "✅ CodeOrbit successfully installed to ~/Applications/CodeOrbit.app!"
