.PHONY: help run-linux run-android run-ios run-windows run-macos get get-example

help:
	@echo "layrz_ui — available targets:"
	@echo "  get           Run flutter pub get on the package"
	@echo "  get-example   Run flutter pub get on the example app"
	@echo "  run-linux     Run example on Linux desktop"
	@echo "  run-android   Run example on Android"
	@echo "  run-ios       Run example on iOS"
	@echo "  run-windows   Run example on Windows desktop"
	@echo "  run-macos     Run example on macOS desktop"

get:
	flutter pub get

get-example:
	$(MAKE) -C example get

run-linux:
	$(MAKE) -C example run-linux

run-android:
	$(MAKE) -C example run-android

run-ios:
	$(MAKE) -C example run-ios

run-windows:
	$(MAKE) -C example run-windows

run-macos:
	$(MAKE) -C example run-macos
