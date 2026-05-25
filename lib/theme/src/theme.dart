import 'package:flutter/widgets.dart';

import 'theme_data.dart';

export 'theme_data.dart';

/// [InheritedWidget] that propagates [LayrzThemeData] down the widget tree.
///
/// Access via [LayrzTheme.of] or [LayrzTheme.maybeOf].
/// [LayrzApp] installs this automatically — consumers rarely need to insert it directly.
class LayrzTheme extends InheritedWidget {
  /// The theme data to propagate to all descendants.
  final LayrzThemeData data;

  const LayrzTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// Returns the nearest [LayrzThemeData], throwing if none is found.
  static LayrzThemeData of(BuildContext context) {
    final theme = maybeOf(context);
    assert(theme != null, 'No LayrzTheme found in the widget tree. Wrap your app with LayrzApp.');
    return theme!;
  }

  /// Returns the nearest [LayrzThemeData], or null if none is found.
  static LayrzThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LayrzTheme>()?.data;
  }

  @override
  bool updateShouldNotify(LayrzTheme oldWidget) => data != oldWidget.data;
}
