import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/refresh/src/refresh_controller.dart';
import 'package:layrz_ui/src/refresh/src/refresh_fallback_button_mode.dart';
import 'package:layrz_ui/src/refresh/src/refresh_indicator.dart';
import 'package:layrz_ui/src/refresh/src/refresh_state.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

Widget _listView() {
  return ListView(
    children: List.generate(20, (i) => SizedBox(height: 60, child: Text('Item $i'))),
  );
}

/// Finds the fallback refresh button's own accessible affordance -- present
/// whenever the button is visible, whether it is currently a tappable button
/// or (mid-refresh) the shared loading ring.
Finder _fallbackButtonSemantics() => find.bySemanticsLabel('Refresh');

void main() {
  group('LayrzRefreshIndicator fallback button', () {
    // These tests exercise `debugDefaultTargetPlatformOverride` directly, so
    // each one resets it in a try/finally rather than relying solely on
    // addTearDown -- an assertion failure partway through the body must never
    // leak the override into a later test. See
    // test/platform/platform_test.dart's `isTouchOS` group for the same
    // pattern this mirrors.

    guardedTestWidgets('auto mode shows the button on a non-touch OS (desktop)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
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

          expect(_fallbackButtonSemantics(), findsOneWidget);
        } finally {
          handle.dispose();
        }
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    guardedTestWidgets('auto mode hides the button on a touch OS (Android)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
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

          expect(
            _fallbackButtonSemantics(),
            findsNothing,
            reason: 'a touch OS session has the pull gesture and needs no fallback',
          );
        } finally {
          handle.dispose();
        }
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    guardedTestWidgets('auto mode hides the button on a touch OS (iOS)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
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

          expect(_fallbackButtonSemantics(), findsNothing);
        } finally {
          handle.dispose();
        }
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    guardedTestWidgets('enabled mode always shows the button, even on a touch OS', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            SizedBox(
              height: 400,
              width: 400,
              child: LayrzRefreshIndicator(
                onRefresh: () async {},
                fallbackButtonMode: LayrzRefreshFallbackButtonMode.enabled,
                child: _listView(),
              ),
            ),
          );

          expect(_fallbackButtonSemantics(), findsOneWidget);
        } finally {
          handle.dispose();
        }
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    guardedTestWidgets('disabled mode never shows the button, even on a non-touch OS', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Non-touch OS here -- auto mode would show the button in this exact
      // configuration (see the first test above).
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            SizedBox(
              height: 400,
              width: 400,
              child: LayrzRefreshIndicator(
                onRefresh: () async {},
                fallbackButtonMode: LayrzRefreshFallbackButtonMode.disabled,
                child: _listView(),
              ),
            ),
          );

          expect(_fallbackButtonSemantics(), findsNothing);
        } finally {
          handle.dispose();
        }
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    guardedTestWidgets('tapping the fallback button triggers the same onRefresh as the controller', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzRefreshController();
      addTearDown(controller.dispose);
      var refreshed = false;
      final completer = Completer<void>();

      await pumpThemed(
        tester,
        SizedBox(
          height: 400,
          width: 400,
          child: LayrzRefreshIndicator(
            controller: controller,
            enableDragGesture: false,
            // `enabled` sidesteps the platform-dependent `auto` policy
            // entirely -- this test is about tap behaviour, not visibility.
            fallbackButtonMode: LayrzRefreshFallbackButtonMode.enabled,
            onRefresh: () {
              refreshed = true;
              return completer.future;
            },
            child: _listView(),
          ),
        ),
      );

      await tester.tap(_fallbackButtonSemantics());
      await tester.pump();

      expect(refreshed, isTrue);
      expect(controller.state, LayrzRefreshState.refreshing);

      completer.complete();
      await tester.pumpAndSettle();
      expect(controller.state, LayrzRefreshState.idle);
    });

    guardedTestWidgets('the fallback button is keyboard-activatable via ActivateIntent', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzRefreshController();
      addTearDown(controller.dispose);
      var refreshed = false;

      await pumpThemed(
        tester,
        SizedBox(
          height: 400,
          width: 400,
          child: LayrzRefreshIndicator(
            controller: controller,
            enableDragGesture: false,
            fallbackButtonMode: LayrzRefreshFallbackButtonMode.enabled,
            onRefresh: () async {
              refreshed = true;
            },
            child: _listView(),
          ),
        ),
      );

      final buttonContext = tester.element(_fallbackButtonSemantics());
      Actions.invoke(buttonContext, const ActivateIntent());
      await tester.pump();

      expect(refreshed, isTrue);
      await tester.pumpAndSettle();
    });

    guardedTestWidgets('the fallback button shows the shared loading ring while refreshing', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzRefreshController();
      addTearDown(controller.dispose);
      final completer = Completer<void>();

      await pumpThemed(
        tester,
        SizedBox(
          height: 400,
          width: 400,
          child: LayrzRefreshIndicator(
            controller: controller,
            enableDragGesture: false,
            fallbackButtonMode: LayrzRefreshFallbackButtonMode.enabled,
            onRefresh: () => completer.future,
            child: _listView(),
          ),
        ),
      );

      unawaited(controller.refresh(() => completer.future));
      await tester.pump();

      // Reuses the same `LayrzRefreshVisual` ring the pull indicator uses,
      // rather than inventing a second loading affordance.
      expect(find.byKey(const ValueKey('layrz-refresh-fallback-button-visual')), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
    });
  });
}
