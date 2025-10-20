#!/bin/bash

echo "========================================"
echo "   Secure App - Release Build Script"
echo "========================================"
echo

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter is not installed or not in PATH"
    echo "Please install Flutter and add it to your PATH"
    exit 1
fi

echo "[1/6] Cleaning previous builds..."
flutter clean
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to clean project"
    exit 1
fi

echo "[2/6] Getting dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to get dependencies"
    exit 1
fi

echo "[3/6] Analyzing code..."
flutter analyze
if [ $? -ne 0 ]; then
    echo "WARNING: Code analysis found issues"
    echo "Continuing with build..."
fi

echo "[4/6] Building release APK..."
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to build release APK"
    exit 1
fi

echo "[5/6] Building release App Bundle..."
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to build release App Bundle"
    exit 1
fi

echo "[6/6] Build completed successfully!"
echo
echo "Output files:"
echo "- APK: build/app/outputs/flutter-apk/app-release.apk"
echo "- AAB: build/app/outputs/bundle/release/app-release.aab"
echo "- Symbols: build/app/outputs/symbols/"
echo
echo "You can now upload the AAB file to Google Play Store"
echo "or install the APK file on Android devices."
echo


