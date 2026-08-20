# Run tests with coverage and enforce a 90% floor.

# Parity with POSIX: clear git environment variables if set (should not happen on Windows,
# but clear them anyway for consistency).
if (Test-Path Env:GIT_DIR) { Remove-Item Env:GIT_DIR -ErrorAction SilentlyContinue }
if (Test-Path Env:GIT_WORK_TREE) { Remove-Item Env:GIT_WORK_TREE -ErrorAction SilentlyContinue }
if (Test-Path Env:GIT_INDEX_FILE) { Remove-Item Env:GIT_INDEX_FILE -ErrorAction SilentlyContinue }

$ErrorActionPreference = 'Stop'

Write-Host "Running tests with coverage..."
flutter test --coverage 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host "   ❌ Tests failed"
  exit 1
}
Write-Host "   ✓ All tests passed"

Write-Host "Coverage floor (90%)..."

# Parse coverage/lcov.info to calculate percentage
if (-not (Test-Path "coverage/lcov.info")) {
  Write-Host "   ❌ No coverage data found (coverage/lcov.info not found)"
  exit 1
}

$coverageFile = Get-Content "coverage/lcov.info"
$lhSum = 0
$lfSum = 0

foreach ($line in $coverageFile) {
  if ($line -match "^LH:(\d+)") {
    $lhSum += [int]$matches[1]
  } elseif ($line -match "^LF:(\d+)") {
    $lfSum += [int]$matches[1]
  }
}

if ($lfSum -eq 0) {
  Write-Host "   ❌ Invalid coverage data (LF sum is 0)"
  exit 1
}

$percentage = [math]::Round(($lhSum / $lfSum) * 100, 2)

Write-Host "   Coverage: $percentage%"

if ($percentage -lt 90) {
  Write-Host "   ❌ Coverage is below the 90% floor!"
  exit 1
} else {
  Write-Host "   ✓ Coverage meets the 90% floor"
}
