# Secure App - Release Build Script (PowerShell)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Secure App - Release Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter not found"
    }
} catch {
    Write-Host "ERROR: Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter and add it to your PATH" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[1/6] Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to clean project" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[2/6] Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to get dependencies" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[3/6] Analyzing code..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Code analysis found issues" -ForegroundColor Yellow
    Write-Host "Continuing with build..." -ForegroundColor Yellow
}

Write-Host "[4/6] Building release APK..." -ForegroundColor Yellow
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to build release APK" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[5/6] Building release App Bundle..." -ForegroundColor Yellow
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to build release App Bundle" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[6/6] Build completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Output files:" -ForegroundColor Cyan
Write-Host "- APK: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor White
Write-Host "- AAB: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor White
Write-Host "- Symbols: build\app\outputs\symbols\" -ForegroundColor White
Write-Host ""
Write-Host "You can now upload the AAB file to Google Play Store" -ForegroundColor Green
Write-Host "or install the APK file on Android devices." -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to exit"


