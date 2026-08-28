import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';
import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzAnchoredPanel', () {
    testWidgets('tapping trigger opens the panel', (tester) async {
      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
          child: SizedBox(
            width: 200,
            height: 100,
            child: Text('Panel content'),
          ),
        ),
      );

      expect(find.text('Panel content'), findsNothing);
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      expect(find.text('Panel content'), findsOneWidget);
    });

    testWidgets('tapping trigger again closes the panel', (tester) async {
      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.isOpen ? controller.close : controller.open,
          ),
          child: SizedBox(
            width: 200,
            height: 100,
            child: Text('Panel content'),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      expect(find.text('Panel content'), findsOneWidget);

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      expect(find.text('Panel content'), findsNothing);
    });

    testWidgets('matchAnchor width policy makes panel width equal to anchor', (tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzAnchoredPanel(
            widthPolicy: LayrzAnchoredPanelWidthPolicy.matchAnchor,
            builder: (context, controller) => LayrzButton(
              labelText: 'Open',
              onTap: controller.open,
            ),
            child: SizedBox(
              height: 100,
              child: Text('Panel'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      final buttonRect = tester.getRect(find.byType(LayrzButton));
      final textRect = tester.getRect(find.text('Panel'));

      expect(textRect.width, closeTo(buttonRect.width, 1.0));
    });

    testWidgets('contentSized width policy respects min/max bounds', (tester) async {
      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          widthPolicy: LayrzAnchoredPanelWidthPolicy.contentSized,
          widthBounds: const LayrzAnchoredPanelWidthBounds(minWidth: 100.0, maxWidth: 200.0),
          builder: (context, controller) => SizedBox(
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: controller.isOpen ? controller.close : controller.open,
              child: Text('Open'),
            ),
          ),
          child: SizedBox(
            height: 100,
            child: Text('Panel'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final textRect = tester.getRect(find.text('Panel'));
      expect(textRect.width, greaterThanOrEqualTo(100.0));
      expect(textRect.width, lessThanOrEqualTo(200.0));
    });

    testWidgets('panel with custom maxHeight scrolls content', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(400, 300);

      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          maxHeight: 100.0,
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
          child: Column(
            children: List.generate(
              10,
              (i) => SizedBox(
                height: 50,
                child: Center(
                  child: Text('Item $i'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 9'), findsOneWidget);

      final scrollViewRect = tester.getRect(find.byType(SingleChildScrollView));
      expect(scrollViewRect.height, lessThanOrEqualTo(120.0));
    });

    testWidgets('different alignment options position panel on a vertical side', (tester) async {
      for (final alignment in LayrzAnchoredPanelAlignment.values) {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(400, 400);

        await pumpThemed(
          tester,
          Align(
            alignment: Alignment.center,
            child: LayrzAnchoredPanel(
              alignment: alignment,
              builder: (context, controller) => LayrzButton(
                labelText: 'Open',
                onTap: controller.open,
              ),
              child: SizedBox(
                width: 150,
                height: 100,
                child: Text('Panel'),
              ),
            ),
          ),
        );

        // Tap the button at its center.
        final buttonCenter = tester.getCenter(find.byType(LayrzButton));
        await tester.tapAt(buttonCenter);
        await tester.pumpAndSettle();

        expect(find.text('Panel'), findsOneWidget);

        // Tap the button again to close the panel.
        final buttonCenterAgain = tester.getCenter(find.byType(LayrzButton));
        await tester.tapAt(buttonCenterAgain);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('different alignment options position panel on a horizontal side', (tester) async {
      for (final alignment in LayrzAnchoredPanelAlignment.values) {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(400, 400);

        await pumpThemed(
          tester,
          Align(
            alignment: Alignment.center,
            child: LayrzAnchoredPanel(
              preferredSide: LayrzPreferredSide.right,
              alignment: alignment,
              builder: (context, controller) => LayrzButton(
                labelText: 'Open',
                onTap: controller.open,
              ),
              child: SizedBox(
                width: 100,
                height: 60,
                child: Text('Panel'),
              ),
            ),
          ),
        );

        // Tap the button at its center.
        final buttonCenter = tester.getCenter(find.byType(LayrzButton));
        await tester.tapAt(buttonCenter);
        await tester.pumpAndSettle();

        expect(find.text('Panel'), findsOneWidget);

        // Tap the button again to close the panel.
        final buttonCenterAgain = tester.getCenter(find.byType(LayrzButton));
        await tester.tapAt(buttonCenterAgain);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('onOpen callback is called when panel opens', (tester) async {
      int openCount = 0;

      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          onOpen: () => openCount++,
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
          child: SizedBox(
            width: 200,
            height: 100,
            child: Text('Panel'),
          ),
        ),
      );

      expect(openCount, 0);
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      expect(openCount, 1);
    });

    testWidgets('onClose callback is called when panel closes', (tester) async {
      int closeCount = 0;

      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          onClose: () => closeCount++,
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.isOpen ? controller.close : controller.open,
          ),
          child: SizedBox(
            width: 200,
            height: 100,
            child: Text('Panel'),
          ),
        ),
      );

      expect(closeCount, 0);

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      expect(closeCount, 0);

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      expect(closeCount, 1);
    });

    testWidgets('onFlipped callback is invoked', (tester) async {
      int callCount = 0;

      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          onFlipped: (up) {
            callCount++;
          },
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
          child: SizedBox(
            width: 200,
            height: 100,
            child: Text('Panel'),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(callCount, greaterThan(0));
    });

    // `pumpThemed` builds a brand-new `OverlayEntry` on every call, so its subtree
    // is torn down and rebuilt from scratch rather than updated in place -- which
    // means `didUpdateWidget` never fires across two `pumpThemed` calls, even with
    // matching keys (see the documented gotcha in `engineering/m3-handoff.md:169-170`,
    // also surfaced by DESIGN-153). Worse: `Overlay.initialEntries` is only consumed
    // in `initState` (`overlay.dart:657`), so even pumping a second `Overlay` widget
    // with a *new* `OverlayEntry` list leaves the old entry mounted -- the new child
    // is never actually built at all, and a naive two-`pumpWidget` test would pass
    // for the wrong reason (nothing ever ran `didUpdateWidget` with a different
    // controller). To genuinely exercise `didUpdateWidget`, the "no behaviour change"
    // test below builds a single `OverlayEntry` once and calls `entry.markNeedsBuild()`
    // to force a real in-place rebuild of the same element.
    //
    // DESIGN-146 history: an earlier revision of this guard threw a `StateError`
    // from `didUpdateWidget` instead of asserting, specifically so the swap would
    // still be caught in release builds. That was reverted -- confirmed by direct
    // experiment, not merely predicted: letting the `StateError` propagate out of
    // `didUpdateWidget` mid-rebuild, inside `LayrzAnchoredPanel`'s real tree (which
    // nests several `InheritedNotifierElement`/`Focus`/`RawMenuAnchor` layers),
    // leaves the framework's own `_InactiveElements` bookkeeping inconsistent -- an
    // `InheritedElement.debugDeactivated` assertion (`'_dependents.isEmpty': is not
    // true`) fires when the test framework tries to unmount the tree, and from that
    // point on every subsequent `testWidgets` in the same file fails, including ones
    // with no relation to this widget (7 unrelated tests failed with the throwing
    // test present; all passed once it was removed). A minimal reproduction (a bare
    // `StatefulWidget` two levels deep, no `RawMenuAnchor`) does NOT corrupt the
    // binding, so the hazard is specific to throwing mid-update through a tree this
    // deep. The guard is therefore assert-only again: it fires in debug, and is
    // compiled out in release, where the swap is silently ignored. See the
    // [LayrzAnchoredPanel.controller] doc comment for the full rationale.
    //
    // What follows is NOT a test that the release build "enforces" the contract --
    // it does not, by design. `flutter_test` runs in debug mode with assertions
    // enabled, so there is no harness-level way to exercise the actual release
    // behaviour (the assert compiling out) from this suite; asserting that would
    // require a separate release-mode test runner this repo does not have. What
    // this test honestly verifies instead: (1) the assert's condition is the exact
    // one `didUpdateWidget` uses, so passing the same controller across a rebuild
    // never trips it, and a genuinely different one does; (2) `assert` throws an
    // `AssertionError` in this (debug) test environment, matching the doc comment's
    // "caught by an assert in debug builds" claim.
    test('the swap guard assert condition matches the documented debug-only contract', () {
      // Mirrors the exact boolean `didUpdateWidget` now asserts on
      // (`anchored_panel.dart`: `widget.controller == null || _lastSuppliedController
      // == widget.controller`), without walking `LayrzAnchoredPanel`'s real element
      // tree -- see the block comment above for why the real tree cannot be used to
      // exercise the throwing path this replaced.
      final firstController = MenuController();
      final secondController = MenuController();

      // Mirrors `_LayrzAnchoredPanelState.initState`, which seeds
      // `_lastSuppliedController` from `widget.controller` directly -- the guard
      // never sees a `null` baseline for a caller that supplies a controller from
      // the start.
      MenuController? lastSupplied = firstController;
      void simulateDidUpdateWidget(MenuController? newController) {
        assert(
          newController == null || lastSupplied == newController,
          'LayrzAnchoredPanel.controller must never be swapped for a different '
          'non-null MenuController instance via didUpdateWidget.',
        );
        lastSupplied = newController;
      }

      // Same controller again (first didUpdateWidget after initState): must not assert.
      simulateDidUpdateWidget(firstController);
      expect(lastSupplied, same(firstController));

      // A genuinely different controller: the assert condition is false, so it
      // throws here (assertions are enabled under flutter_test). This confirms the
      // guard actually fires in debug -- it says nothing about release, where the
      // same `assert` compiles out and this call would instead fall through
      // silently, leaving `lastSupplied` unchanged from the caller's perspective.
      expect(
        () => simulateDidUpdateWidget(secondController),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets(
      'no behaviour change for current callers: a caller that never passes a controller '
      'is unaffected by the swap guard',
      (tester) async {
        // Every internal caller today passes no controller at all, so the widget owns an
        // internally-created MenuController and `_lastSuppliedController` stays null
        // across rebuilds. This asserts that path never throws, across real
        // `didUpdateWidget` calls on the same element (see the note above the
        // previous test for why a fresh `pumpThemed`/`Overlay` tree per pump
        // would not actually exercise `didUpdateWidget` at all).
        var maxHeight = 100.0;

        late final OverlayEntry entry;
        entry = OverlayEntry(
          builder: (context) => Center(
            child: LayrzAnchoredPanel(
              maxHeight: maxHeight,
              builder: (context, controller) => LayrzButton(
                labelText: 'Open',
                onTap: controller.open,
              ),
              child: SizedBox(
                width: 200,
                height: 100,
                child: Text('Panel content'),
              ),
            ),
          ),
        );

        await tester.pumpWidget(
          Localizations(
            locale: const Locale('en'),
            delegates: const [
              DefaultWidgetsLocalizations.delegate,
              LayrzUiL10nDelegate(),
            ],
            child: LayrzTheme(
              data: LayrzThemeData.light(),
              child: Overlay(initialEntries: [entry]),
            ),
          ),
        );
        expect(tester.takeException(), isNull);

        // Rebuild several times with no controller supplied -- must never throw.
        for (var i = 1; i <= 3; i++) {
          maxHeight = 100.0 + i;
          entry.markNeedsBuild();
          await tester.pump();
          expect(tester.takeException(), isNull);
        }

        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();
        expect(find.text('Panel content'), findsOneWidget);
      },
    );

    testWidgets('controller parameter allows external control', (tester) async {
      final controller = MenuController();

      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          controller: controller,
          builder: (context, menuController) => LayrzButton(
            labelText: 'Trigger',
            onTap: () {},
          ),
          child: SizedBox(
            width: 200,
            height: 100,
            child: Text('Panel content'),
          ),
        ),
      );

      expect(find.text('Panel content'), findsNothing);

      controller.open();
      await tester.pumpAndSettle();
      expect(find.text('Panel content'), findsOneWidget);

      controller.close();
      await tester.pumpAndSettle();
      expect(find.text('Panel content'), findsNothing);
    });
  });

  // Regression coverage for the panel-tap-region defect: tapping content inside
  // the panel's overlay must never be treated as a tap "outside" a nearby
  // EditableText, and a genuinely outside tap must dismiss the panel — both
  // uniformly across mouse and touch pointers. See `_buildPanelOverlay`'s
  // `TextFieldTapRegion` wrapper for the fix and its doc comment for why.
  //
  // A bystander `EditableText`, unrelated to the panel's own anchor, is used
  // here so these assertions are not entangled with the anchored panel's own
  // (separate, out-of-scope) focus-steal-to-`_panelFocusNode` behavior in
  // `_handlePanelOpenRequested`, which would otherwise pull focus away from
  // the anchor itself immediately after every open, independent of this fix.
  group('LayrzAnchoredPanel panel/field tap-region grouping', () {
    Future<FocusNode> pumpPanelWithBystanderField(WidgetTester tester) async {
      final fieldFocusNode = FocusNode(debugLabel: 'bystander-field');
      final controller = TextEditingController();
      addTearDown(fieldFocusNode.dispose);
      addTearDown(controller.dispose);

      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 30,
              child: EditableText(
                controller: controller,
                focusNode: fieldFocusNode,
                style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
                cursorColor: const Color(0xFF000000),
                backgroundCursorColor: const Color(0xFFAAAAAA),
              ),
            ),
            LayrzAnchoredPanel(
              builder: (context, panelController) => LayrzButton(
                labelText: 'Open',
                onTap: panelController.open,
              ),
              child: SizedBox(
                width: 150,
                height: 60,
                child: GestureDetector(
                  onTap: () {},
                  child: const Text('Option'),
                ),
              ),
            ),
          ],
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Refocus the bystander field explicitly, after the panel's own open
      // sequence (including its unrelated focus steal) has fully settled, so
      // the assertions below isolate this fix from that other defect.
      fieldFocusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(fieldFocusNode.hasFocus, isTrue, reason: 'precondition: the bystander field must be focused');

      return fieldFocusNode;
    }

    testWidgets(
      'a mouse tap on panel content does not unfocus a field elsewhere on screen',
      (tester) async {
        final fieldFocusNode = await pumpPanelWithBystanderField(tester);

        final optionCenter = tester.getCenter(find.text('Option'));
        final gesture = await tester.startGesture(optionCenter, kind: PointerDeviceKind.mouse);
        await tester.pump();

        expect(
          fieldFocusNode.hasFocus,
          isTrue,
          reason:
              'a mouse tap-down on panel content must not be classified as "outside" the '
              'bystander field\'s own TextFieldTapRegion — without the fix, EditableText '
              'unconditionally unfocuses on a mouse tap-down it considers outside',
        );

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'a touch tap on panel content does not unfocus a field elsewhere on screen (parity with mouse)',
      (tester) async {
        final fieldFocusNode = await pumpPanelWithBystanderField(tester);

        final optionCenter = tester.getCenter(find.text('Option'));
        final gesture = await tester.startGesture(optionCenter, kind: PointerDeviceKind.touch);
        await tester.pump();

        expect(fieldFocusNode.hasFocus, isTrue);

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'a genuine mouse tap outside the field and panel closes the panel',
      (tester) async {
        await pumpPanelWithBystanderField(tester);
        expect(find.text('Option'), findsOneWidget, reason: 'panel must be open before the outside tap');

        final gesture = await tester.startGesture(const Offset(780, 580), kind: PointerDeviceKind.mouse);
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.text('Option'), findsNothing, reason: 'a genuine outside tap must close the panel');
      },
    );

    testWidgets(
      'a genuine touch tap outside the field and panel closes the panel (parity with mouse)',
      (tester) async {
        await pumpPanelWithBystanderField(tester);
        expect(find.text('Option'), findsOneWidget, reason: 'panel must be open before the outside tap');

        final gesture = await tester.startGesture(const Offset(780, 580), kind: PointerDeviceKind.touch);
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.text('Option'), findsNothing, reason: 'a genuine outside tap must close the panel');
      },
    );
  });
}
