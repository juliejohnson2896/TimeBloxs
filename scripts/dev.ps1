# Quick dev script — regenerates code and runs on connected device
param(
    [string]$Device = "android"
)

$ErrorActionPreference = "Stop"

Write-Host "==> Getting dependencies..." -ForegroundColor Cyan
flutter pub get

Write-Host "==> Running code generation..." -ForegroundColor Cyan
dart run build_runner build --delete-conflicting-outputs

Write-Host "==> Running on $Device..." -ForegroundColor Cyan
flutter run -d $Device