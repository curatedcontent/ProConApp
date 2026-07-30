#!/bin/bash
# ProCon App - Weekly Rebuild Script
# Run this every 7 days to keep the app working on your device when disconnected

echo "🔄 Rebuilding ProCon App for iPhone..."
echo "📱 Make sure your iPhone is connected via cable"
echo ""

# Get device ID
DEVICE_ID="00008120-001651180EF8C01E"

# Check if device is connected
flutter devices | grep -q "$DEVICE_ID"
if [ $? -ne 0 ]; then
    echo "❌ Device not found. Please connect your iPhone via cable."
    echo ""
    echo "Available devices:"
    flutter devices
    exit 1
fi

echo "✅ Device found: Vintage"
echo ""
echo "Building and installing app..."
echo ""

# Build and install
flutter run --release --device-id=Vintage

echo ""
echo "✅ Done! Your app will work for the next 7 days."
echo "📅 Rebuild again by: $(date -v+7d '+%B %d, %Y')"
echo ""
echo "💡 Tip: You can disconnect the cable after the app launches successfully."
