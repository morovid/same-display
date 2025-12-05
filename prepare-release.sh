#!/bin/bash
#
# Prepare a distributable DMG for SameDisplay
#
# Usage:
#   ./prepare-release.sh           # Uses Release build by default
#   ./prepare-release.sh Debug    # Use Debug build instead

set -e

BUILD_CONFIG="${1:-Release}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DERIVED_DATA_DIR="$PROJECT_DIR/build"
APP_PATH="$DERIVED_DATA_DIR/Build/Products/$BUILD_CONFIG/SameDisplay.app"
DIST_DIR="$PROJECT_DIR/dist"
DMG_ROOT="$DIST_DIR/dmg_root"
DMG_PATH="$DIST_DIR/SameDisplay.dmg"

echo "Preparing DMG from build configuration: $BUILD_CONFIG"
echo "Looking for app bundle at: $APP_PATH"

if [ ! -d "$APP_PATH" ]; then
  echo "❌ Application bundle not found at:"
  echo "   $APP_PATH"
  echo ""
  echo "Make sure you have built the app first, e.g.:"
  echo "  ./build.sh $BUILD_CONFIG"
  exit 1
fi

# Ensure dist directory exists and recreate dmg_root staging folder
mkdir -p "$DIST_DIR"
rm -rf "$DMG_ROOT"
mkdir -p "$DMG_ROOT"

echo "📦 Copying app bundle to DMG staging directory..."
cp -R "$APP_PATH" "$DMG_ROOT/SameDisplay.app"

echo "🔗 Creating Applications symlink..."
ln -s /Applications "$DMG_ROOT/Applications"

echo "💿 Creating DMG at: $DMG_PATH"
hdiutil create \
  -volname "SameDisplay" \
  -srcfolder "$DMG_ROOT" \
  -ov -format UDZO \
  "$DMG_PATH"

# Clean up staging folder
echo "🧹 Cleaning up staging folder..."
rm -rf "$DMG_ROOT"

echo ""
echo "✅ DMG created successfully:"
echo "   $DMG_PATH"