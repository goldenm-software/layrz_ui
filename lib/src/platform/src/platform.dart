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
  ///
  /// **Use this for "is this a phone/tablet form factor" questions.** This getter
  /// routes through [current], which checks [kIsWeb] first — so it is `false` for
  /// every web target, including Chrome on an Android phone. That is correct for
  /// layout/form-factor decisions, but wrong for "does this OS have touch-selection
  /// affordances" questions: see [isTouchOS] for that case. The two differ **only
  /// on web** — on native builds they agree exactly.
  static bool get isMobile => isAndroid || isIOS;

  /// Whether the app is running on a desktop platform (macOS, Windows, or Linux).
  static bool get isDesktop => isMacOS || isWindows || isLinux;

  /// Whether the underlying operating system is Android or iOS, on web or native.
  ///
  /// **Use this for "should touch-selection affordances (magnifier, drag handles,
  /// selection action menu) appear" questions.** Unlike [isMobile], this reads
  /// [defaultTargetPlatform] directly and does **not** route through [current] —
  /// so it does not short-circuit on [kIsWeb]. [defaultTargetPlatform] reports the
  /// real host OS even on web, so a phone browser (e.g. Chrome on Android) reports
  /// `true` here, where [isMobile] reports `false`.
  ///
  /// This distinction is deliberate and encodes the team's DESIGN-147 decision: the
  /// three touch-selection affordances are gated on OS identity alone — "Android and
  /// iOS, via web or native" — with no form-factor or viewport-size term. [isMobile]
  /// answers a different question (form factor) and must not be used for this gate.
  ///
  /// The two getters **differ only on web** — on native builds they agree exactly.
  /// Picking the wrong one is a real footgun: using [isMobile] here reproduces the
  /// exact bug this getter exists to fix (mobile web silently losing touch
  /// selection UI), while using [isTouchOS] for a form-factor decision would
  /// wrongly treat desktop-shaped browsers on Android/iOS as compact layouts.
  static bool get isTouchOS =>
      defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

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
