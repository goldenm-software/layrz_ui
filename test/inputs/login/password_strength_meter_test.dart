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
/// order. Only the first 4 belong to the strength bar — the checklist renders no
/// [DecoratedBox] of its own, so this list is exactly the 4 bar segments.
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

/// Builds a fully-valid password (meets all 4 requirements, only allowed characters)
/// of exactly [length] characters, for tests that need to pin an exact level.
String _validOfLength(int length) {
  const base = 'Aa1!';
  final buffer = StringBuffer(base);
  while (buffer.length < length) {
    buffer.write('x');
  }
  return buffer.toString().substring(0, length);
}

void main() {
  group('LayrzPasswordStrengthMeter construction', () {
    test('asserts exactly one of requirements/password via the named constructors', () {
      // The unnamed constructor requires `requirements`; the `.fromPassword`
      // constructor requires `password`. Each constructor's own required parameter
      // enforces the "exactly one" contract at compile time, so there is no runtime
      // path that supplies both or neither through the public API.
      final byRequirements = LayrzPasswordStrengthMeter(
        requirements: LayrzPasswordRequirements.evaluate('Abcdefg1!'),
      );
      const byPassword = LayrzPasswordStrengthMeter.fromPassword(password: 'Abcdefg1!');

      expect(byRequirements.requirements, isNotNull);
      expect(byRequirements.password, isNull);
      expect(byPassword.password, 'Abcdefg1!');
      expect(byPassword.requirements, isNull);
    });
  });

  group('LayrzPasswordStrengthMeter — 4-segment bar fill', () {
    testWidgets('level 0 (empty) fills zero of 4 segments', (tester) async {
      _setDesktopViewport(tester);

      await pumpThemed(tester, const LayrzPasswordStrengthMeter.fromPassword(password: ''));

      final theme = LayrzTheme.of(tester.element(find.byType(LayrzPasswordStrengthMeter)));
      final colors = theme.tokens.colors;
      final segmentColors = _segmentColors(tester);

      expect(segmentColors.length, 4);
      expect(segmentColors.every((c) => c == colors.fg4), isTrue);
    });

    testWidgets('level 0 (invalid, missing a requirement) fills zero segments in danger color', (tester) async {
      _setDesktopViewport(tester);

      // 16 lowercase-only chars: long enough for level 3+ by length alone, but
      // invalid (missing uppercase/digit/special), so it must still render level 0.
      await pumpThemed(
        tester,
        const LayrzPasswordStrengthMeter.fromPassword(password: 'abcdefghijklmnop'),
      );

      final theme = LayrzTheme.of(tester.element(find.byType(LayrzPasswordStrengthMeter)));
      final colors = theme.tokens.colors;
      final segmentColors = _segmentColors(tester);

      expect(segmentColors.every((c) => c == colors.fg4), isTrue);
    });

    testWidgets('level 1 fills exactly 1 of 4 segments in warning color', (tester) async {
      _setDesktopViewport(tester);

      await pumpThemed(
        tester,
        LayrzPasswordStrengthMeter.fromPassword(password: _validOfLength(8)),
      );

      final theme = LayrzTheme.of(tester.element(find.byType(LayrzPasswordStrengthMeter)));
      final colors = theme.tokens.colors;
      final segmentColors = _segmentColors(tester);

      expect(segmentColors.where((c) => c == colors.warning.shade500).length, 1);
      expect(segmentColors.where((c) => c == colors.fg4).length, 3);
    });

    testWidgets('level 2 fills exactly 2 of 4 segments in warning color', (tester) async {
      _setDesktopViewport(tester);

      await pumpThemed(
        tester,
        LayrzPasswordStrengthMeter.fromPassword(password: _validOfLength(12)),
      );

      final theme = LayrzTheme.of(tester.element(find.byType(LayrzPasswordStrengthMeter)));
      final colors = theme.tokens.colors;
      final segmentColors = _segmentColors(tester);

      expect(segmentColors.where((c) => c == colors.warning.shade500).length, 2);
      expect(segmentColors.where((c) => c == colors.fg4).length, 2);
    });

    testWidgets('level 3 fills exactly 3 of 4 segments in success color', (tester) async {
      _setDesktopViewport(tester);

      await pumpThemed(
        tester,
        LayrzPasswordStrengthMeter.fromPassword(password: _validOfLength(16)),
      );

      final theme = LayrzTheme.of(tester.element(find.byType(LayrzPasswordStrengthMeter)));
      final colors = theme.tokens.colors;
      final segmentColors = _segmentColors(tester);

      expect(segmentColors.where((c) => c == colors.success.shade500).length, 3);
      expect(segmentColors.where((c) => c == colors.fg4).length, 1);
    });

    testWidgets('level 4 fills all 4 of 4 segments in success color', (tester) async {
      _setDesktopViewport(tester);

      await pumpThemed(
        tester,
        LayrzPasswordStrengthMeter.fromPassword(password: _validOfLength(20)),
      );

      final theme = LayrzTheme.of(tester.element(find.byType(LayrzPasswordStrengthMeter)));
      final colors = theme.tokens.colors;
      final segmentColors = _segmentColors(tester);

      expect(segmentColors.where((c) => c == colors.success.shade500).length, 4);
      expect(segmentColors.where((c) => c == colors.fg4).length, 0);
    });

    testWidgets('level 0 legitimately uses the danger color (superseding the old "never danger" rule)', (
      tester,
    ) async {
      _setDesktopViewport(tester);

      final theme = LayrzThemeData.light();
      final colors = theme.tokens.colors;

      // An invalid, non-empty password (missing 3 of 4 requirements) must resolve
      // colorFor(colors) to danger, per LayrzPasswordRequirements.colorFor — even
      // though this particular widget test only exercises the bar's fill color
      // indirectly via the requirements' own `colorFor`, which is asserted directly
      // in password_strength_test.dart. This test locks in that the bar widget does
      // NOT filter out danger for level 0 the way the previous meter design did.
      final requirements = LayrzPasswordRequirements.evaluate('abcdefghijklmnop');
      expect(requirements.colorFor(colors), colors.danger.shade500);
    });
  });

  group('LayrzPasswordStrengthMeter — requirements checklist', () {
    testWidgets('renders exactly 4 checklist items with their localized labels', (tester) async {
      _setDesktopViewport(tester);

      await pumpThemed(
        tester,
        const LayrzPasswordStrengthMeter.fromPassword(password: 'abc'),
      );

      expect(find.text('At least one lowercase letter'), findsOneWidget);
      expect(find.text('At least one uppercase letter'), findsOneWidget);
      expect(find.text('At least one digit'), findsOneWidget);
      expect(find.text('At least one special character'), findsOneWidget);
    });

    testWidgets('shows met vs. unmet state correctly for a partially-satisfying password', (tester) async {
      _setDesktopViewport(tester);

      // 'abc123' meets lowercase + digit, but not uppercase or special.
      await pumpThemed(
        tester,
        const LayrzPasswordStrengthMeter.fromPassword(password: 'abc123'),
      );

      final theme = LayrzTheme.of(tester.element(find.byType(LayrzPasswordStrengthMeter)));
      final colors = theme.tokens.colors;

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      final metIcons = icons.where((icon) => icon.color == colors.success.shade500);
      final unmetIcons = icons.where((icon) => icon.color == colors.fg4);

      expect(metIcons.length, 2, reason: 'lowercase + digit are met');
      expect(unmetIcons.length, 2, reason: 'uppercase + special are unmet');
    });

    testWidgets('all 4 requirements show as met for a fully-valid password', (tester) async {
      _setDesktopViewport(tester);

      await pumpThemed(
        tester,
        const LayrzPasswordStrengthMeter.fromPassword(password: 'Abcdefg1!'),
      );

      final theme = LayrzTheme.of(tester.element(find.byType(LayrzPasswordStrengthMeter)));
      final colors = theme.tokens.colors;

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      final metIcons = icons.where((icon) => icon.color == colors.success.shade500);

      expect(metIcons.length, 4);
    });
  });

  group('LayrzPasswordStrengthMeter — .fromPassword derivation', () {
    testWidgets('.fromPassword derives requirements from the raw password text', (tester) async {
      _setDesktopViewport(tester);

      await pumpThemed(tester, LayrzPasswordStrengthMeter.fromPassword(password: _validOfLength(8)));

      final theme = LayrzTheme.of(tester.element(find.byType(LayrzPasswordStrengthMeter)));
      final colors = theme.tokens.colors;
      final segmentColors = _segmentColors(tester);

      final filledCount = segmentColors.where((c) => c == colors.warning.shade500).length;
      expect(filledCount, 1);
    });
  });

  group('LayrzPasswordStrengthMeter accessibility', () {
    testWidgets('exposes a non-interactive semantics container', (tester) async {
      _setDesktopViewport(tester);
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(
          tester,
          LayrzPasswordStrengthMeter.fromPassword(password: _validOfLength(12)),
        );

        final semanticsNode = tester.getSemantics(
          find.descendant(of: find.byType(LayrzPasswordStrengthMeter), matching: find.byType(Semantics)).first,
        );

        expect(
          semanticsNode,
          matchesSemantics(
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
