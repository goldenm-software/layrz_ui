import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/theme/theme.dart';
import 'package:layrz_ui/src/tokenizer/tokenizer.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Convenience extensions on [BuildContext] for quick access to the active
/// [LayrzThemeData] and common derived styles.
extension LayrzContextExtensions on BuildContext {
  /// The resolved [LayrzThemeData] from the nearest [LayrzTheme] ancestor.
  LayrzThemeData get theme => LayrzTheme.of(this);

  /// The design token set from the active theme.
  ///
  /// Provides direct access to [LayrzThemeData.tokens]. This is the preferred
  /// way to access design values in new code.
  LayrzTokens get tokens => LayrzTheme.of(this).tokens;

  /// The active breakpoint band, resolved from the viewport width.
  ///
  /// Resolves the breakpoint band using the viewport width (from [MediaQuery.sizeOf]).
  /// This is always viewport-driven, not container-driven. Breakpoint bands are
  /// independent of a widget's own box width — they reflect global screen size.
  ///
  /// Returns one of [LayrzBreakpoint.xs], [LayrzBreakpoint.sm], [LayrzBreakpoint.md],
  /// [LayrzBreakpoint.lg], or [LayrzBreakpoint.xl].
  LayrzBreakpoint get breakpoint => LayrzTheme.of(this).tokens.breakpoints.bandAt(MediaQuery.sizeOf(this).width);

  /// The tokenizer for convenient access to design tokens via shortcuts.
  ///
  /// Provides both group getters (e.g., [LayrzTokenizer.colors]) and
  /// flat shortcuts (e.g., [LayrzTokenizer.primary]).
  LayrzTokenizer get tokenizer => LayrzTokenizer(tokens);

  /// The resolved [LayrzUiL10n] from the nearest [LayrzUiL10n] delegate.
  ///
  /// Provides access to all user-visible strings throughout layrz_ui.
  /// This is the preferred way to access localized strings in components.
  ///
  /// Example:
  /// ```dart
  /// final cancelText = context.l10n.actionCancel;
  /// ```
  LayrzUiL10n get l10n => LayrzUiL10n.of(this);

  /// Primary brand color from the active theme.
  Color get primaryColor => LayrzTheme.of(this).primaryColor;

  /// Bold title text style derived from [LayrzThemeData.textTheme].
  TextStyle get titleStyle => LayrzTheme.of(this).textStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold);

  /// Bold subtitle text style derived from [LayrzThemeData.textTheme].
  TextStyle get subtitleStyle => LayrzTheme.of(this).textStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold);

  /// Standard body text style from [LayrzThemeData.textTheme].
  TextStyle get bodyStyle => LayrzTheme.of(this).textStyle;

  /// Retrieves a registered theme extension, throwing if it is not found.
  ///
  /// This is the ergonomic entry point for accessing theme extensions from the
  /// widget tree. It delegates to [LayrzThemeData.extension].
  ///
  /// Throws an assertion error if the extension is not registered.
  ///
  /// Example:
  /// ```dart
  /// final extension = context.themeExtension<ButtonVariantsExtension>();
  /// ```
  T themeExtension<T extends LayrzThemeExtension<T>>() {
    return LayrzTheme.of(this).extension<T>();
  }

  /// Retrieves a registered theme extension, returning null if it is not found.
  ///
  /// This is the ergonomic entry point for optional access to theme extensions
  /// from the widget tree. It delegates to [LayrzThemeData.maybeExtension].
  ///
  /// Example:
  /// ```dart
  /// final extension = context.maybeThemeExtension<ButtonVariantsExtension>();
  /// if (extension != null) {
  ///   // Use the extension
  /// }
  /// ```
  T? maybeThemeExtension<T extends LayrzThemeExtension<T>>() {
    return LayrzTheme.of(this).maybeExtension<T>();
  }
}
