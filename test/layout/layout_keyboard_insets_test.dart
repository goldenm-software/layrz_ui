import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/layout/src/navigator_panel.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzLayout - Keyboard viewInsets (Notion: LayrzLayout ignores viewInsets)', () {
    group('Drawer (compact) presentation — body shrinks by viewInsets.bottom', () {
      testWidgets('body usable height shrinks by the keyboard inset', (WidgetTester tester) async {
        /// Scaffold-style behaviour: the layout reduces the body's available height by
        /// viewInsets.bottom, as Material's Scaffold does with resizeToAvoidBottomInset.
        /// Force drawer presentation (sm breakpoint) with devicePixelRatio pinned to 1.0.
        const screenHeight = 800.0;
        const keyboardInset = 300.0;

        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, screenHeight);

        // Baseline: no keyboard.
        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: Container(key: const ValueKey('body_probe')),
          ),
        );
        await tester.pumpAndSettle();
        final baselineRect = tester.getRect(find.byKey(const ValueKey('body_probe')));

        // With keyboard open.
        tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: Container(key: const ValueKey('body_probe')),
          ),
        );
        await tester.pumpAndSettle();
        final keyboardRect = tester.getRect(find.byKey(const ValueKey('body_probe')));

        expect(
          keyboardRect.height,
          closeTo(baselineRect.height - keyboardInset, 1.0),
          reason:
              'CRITICAL: drawer/compact body height must shrink by the keyboard inset '
              '($keyboardInset). Baseline height: ${baselineRect.height}, '
              'with keyboard: ${keyboardRect.height}.',
        );
      });
    });

    group('Rail (expanded) presentation — body shrinks by viewInsets.bottom', () {
      testWidgets('body usable height shrinks by the keyboard inset', (WidgetTester tester) async {
        const screenHeight = 800.0;
        const keyboardInset = 300.0;

        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1200, screenHeight);

        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
            ],
            body: Container(key: const ValueKey('body_probe')),
          ),
        );
        await tester.pumpAndSettle();
        final baselineRect = tester.getRect(find.byKey(const ValueKey('body_probe')));

        tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
            ],
            body: Container(key: const ValueKey('body_probe')),
          ),
        );
        await tester.pumpAndSettle();
        final keyboardRect = tester.getRect(find.byKey(const ValueKey('body_probe')));

        expect(
          keyboardRect.height,
          closeTo(baselineRect.height - keyboardInset, 1.0),
          reason:
              'CRITICAL: rail/expanded body height must shrink by the keyboard inset '
              '($keyboardInset). Baseline height: ${baselineRect.height}, '
              'with keyboard: ${keyboardRect.height}.',
        );
      });
    });

    group('Nested widgets do not double-count the inset — viewInsets is zeroed for the body', () {
      testWidgets('MediaQuery.viewInsets read inside the body is zero when the keyboard is open', (
        WidgetTester tester,
      ) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300.0);

        EdgeInsets? observedViewInsets;

        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: Builder(
              builder: (context) {
                observedViewInsets = MediaQuery.viewInsetsOf(context);
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          observedViewInsets,
          equals(EdgeInsets.zero),
          reason:
              'The body must see viewInsets == EdgeInsets.zero — the layout already consumed '
              'the inset by shrinking available height, so a nested widget reading '
              'MediaQuery.viewInsetsOf itself must not double-count it (Scaffold-style).',
        );
      });
    });

    group('Navigator panel also shrinks with the keyboard (drawer open)', () {
      testWidgets('drawer panel height shrinks by viewInsets.bottom when open', (WidgetTester tester) async {
        const screenHeight = 800.0;
        const keyboardInset = 300.0;

        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, screenHeight);

        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: const SizedBox(),
          ),
        );
        await tester.pumpAndSettle();

        final triggerFinder = find.byKey(const ValueKey('drawer_trigger_button'));
        await tester.tap(triggerFinder);
        await tester.pumpAndSettle();

        final panelFinder = find.byType(LayrzLayoutNavigatorPanel);
        final baselineRect = tester.getRect(panelFinder);

        tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
        await tester.pumpAndSettle();

        final keyboardRect = tester.getRect(panelFinder);

        expect(
          keyboardRect.height,
          closeTo(baselineRect.height - keyboardInset, 1.0),
          reason:
              'CRITICAL: the open drawer navigator panel height must shrink by the keyboard '
              'inset ($keyboardInset), consistent with the body being resized. Baseline: '
              '${baselineRect.height}, with keyboard: ${keyboardRect.height}.',
        );
      });
    });
  });
}
