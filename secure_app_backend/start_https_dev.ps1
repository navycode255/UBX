# Start HTTPS development environment
# This script starts both Laravel and nginx for HTTPS development

Write-Host "Starting HTTPS Development Environment..." -ForegroundColor Green
Write-Host ""

# Check if nginx is installed
$nginxPath = Get-Command nginx -ErrorAction SilentlyContinue

if (-not $nginxPath) {
    Write-Host "nginx not found. Please install nginx first:" -ForegroundColor Red
    Write-Host "1. Download from: https://nginx.org/en/download.html" -ForegroundColor White
    Write-Host "2. Or use: choco install nginx" -ForegroundColor White
    Write-Host ""
    Write-Host "Falling back to HTTP development server..." -ForegroundColor Yellow
    php artisan serve --host=0.0.0.0 --port=5000
    exit
}

# Convert certificate if needed
if (-not (Test-Path "ssl\secure_app_backend.pem")) {
    Write-Host "Converting certificate to PEM format..." -ForegroundColor Yellow
    powershell -ExecutionPolicy Bypass -File convert_cert.ps1
}

# Start Laravel in background
Write-Host "Starting Laravel backend on port 5000..." -ForegroundColor Cyan
$laravelJob = Start-Job -ScriptBlock { 
    Set-Location $using:PWD
    php artisan serve --host=127.0.0.1 --port=5000
}

# Wait a moment for Laravel to start
Start-Sleep -Seconds 3

# Start nginx with HTTPS
Write-Host "Starting nginx with HTTPS on port 5000..." -ForegroundColor Cyan
Write-Host "HTTPS URL: https://10.197.105.153:5000" -ForegroundColor Green
Write-Host "Note: You may see a security warning due to self-signed certificate" -ForegroundColor Yellow
Write-Host ""

# Start nginx
nginx -c "$PWD\nginx.conf" -p "$PWD"

# Cleanup function
$cleanup = {
    Write-Host "`nStopping services..." -ForegroundColor Yellow
    Stop-Job $laravelJob -ErrorAction SilentlyContinue
    Remove-Job $laravelJob -ErrorAction SilentlyContinue
    nginx -s quit -c "$PWD\nginx.conf" -p "$PWD"
    Write-Host "Services stopped." -ForegroundColor Green
}

# Register cleanup on script exit
Register-EngineEvent PowerShell.Exiting -Action $cleanup

# Wait for user input
Write-Host "Press Ctrl+C to stop all services" -ForegroundColor White
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    & $cleanup
}
