#!/bin/bash

# Setup App Icon and Splash Screen for S25UltraWallpapers
# This script will copy your image to the correct locations and update configurations

PROJECT_DIR="/Users/Azam/iOS Projects/S25UltraWallpapers/S25UltraWallpapers"
ASSETS_DIR="$PROJECT_DIR/Assets.xcassets"
APP_ICON_DIR="$ASSETS_DIR/AppIcon.appiconset"
LAUNCH_IMAGE_DIR="$ASSETS_DIR/LaunchImage.imageset"

echo "🎨 Setting up App Icon and Splash Screen..."

# Check if image file is provided
if [ -z "$1" ]; then
    echo "❌ Error: Please provide the image file path"
    echo "Usage: ./setup_app_icon.sh <path_to_image.png>"
    exit 1
fi

IMAGE_FILE="$1"

# Check if file exists
if [ ! -f "$IMAGE_FILE" ]; then
    echo "❌ Error: Image file not found: $IMAGE_FILE"
    exit 1
fi

echo "✅ Found image: $IMAGE_FILE"

# Copy to App Icon directory
echo "📱 Setting up App Icon..."
cp "$IMAGE_FILE" "$APP_ICON_DIR/app-icon.png"

# Copy to Launch Image directory
echo "🚀 Setting up Splash Screen..."
cp "$IMAGE_FILE" "$LAUNCH_IMAGE_DIR/launch-icon.png"

echo "✅ Images copied successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Open Xcode"
echo "2. Navigate to Assets.xcassets in the project navigator"
echo "3. Click on AppIcon and verify the icon appears"
echo "4. Click on LaunchImage and verify the splash screen appears"
echo "5. Build and run the app to see your new icon and splash screen!"
echo ""
echo "✨ Done!"
