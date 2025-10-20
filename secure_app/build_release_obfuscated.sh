#!/bin/bash

echo "Building Flutter app with obfuscation for release..."

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build Android APK with obfuscation
echo "Building Android APK with obfuscation..."
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Build Android App Bundle with obfuscation
echo "Building Android App Bundle with obfuscation..."
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Build iOS with obfuscation
echo "Building iOS with obfuscation..."
flutter build ios --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Build macOS with obfuscation
echo "Building macOS with obfuscation..."
flutter build macos --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Build Linux with obfuscation
echo "Building Linux with obfuscation..."
flutter build linux --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Build Windows with obfuscation
echo "Building Windows with obfuscation..."
flutter build windows --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Build Web with obfuscation
echo "Building Web with obfuscation..."
flutter build web --release --obfuscate --split-debug-info=build/app/outputs/symbols

echo "Build completed! Obfuscated builds created for all platforms."
echo "Debug symbols saved to: build/app/outputs/symbols/"
echo "APK location: build/app/outputs/flutter-apk/app-release.apk"
echo "App Bundle location: build/app/outputs/bundle/release/app-release.aab"

