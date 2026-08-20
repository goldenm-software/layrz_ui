CHMOD_CMD = chmod +x tool/checks.sh tool/coverage.sh
ifeq ($(OS),Windows_NT)
    CHMOD_CMD = echo "Skipping chmod on Windows"
endif

.PHONY: help
help:
	@echo "layrz_ui — available targets:"
	@echo "  get           Run flutter pub get on the package"
	@echo "  get-example   Run flutter pub get on the example app"
	@echo "  checks        Run static CI checks (analyze, guards)"
	@echo "  run-linux     Run example on Linux desktop"
	@echo "  run-android   Run example on Android"
	@echo "  run-ios       Run example on iOS"
	@echo "  run-windows   Run example on Windows desktop"
	@echo "  run-macos     Run example on macOS desktop"
	@echo "  coverage      Run tests with coverage and enforce 90% floor"
	@echo "  coverage-html Generate HTML coverage report in coverage/html/"

.PHONY: install-hooks
install-hooks:
	@echo "Installing git hooks..."
	@$(CHMOD_CMD)
	@echo "Setting up pre-commit hook to run tool/checks.sh..."
	@mkdir -p .git/hooks
	@echo "#!/bin/sh" > .git/hooks/pre-commit
	@echo "# Pre-commit hook: delegate to tool/checks.sh for static checks." >> .git/hooks/pre-commit
	@echo "#" >> .git/hooks/pre-commit
	@echo "# Resolve the toplevel of the CURRENT worktree, so each worktree runs its own" >> .git/hooks/pre-commit
	@echo "# copy of the script rather than the main checkout's." >> .git/hooks/pre-commit
	@echo "#" >> .git/hooks/pre-commit
	@echo "# Skip gracefully when the script is absent — branches and worktrees created" >> .git/hooks/pre-commit
	@echo "# before tool/checks.sh existed must remain committable, and a hook that hard" >> .git/hooks/pre-commit
	@echo "# fails on a missing file would block them with an opaque error." >> .git/hooks/pre-commit
	@echo 'ROOT="$$(git rev-parse --show-toplevel)"' >> .git/hooks/pre-commit
	@echo 'if [ -x "$$ROOT/tool/checks.sh" ]; then' >> .git/hooks/pre-commit
	@echo '  exec "$$ROOT/tool/checks.sh" --staged-only' >> .git/hooks/pre-commit
	@echo 'fi' >> .git/hooks/pre-commit
	@echo 'echo "pre-commit: $$ROOT/tool/checks.sh not found — skipping static checks"' >> .git/hooks/pre-commit
	@echo 'exit 0' >> .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@git config --unset core.hooksPath 2>/dev/null || true
	@echo "✓ Git hooks installed"

.PHONY: checks
checks:
	@sh tool/checks.sh

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
	@sh tool/coverage.sh

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

.PHONY: build-android
build-android:
	@echo "Cleaning previous build artifacts..."
	@rm -rf com.layrz.ui.apk
	@echo "Building Android APK..."
	$(MAKE) -C example build-android