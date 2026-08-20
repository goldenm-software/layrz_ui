#!/bin/sh
# Static CI checks: analyze and import guards.
# This script does NOT run tests or coverage — that's the responsibility of coverage.sh.

# Git exports GIT_DIR / GIT_WORK_TREE / GIT_INDEX_FILE when running a hook.
# Flutter resolves its own version via git inside $FLUTTER_ROOT,
# and an inherited GIT_DIR overrides `git -C` — so Flutter reads THIS repo
# instead and reports 0.0.0-unknown, failing the SDK constraint in pubspec.yaml.
# Unset them before calling flutter.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

set -e

echo "Running CI checks..."
echo "1. flutter analyze..."
flutter analyze || exit 1
echo "   ✓ No analysis issues"

echo "3. Material/Cupertino guard..."
if grep -rq "package:flutter/material\|package:flutter/cupertino" lib/; then
  echo "   ❌ Material or Cupertino imports found in lib/"
  exit 1
else
  echo "   ✓ No Material or Cupertino imports in lib/"
fi

echo "4. GoogleFonts TextTheme guard..."
if grep -rq "GoogleFonts\..*TextTheme\|from 'package:google_fonts/.*TextTheme" lib/; then
  echo "   ❌ Material-coupled GoogleFonts TextTheme methods found in lib/"
  exit 1
else
  echo "   ✓ No Material-coupled GoogleFonts TextTheme methods in lib/"
fi

echo "All checks passed ✓"
