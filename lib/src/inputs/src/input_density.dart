import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Centralized specification of all dimensions that change with dense mode.
///
/// Dense and comfortable modes differ in four dimensions: vertical padding,
/// icon size, text style (for hints and slot text), and the editable's own text style.
/// This class ensures all four are always in sync, and makes it impossible to miss
/// adding a new dimension — there is exactly one place to do it.
abstract class InputDensitySpec {
  /// The vertical padding inside the input field (top and bottom).
  double get verticalPadding;

  /// The size of icons in slots and state indicators.
  double get iconSize;

  /// The text style for input hints and slot text.
  TextStyle get textStyle;

  /// The text style for the editable value itself (EditableText.style).
  TextStyle get editableTextStyle;

  /// Creates the appropriate density spec for the given parameters.
  factory InputDensitySpec({
    required bool dense,
    required LayrzTokens tokens,
    IconThemeData? iconTheme,
  }) => dense ? _DenseSpec(tokens) : _ComfortableSpec(tokens, iconTheme);
}

/// Comfortable (normal) density specification.
class _ComfortableSpec implements InputDensitySpec {
  final LayrzTokens tokens;
  final IconThemeData? iconTheme;

  _ComfortableSpec(this.tokens, this.iconTheme);

  @override
  double get verticalPadding => tokens.spacing.sp10;

  @override
  double get iconSize => iconTheme?.size ?? (tokens.typography.body.fontSize ?? 16.0) + tokens.spacing.sp4;

  @override
  TextStyle get textStyle => tokens.typography.body.copyWith(
    fontSize: tokens.typography.title.fontSize,
  );

  @override
  TextStyle get editableTextStyle => tokens.typography.body.copyWith(
    fontSize: tokens.typography.title.fontSize,
  );
}

/// Dense (compact) density specification.
class _DenseSpec implements InputDensitySpec {
  final LayrzTokens tokens;

  _DenseSpec(this.tokens);

  @override
  double get verticalPadding => tokens.spacing.sp6;

  @override
  double get iconSize => kLayrzTextInputDenseIconSize;

  @override
  TextStyle get textStyle => tokens.typography.label;

  @override
  TextStyle get editableTextStyle => tokens.typography.label;
}
