@echo off
echo ========================================
echo    Secure App - Release Build Script
echo ========================================
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter and add it to your PATH
    pause
    exit /b 1
)

echo [1/6] Cleaning previous builds...
flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Failed to clean project
    pause
    exit /b 1
)

echo [2/6] Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)

echo [3/6] Analyzing code...
flutter analyze
if %errorlevel% neq 0 (
    echo WARNING: Code analysis found issues
    echo Continuing with build...
)

echo [4/6] Building release APK...
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
if %errorlevel% neq 0 (
    echo ERROR: Failed to build release APK
    pause
    exit /b 1
)

echo [5/6] Building release App Bundle...
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
if %errorlevel% neq 0 (
    echo ERROR: Failed to build release App Bundle
    pause
    exit /b 1
)

echo [6/6] Build completed successfully!
echo.
echo Output files:
echo - APK: build\app\outputs\flutter-apk\app-release.apk
echo - AAB: build\app\outputs\bundle\release\app-release.aab
echo - Symbols: build\app\outputs\symbols\
echo.
echo You can now upload the AAB file to Google Play Store
echo or install the APK file on Android devices.
echo.
pause


