import 'package:flutter/widgets.dart';

import 'theme_data.dart';

export 'theme_data.dart';

/// [InheritedTheme] that propagates [LayrzThemeData] down the widget tree.
///
/// This widget extends [InheritedTheme] (rather than plain [InheritedWidget]) so that
/// the theme survives route and overlay boundaries. When Flutter crosses an [Overlay]
/// boundary (as with dialogs, tooltips, menus, and dropdowns) or a route boundary,
/// [InheritedTheme.wrap] is called to reinstall the theme below the new context, keeping
/// [LayrzTheme.of(context)] working inside dialogs and other overlays.
///
/// Access via [LayrzTheme.of] or [LayrzTheme.maybeOf].
/// [LayrzApp] installs this automatically — consumers rarely need to insert it directly.
class LayrzTheme extends InheritedTheme {
  /// The theme data to propagate to all descendants.
  final LayrzThemeData data;

  /// Creates a [LayrzTheme] widget.
  ///
  /// The [data] and [child] arguments are required.
  const LayrzTheme({super.key, required this.data, required super.child});

  /// Returns the nearest [LayrzThemeData], throwing if none is found.
  static LayrzThemeData of(BuildContext context) {
    final theme = maybeOf(context);
    assert(
      theme != null,
      'No LayrzTheme found in the widget tree. Wrap your app with LayrzApp.',
    );
    return theme!;
  }

  /// Returns the nearest [LayrzThemeData], or null if none is found.
  static LayrzThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LayrzTheme>()?.data;
  }

  @override
  Widget wrap(BuildContext context, Widget child) => LayrzTheme(data: data, child: child);

  @override
  bool updateShouldNotify(LayrzTheme oldWidget) => data != oldWidget.data;
}
