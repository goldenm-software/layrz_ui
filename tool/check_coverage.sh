#!/bin/bash
#
# check_coverage.sh
#
# Implements a coverage ratchet that never allows coverage to decrease. Parses
# line coverage from coverage/lcov.info (produced by 'flutter test --coverage')
# and compares it against the baseline in tool/coverage_baseline.
#
# If current coverage is less than baseline: FAIL (exit 1)
# If current coverage is greater than baseline: PASS (exit 0), prompt to update baseline
# If coverage/lcov.info is missing: FAIL (exit 1)
#
# Exit codes:
#   0 — coverage meets or exceeds baseline
#   1 — coverage regressed, missing report, or parse error
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

COVERAGE_REPORT="coverage/lcov.info"
BASELINE_FILE="tool/coverage_baseline"

# Check if coverage report exists
if [ ! -f "$COVERAGE_REPORT" ]; then
  echo -e "${RED}✗ Coverage report not found: $COVERAGE_REPORT${NC}"
  echo "  Run 'flutter test --coverage' first to generate the report."
  exit 1
fi

# Parse coverage from lcov.info
# LH: = lines hit
# LF: = lines found (total)
LH=$(grep '^LH:' "$COVERAGE_REPORT" | awk -F: '{sum += $2} END {print (sum ? sum : 0)}')
LF=$(grep '^LF:' "$COVERAGE_REPORT" | awk -F: '{sum += $2} END {print (sum ? sum : 0)}')

# Guard against divide by zero
if [ "$LF" -eq 0 ]; then
  echo -e "${RED}✗ Coverage report is empty (LF = 0)${NC}"
  exit 1
fi

# Calculate percentage
CURRENT_COVERAGE=$(awk "BEGIN {printf \"%.2f\", ($LH / $LF) * 100}")

# Check if baseline exists
if [ ! -f "$BASELINE_FILE" ]; then
  echo -e "${RED}✗ Baseline file not found: $BASELINE_FILE${NC}"
  exit 1
fi

# Read baseline
BASELINE=$(cat "$BASELINE_FILE" | tr -d '[:space:]')

# Validate baseline format
if ! [[ "$BASELINE" =~ ^[0-9]+\.[0-9]{2}$ ]]; then
  echo -e "${RED}✗ Invalid baseline format in $BASELINE_FILE: $BASELINE${NC}"
  echo "  Expected format: NN.NN (e.g., 45.67)"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Coverage Ratchet Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Baseline:  $BASELINE%"
echo "Current:   $CURRENT_COVERAGE%"
echo "Lines:     $LH / $LF"
echo ""

# Compare coverage
# Use bc if available, otherwise use awk for floating-point comparison
COVERAGE_IMPROVED=0
if command -v bc &>/dev/null; then
  if (( $(echo "$CURRENT_COVERAGE > $BASELINE" | bc -l) )); then
    COVERAGE_IMPROVED=1
  fi
else
  # Fallback: awk-based comparison
  COVERAGE_IMPROVED=$(awk -v curr="$CURRENT_COVERAGE" -v base="$BASELINE" 'BEGIN {if (curr > base) print 1; else print 0}')
fi

if [ "$COVERAGE_IMPROVED" -eq 1 ]; then
  DELTA=$(awk -v curr="$CURRENT_COVERAGE" -v base="$BASELINE" "BEGIN {printf \"%.2f\", curr - base}")
  echo -e "${GREEN}✓ Coverage improved by ${DELTA}%${NC}"
  echo ""
  echo "To update the baseline and persist this improvement:"
  echo "  echo '$CURRENT_COVERAGE' > tool/coverage_baseline"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

# Check if coverage equals baseline (within floating-point tolerance)
COVERAGE_EQUAL=0
COVERAGE_EQUAL=$(awk -v curr="$CURRENT_COVERAGE" -v base="$BASELINE" 'BEGIN {if (curr >= base - 0.01 && curr <= base + 0.01) print 1; else print 0}')

if [ "$COVERAGE_EQUAL" -eq 1 ]; then
  echo -e "${GREEN}✓ Coverage meets baseline${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

# Coverage regressed
DELTA=$(awk -v curr="$CURRENT_COVERAGE" -v base="$BASELINE" "BEGIN {printf \"%.2f\", base - curr}")
echo -e "${RED}✗ Coverage regressed by ${DELTA}%${NC}"
echo ""
echo "Your changes reduced code coverage below the baseline."
echo "Add more tests to restore coverage to $BASELINE% or above."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exit 1
