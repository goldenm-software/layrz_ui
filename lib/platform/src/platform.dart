import 'package:flutter/foundation.dart';

/// Runtime platform identifier — Material-free equivalent of `ThemedPlatform` from layrz_theme.
enum LayrzPlatform {
  /// Web platform compiled with CanvasKit.
  web,

  /// Google Android.
  android,

  /// Apple iOS.
  iOS,

  /// Apple macOS.
  macOS,

  /// Microsoft Windows.
  windows,

  /// GNU/Linux.
  linux,

  /// Google Fuchsia.
  fuchsia,

  /// Web platform compiled with WebAssembly (WASM).
  webWasm,

  /// Unknown / unrecognized platform.
  unknown;

  /// Whether the app is running on any web target.
  static bool get isWeb => current == web;

  /// Whether the app is running on Android.
  static bool get isAndroid => current == android;

  /// Whether the app is running on iOS.
  static bool get isIOS => current == iOS;

  /// Whether the app is running on macOS.
  static bool get isMacOS => current == macOS;

  /// Whether the app is running on Windows.
  static bool get isWindows => current == windows;

  /// Whether the app is running on Linux.
  static bool get isLinux => current == linux;

  /// Whether the app is running on Fuchsia.
  static bool get isFuchsia => current == fuchsia;

  /// Whether the app is running on the WASM web target.
  static bool get isWebWasm => current == webWasm;

  /// Whether the app is running on a mobile platform (Android or iOS).
  static bool get isMobile => isAndroid || isIOS;

  /// Whether the app is running on a desktop platform (macOS, Windows, or Linux).
  static bool get isDesktop => isMacOS || isWindows || isLinux;

  /// The [LayrzPlatform] value for the current runtime environment.
  static LayrzPlatform get current {
    if (kIsWeb) {
      if (kIsWasm) return LayrzPlatform.webWasm;
      return LayrzPlatform.web;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => LayrzPlatform.android,
      TargetPlatform.iOS => LayrzPlatform.iOS,
      TargetPlatform.macOS => LayrzPlatform.macOS,
      TargetPlatform.windows => LayrzPlatform.windows,
      TargetPlatform.linux => LayrzPlatform.linux,
      TargetPlatform.fuchsia => LayrzPlatform.fuchsia,
    };
  }

  @override
  String toString() => switch (this) {
        LayrzPlatform.webWasm => 'Web (WASM)',
        LayrzPlatform.web => 'Web (CanvasKit)',
        LayrzPlatform.android => 'Google Android',
        LayrzPlatform.iOS => 'Apple iOS',
        LayrzPlatform.macOS => 'Apple macOS',
        LayrzPlatform.windows => 'Microsoft Windows',
        LayrzPlatform.linux => 'GNU/Linux',
        LayrzPlatform.fuchsia => 'Google Fuchsia',
        LayrzPlatform.unknown => 'Unknown',
      };
}
