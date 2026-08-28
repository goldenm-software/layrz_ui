import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/refresh/src/refresh_controller.dart';
import 'package:layrz_ui/src/refresh/src/refresh_indicator.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

Widget _listView() {
  return ListView(
    children: List.generate(20, (i) => SizedBox(height: 60, child: Text('Item $i'))),
  );
}

void main() {
  group('LayrzRefreshIndicator Accessibility', () {
    guardedTestWidgets('idle indicator exposes nothing to assistive technology', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            height: 400,
            width: 400,
            child: LayrzRefreshIndicator(onRefresh: () async {}, child: _listView()),
          ),
        );

        // The floating pull indicator is genuinely absent from the tree at
        // rest (zero drag progress, no refresh in flight) -- not merely
        // present-but-silent. See refresh_indicator.dart's `_onControllerChanged`
        // for why the widget itself, not just its opacity, is gated this way.
        expect(find.byKey(const ValueKey('layrz-refresh-pull-visual')), findsNothing);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets(
      'a programmatically triggered refresh announces itself as a live region',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        final controller = LayrzRefreshController();
        addTearDown(controller.dispose);
        final completer = Completer<void>();

        try {
          await pumpThemed(
            tester,
            SizedBox(
              height: 400,
              width: 400,
              child: LayrzRefreshIndicator(
                controller: controller,
                enableDragGesture: false,
                onRefresh: () => completer.future,
                child: _listView(),
              ),
            ),
          );

          unawaited(controller.refresh(() => completer.future));
          await tester.pump();

          // `enableDragGesture: false` still leaves the automatic fallback
          // button visible (no mouse has been observed connected in this
          // test), which paints a second `LayrzRefreshVisual` for its own
          // loading state -- disambiguate by key to target the pull
          // indicator's visual specifically.
          final semanticsNode = tester.getSemantics(
            find.byKey(const ValueKey('layrz-refresh-pull-visual')),
          );
          expect(
            semanticsNode,
            matchesSemantics(isLiveRegion: true, label: 'Refreshing'),
          );

          completer.complete();
          await tester.pumpAndSettle();
        } finally {
          handle.dispose();
        }
      },
    );

    guardedTestWidgets('the scrollable child keeps its own semantics under the indicator', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            height: 400,
            width: 400,
            child: LayrzRefreshIndicator(onRefresh: () async {}, child: _listView()),
          ),
        );

        // The wrapped ListView's items are still reachable in the semantics
        // tree -- the indicator must not swallow or hide the content it wraps.
        final itemNode = tester.getSemantics(find.text('Item 0'));
        expect(itemNode.label, 'Item 0');
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a settled refresh leaves nothing behind in the tree', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      final controller = LayrzRefreshController();
      addTearDown(controller.dispose);

      try {
        await pumpThemed(
          tester,
          SizedBox(
            height: 400,
            width: 400,
            child: LayrzRefreshIndicator(
              controller: controller,
              enableDragGesture: false,
              onRefresh: () async {},
              child: _listView(),
            ),
          ),
        );

        unawaited(controller.refresh(() async {}));
        await tester.pumpAndSettle();

        // Once settling completes and the controller reports `idle` again,
        // the pull indicator must be gone from the tree entirely -- this is
        // the same collapse-to-nothing contract the abandoned/reversed-pull
        // regression tests in refresh_indicator_test.dart cover for the drag
        // path, verified here for the programmatic-refresh path instead.
        expect(find.byKey(const ValueKey('layrz-refresh-pull-visual')), findsNothing);
      } finally {
        handle.dispose();
      }
    });
  });
}
