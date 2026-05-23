# Timebloxs Local Build Script
# Usage: .\scripts\build.ps1 [-Target android|windows|all] [-Mode debug|release]

param(
    [string]$Target = "all",
    [string]$Mode = "debug"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

# ── Step 1: Clean ────────────────────────────────────────────
Write-Step "Cleaning previous build artifacts..."
flutter clean
if ($LASTEXITCODE -ne 0) { Write-Fail "Clean failed"; exit 1 }
Write-Success "Clean complete"

# ── Step 2: Get dependencies ─────────────────────────────────
Write-Step "Getting dependencies..."
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Fail "pub get failed"; exit 1 }
Write-Success "Dependencies resolved"

# ── Step 3: Code generation ──────────────────────────────────
Write-Step "Running code generation..."
dart run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) { Write-Fail "Code generation failed"; exit 1 }
Write-Success "Code generation complete"

# ── Step 4: Analyze ──────────────────────────────────────────
Write-Step "Running static analysis..."
flutter analyze
if ($LASTEXITCODE -ne 0) { Write-Fail "Analysis failed"; exit 1 }
Write-Success "Analysis passed"

# ── Step 5: Tests ────────────────────────────────────────────
Write-Step "Running tests..."
flutter test
if ($LASTEXITCODE -ne 0) { Write-Fail "Tests failed"; exit 1 }
Write-Success "All tests passed"

# ── Step 6: Build ────────────────────────────────────────────
if ($Target -eq "android" -or $Target -eq "all") {
    Write-Step "Building Android ($Mode)..."
    if ($Mode -eq "release") {
        flutter build apk --release
    } else {
        flutter build apk --debug
    }
    if ($LASTEXITCODE -ne 0) { Write-Fail "Android build failed"; exit 1 }
    Write-Success "Android build complete"
}

if ($Target -eq "windows" -or $Target -eq "all") {
    Write-Step "Building Windows ($Mode)..."
    if ($Mode -eq "release") {
        flutter build windows --release
    } else {
        flutter build windows --debug
    }
    if ($LASTEXITCODE -ne 0) { Write-Fail "Windows build failed"; exit 1 }
    Write-Success "Windows build complete"
}

Write-Host "`n✓ Build pipeline complete!" -ForegroundColor Green