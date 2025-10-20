# Extract private key from PFX file
$pfxPath = "ssl\secure_app_backend.pfx"
$keyPath = "ssl\server.key"
$certPath = "ssl\server.crt"

# Load the PFX file
$pfxPassword = "secure_app_2025"
$pfxBytes = [System.IO.File]::ReadAllBytes($pfxPath)
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($pfxBytes, $pfxPassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)

# Export certificate to PEM format
$certPem = "-----BEGIN CERTIFICATE-----`n"
$certPem += [System.Convert]::ToBase64String($cert.RawData, [System.Base64FormattingOptions]::InsertLineBreaks)
$certPem += "`n-----END CERTIFICATE-----"
$certPem | Out-File -FilePath $certPath -Encoding ASCII

# Export private key to PEM format
$rsa = $cert.PrivateKey
if ($rsa -is [System.Security.Cryptography.RSACryptoServiceProvider]) {
    $keyPem = "-----BEGIN RSA PRIVATE KEY-----`n"
    $keyPem += [System.Convert]::ToBase64String($rsa.ExportCspBlob($true), [System.Base64FormattingOptions]::InsertLineBreaks)
    $keyPem += "`n-----END RSA PRIVATE KEY-----"
    $keyPem | Out-File -FilePath $keyPath -Encoding ASCII
    
    Write-Host "✓ Private key extracted successfully!"
} else {
    Write-Host "❌ Could not extract private key - unsupported key type"
}

Write-Host "Certificate file: $certPath"
Write-Host "Private key file: $keyPath"
