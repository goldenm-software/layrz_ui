import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/theme/theme.dart';

/// A [PreviewThemeData] implementation that applies the layrz_ui light-mode theme
/// to Flutter 3.47+ widget previews.
///
/// This class extends the SDK's [PreviewThemeData] (an `abstract base class`) to provide
/// a complete light-theme context for `@Preview` annotations. It reproduces the exact
/// widget nesting that [LayrzApp] installs at the root, so previewed widgets render
/// identically to the production app rather than with SDK defaults.
///
/// Usage with `@Preview` annotations:
/// ```dart
/// import 'package:flutter/widget_previews.dart';
/// import 'package:layrz_ui/preview.dart';
///
/// @Preview(
///   name: 'Light',
///   theme: LayrzPreviewTheme.light,
/// )
/// Widget previewMyWidget() => MyWidget(/* ... */);
/// ```
///
/// The [apply] method nests the child in the exact same layers as the nesting
/// [LayrzApp] installs at the root:
/// - [LayrzTheme] to propagate theme data
/// - [DefaultTextStyle] to set base typography
/// - [IconTheme] to configure icon styling
/// - [ColoredBox] to paint the background
///
/// The theme's data can be accessed via [LayrzTheme.of] or the `tokens` extension
/// method inside any descendant.
final class LayrzPreviewTheme extends PreviewThemeData {
  /// The theme data applied to all descendants in [apply].
  final LayrzThemeData data;

  /// Creates a [LayrzPreviewTheme] wrapping the given [LayrzThemeData].
  ///
  /// [data] must be a complete [LayrzThemeData]; typically created via
  /// [LayrzThemeData.light()]. This constructor is const, which allows the
  /// static factory method [light] to produce a compile-time constant tear-off
  /// suitable for the `@Preview.theme` parameter.
  const LayrzPreviewTheme({required this.data});

  /// Creates a [LayrzPreviewTheme] with default light-mode design tokens.
  ///
  /// This static method constructs a new [LayrzPreviewTheme] wrapping a fresh
  /// [LayrzThemeData.light()] on each call. The tear-off `LayrzPreviewTheme.light`
  /// (the function itself) is a compile-time constant suitable for the
  /// `@Preview.theme` parameter:
  ///
  /// ```dart
  /// @Preview(theme: LayrzPreviewTheme.light)
  /// ```
  ///
  /// The return type is [PreviewThemeData] (the SDK interface), ensuring
  /// type-safe assignment to the annotation parameter.
  static PreviewThemeData light() => LayrzPreviewTheme(data: LayrzThemeData.light());

  /// Wraps the child widget in the full layrz_ui theme context.
  ///
  /// Applies the same nesting layers as the nesting [LayrzApp] installs at the root
  /// (minus app-level concerns like [ScrollConfiguration] and custom builder callbacks):
  ///
  /// 1. [LayrzTheme] — propagates the theme data to all descendants
  /// 2. [DefaultTextStyle] — installs the base text style
  /// 3. [IconTheme] — configures icon sizing and colour
  /// 4. [ColoredBox] — paints the background colour
  ///
  /// This ensures that previewed widgets have access to [LayrzTheme.of] and the
  /// `tokens` extension method, and that colours, typography, and icon rendering
  /// all match the production app.
  @override
  Widget apply(BuildContext context, Widget child) {
    return LayrzTheme(
      data: data,
      child: DefaultTextStyle(
        style: data.textStyle,
        child: IconTheme(
          data: data.iconTheme,
          child: ColoredBox(
            color: data.backgroundColor,
            child: child,
          ),
        ),
      ),
    );
  }
}
