import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';
import '../helpers/root_semantics_node.dart';

/// Counts semantics nodes under [tester]'s current tree whose label exactly
/// equals [label].
///
/// Used to prove a single announcement string appears exactly once in the
/// semantics tree — guarding against a competing outer `Semantics` node
/// duplicating [LayrzBadge]'s own merged announcement (DESIGN "double
/// semantics" hazard: see `combobox_input_a11y_test.dart`'s identical
/// pattern).
int _countSemanticsWithExactLabel(WidgetTester tester, String label) {
  var count = 0;
  void walk(SemanticsNode node) {
    if (node.getSemanticsData().label == label) count++;
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(rootSemanticsNode());
  return count;
}

void main() {
  final fixedNow = DateTime(2026, 1, 1, 12, 0, 0);

  group('LayrzConnectionIndicator construction (no child-related asserts)', () {
    test('.full with a null child does not throw', () {
      expect(
        () => LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.full,
          clock: ValueNotifier<DateTime>(fixedNow),
        ),
        returnsNormally,
      );
    });

    test('.dot with no child does not throw', () {
      expect(
        () => LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.dot,
          clock: ValueNotifier<DateTime>(fixedNow),
        ),
        returnsNormally,
      );
    });

    test('.dot with a non-null child does not throw (dot-over-child overlay is legal)', () {
      expect(
        () => LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.dot,
          clock: ValueNotifier<DateTime>(fixedNow),
          child: const SizedBox(),
        ),
        returnsNormally,
      );
    });

    test('.full with a child does not throw', () {
      expect(
        () => LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.full,
          clock: ValueNotifier<DateTime>(fixedNow),
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
          clock: ValueNotifier<DateTime>(fixedNow),
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
          clock: ValueNotifier<DateTime>(fixedNow),
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
          clock: ValueNotifier<DateTime>(fixedNow),
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
          clock: ValueNotifier<DateTime>(fixedNow),
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
          clock: ValueNotifier<DateTime>(fixedNow),
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
          clock: ValueNotifier<DateTime>(fixedNow),
        ),
        theme: theme,
      );

      final badge = tester.widget<LayrzBadgeVisual>(find.byType(LayrzBadgeVisual));
      expect(badge.color, theme.tokens.colors.contextual);
    });
  });

  group('LayrzConnectionIndicator.full rendering', () {
    guardedTestWidgets('renders the resolved state label as a self-contained chip, with no child', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.full,
          clock: ValueNotifier<DateTime>(fixedNow),
        ),
        theme: theme,
      );

      expect(find.text('Connected'), findsOneWidget);

      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.color, theme.tokens.colors.success);
    });

    guardedTestWidgets('ignores a passed child entirely and renders the state label instead', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.full,
          clock: ValueNotifier<DateTime>(fixedNow),
          child: const Text('SHOULD_NOT_APPEAR'),
        ),
      );

      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('SHOULD_NOT_APPEAR'), findsNothing);
    });

    guardedTestWidgets('full-mode chrome is chip-shaped (r1 radius, not a fully-rounded pill)', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.full,
          clock: ValueNotifier<DateTime>(fixedNow),
        ),
        theme: theme,
      );

      final decoration = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration as BoxDecoration;

      // The chrome must use the chip's rounded-box r1 radius, never the pill
      // `full` radius — matching LayrzChip so it reads as a chip, not a pill.
      expect(decoration.borderRadius, BorderRadius.circular(theme.tokens.radius.r1));
      expect(
        decoration.borderRadius,
        isNot(BorderRadius.circular(theme.tokens.radius.full)),
        reason: 'full mode must not use the fully-rounded pill radius',
      );

      // And the compact chip vertical padding (sp1 / 2), not the taller sp1.
      final padding = tester.widget<Padding>(
        find.descendant(of: find.byType(DecoratedBox).first, matching: find.byType(Padding)).first,
      );
      expect(
        padding.padding,
        EdgeInsets.symmetric(horizontal: theme.tokens.spacing.sp2, vertical: theme.tokens.spacing.sp1 / 2),
      );
    });

    guardedTestWidgets('reflects the offline state color and label when stale', (tester) async {
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
          clock: ValueNotifier<DateTime>(fixedNow),
        ),
        theme: theme,
      );

      expect(find.text('Offline'), findsOneWidget);

      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.color, theme.tokens.colors.danger);
    });

    guardedTestWidgets('forces contrastColor on the state label text on the dark Disconnected chip', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      // 40 days elapsed resolves to the disconnected state, whose color is
      // the dark `fg1` token — contrastColor guarantees the chip's own label
      // text stays legible against it.
      final receivedAt = fixedNow.subtract(const Duration(days: 40));
      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: receivedAt,
          mode: LayrzConnectionIndicatorMode.full,
          clock: ValueNotifier<DateTime>(fixedNow),
        ),
        theme: theme,
      );

      final label = tester.widget<Text>(find.text('Disconnected'));
      expect(label.style?.color, theme.tokens.colors.fg1.contrastColor);
      expect(label.style?.color, isNot(theme.tokens.colors.fg1));
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
          clock: ValueNotifier<DateTime>(fixedNow),
        ),
      );

      expect(find.byType(LayrzBadgeVisual), findsNothing);
      expect(find.byType(LayrzTooltip), findsNothing);
    });

    guardedTestWidgets('the state label updates when the clock notifier resolves a different state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      // receivedAt stays fixed 2 minutes behind the clock's initial value —
      // resolves to online. Advancing the clock notifier alone past the
      // offline threshold must flip both the chip's color and its label.
      final receivedAt = fixedNow.subtract(const Duration(minutes: 2));
      final clock = ValueNotifier<DateTime>(fixedNow);
      addTearDown(clock.dispose);

      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: receivedAt,
          mode: LayrzConnectionIndicatorMode.full,
          clock: clock,
        ),
        theme: theme,
      );

      expect(find.text('Connected'), findsOneWidget);
      var decoration = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration as BoxDecoration;
      expect(decoration.color, theme.tokens.colors.success);

      clock.value = fixedNow.add(const Duration(hours: 3));
      await tester.pump();

      expect(find.text('Connected'), findsNothing);
      expect(find.text('Offline'), findsOneWidget);
      decoration = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration as BoxDecoration;
      expect(decoration.color, theme.tokens.colors.danger);
    });
  });

  group('LayrzConnectionIndicator reactive clock', () {
    guardedTestWidgets('rebuilds its state-dependent subtree when the clock notifier ticks, without owning '
        'a timer of its own', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      // receivedAt stays fixed 2 minutes behind the clock's initial value —
      // resolves to online. Advancing the clock notifier alone (never
      // touching receivedAt, and with no Timer anywhere in this test) past
      // the offline threshold must flip the resolved state, proving the
      // widget reacts purely to the caller-driven ValueNotifier.
      final receivedAt = fixedNow.subtract(const Duration(minutes: 2));
      final clock = ValueNotifier<DateTime>(fixedNow);
      addTearDown(clock.dispose);

      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: receivedAt,
          mode: LayrzConnectionIndicatorMode.dot,
          clock: clock,
        ),
        theme: theme,
      );

      final onlineBadge = tester.widget<LayrzBadgeVisual>(find.byType(LayrzBadgeVisual));
      expect(onlineBadge.color, theme.tokens.colors.success);

      // Push the notifier's value far enough past receivedAt to resolve to
      // offline, then pump — no Timer involved, purely the notifier's own
      // listener notification driving the rebuild.
      clock.value = fixedNow.add(const Duration(hours: 3));
      await tester.pump();

      final offlineBadge = tester.widget<LayrzBadgeVisual>(find.byType(LayrzBadgeVisual));
      expect(offlineBadge.color, theme.tokens.colors.danger);
    });
  });

  group('LayrzConnectionIndicator.dot with a child (badge overlay)', () {
    guardedTestWidgets('renders the child plus a LayrzBadge dot on its bottom-right corner', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.dot,
          clock: ValueNotifier<DateTime>(fixedNow),
          child: const Text('Asset A'),
        ),
        theme: theme,
      );

      expect(find.text('Asset A'), findsOneWidget);
      expect(find.byType(LayrzBadge), findsOneWidget);
      // LayrzBadge itself renders exactly one LayrzBadgeVisual internally for
      // its corner dot -- present here as a nested detail of LayrzBadge, not
      // a second, competing bare-dot rendering path.
      expect(find.byType(LayrzBadgeVisual), findsOneWidget);

      final badge = tester.widget<LayrzBadge>(find.byType(LayrzBadge));
      expect(badge.color, theme.tokens.colors.success);
      expect(badge.type, LayrzBadgeType.custom);
      expect(badge.alignment, LayrzBadgeAlignment.bottomRight);
    });

    guardedTestWidgets('without a child still renders the classic bare dot, not a LayrzBadge', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzConnectionIndicator(
          receivedAt: fixedNow,
          mode: LayrzConnectionIndicatorMode.dot,
          clock: ValueNotifier<DateTime>(fixedNow),
        ),
      );

      expect(find.byType(LayrzBadgeVisual), findsOneWidget);
      expect(find.byType(LayrzBadge), findsNothing);
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
            clock: ValueNotifier<DateTime>(fixedNow),
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
            clock: ValueNotifier<DateTime>(fixedNow),
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

    guardedTestWidgets('the dot-over-child announcement appears exactly once (no double semantics)', (
      tester,
    ) async {
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
            clock: ValueNotifier<DateTime>(fixedNow),
            child: const Text('Asset A'),
          ),
        );

        // LayrzBadge appends ", new" to the label it is given for a bare-dot
        // badge (no count/icon) -- see LayrzBadge._announcement(). The
        // connection announcement is passed straight through as that
        // `label`, so the merged node reads "<announcement>, new" and must
        // appear exactly once: a competing outer `Semantics` node wrapping
        // the same announcement text would duplicate it into two nodes.
        const announcement = 'Connected (2 minutes ago), new';
        expect(_countSemanticsWithExactLabel(tester, announcement), 1);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the .full chip announces just the state label, exactly once', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzConnectionIndicator(
            receivedAt: fixedNow,
            mode: LayrzConnectionIndicatorMode.full,
            clock: ValueNotifier<DateTime>(fixedNow),
          ),
        );

        expect(
          tester.getSemantics(find.text('Connected')),
          matchesSemantics(label: 'Connected'),
        );
        expect(_countSemanticsWithExactLabel(tester, 'Connected'), 1);
      } finally {
        handle.dispose();
      }
    });
  });
}
