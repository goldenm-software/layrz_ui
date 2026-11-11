import 'package:flutter/widgets.dart';

/// Immutable color tokens for the text-field family of inputs.
///
/// Fill colors are resolved from this dedicated group instead of the generic surface tokens, so
/// the look of inputs can be tuned without affecting cards, menus or other surfaces.
///
/// [hoverOverlay] and [pressedOverlay] are translucent tints that are composited **on top of**
/// the current fill with [Color.alphaBlend], so a hovered field never depends on, or collides
/// with, a specific background color (for example, hovering an errored field stays red-tinted).
@immutable
class LayrzInputColorTokens {
  /// Resting fill. Also used for read-only fields, which are not interactive but not disabled.
  final Color idle;

  /// Fill while the field is focused.
  final Color focused;

  /// Fill while the field is disabled.
  final Color disabled;

  /// Fill while the field shows validation errors.
  final Color error;

  /// Translucent tint composited on top of the current fill while hovered.
  final Color hoverOverlay;

  /// Translucent tint composited on top of the current fill while pressed.
  final Color pressedOverlay;

  /// Creates a new [LayrzInputColorTokens] with every color explicitly set.
  const LayrzInputColorTokens({
    required this.idle,
    required this.focused,
    required this.disabled,
    required this.error,
    required this.hoverOverlay,
    required this.pressedOverlay,
  });

  /// Light appearance input colors.
  const LayrzInputColorTokens.light()
    : idle = const Color(0xFFF7F7F7),
      focused = const Color(0xFFF7F7F7),
      disabled = const Color(0xFFF7F7F7),
      error = const Color(0xFFFFEBEE),
      hoverOverlay = const Color(0x0A000000),
      pressedOverlay = const Color(0x14000000);

  /// BETA dark appearance input colors.
  const LayrzInputColorTokens.dark()
    : idle = const Color(0xFF322F35),
      focused = const Color(0xFF322F35),
      disabled = const Color(0xFF322F35),
      error = const Color(0xFF513235),
      hoverOverlay = const Color(0x0FFFFFFF),
      pressedOverlay = const Color(0x1AFFFFFF);

  /// Returns a copy of these tokens with the given colors replaced.
  LayrzInputColorTokens copyWith({
    Color? idle,
    Color? focused,
    Color? disabled,
    Color? error,
    Color? hoverOverlay,
    Color? pressedOverlay,
  }) {
    return LayrzInputColorTokens(
      idle: idle ?? this.idle,
      focused: focused ?? this.focused,
      disabled: disabled ?? this.disabled,
      error: error ?? this.error,
      hoverOverlay: hoverOverlay ?? this.hoverOverlay,
      pressedOverlay: pressedOverlay ?? this.pressedOverlay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzInputColorTokens &&
          runtimeType == other.runtimeType &&
          idle == other.idle &&
          focused == other.focused &&
          disabled == other.disabled &&
          error == other.error &&
          hoverOverlay == other.hoverOverlay &&
          pressedOverlay == other.pressedOverlay;

  @override
  int get hashCode => Object.hash(idle, focused, disabled, error, hoverOverlay, pressedOverlay);
}
