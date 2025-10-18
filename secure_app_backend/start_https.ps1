# Start HTTPS development environment
Write-Host "🚀 Starting HTTPS Development Environment..." -ForegroundColor Green
Write-Host ""

# Check if Node.js is available
$nodePath = Get-Command node -ErrorAction SilentlyContinue

if (-not $nodePath) {
    Write-Host "❌ Node.js not found. Please install Node.js first:" -ForegroundColor Red
    Write-Host "1. Download from: https://nodejs.org/" -ForegroundColor White
    Write-Host "2. Or use: winget install OpenJS.NodeJS" -ForegroundColor White
    Write-Host ""
    Write-Host "Falling back to HTTP development server..." -ForegroundColor Yellow
    php artisan serve --host=0.0.0.0 --port=5000
    exit
}

# Start the HTTPS proxy
Write-Host "✅ Node.js found. Starting HTTPS proxy..." -ForegroundColor Green
Write-Host ""

node https-proxy.js