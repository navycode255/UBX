# Simple HTTPS setup for Laravel development
# This script will help you set up HTTPS for your Laravel backend

Write-Host "Setting up HTTPS for Laravel development..." -ForegroundColor Green
Write-Host ""

# Check if we have the certificate
$certPath = "ssl\secure_app_backend.pfx"
if (Test-Path $certPath) {
    Write-Host "✓ Certificate found: $certPath" -ForegroundColor Green
} else {
    Write-Host "✗ Certificate not found. Please run the certificate generation first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "For now, we'll use a workaround approach:" -ForegroundColor Yellow
Write-Host "1. Start Laravel on HTTP (port 5000)" -ForegroundColor White
Write-Host "2. Use a reverse proxy (like nginx) for HTTPS" -ForegroundColor White
Write-Host "3. Or use a tool like 'mkcert' for trusted certificates" -ForegroundColor White
Write-Host ""

Write-Host "Starting Laravel on HTTP for now..." -ForegroundColor Cyan
Write-Host "You can access it at: http://0.0.0.0:5000" -ForegroundColor White
Write-Host ""

# Start Laravel on HTTP
php artisan serve --host=0.0.0.0 --port=5000
