import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/login/password_strength.dart';
import 'package:layrz_ui/src/inputs/src/login/password_strength_meter.dart';
import 'package:layrz_ui/src/theme/theme.dart';

import '../../helpers/pump_themed.dart';

/// Sets a fixed, explicit desktop viewport for the test and schedules its teardown.
///
/// See CLAUDE.md's testing traps: the default 800x600 test surface sits below the
/// 960px `isCompact` threshold, so every test in this file pins an explicit size
/// rather than relying on the default.
void _setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Walks the render tree under [finder] and collects the fill [Color] of every
/// [DecoratedBox]/[Container] segment the meter renders, in build order.
///
/// The meter paints each segment via an [AnimatedContainer], which is itself backed
/// by a plain [Container] internally; this collects the [BoxDecoration.color] of
/// every [DecoratedBox] found, which is the segment fill colors in left-to-right
/// order.
List<Color?> _segmentColors(WidgetTester tester) {
  final boxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
  return boxes.map((box) {
    final decoration = box.decoration;
    if (decoration is BoxDecoration) {
      return decoration.color;
    }
    return null;
  }).toList();
}

void main() {
  group('LayrzPasswordStrengthMeter construction', () {
    test('asserts exactly one of strength/password via the named constructors', () {
      // The unnamed constructor requires `strength`; the `.fromPassword` constructor
      // requires `password`. Each constructor's own required parameter enforces the
      // "exactly one" contract at compile time, so there is no runtime path that
      // supplies both or neither through the public API.
      const byStrength = LayrzPasswordStrengthMeter(strength: LayrzPasswordStrength.strong);
      const byPassword = LayrzPasswordStrengthMeter.fromPassword(password: 'Abcdefgh1!');

      expect(byStrength.strength, LayrzPasswordStrength.strong);
      expect(byStrength.password, isNull);
      expect(byPassword.password, 'Abcdefgh1!');
      expect(byPassword.strength, isNull);
    });
  });

  group('LayrzPasswordStrengthMeter rendering', () {
    testWidgets('renders without error for every LayrzPasswordStrength value', (tester) async {
      _setDesktopViewport(tester);

      for (final value in LayrzPasswordStrength.values) {
        await pumpThemed(tester, LayrzPasswordStrengthMeter(strength: value));
        expect(find.byType(LayrzPasswordStrengthMeter), findsOneWidget);
      }
    });

    testWidgets('.fromPassword derives strength from the raw password text', (tester) async {
      _setDesktopViewport(tester);

      // 'abcdefg' (7 lowercase-only chars) scores weak per password_strength_test.dart.
      await pumpThemed(tester, const LayrzPasswordStrengthMeter.fromPassword(password: 'abcdefg'));

      final theme = LayrzTheme.of(tester.element(find.byType(LayrzPasswordStrengthMeter)));
      final colors = theme.tokens.colors;
      final segmentColors = _segmentColors(tester);

      // weak fills exactly 1 of 3 segments, in the informational (not danger) color.
      final filledCount = segmentColors.where((c) => c == colors.info.shade500).length;
      expect(filledCount, 1);
      expect(segmentColors, isNot(contains(colors.danger.shade500)));
    });

    testWidgets('empty strength fills zero segments', (tester) async {
      _setDesktopViewport(tester);

      await pumpThemed(tester, const LayrzPasswordStrengthMeter(strength: LayrzPasswordStrength.empty));

      final theme = LayrzTheme.of(tester.element(find.byType(LayrzPasswordStrengthMeter)));
      final colors = theme.tokens.colors;
      final segmentColors = _segmentColors(tester);

      expect(segmentColors.every((c) => c == colors.fg4), isTrue);
    });

    testWidgets('weak strength fills exactly 1 of 3 segments', (tester) async {
      _setDesktopViewport(tester);

      await pumpThemed(tester, const LayrzPasswordStrengthMeter(strength: LayrzPasswordStrength.weak));

      final theme = LayrzTheme.of(tester.element(find.byType(LayrzPasswordStrengthMeter)));
      final colors = theme.tokens.colors;
      final segmentColors = _segmentColors(tester);

      expect(segmentColors.where((c) => c == colors.info.shade500).length, 1);
      expect(segmentColors.where((c) => c == colors.fg4).length, 2);
    });

    testWidgets('medium strength fills exactly 2 of 3 segments', (tester) async {
      _setDesktopViewport(tester);

      await pumpThemed(tester, const LayrzPasswordStrengthMeter(strength: LayrzPasswordStrength.medium));

      final theme = LayrzTheme.of(tester.element(find.byType(LayrzPasswordStrengthMeter)));
      final colors = theme.tokens.colors;
      final segmentColors = _segmentColors(tester);

      expect(segmentColors.where((c) => c == colors.info.shade700).length, 2);
      expect(segmentColors.where((c) => c == colors.fg4).length, 1);
    });

    testWidgets('strong strength fills all 3 of 3 segments', (tester) async {
      _setDesktopViewport(tester);

      await pumpThemed(tester, const LayrzPasswordStrengthMeter(strength: LayrzPasswordStrength.strong));

      final theme = LayrzTheme.of(tester.element(find.byType(LayrzPasswordStrengthMeter)));
      final colors = theme.tokens.colors;
      final segmentColors = _segmentColors(tester);

      expect(segmentColors.where((c) => c == colors.success.shade500).length, 3);
      expect(segmentColors.where((c) => c == colors.fg4).length, 0);
    });

    testWidgets('NEVER uses the danger color for any strength level, including weak', (tester) async {
      _setDesktopViewport(tester);

      final theme = LayrzThemeData.light();
      final colors = theme.tokens.colors;
      final dangerShades = {
        colors.danger.shade50,
        colors.danger.shade100,
        colors.danger.shade200,
        colors.danger.shade300,
        colors.danger.shade400,
        colors.danger.shade500,
        colors.danger.shade600,
        colors.danger.shade700,
        colors.danger.shade800,
        colors.danger.shade900,
      };

      for (final value in LayrzPasswordStrength.values) {
        await pumpThemed(tester, LayrzPasswordStrengthMeter(strength: value), theme: theme);
        final segmentColors = _segmentColors(tester);
        expect(
          segmentColors.any((c) => c != null && dangerShades.contains(c)),
          isFalse,
          reason: 'LayrzPasswordStrengthMeter must never render a danger-colored segment for $value',
        );
      }
    });

    testWidgets('showLabel=false hides the text label but keeps the segment track', (tester) async {
      _setDesktopViewport(tester);

      await pumpThemed(
        tester,
        const LayrzPasswordStrengthMeter(strength: LayrzPasswordStrength.strong, showLabel: false),
      );

      expect(find.textContaining('Password Length'), findsNothing);
      expect(find.byType(LayrzPasswordStrengthMeter), findsOneWidget);
    });

    testWidgets('showLabel=true (default) renders a label containing the level name', (tester) async {
      _setDesktopViewport(tester);

      await pumpThemed(tester, const LayrzPasswordStrengthMeter(strength: LayrzPasswordStrength.strong));

      expect(find.textContaining('Strong'), findsOneWidget);
    });
  });

  group('LayrzPasswordStrengthMeter accessibility', () {
    testWidgets('exposes a single labelled, non-interactive semantics container', (tester) async {
      _setDesktopViewport(tester);
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(tester, const LayrzPasswordStrengthMeter(strength: LayrzPasswordStrength.medium));

        final semanticsNode = tester.getSemantics(
          find.descendant(of: find.byType(LayrzPasswordStrengthMeter), matching: find.byType(Semantics)).first,
        );

        expect(
          semanticsNode,
          matchesSemantics(
            label: 'Password Length: Medium',
            hasTapAction: false,
            hasToggledState: false,
            isFocusable: false,
          ),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
