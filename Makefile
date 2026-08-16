CHMOD_CMD = chmod +x .githooks/pre-commit
ifeq ($(OS),Windows_NT)
    CHMOD_CMD = echo "Skipping chmod on Windows"
endif

.PHONY: help
help:
	@echo "layrz_ui — available targets:"
	@echo "  get           Run flutter pub get on the package"
	@echo "  get-example   Run flutter pub get on the example app"
	@echo "  checks        Run all CI checks (analyze, test, guards, coverage floor)"
	@echo "  run-linux     Run example on Linux desktop"
	@echo "  run-android   Run example on Android"
	@echo "  run-ios       Run example on iOS"
	@echo "  run-windows   Run example on Windows desktop"
	@echo "  run-macos     Run example on macOS desktop"
	@echo "  coverage      Run tests with coverage and report percentage (exits non-zero if <90%)"
	@echo "  coverage-html Generate HTML coverage report in coverage/html/"

.PHONY: install-hooks
install-hooks:
	@echo "Installing git hooks from .githooks directory..."
	@$(CHMOD_CMD)
	@git config core.hooksPath .githooks

.PHONY: checks
checks:
	@echo "Running CI checks..."
	@echo ""
	@echo "1. flutter analyze (lib/)..."
	@flutter analyze lib/ || exit 1
	@echo "   ✓ lib/ is clean"
	@echo ""
	@echo "2. flutter analyze (example/)..."
	@flutter analyze example/ || exit 1
	@echo "   ✓ example/ is clean"
	@echo ""
	@echo "3. Material/Cupertino guard..."
	@if grep -rq "package:flutter/material\|package:flutter/cupertino" lib/; then \
		echo "   ❌ Material or Cupertino imports found in lib/"; exit 1; \
	else \
		echo "   ✓ No Material or Cupertino imports in lib/"; \
	fi
	@echo ""
	@echo "4. GoogleFonts TextTheme guard..."
	@if grep -rq "GoogleFonts\..*TextTheme\|from 'package:google_fonts/.*TextTheme" lib/; then \
		echo "   ❌ Material-coupled GoogleFonts TextTheme methods found in lib/"; exit 1; \
	else \
		echo "   ✓ No Material-coupled GoogleFonts TextTheme methods in lib/"; \
	fi
	@echo ""
	@echo "5. Running tests with coverage..."
	@flutter test --coverage > /dev/null 2>&1 || { echo "   ❌ Tests failed"; exit 1; }
	@echo "   ✓ All tests passed"
	@echo ""
	@echo "6. Coverage floor (90%)..."
	@if command -v lcov > /dev/null 2>&1; then \
		PERCENTAGE=$$(lcov --summary coverage/lcov.info 2>/dev/null | grep "lines" | grep -oE '[0-9]+\.[0-9]+' | head -1); \
	else \
		LH=$$(grep "^LH:" coverage/lcov.info | cut -d: -f2 | awk '{sum+=$$1} END {print sum}'); \
		LF=$$(grep "^LF:" coverage/lcov.info | cut -d: -f2 | awk '{sum+=$$1} END {print sum}'); \
		PERCENTAGE=$$(awk "BEGIN {printf \"%.2f\", ($$LH / $$LF) * 100}"); \
	fi; \
	echo "   Coverage: $$PERCENTAGE%"; \
	if [ "$$(echo "$$PERCENTAGE < 90" | bc)" -eq 1 ]; then \
		echo "   ❌ Coverage is below the 90% floor!"; exit 1; \
	else \
		echo "   ✓ Coverage meets the 90% floor"; \
	fi
	@echo ""
	@echo "All checks passed ✓"

.PHONY: get
get:
	flutter pub get

.PHONY: get-example
get-example:
	$(MAKE) -C example get

.PHONY: run-linux
run-linux:
	$(MAKE) -C example run-linux

.PHONY: run-android
run-android:
	$(MAKE) -C example run-android

.PHONY: run-ios
run-ios:
	$(MAKE) -C example run-ios

.PHONY: run-windows
run-windows:
	$(MAKE) -C example run-windows

.PHONY: run-macos
run-macos:
	$(MAKE) -C example run-macos

.PHONY: coverage
coverage:
	@echo "Running tests with coverage..."
	@flutter test --coverage > /dev/null 2>&1 || { echo "Tests failed"; exit 1; }
	@if command -v lcov > /dev/null 2>&1; then \
		PERCENTAGE=$$(lcov --summary coverage/lcov.info 2>/dev/null | grep "lines" | grep -oE '[0-9]+\.[0-9]+' | head -1); \
	else \
		LH=$$(grep "^LH:" coverage/lcov.info | cut -d: -f2 | awk '{sum+=$$1} END {print sum}'); \
		LF=$$(grep "^LF:" coverage/lcov.info | cut -d: -f2 | awk '{sum+=$$1} END {print sum}'); \
		PERCENTAGE=$$(awk "BEGIN {printf \"%.2f\", ($$LH / $$LF) * 100}"); \
	fi; \
	echo ""; \
	echo "Coverage Report"; \
	echo "==============="; \
	echo "Overall line coverage: $$PERCENTAGE%"; \
	echo "CI floor: 90%"; \
	echo ""; \
	if [ "$$(echo "$$PERCENTAGE < 90" | bc)" -eq 1 ]; then \
		echo "❌ Coverage is below the 90% floor!"; \
		exit 1; \
	else \
		echo "✓ Coverage meets the 90% floor"; \
	fi

.PHONY: coverage-html
coverage-html:
	@if ! command -v genhtml > /dev/null 2>&1; then \
		echo "genhtml not found; install lcov or skip this target"; \
		exit 1; \
	fi
	@if [ ! -f coverage/lcov.info ]; then \
		echo "No coverage data found. Run 'make coverage' first."; \
		exit 1; \
	fi
	@echo "Generating HTML coverage report..."
	@rm -rf coverage/html
	@genhtml coverage/lcov.info --output-directory coverage/html > /dev/null 2>&1
	@echo "✓ Report generated at coverage/html/index.html"
