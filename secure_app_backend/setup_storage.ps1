# Setup storage for profile pictures
Write-Host "Setting up storage for profile pictures..." -ForegroundColor Green

# Create storage directories
$storagePath = "storage/app/public/profile-pictures"
if (!(Test-Path $storagePath)) {
    New-Item -ItemType Directory -Path $storagePath -Force
    Write-Host "Created directory: $storagePath" -ForegroundColor Yellow
}

# Create public storage link (if not exists)
$publicLink = "public/storage"
if (!(Test-Path $publicLink)) {
    # Create symbolic link
    cmd /c mklink /D $publicLink "..\storage\app\public"
    Write-Host "Created storage link: $publicLink" -ForegroundColor Yellow
} else {
    Write-Host "Storage link already exists: $publicLink" -ForegroundColor Green
}

Write-Host "Storage setup complete!" -ForegroundColor Green
Write-Host "Profile pictures will be stored in: storage/app/public/profile-pictures" -ForegroundColor Cyan
Write-Host "Public access via: /storage/profile-pictures/" -ForegroundColor Cyan
