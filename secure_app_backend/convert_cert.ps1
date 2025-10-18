# Convert PFX certificate to PEM format for nginx
# This script converts the Windows certificate to a format nginx can use

Write-Host "Converting PFX certificate to PEM format for nginx..." -ForegroundColor Green

$pfxFile = "ssl\secure_app_backend.pfx"
$pemFile = "ssl\secure_app_backend.pem"
$keyFile = "ssl\secure_app_backend.key"
$password = "secure_app_2025"

# Check if OpenSSL is available
$opensslPath = Get-Command openssl -ErrorAction SilentlyContinue

if ($opensslPath) {
    Write-Host "Using OpenSSL to convert certificate..." -ForegroundColor Yellow
    
    # Convert PFX to PEM (certificate + private key)
    $command1 = "openssl pkcs12 -in `"$pfxFile`" -out `"$pemFile`" -nodes -passin pass:$password"
    Invoke-Expression $command1
    
    # Extract private key
    $command2 = "openssl pkcs12 -in `"$pfxFile`" -nocerts -out `"$keyFile`" -nodes -passin pass:$password"
    Invoke-Expression $command2
    
    Write-Host "Certificate converted successfully!" -ForegroundColor Green
    Write-Host "Certificate file: $pemFile" -ForegroundColor White
    Write-Host "Private key file: $keyFile" -ForegroundColor White
} else {
    Write-Host "OpenSSL not found. Please install OpenSSL or use an alternative method." -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative: Use the Windows certificate store method:" -ForegroundColor Yellow
    Write-Host "1. Import the PFX into Windows Certificate Store" -ForegroundColor White
    Write-Host "2. Export as PEM format" -ForegroundColor White
    Write-Host "3. Or use a tool like mkcert for trusted certificates" -ForegroundColor White
}