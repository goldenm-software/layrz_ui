import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Minimal domain object used to exercise [LayrzScaffoldShell] in isolation.
class _TestItem {
  /// Creates a test item with the given [id] and [name].
  const _TestItem(this.id, this.name);

  /// Stable identifier, mirrored by the [LayrzScaffoldItem.key] used in tests.
  final String id;

  /// Display name rendered by the tile and detail builder.
  final String name;
}

void main() {
  group('LayrzScaffoldShell narrow sheet selection scope (nested Navigator)', () {
    /// Pumps [LayrzLayout] > a NESTED [Navigator] > [LayrzScaffoldShell],
    /// reproducing the exact ancestry `go_router`'s `ShellRoute` produces in
    /// the real showroom app: "All ShellRoutes build a Navigator by default.
    /// Child GoRoutes are placed onto this Navigator instead of the root
    /// Navigator." (go_router 14.8.1, route.dart:709-710). That nested
    /// Navigator is built INSIDE LayrzLayout's body in the real app
    /// (ShowroomLayout wraps the ShellRoute's own child Navigator in
    /// LayrzLayout), which is why it ends up inside LayrzLayout's
    /// SelectableRegion subtree. LayrzLayoutDrawerScaffold introduces no
    /// Navigator of its own (confirmed by grep) -- the nesting comes from
    /// go_router, not from anything in this package's layout code.
    ///
    /// go_router itself is only an example-app dependency, not a layrz_ui
    /// dependency, so this reproduces its Navigator-nesting *behavior*
    /// directly with a bare [Navigator] rather than depending on the package.
    ///
    /// The Navigator is given a [GlobalKey]: go_router's ShellRoute always
    /// keys its nested Navigator this way (confirmed in the go_router source
    /// -- `navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>()`) so it
    /// survives LayrzLayout's own breakpoint-driven rebuilds (expanded vs.
    /// drawer are structurally different subtrees, not a single stable
    /// structure with reparented children) instead of being disposed and
    /// recreated -- which would otherwise tear down LayrzScaffoldShell's own
    /// State (and its _itemsChangeNotifier) while a useRootNavigator: true
    /// sheet, now on a different lifecycle, is still open and listening to
    /// it. Confirmed by removing this key during investigation: doing so
    /// reproduces "A ValueNotifier<int> was used after being disposed" on
    /// the band-transition test below -- a test-harness fidelity gap, not a
    /// defect in the fix, but real enough to be worth recording here.
    Future<BuildContext> pumpNestedShellApp(WidgetTester tester, LayrzScaffoldController controller) async {
      late BuildContext capturedShellBodyContext;
      final navigatorKey = GlobalKey<NavigatorState>();

      final items = [
        LayrzScaffoldItem<_TestItem>(
          key: const ValueKey('text-input'),
          item: const _TestItem('text-input', 'Text Input'),
          tile: const SizedBox(height: 40, child: Text('Text Input')),
          searchableStrings: const {'Text Input'},
        ),
        LayrzScaffoldItem<_TestItem>(
          key: const ValueKey('combobox-input'),
          item: const _TestItem('combobox-input', 'ComboBox Input'),
          tile: const SizedBox(height: 40, child: Text('ComboBox Input')),
          searchableStrings: const {'ComboBox Input'},
        ),
      ];

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [LayrzNavigatorPage(id: 'home', labelText: 'Home')],
            selectableContent: true,
            body: Navigator(
              key: navigatorKey,
              onGenerateRoute: (settings) {
                return PageRouteBuilder(
                  settings: settings,
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return Builder(
                      builder: (context) {
                        capturedShellBodyContext = context;
                        return LayrzScaffoldShell<_TestItem>(
                          controller: controller,
                          items: items,
                          itemExtent: 56.0,
                          onDetailsBuild: (item) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Field States for ${item.name}', style: const TextStyle(fontSize: 20)),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      return capturedShellBodyContext;
    }

    testWidgets(
      'STRUCTURE: with the sheet open, its content is NOT a descendant of the page\'s SelectableRegion',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800);

        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        await pumpNestedShellApp(tester, controller);

        await tester.tap(find.text('Text Input'));
        await tester.pumpAndSettle();

        final sheetTitleFinder = find.text('Field States for Text Input');
        expect(sheetTitleFinder, findsOneWidget, reason: 'sheet must be open');

        // Structural assertion: walk UP from the sheet's own content and
        // confirm the page's SelectableRegion is NOT among its ancestors.
        // This is what the bug actually was -- the sheet living inside the
        // region's subtree -- so this survives refactors that a
        // gesture/selection-state test alone would not catch.
        final sheetContentContext = tester.element(sheetTitleFinder);
        final ancestorRegion = sheetContentContext.findAncestorStateOfType<SelectableRegionState>();
        expect(
          ancestorRegion,
          isNull,
          reason: 'the sheet\'s content must not be a descendant of the page\'s SelectableRegion',
        );
      },
    );

    testWidgets(
      'a double-tap on the sheet\'s own text does not select the page-body row behind it',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        // Reset via try/finally, not addTearDown: _verifyInvariants runs
        // BEFORE tearDowns, at the end of the test body, so if an earlier
        // expect() in this test throws, an addTearDown-scheduled reset would
        // never run and this override would leak into later tests.
        try {
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = const Size(400, 800);

          final controller = LayrzScaffoldController();
          addTearDown(controller.dispose);

          await pumpNestedShellApp(tester, controller);

          await tester.tap(find.text('Text Input'));
          await tester.pumpAndSettle();

          final sheetTitleFinder = find.text('Field States for Text Input');
          expect(sheetTitleFinder, findsOneWidget, reason: 'sheet must be open and settled');

          final tapPoint = tester.getCenter(sheetTitleFinder);

          // Genuine double-tap, within kDoubleTapTimeout, on the sheet's own
          // text.
          await tester.tapAt(tapPoint);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tapAt(tapPoint);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);

          // Ground truth: read the PAGE's own SelectableRegionState directly.
          final pageRegionElement = find.byType(SelectableRegion).evaluate().single;
          final pageRegionState = (pageRegionElement as StatefulElement).state as SelectableRegionState;
          expect(
            () => pageRegionState.contextMenuAnchors,
            throwsA(anything),
            reason:
                'the page region must have NO active selection -- contextMenuAnchors throws when there is '
                'nothing selected; a non-throwing call here would mean the double-tap on the sheet leaked '
                'into the page\'s selection scope',
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('barrier-tap dismissal still closes the sheet and closes the controller', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);

      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      await pumpNestedShellApp(tester, controller);

      await tester.tap(find.text('Text Input'));
      await tester.pumpAndSettle();
      expect(find.text('Field States for Text Input'), findsOneWidget);
      expect(controller.openedKey, equals(const ValueKey('text-input')));

      // A point visibly above the sheet's own content, so it lands on the
      // barrier.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Field States for Text Input'), findsNothing, reason: 'sheet must close');
      expect(controller.openedKey, isNull, reason: 'dismissing the sheet must close the controller');
    });

    testWidgets('Escape still closes the sheet and closes the controller', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);

      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      await pumpNestedShellApp(tester, controller);

      await tester.tap(find.text('Text Input'));
      await tester.pumpAndSettle();
      expect(find.text('Field States for Text Input'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Field States for Text Input'), findsNothing);
      expect(controller.openedKey, isNull);
    });

    testWidgets('drag-to-dismiss still closes the sheet and closes the controller', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);

      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      await pumpNestedShellApp(tester, controller);

      await tester.tap(find.text('Text Input'));
      await tester.pumpAndSettle();
      expect(find.text('Field States for Text Input'), findsOneWidget);

      final handle = find.byWidgetPredicate(
        (widget) => widget is Container && widget.constraints?.maxWidth == 40 && widget.constraints?.maxHeight == 4,
      );
      expect(handle, findsOneWidget);

      await tester.drag(handle, const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Field States for Text Input'), findsNothing);
      expect(controller.openedKey, isNull);
    });

    testWidgets(
      'band transition to wide while the sheet is open still pops it and preserves the selection',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800);

        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        await pumpNestedShellApp(tester, controller);

        await tester.tap(find.text('Text Input'));
        await tester.pumpAndSettle();
        expect(find.text('Field States for Text Input'), findsOneWidget);
        expect(controller.openedKey, equals(const ValueKey('text-input')));

        // Ground truth for "did the narrow sheet's own route pop": the root
        // Navigator must go from 2 routes (the nested-shell page + the
        // useRootNavigator:true sheet) to 1. Checking for the text's absence
        // is NOT valid here -- the wide layout's own side-by-side DetailPane
        // legitimately renders the SAME text once resized (per this class's
        // own doc: "A resize from narrow to wide pops the sheet but
        // preserves the selection"), so the text staying visible is
        // correct, not a sign the sheet failed to pop.
        final rootNavigatorState = Navigator.of(tester.element(find.byType(LayrzLayout)), rootNavigator: true);
        expect(rootNavigatorState.canPop(), isTrue, reason: 'the sheet route must be poppable before the resize');

        // Resize to a wide breakpoint while the narrow sheet is open.
        tester.view.physicalSize = const Size(1400, 900);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          rootNavigatorState.canPop(),
          isFalse,
          reason: 'the sheet\'s own route must have been popped off the root Navigator on band transition',
        );
        expect(
          controller.openedKey,
          equals(const ValueKey('text-input')),
          reason: 'band-transition dismissal must preserve the selection (_dismissedByShell), unlike a user dismiss',
        );
        // The wide layout's own detail pane legitimately shows the same
        // content now -- confirming the preserved selection is actually
        // rendered, not just recorded in the controller.
        expect(find.text('Field States for Text Input'), findsOneWidget);
      },
    );
  });
}
