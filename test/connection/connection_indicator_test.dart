import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  final fixedNow = DateTime(2026, 1, 1, 12, 0, 0);

  group('LayrzConnectionIndicator construction asserts', () {
    test('.dot with a non-null child throws an AssertionError', () {
      expect(
        () => LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.dot,
          child: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });

    test('.full with a null child throws an AssertionError', () {
      expect(
        () => LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.full,
        ),
        throwsAssertionError,
      );
    });

    test('.dot with no child does not throw', () {
      expect(
        () => LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.dot,
        ),
        returnsNormally,
      );
    });

    test('.full with a child does not throw', () {
      expect(
        () => LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.full,
          child: const SizedBox(),
        ),
        returnsNormally,
      );
    });
  });

  group('LayrzConnectionIndicator.dot rendering', () {
    guardedTestWidgets('renders a badge dot and a tooltip-wrapped Semantics label', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.dot,
          clock: () => fixedNow,
        ),
      );

      expect(find.byType(LayrzBadgeVisual), findsOneWidget);
      expect(find.byType(LayrzTooltip), findsOneWidget);
    });

    guardedTestWidgets('renders the success color when online (0 elapsed)', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.dot,
          clock: () => fixedNow,
        ),
        theme: theme,
      );

      final badge = tester.widget<LayrzBadgeVisual>(find.byType(LayrzBadgeVisual));
      expect(badge.color, theme.tokens.colors.success);
    });

    guardedTestWidgets('renders the warning color when idle (20 minutes elapsed)', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      final receivedAt = fixedNow.subtract(const Duration(minutes: 20));
      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: receivedAt,
          mode: LayrzConnectionIndicatorMode.dot,
          clock: () => fixedNow,
        ),
        theme: theme,
      );

      final badge = tester.widget<LayrzBadgeVisual>(find.byType(LayrzBadgeVisual));
      expect(badge.color, theme.tokens.colors.warning);
    });

    guardedTestWidgets('renders the danger color when offline (90 minutes elapsed)', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      final receivedAt = fixedNow.subtract(const Duration(minutes: 90));
      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: receivedAt,
          mode: LayrzConnectionIndicatorMode.dot,
          clock: () => fixedNow,
        ),
        theme: theme,
      );

      final badge = tester.widget<LayrzBadgeVisual>(find.byType(LayrzBadgeVisual));
      expect(badge.color, theme.tokens.colors.danger);
    });

    guardedTestWidgets('renders the fg1 color when disconnected (40 days elapsed)', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      final receivedAt = fixedNow.subtract(const Duration(days: 40));
      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: receivedAt,
          mode: LayrzConnectionIndicatorMode.dot,
          clock: () => fixedNow,
        ),
        theme: theme,
      );

      final badge = tester.widget<LayrzBadgeVisual>(find.byType(LayrzBadgeVisual));
      expect(badge.color, theme.tokens.colors.fg1);
    });

    guardedTestWidgets('renders the contextual color when receivedAt is null (no data)', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: null,
          mode: LayrzConnectionIndicatorMode.dot,
          clock: () => fixedNow,
        ),
        theme: theme,
      );

      final badge = tester.widget<LayrzBadgeVisual>(find.byType(LayrzBadgeVisual));
      expect(badge.color, theme.tokens.colors.contextual);
    });
  });

  group('LayrzConnectionIndicator.full rendering', () {
    guardedTestWidgets('wraps the given child with a colored chrome', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.full,
          clock: () => fixedNow,
          child: const Text('unit-42'),
        ),
        theme: theme,
      );

      expect(find.text('unit-42'), findsOneWidget);

      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.color, theme.tokens.colors.success);
    });

    guardedTestWidgets('reflects the offline state color when stale', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      final receivedAt = fixedNow.subtract(const Duration(minutes: 90));
      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: receivedAt,
          mode: LayrzConnectionIndicatorMode.full,
          clock: () => fixedNow,
          child: const Text('unit-99'),
        ),
        theme: theme,
      );

      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.color, theme.tokens.colors.danger);
    });

    guardedTestWidgets('forces contrastColor on a child Text with its own explicit dark color', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      // 40 days elapsed resolves to the disconnected state, whose color is
      // the dark `fg1` token — the case that was unreadable before the fix,
      // since the child's own explicit `fg1` color used to win over
      // `contrastColor` under `DefaultTextStyle.merge`.
      final receivedAt = fixedNow.subtract(const Duration(days: 40));
      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: receivedAt,
          mode: LayrzConnectionIndicatorMode.full,
          clock: () => fixedNow,
          child: Text('unit-40', style: TextStyle(color: theme.tokens.colors.fg1)),
        ),
        theme: theme,
      );

      final defaultTextStyle = tester.widget<DefaultTextStyle>(
        find.ancestor(of: find.text('unit-40'), matching: find.byType(DefaultTextStyle)).first,
      );
      expect(defaultTextStyle.style.color, theme.tokens.colors.fg1.contrastColor);
      expect(defaultTextStyle.style.color, isNot(theme.tokens.colors.fg1));
    });

    guardedTestWidgets('does not render LayrzBadgeVisual or LayrzTooltip in full mode', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.full,
          clock: () => fixedNow,
          child: const Text('unit-1'),
        ),
      );

      expect(find.byType(LayrzBadgeVisual), findsNothing);
      expect(find.byType(LayrzTooltip), findsNothing);
    });
  });

  group('LayrzConnectionIndicator timer lifecycle', () {
    guardedTestWidgets('the periodic timer does not leak after dispose', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.dot,
          clock: () => fixedNow,
        ),
      );

      // Remove the widget from the tree, triggering dispose().
      await tester.pumpWidget(const SizedBox());

      // If the Timer.periodic were left running, pumping past its interval
      // with nothing left mounted would either throw or leave a pending
      // timer that fails the test via FlutterError.onError / pending timers
      // check. Both getting here without exception and the tester's own
      // pending-timer verification at tear-down prove no leak.
      await tester.pump(const Duration(minutes: 2));
      expect(tester.takeException(), isNull);
    });

    guardedTestWidgets('advancing past the tick interval keeps the widget mounted (no rebuild crash)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var now = fixedNow;
      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.dot,
          clock: () => now,
        ),
      );

      // Simulate elapsed wall-clock time by advancing the injected clock,
      // then let the periodic timer fire to trigger a rebuild against it.
      now = fixedNow.add(const Duration(minutes: 20));
      await tester.pump(kLayrzConnectionIndicatorTickInterval);

      expect(find.byType(LayrzBadgeVisual), findsOneWidget);
    });
  });

  group('LayrzConnectionIndicator accessibility', () {
    guardedTestWidgets('the dot announces the state label and time-ago via Semantics', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzConnectionIndicator(
            receivedAt: fixedNow.subtract(const Duration(minutes: 2)),
            mode: LayrzConnectionIndicatorMode.dot,
            clock: () => fixedNow,
          ),
        );

        expect(
          tester.getSemantics(find.byType(LayrzBadgeVisual)),
          matchesSemantics(label: 'Connected (2 minutes ago)'),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the no-data dot announces just the "No data" label', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzConnectionIndicator(
            receivedAt: null,
            mode: LayrzConnectionIndicatorMode.dot,
            clock: () => fixedNow,
          ),
        );

        expect(
          tester.getSemantics(find.byType(LayrzBadgeVisual)),
          matchesSemantics(label: 'No data'),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
