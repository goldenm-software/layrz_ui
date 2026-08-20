#!/bin/sh
# Run tests with coverage and enforce a 90% floor.

# Git exports GIT_DIR / GIT_WORK_TREE / GIT_INDEX_FILE when running a hook.
# Flutter resolves its own version via git inside $FLUTTER_ROOT,
# and an inherited GIT_DIR overrides `git -C` — so Flutter reads THIS repo
# instead and reports 0.0.0-unknown, failing the SDK constraint in pubspec.yaml.
# Unset them before calling flutter.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

set -e

echo "Running tests with coverage..."
flutter test --coverage > /dev/null 2>&1 || { echo "   ❌ Tests failed"; exit 1; }
echo "   ✓ All tests passed"

echo "Coverage floor (90%)..."

# Try lcov if available, otherwise fall back to awk
if command -v lcov > /dev/null 2>&1; then
  PERCENTAGE=$(lcov --summary coverage/lcov.info 2>/dev/null | grep "lines" | grep -oE '[0-9]+\.[0-9]+' | head -1)
else
  # Parse coverage/lcov.info and sum up LH (lines hit) and LF (lines found)
  LH=$(grep "^LH:" coverage/lcov.info | cut -d: -f2 | awk '{sum+=$1} END {print sum}')
  LF=$(grep "^LF:" coverage/lcov.info | cut -d: -f2 | awk '{sum+=$1} END {print sum}')
  PERCENTAGE=$(awk -v lh="$LH" -v lf="$LF" "BEGIN {printf \"%.2f\", (lh / lf) * 100}")
fi

echo "   Coverage: $PERCENTAGE%"

# Use awk for comparison instead of bc (more portable)
if awk -v pct="$PERCENTAGE" "BEGIN {exit !(pct < 90)}"; then
  echo "   ❌ Coverage is below the 90% floor!"
  exit 1
else
  echo "   ✓ Coverage meets the 90% floor"
fi
