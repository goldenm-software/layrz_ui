import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import 'fake_font_handler.dart';

/// Pumps a widget into a full [LayrzApp] hierarchy with theme and app infrastructure.
///
/// This helper is used for tests that require full app-level features:
/// - **[WidgetsApp]**: enables [TapRegionSurface], focus handling, and shortcut scaffolding
/// - **[LayrzTheme]**: provides design tokens and theming context
/// - **Keyboard and gesture handling**: supports Escape key dismissal and tap-outside detection
///
/// Unlike [pumpThemed], which provides a minimal tree, [pumpThemedApp] wraps the child
/// in a real [LayrzApp], bringing full app-level semantics. Use this for:
/// - Tests that rely on Escape key or keyboard shortcuts
/// - Tests that require tap-outside (tap region) dismissal
/// - Tests of overlay-based widgets that need app-level focus/event handling
///
/// Usage:
/// ```dart
/// testWidgets('menu closes on Escape', (tester) async {
///   await pumpThemedApp(
///     tester,
///     LayrzDropdownMenu(
///       items: [...],
///       builder: (context, controller) => LayrzButton(
///         labelText: 'Open',
///         onTap: controller.open,
///       ),
///     ),
///   );
///   // ...
/// });
/// ```
Future<void> pumpThemedApp(
  WidgetTester tester,
  Widget child, {
  LayrzThemeData? theme,
}) async {
  await tester.pumpWidget(
    LayrzApp(
      home: Center(child: child),
      theme: theme ?? LayrzThemeData.light(fontHandler: const FakeFontHandler()),
      debugShowCheckedModeBanner: false,
    ),
  );
  // Additional pump to allow the tree to fully settle and semantics to build.
  await tester.pump();
}
