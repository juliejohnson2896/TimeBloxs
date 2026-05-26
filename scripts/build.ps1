# Timebloxs Local Build Script
# Usage: .\scripts\build.ps1 [-Target android|windows|all] [-Mode debug|release]

param(
    [string]$Target = "all",
    [string]$Mode = "debug",
    [int]$CoverageThreshold = 35
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
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

# ── Step 5: Tests with coverage ──────────────────────────────
Write-Step "Running tests with coverage..."
flutter test --coverage
if ($LASTEXITCODE -ne 0) { Write-Fail "Tests failed"; exit 1 }
Write-Success "All tests passed"

# -- Step 6: Coverage filtering and threshold check -----------
Write-Step "Checking coverage threshold..."

$lcovPath = "coverage/lcov.info"
$filteredPath = "coverage/filtered_lcov.info"

# Find lcov script path via choco or PATH
function Find-LcovScript {
    param([string]$ScriptName)

    # Search common chocolatey install locations
    $searchPaths = @(
        "$env:ChocolateyInstall\lib\lcov\tools\bin\$ScriptName",
        "$env:ChocolateyInstall\bin\$ScriptName",
        "C:\ProgramData\chocolatey\lib\lcov\tools\bin\$ScriptName",
        "C:\tools\lcov\bin\$ScriptName"
    )

    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    # Last resort - try where.exe output
    try {
        $result = where.exe $ScriptName 2>$null
        if ($result) {
            return $result | Select-Object -First 1
        }
    } catch { }

    return $null
}

function Invoke-LcovCommand {
    param([string]$ScriptPath, [string[]]$Arguments)

    # Always use perl explicitly on Windows to avoid
    # the file association dialog
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        $perlPath = (Get-Command perl -ErrorAction SilentlyContinue)
        if (-not $perlPath) {
            Write-Warning "perl not found - cannot run lcov"
            return $null
        }
        $output = & $perlPath $ScriptPath @Arguments 2>&1
    } else {
        $output = & $ScriptPath @Arguments 2>&1
    }
    return $output
}

if (-not (Test-Path $lcovPath)) {
    Write-Host "    No coverage report found - skipping threshold check" -ForegroundColor Yellow
} else {
    $lcovScript = Find-LcovScript "lcov"

    if (-not $lcovScript) {
        Write-Host "    lcov not found - install via: choco install lcov" -ForegroundColor Yellow
        Write-Host "    Skipping coverage threshold check" -ForegroundColor Yellow
    } else {
        Write-Host "    Using lcov at: $lcovScript" -ForegroundColor Gray
        Write-Host "    Filtering coverage report..." -ForegroundColor Gray

        $filterArgs = @(
            "--config-file", "lcovrc",
            "--remove", $lcovPath,
            "lib/core/database/tables/*",
            "lib/core/theme/app_theme.dart",
            "lib/**/*.g.dart",
            "lib/core/services/pocketbase_service.dart",
            "lib/core/services/auth_notifier.dart",
            "lib/core/router/app_router.dart",
            "lib/main.dart",
            "--ignore-errors", "unused",
            "-o", $filteredPath
        )

        Invoke-LcovCommand -ScriptPath $lcovScript -Arguments $filterArgs | Out-Null

        if ($LASTEXITCODE -ne 0) {
            Write-Host "    Coverage filtering failed - skipping threshold check" -ForegroundColor Yellow
        } else {
            $summaryArgs = @("--summary", $filteredPath)
            $summaryOutput = Invoke-LcovCommand -ScriptPath $lcovScript -Arguments $summaryArgs

            # Parse coverage percentage
            $coverageLine = $summaryOutput | Select-String -Pattern "lines\.*:\s+(\d+\.\d+)%"

            if (-not $coverageLine) {
                Write-Host "    Raw summary output:" -ForegroundColor Gray
                $summaryOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
                Write-Host "    Could not parse coverage percentage - skipping threshold check" -ForegroundColor Yellow
            } else {
                $coverage = [double]$coverageLine.Matches[0].Groups[1].Value

                # Generate HTML report if genhtml is available
                $genhtmlScript = Find-LcovScript "genhtml"
                if ($genhtmlScript) {
                    $htmlOutput = "coverage/html"
                    Invoke-LcovCommand -ScriptPath $genhtmlScript -Arguments @($filteredPath, "-o", $htmlOutput) | Out-Null
                    Write-Host "    HTML report at $htmlOutput/index.html" -ForegroundColor Gray
                } else {
                    Write-Host "    genhtml not found - skipping HTML report" -ForegroundColor Gray
                }

                Write-Host "    Coverage: $coverage%" -ForegroundColor Gray

                if ($coverage -lt $CoverageThreshold) {
                    Write-Fail "Coverage $coverage% is below threshold of $CoverageThreshold%"
                    Write-Host "    Adjust with -CoverageThreshold flag or add more tests" -ForegroundColor Yellow
                    exit 1
                }

                Write-Success "Coverage $coverage% meets threshold of $CoverageThreshold%"
            }
        }
    }
}

# ── Step 7: Build ────────────────────────────────────────────
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

Write-Host "`n[DONE] Build pipeline complete!" -ForegroundColor Green