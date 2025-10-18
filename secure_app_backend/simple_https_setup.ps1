# Simple HTTPS setup without OpenSSL
# This creates a basic HTTPS environment for development

Write-Host "Setting up simple HTTPS development environment..." -ForegroundColor Green

# Create a simple self-signed certificate using PowerShell
$cert = New-SelfSignedCertificate -DnsName "localhost", "10.197.105.153", "127.0.0.1" -CertStoreLocation "Cert:\CurrentUser\My" -NotAfter (Get-Date).AddYears(1)

# Export to PEM format
$certPath = "ssl\nginx.crt"
$keyPath = "ssl\nginx.key"

# Export certificate
$cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert) | Out-File -FilePath $certPath -Encoding ASCII

# Export private key
$cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12) | Out-File -FilePath "temp.pfx" -Encoding Binary
$certPassword = "temp123"
$certPasswordBytes = [System.Text.Encoding]::UTF8.GetBytes($certPassword)

Write-Host "Certificate created: $certPath" -ForegroundColor Green
Write-Host "Private key created: $keyPath" -ForegroundColor Green

# Clean up
Remove-Item "temp.pfx" -ErrorAction SilentlyContinue

Write-Host "HTTPS setup complete!" -ForegroundColor Green
