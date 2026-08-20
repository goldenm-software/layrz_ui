import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/theme/theme.dart';

/// Creates a [LayrzPreviewTheme] with default light-mode design tokens.
///
/// This function is a top-level tear-off that returns a [PreviewThemeData] suitable
/// for use as the `theme:` parameter in `@Preview` annotations. The widget-preview
/// code generator can only serialize top-level function tear-offs (not static methods
/// on a class), so this top-level function is the working pattern for `@Preview`.
///
/// **Use this in your `@Preview` annotations:**
/// ```dart
/// import 'package:flutter/widget_previews.dart';
/// import 'package:layrz_ui/preview.dart';
///
/// @Preview(
///   name: 'Light',
///   theme: layrzPreviewLightTheme,
/// )
/// Widget previewMyWidget() => MyWidget(/* ... */);
/// ```
///
/// On each call, it constructs a new [LayrzPreviewTheme] wrapping a fresh
/// [LayrzThemeData.light()], ensuring previewed widgets render with the complete
/// layrz_ui light-mode theme (including [LayrzTheme], [DefaultTextStyle], [IconTheme],
/// and background color).
PreviewThemeData layrzPreviewLightTheme() => LayrzPreviewTheme(data: LayrzThemeData.light());

/// A [PreviewThemeData] implementation that applies the layrz_ui light-mode theme
/// to Flutter 3.47+ widget previews.
///
/// This class extends the SDK's [PreviewThemeData] (an `abstract base class`) to provide
/// a complete light-theme context for `@Preview` annotations. It reproduces the exact
/// widget nesting that [LayrzApp] installs at the root, so previewed widgets render
/// identically to the production app rather than with SDK defaults.
///
/// To use with `@Preview` annotations, use the top-level function [layrzPreviewLightTheme]
/// (not the static method [LayrzPreviewTheme.light], which the code generator cannot resolve):
///
/// ```dart
/// import 'package:flutter/widget_previews.dart';
/// import 'package:layrz_ui/preview.dart';
///
/// @Preview(
///   name: 'Light',
///   theme: layrzPreviewLightTheme,
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
  /// static factory method [light] to produce a compile-time constant tear-off.
  const LayrzPreviewTheme({required this.data});

  /// Creates a [LayrzPreviewTheme] with default light-mode design tokens.
  ///
  /// **Deprecated in favor of the top-level function [layrzPreviewLightTheme].** The
  /// widget-preview code generator can only serialize top-level function tear-offs (not
  /// static methods on a class), so `@Preview(theme: LayrzPreviewTheme.light)` will fail
  /// to compile. Use [layrzPreviewLightTheme] instead.
  ///
  /// This method is retained for backward compatibility in code that does not use `@Preview`.
  static PreviewThemeData light() => layrzPreviewLightTheme();

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
