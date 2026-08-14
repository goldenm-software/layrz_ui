#!/bin/bash
#
# check_test_mirror.sh
#
# Enforces the test-mirror invariant: every implementation file under lib/ must have
# a corresponding test file under test/. Export-only barrel files (those containing
# only export statements) are exempt from this requirement.
#
# Exit codes:
#   0 — all checks passed
#   1 — missing test files or orphaned tests found
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

MISSING_TESTS=()
ORPHANED_TESTS=()
CHECKED_IMPL_COUNT=0
CHECKED_TEST_COUNT=0

# Function to check if a Dart file is export-only
# Returns 0 if export-only, 1 otherwise
is_export_only() {
  local file="$1"
  local non_export_count=0

  # Count non-blank, non-comment lines that are NOT export statements and NOT 'library;'
  while IFS= read -r line; do
    # Skip blank lines
    if [[ -z "${line// }" ]]; then
      continue
    fi
    # Skip comment-only lines
    if [[ "$line" == *"//"* ]] && [[ ! "$line" == *"export"* ]]; then
      continue
    fi
    # Skip library declarations
    if [[ "$line" == *"library"* ]]; then
      continue
    fi
    # Skip export statements
    if [[ "$line" == *"export "* ]]; then
      continue
    fi
    # Any other non-empty line that isn't an export means it's not export-only
    if [[ -n "${line// }" ]]; then
      non_export_count=$((non_export_count + 1))
    fi
  done < "$file"

  if [ "$non_export_count" -eq 0 ]; then
    return 0  # export-only
  else
    return 1  # not export-only
  fi
}

# Check implementation files for corresponding tests
echo "Checking implementation files..."
while IFS= read -r impl_file; do
  CHECKED_IMPL_COUNT=$((CHECKED_IMPL_COUNT + 1))

  # Skip if file is export-only
  if is_export_only "$impl_file"; then
    continue
  fi

  # Convert lib/module/src/name.dart → test/module/name_test.dart
  relative_path="${impl_file#lib/}"

  if [[ "$relative_path" == "layrz_ui.dart" ]]; then
    # Root barrel - should be export-only and skipped above
    continue
  fi

  if [[ "$relative_path" == *"/src/"* ]]; then
    # lib/module/src/name.dart → test/module/name_test.dart
    module=$(echo "$relative_path" | cut -d/ -f1)
    name=$(basename "$impl_file" .dart)
    test_file="test/${module}/${name}_test.dart"
  else
    # lib/module/module.dart (barrel) - should be export-only and skipped above
    continue
  fi

  if [ ! -f "$test_file" ]; then
    MISSING_TESTS+=("$impl_file → $test_file")
  fi
done < <(find lib -name "*.dart" -type f | sort)

# Check for orphaned tests
echo "Checking for orphaned tests..."
while IFS= read -r test_file; do
  CHECKED_TEST_COUNT=$((CHECKED_TEST_COUNT + 1))

  # Convert test/module/name_test.dart → lib/module/src/name.dart
  relative_path="${test_file#test/}"
  module=$(echo "$relative_path" | cut -d/ -f1)
  name=$(basename "$test_file" _test.dart)
  impl_file="lib/${module}/src/${name}.dart"

  if [ ! -f "$impl_file" ]; then
    ORPHANED_TESTS+=("$test_file (no impl at $impl_file)")
  fi
done < <(find test -name "*_test.dart" -type f ! -path "test/helpers/*" | sort)

# Print results
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Mirror Check Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Implementation files checked: $CHECKED_IMPL_COUNT"
echo "Test files checked: $CHECKED_TEST_COUNT"
echo ""

if [ ${#MISSING_TESTS[@]} -gt 0 ]; then
  echo -e "${RED}✗ Missing test files (${#MISSING_TESTS[@]}):${NC}"
  for missing in "${MISSING_TESTS[@]}"; do
    echo "  - $missing"
  done
  echo ""
fi

if [ ${#ORPHANED_TESTS[@]} -gt 0 ]; then
  echo -e "${RED}✗ Orphaned test files (${#ORPHANED_TESTS[@]}):${NC}"
  for orphaned in "${ORPHANED_TESTS[@]}"; do
    echo "  - $orphaned"
  done
  echo ""
fi

if [ ${#MISSING_TESTS[@]} -eq 0 ] && [ ${#ORPHANED_TESTS[@]} -eq 0 ]; then
  echo -e "${GREEN}✓ All checks passed${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
else
  echo -e "${RED}✗ Test mirror check failed${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 1
fi
