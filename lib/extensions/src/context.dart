import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';

/// Convenience extensions on [BuildContext] for quick access to the active
/// [LayrzThemeData] and common derived styles.
extension LayrzContextExtensions on BuildContext {
  /// The resolved [LayrzThemeData] from the nearest [LayrzTheme] ancestor.
  LayrzThemeData get theme => LayrzTheme.of(this);

  /// Whether the active theme has [Brightness.dark].
  bool get isDark => LayrzTheme.of(this).brightness == Brightness.dark;

  /// Primary brand color from the active theme.
  Color get primaryColor => LayrzTheme.of(this).primaryColor;

  /// Bold title text style derived from [LayrzThemeData.textTheme].
  TextStyle get titleStyle => LayrzTheme.of(this).textStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      );

  /// Bold subtitle text style derived from [LayrzThemeData.textTheme].
  TextStyle get subtitleStyle => LayrzTheme.of(this).textStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      );

  /// Standard body text style from [LayrzThemeData.textTheme].
  TextStyle get bodyStyle => LayrzTheme.of(this).textStyle;
}
