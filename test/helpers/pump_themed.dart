import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import 'fake_font_handler.dart';

/// Pumps a widget into a themed [Localizations] + [LayrzTheme] + [Overlay] hierarchy.
///
/// This helper wraps [child] with the minimal tree needed for widget testing:
/// 1. **[Localizations]**: provides localization support via [DefaultWidgetsLocalizations] and [LayrzUiL10nDelegate].
///    This widget also provides [Directionality] (LTR) based on the locale.
/// 2. **[LayrzTheme]**: provides design tokens and theming context.
/// 3. **[Overlay]**: MANDATORY for widgets that use [RawTooltip], which asserts
///    an [Overlay] ancestor via [debugCheckHasOverlay]. Without this, Fab tests
///    will fail with a confusing "No Overlay widget found" assertion.
/// 4. **[Center]**: centers the child for easier visibility in test output.
///
/// **Why [Overlay] is essential**: [RawTooltip] is used by [LayrzButton.Fab]
/// variants to show tooltips on long-press. [RawTooltip] internally calls
/// [debugCheckHasOverlay] in its build method, which asserts that an [Overlay]
/// widget exists in the ancestor tree. Without it, every Fab test will fail with
/// a runtime assertion before even building the button. The Overlay is created
/// with a single dummy entry that is replaced by the actual content.
///
/// Usage:
/// ```dart
/// testWidgets('button renders', (tester) async {
///   await pumpThemed(tester, LayrzButton(labelText: 'Test', onTap: () {}));
///   expect(find.text('Test'), findsOneWidget);
/// });
/// ```
Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  LayrzThemeData? theme,
}) async {
  await tester.pumpWidget(
    Localizations(
      locale: const Locale('en'),
      delegates: const [
        DefaultWidgetsLocalizations.delegate,
        LayrzUiL10nDelegate(),
      ],
      child: LayrzTheme(
        data: theme ?? LayrzThemeData.light(fontHandler: const FakeFontHandler()),
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => Center(child: child),
            ),
          ],
        ),
      ),
    ),
  );
  // Additional pump to allow the tree to fully settle and semantics to build.
  await tester.pump();
}
