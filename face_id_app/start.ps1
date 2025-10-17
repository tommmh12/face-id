# Quick Start Script for Face Recognition Attendance App

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Face Recognition Attendance App" -ForegroundColor Cyan
Write-Host "  Quick Start Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Flutter installation
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
flutter --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter is not installed or not in PATH!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check connected devices
Write-Host "Checking connected devices..." -ForegroundColor Yellow
flutter devices
Write-Host ""

# Clean and get dependencies
Write-Host "Cleaning project..." -ForegroundColor Yellow
flutter clean
Write-Host ""

Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host ""

# Check for .env file
Write-Host "Checking configuration..." -ForegroundColor Yellow
if (Test-Path ".env") {
    Write-Host "✅ .env file found" -ForegroundColor Green
    Get-Content .env | Write-Host -ForegroundColor Gray
} else {
    Write-Host "❌ .env file not found! Creating from example..." -ForegroundColor Red
    Copy-Item ".env.example" ".env"
    Write-Host "✅ .env file created. Please update it if needed." -ForegroundColor Green
}
Write-Host ""

# Ask user if they want to run the app
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To run the app, use: flutter run" -ForegroundColor Yellow
Write-Host ""
$run = Read-Host "Do you want to run the app now? (y/n)"
if ($run -eq "y" -or $run -eq "Y") {
    Write-Host ""
    Write-Host "Starting app..." -ForegroundColor Green
    flutter run
}
