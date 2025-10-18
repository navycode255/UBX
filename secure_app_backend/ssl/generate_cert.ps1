# PowerShell script to generate self-signed SSL certificate for Laravel development

# Get the current computer's IP address
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "10.*" -or $_.IPAddress -like "192.168.*"} | Select-Object -First 1).IPAddress

if (-not $ipAddress) {
    $ipAddress = "127.0.0.1"
}

Write-Host "Using IP address: $ipAddress"

# Create a self-signed certificate
$cert = New-SelfSignedCertificate -DnsName "localhost", $ipAddress, "127.0.0.1" -CertStoreLocation "Cert:\CurrentUser\My" -NotAfter (Get-Date).AddYears(1)

# Export the certificate to PFX format
$certPath = ".\secure_app_backend.pfx"
$certPassword = "secure_app_2025"
$securePassword = ConvertTo-SecureString -String $certPassword -Force -AsPlainText

Export-PfxCertificate -Cert $cert -FilePath $certPath -Password $securePassword

# Export the certificate to PEM format (for Laravel)
$certPem = ".\secure_app_backend.crt"
$keyPem = ".\secure_app_backend.key"

# Export certificate to PEM
$cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert) | Out-File -FilePath $certPem -Encoding ASCII

# Export private key to PEM
$cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12) | Out-File -FilePath "temp.pfx" -Encoding Binary
$certPasswordBytes = [System.Text.Encoding]::UTF8.GetBytes($certPassword)

Write-Host "Certificate generated successfully!"
Write-Host "Certificate file: $certPem"
Write-Host "Private key file: $keyPem"
Write-Host "PFX file: $certPath"
Write-Host "Certificate password: $certPassword"
Write-Host ""
Write-Host "You can now use these files with Laravel's HTTPS server."
Write-Host "IP addresses included: localhost, $ipAddress, 127.0.0.1"

# Clean up temporary file
Remove-Item "temp.pfx" -ErrorAction SilentlyContinue
