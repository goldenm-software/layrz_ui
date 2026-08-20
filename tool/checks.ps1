# Static CI checks: analyze and import guards.
# This script does NOT run tests or coverage — that's the responsibility of coverage.ps1.

# Parity with POSIX: clear git environment variables if set (should not happen on Windows,
# but clear them anyway for consistency). This was a POSIX-specific issue, but we clear
# them here for belt-and-suspenders.
if (Test-Path Env:GIT_DIR) { Remove-Item Env:GIT_DIR -ErrorAction SilentlyContinue }
if (Test-Path Env:GIT_WORK_TREE) { Remove-Item Env:GIT_WORK_TREE -ErrorAction SilentlyContinue }
if (Test-Path Env:GIT_INDEX_FILE) { Remove-Item Env:GIT_INDEX_FILE -ErrorAction SilentlyContinue }

$ErrorActionPreference = 'Stop'

Write-Host "Running CI checks..."
Write-Host "1. flutter analyze..."
flutter analyze
if ($LASTEXITCODE -ne 0) {
  exit 1
}
Write-Host "   ✓ No analysis issues"

Write-Host "3. Material/Cupertino guard..."
$materialImports = Select-String -Path @(Get-ChildItem -Path "lib" -Recurse -Include "*.dart" -ErrorAction SilentlyContinue) `
  -Pattern "package:flutter/material|package:flutter/cupertino" -ErrorAction SilentlyContinue
if ($materialImports) {
  Write-Host "   ❌ Material or Cupertino imports found in lib/"
  exit 1
} else {
  Write-Host "   ✓ No Material or Cupertino imports in lib/"
}

Write-Host "4. GoogleFonts TextTheme guard..."
$googleFontsImports = Select-String -Path @(Get-ChildItem -Path "lib" -Recurse -Include "*.dart" -ErrorAction SilentlyContinue) `
  -Pattern "GoogleFonts\..*TextTheme|from 'package:google_fonts/.*TextTheme" -ErrorAction SilentlyContinue
if ($googleFontsImports) {
  Write-Host "   ❌ Material-coupled GoogleFonts TextTheme methods found in lib/"
  exit 1
} else {
  Write-Host "   ✓ No Material-coupled GoogleFonts TextTheme methods in lib/"
}

Write-Host "All checks passed ✓"
