@echo off
echo Building Flutter app with obfuscation for release...

REM Clean previous builds
echo Cleaning previous builds...
flutter clean

REM Get dependencies
echo Getting dependencies...
flutter pub get

REM Build Android APK with obfuscation
echo Building Android APK with obfuscation...
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

REM Build Android App Bundle with obfuscation
echo Building Android App Bundle with obfuscation...
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

REM Build iOS with obfuscation (if on macOS)
echo Building iOS with obfuscation...
flutter build ios --release --obfuscate --split-debug-info=build/app/outputs/symbols

echo Build completed! Obfuscated APK and App Bundle created.
echo Debug symbols saved to: build/app/outputs/symbols/
echo APK location: build/app/outputs/flutter-apk/app-release.apk
echo App Bundle location: build/app/outputs/bundle/release/app-release.aab

