.PHONY: help
help:
	@echo "layrz_ui example — available targets:"
	@echo "  get          Run flutter pub get"
	@echo "  run-linux    Run on Linux desktop"
	@echo "  run-android  Run on Android"
	@echo "  run-ios      Run on iOS"
	@echo "  run-windows  Run on Windows desktop"
	@echo "  run-macos    Run on macOS desktop"

.PHONY: get
get:
	flutter pub get

.PHONY: run-linux
run-linux:
	flutter run -d linux

.PHONY: run-android
run-android:
	flutter run -d android

.PHONY: clean
clean:
	flutter clean
	$(MAKE) get

.PHONY: build-android
build-android: clean
	flutter build apk --release --no-tree-shake-icons
	mv build/app/outputs/flutter-apk/app-release.apk ../com.layrz.ui.apk

