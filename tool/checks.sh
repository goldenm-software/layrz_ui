#!/bin/sh
# Static CI checks: analyze and import guards.
# This script does NOT run tests or coverage — that's the responsibility of coverage.sh.
#
# Usage:
#   ./checks.sh         # Run full checks (default)
#   ./checks.sh --staged-only  # Skip checks if all staged files are safe-to-skip patterns

# Git exports GIT_DIR / GIT_WORK_TREE / GIT_INDEX_FILE when running a hook.
# Flutter resolves its own version via git inside $FLUTTER_ROOT,
# and an inherited GIT_DIR overrides `git -C` — so Flutter reads THIS repo
# instead and reports 0.0.0-unknown, failing the SDK constraint in pubspec.yaml.
# Unset them before calling flutter.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

set -e

# If --staged-only is passed, check whether all staged files are safe to skip
if [ "$1" = "--staged-only" ]; then
  # Get list of staged files (ACMR = Added, Copied, Modified, Renamed; excludes Deleted)
  staged_files=$(git diff --cached --name-only --diff-filter=ACMR)

  # If nothing staged, run full checks (don't skip if git state is unclear)
  if [ -z "$staged_files" ]; then
    echo "No staged files detected; running full checks..."
    unset staged_files
  else
    # Check if every staged file matches a safe-to-skip pattern
    all_safe=true

    while IFS= read -r file; do
      # ALLOWLIST patterns that are safe to skip Dart checks for:
      # - Documentation files (.md)
      # - Wiki submodule and its contents (wiki, wiki/**)
      # - Engineering documentation (engineering/**)
      # - License and config files
      # - Image files
      case "$file" in
        *.md | wiki | wiki/* | engineering/* | LICENSE | .gitignore | .gitattributes | *.png | *.jpg | *.jpeg | *.svg)
          # Safe to skip
          ;;
        *)
          # Anything else (including pubspec.yaml, lib/*, test/*, tool/*, etc.) must trigger full checks
          all_safe=false
          break
          ;;
      esac
    done <<EOF
$staged_files
EOF

    if [ "$all_safe" = true ]; then
      echo "Skipping Dart checks (only safe-to-skip files staged)"
      exit 0
    fi
  fi
fi

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
