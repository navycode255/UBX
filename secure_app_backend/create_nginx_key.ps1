# Create private key for nginx
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object {$_.Subject -like "*localhost*"} | Select-Object -First 1

if ($cert) {
    # Export private key
    $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12) | Set-Content -Path "ssl\nginx.pfx" -Encoding Byte
    
    Write-Host "Private key exported to ssl\nginx.pfx" -ForegroundColor Green
    Write-Host "You can now use nginx with these certificates" -ForegroundColor Green
} else {
    Write-Host "Certificate not found" -ForegroundColor Red
}
