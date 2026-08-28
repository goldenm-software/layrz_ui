import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/refresh/src/refresh_state.dart';
import 'package:layrz_ui/src/refresh/src/refresh_visual.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzRefreshVisual', () {
    guardedTestWidgets('renders at the requested size', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzRefreshVisual(
          state: LayrzRefreshState.idle,
          dragProgress: 0.0,
          size: 40.0,
        ),
      );

      final box = tester.renderObject<RenderBox>(find.byType(LayrzRefreshVisual));
      expect(box.size, const Size(40.0, 40.0));
    });

    guardedTestWidgets('idle state paints without a live region', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          const LayrzRefreshVisual(state: LayrzRefreshState.idle, dragProgress: 0.4),
        );

        final semanticsNode = tester.getSemantics(find.byType(LayrzRefreshVisual));
        expect(semanticsNode, matchesSemantics(isLiveRegion: false));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('armed state paints without a live region', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          const LayrzRefreshVisual(state: LayrzRefreshState.armed, dragProgress: 1.0),
        );

        final semanticsNode = tester.getSemantics(find.byType(LayrzRefreshVisual));
        expect(semanticsNode, matchesSemantics(isLiveRegion: false));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('refreshing state announces itself via a live region', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          const LayrzRefreshVisual(state: LayrzRefreshState.refreshing, dragProgress: 0.0),
        );
        await tester.pump(const Duration(milliseconds: 16));

        final semanticsNode = tester.getSemantics(find.byType(LayrzRefreshVisual));
        expect(
          semanticsNode,
          matchesSemantics(isLiveRegion: true, label: 'Refreshing'),
        );
      } finally {
        handle.dispose();
      }

      // Stop the repeating ticker before the test ends (settling state keeps
      // spinning too, so a plain idle rebuild is the clean way to halt it).
      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('settling state keeps announcing itself while retracting', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          const LayrzRefreshVisual(state: LayrzRefreshState.settling, dragProgress: 0.0),
        );
        await tester.pump(const Duration(milliseconds: 16));

        final semanticsNode = tester.getSemantics(find.byType(LayrzRefreshVisual));
        expect(semanticsNode, matchesSemantics(isLiveRegion: true, label: 'Refreshing'));
      } finally {
        handle.dispose();
      }

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('respects reduce-motion by not repeating the spin ticker', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const LayrzRefreshVisual(state: LayrzRefreshState.refreshing, dragProgress: 0.0),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      // With reduce-motion honoured, pumping additional frames must not hang
      // a repeating animation -- pumpAndSettle only completes if nothing is
      // still ticking.
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    guardedTestWidgets('updating from idle to refreshing starts the spin without error', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzRefreshVisual(state: LayrzRefreshState.idle, dragProgress: 0.6),
      );

      await pumpThemed(
        tester,
        const LayrzRefreshVisual(state: LayrzRefreshState.refreshing, dragProgress: 0.0),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
