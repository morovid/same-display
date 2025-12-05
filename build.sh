#!/bin/bash
#
# Build script for SameDisplay
#
# Usage:
#   ./build.sh          # Build debug version
#   ./build.sh release  # Build release version
#

set -e

BUILD_CONFIG="${1:-Debug}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_FILE="SameDisplay.xcodeproj"
SCHEME="SameDisplay"
# Where xcodebuild will put DerivedData (and thus the .app)
DERIVED_DATA_DIR="$PROJECT_DIR/build"

echo "Building SameDisplay ($BUILD_CONFIG)..."

cd "$PROJECT_DIR"

# Build the project into our local ./build directory
xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -configuration "$BUILD_CONFIG" \
    -derivedDataPath "$DERIVED_DATA_DIR" \
    clean build

APP_PATH="$DERIVED_DATA_DIR/Build/Products/$BUILD_CONFIG/SameDisplay.app"

if [ -d "$APP_PATH" ]; then
    echo ""
    echo "✅ Build successful!"
    echo "📦 Application bundle: $APP_PATH"
    echo ""
    echo "To run the app:"
    echo "  open \"$APP_PATH\""
else
    echo "❌ Build failed - application bundle not found"
    exit 1
fi

