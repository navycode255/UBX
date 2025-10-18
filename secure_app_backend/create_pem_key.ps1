# Create PEM private key for nginx
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object {$_.Subject -like "*localhost*"} | Select-Object -First 1

if ($cert) {
    # Get the private key
    $privateKey = $cert.PrivateKey
    
    if ($privateKey) {
        # Export as PEM format
        $pemContent = "-----BEGIN PRIVATE KEY-----`n"
        $pemContent += [Convert]::ToBase64String($privateKey.Export([System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob))
        $pemContent += "`n-----END PRIVATE KEY-----"
        
        $pemContent | Out-File -FilePath "ssl\nginx.key" -Encoding ASCII
        
        Write-Host "Private key created: ssl\nginx.key" -ForegroundColor Green
    } else {
        Write-Host "Could not access private key" -ForegroundColor Red
    }
} else {
    Write-Host "Certificate not found" -ForegroundColor Red
}
