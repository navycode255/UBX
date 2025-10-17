# Secure App - Key Regeneration Script
# This script generates new JWT_SECRET and ENCRYPTION_KEY for the Secure App

Write-Host "Secure App - Key Regeneration Script" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "Error: .env file not found!" -ForegroundColor Red
    Write-Host "Please run this script from the secure_app directory." -ForegroundColor Yellow
    exit 1
}

Write-Host "Found .env file" -ForegroundColor Green

# Generate new JWT_SECRET (64 characters)
Write-Host "Generating new JWT_SECRET..." -ForegroundColor Yellow
$jwtSecret = -join ((1..64) | ForEach {[char]((65..90) + (97..122) + (48..57) | Get-Random)})
Write-Host "JWT_SECRET generated (64 characters)" -ForegroundColor Green

# Generate new ENCRYPTION_KEY (32 characters)
Write-Host "Generating new ENCRYPTION_KEY..." -ForegroundColor Yellow
$encryptionKey = -join ((1..32) | ForEach {[char]((65..90) + (97..122) + (48..57) | Get-Random)})
Write-Host "ENCRYPTION_KEY generated (32 characters)" -ForegroundColor Green

# Backup current .env file
$backupFile = ".env.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Write-Host "Creating backup: $backupFile" -ForegroundColor Yellow
Copy-Item ".env" $backupFile
Write-Host "Backup created successfully" -ForegroundColor Green

# Update .env file with new JWT_SECRET
Write-Host "Updating JWT_SECRET in .env file..." -ForegroundColor Yellow
(Get-Content .env) -replace 'JWT_SECRET=.*', "JWT_SECRET=$jwtSecret" | Set-Content .env

# Update .env file with new ENCRYPTION_KEY
Write-Host "Updating ENCRYPTION_KEY in .env file..." -ForegroundColor Yellow
(Get-Content .env) -replace 'ENCRYPTION_KEY=.*', "ENCRYPTION_KEY=$encryptionKey" | Set-Content .env

Write-Host ".env file updated successfully" -ForegroundColor Green

# Verify the changes
Write-Host "Verifying changes..." -ForegroundColor Yellow
$envContent = Get-Content .env
$jwtLine = $envContent | Where-Object {$_ -match 'JWT_SECRET='}
$encLine = $envContent | Where-Object {$_ -match 'ENCRYPTION_KEY='}

Write-Host ""
Write-Host "Updated Configuration:" -ForegroundColor Cyan
Write-Host "JWT_SECRET: $($jwtLine -split '=' | Select-Object -Last 1)" -ForegroundColor White
Write-Host "ENCRYPTION_KEY: $($encLine -split '=' | Select-Object -Last 1)" -ForegroundColor White

# Verify key lengths
$jwtValue = ($jwtLine -split '=' | Select-Object -Last 1)
$encValue = ($encLine -split '=' | Select-Object -Last 1)

Write-Host ""
Write-Host "Key Lengths:" -ForegroundColor Cyan
Write-Host "JWT_SECRET length: $($jwtValue.Length) characters" -ForegroundColor White
Write-Host "ENCRYPTION_KEY length: $($encValue.Length) characters" -ForegroundColor White

# Validate character sets
$jwtValid = $jwtValue -match '^[A-Za-z0-9]+$'
$encValid = $encValue -match '^[A-Za-z0-9]+$'

Write-Host ""
Write-Host "Validation Results:" -ForegroundColor Cyan
Write-Host "JWT_SECRET valid format: $jwtValid" -ForegroundColor $(if($jwtValid) {"Green"} else {"Red"})
Write-Host "ENCRYPTION_KEY valid format: $encValid" -ForegroundColor $(if($encValid) {"Green"} else {"Red"})

Write-Host ""
Write-Host "Key regeneration completed successfully!" -ForegroundColor Green
Write-Host "Backup file: $backupFile" -ForegroundColor Yellow
Write-Host "Remember to restart your Flutter app to use the new keys." -ForegroundColor Yellow

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Restart your Flutter app: flutter run" -ForegroundColor White
Write-Host "2. Test authentication functionality" -ForegroundColor White
Write-Host "3. Update production environment if needed" -ForegroundColor White
Write-Host "4. Keep backup file for rollback if necessary" -ForegroundColor White
