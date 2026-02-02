#!/bin/bash
# Build WindowSwitcher.app with proper icon

set -e

cd "$(dirname "$0")/.."

echo "Building WindowSwitcher..."
swift build -c release

echo "Creating app bundle..."
rm -rf WindowSwitcher.app
mkdir -p WindowSwitcher.app/Contents/MacOS
mkdir -p WindowSwitcher.app/Contents/Resources

# Copy executable
cp .build/release/WindowSwitcher WindowSwitcher.app/Contents/MacOS/

# Copy Info.plist
cp Resources/Info.plist WindowSwitcher.app/Contents/

# Create .icns from PNGs
mkdir -p AppIcon.iconset
cp assets/icon-16.png AppIcon.iconset/icon_16x16.png
cp assets/icon-32.png AppIcon.iconset/icon_16x16@2x.png
cp assets/icon-32.png AppIcon.iconset/icon_32x32.png
cp assets/icon-64.png AppIcon.iconset/icon_32x32@2x.png
cp assets/icon-128.png AppIcon.iconset/icon_128x128.png
cp assets/icon-256.png AppIcon.iconset/icon_128x128@2x.png
cp assets/icon-256.png AppIcon.iconset/icon_256x256.png
cp assets/icon-512.png AppIcon.iconset/icon_256x256@2x.png
cp assets/icon-512.png AppIcon.iconset/icon_512x512.png
cp assets/icon-1024.png AppIcon.iconset/icon_512x512@2x.png

iconutil -c icns AppIcon.iconset -o WindowSwitcher.app/Contents/Resources/AppIcon.icns
rm -rf AppIcon.iconset

# Sign the app with a stable identifier (required for Accessibility permission to persist)
echo "Signing app bundle..."
codesign --force --sign - --identifier "com.brandonstanford.windowswitcher" WindowSwitcher.app

echo "Done! WindowSwitcher.app created"
echo "To install: cp -r WindowSwitcher.app /Applications/"
