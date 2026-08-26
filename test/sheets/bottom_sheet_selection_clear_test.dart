import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzBottomSheet clears an ancestor page selection before opening (modal only)', () {
    /// Pumps a [LayrzLayout] with selectable body text and returns its
    /// finder, so a real (non-collapsed) selection can be created on it via
    /// double-tap before a sheet is ever shown.
    Future<Finder> pumpSelectableBody(WidgetTester tester) async {
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            selectableContent: true,
            body: const Align(
              alignment: Alignment.topCenter,
              child: Text('Text Input'),
            ),
          ),
        ),
      );
      await tester.pump();
      return find.text('Text Input');
    }

    /// Creates a real (non-collapsed) selection on [textFinder] via a genuine
    /// double-tap — the confirmed-working word-selection gesture — and
    /// asserts it actually produced a selection before returning, so every
    /// test starts from a known-good state rather than assuming the gesture
    /// landed.
    Future<void> createSelectionVia(WidgetTester tester, Finder textFinder) async {
      final point = tester.getCenter(textFinder);
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(point);
      await tester.pumpAndSettle();

      expect(
        find.byType(LayrzSelectionToolbar),
        findsOneWidget,
        reason: 'a real selection must exist before the sheet is opened, for this test to be valid',
      );
    }

    testWidgets(
      'a selection made before a MODAL sheet opens does not survive to paint over it',
      (tester) async {
        final textFinder = await pumpSelectableBody(tester);
        await createSelectionVia(tester, textFinder);

        final context = tester.element(textFinder);
        LayrzBottomSheet.show<void>(
          context,
          useRootNavigator: true,
          initialSize: 0.5,
          builder: (context) => const SizedBox(height: 100, child: Center(child: Text('Sheet content'))),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sheet content'), findsOneWidget, reason: 'sheet must be open for this test to be valid');

        expect(
          find.byType(LayrzSelectionToolbar),
          findsNothing,
          reason: 'the pre-existing page selection must be cleared before a modal sheet opens over it',
        );
      },
    );

    testWidgets(
      'a selection made before a PERSISTENT sheet opens is left alone',
      (tester) async {
        final textFinder = await pumpSelectableBody(tester);
        await createSelectionVia(tester, textFinder);

        final context = tester.element(textFinder);
        LayrzBottomSheet.show<void>(
          context,
          useRootNavigator: true,
          isPersistent: true,
          initialSize: 0.5,
          builder: (context) => const SizedBox(height: 100, child: Center(child: Text('Persistent sheet content'))),
        );
        await tester.pumpAndSettle();

        expect(find.text('Persistent sheet content'), findsOneWidget);

        expect(
          find.byType(LayrzSelectionToolbar),
          findsOneWidget,
          reason:
              'a persistent sheet has no barrier and the page stays interactive, so an existing selection '
              'is not occluded and must not be cleared',
        );
      },
    );

    testWidgets(
      'a modal sheet opened with NO live selection behaves identically to today',
      (tester) async {
        final textFinder = await pumpSelectableBody(tester);

        expect(find.byType(LayrzSelectionToolbar), findsNothing, reason: 'no selection exists yet');

        final context = tester.element(textFinder);
        LayrzBottomSheet.show<void>(
          context,
          useRootNavigator: true,
          initialSize: 0.5,
          builder: (context) => const SizedBox(height: 100, child: Center(child: Text('Sheet content'))),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'no crash when there was never a selection to clear');
        expect(find.text('Sheet content'), findsOneWidget);
        expect(find.byType(LayrzSelectionToolbar), findsNothing);
      },
    );

    testWidgets(
      'a modal sheet opened with NO ancestor SelectableRegion at all does not throw',
      (tester) async {
        // No LayrzLayout, no SelectableRegion anywhere in the ancestry --
        // context.findAncestorStateOfType<SelectableRegionState>() must
        // return null and the lookup must be a silent no-op.
        await tester.pumpWidget(
          LayrzApp(
            theme: LayrzThemeData.light(),
            debugShowCheckedModeBanner: false,
            home: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzBottomSheet.show<void>(
                    context,
                    builder: (context) => const SizedBox(height: 200, child: Text('Sheet body')),
                  );
                },
                child: const SizedBox(width: 100, height: 100, child: Text('Open')),
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'no ancestor SelectableRegion must not crash the lookup');
        expect(find.text('Sheet body'), findsOneWidget);
      },
    );

    testWidgets(
      'a modal sheet opened with selectableContent: false does not throw (region absent, not just unselected)',
      (tester) async {
        await tester.pumpWidget(
          LayrzApp(
            theme: LayrzThemeData.light(),
            debugShowCheckedModeBanner: false,
            home: LayrzLayout(
              logo: 'assets/test-logo.png',
              items: [
                LayrzNavigatorPage(id: 'home', labelText: 'Home'),
              ],
              selectableContent: false,
              body: const Text('No selection here'),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(SelectableRegion), findsNothing, reason: 'selectableContent: false removes the region');

        final context = tester.element(find.text('No selection here'));
        LayrzBottomSheet.show<void>(
          context,
          useRootNavigator: true,
          builder: (context) => const SizedBox(height: 100, child: Text('Sheet content')),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Sheet content'), findsOneWidget);
      },
    );

    testWidgets(
      'selection in the page body still works normally when no sheet is involved',
      (tester) async {
        final textFinder = await pumpSelectableBody(tester);

        // Double-tap still selects a word.
        await createSelectionVia(tester, textFinder);

        // Long-press still selects and enables drag-to-extend -- assert the
        // toolbar remains available after a fresh long-press elsewhere, i.e.
        // this fix has not disturbed the gesture itself in the ordinary case
        // (no sheet ever opened in this test).
        await tester.longPress(textFinder);
        await tester.pumpAndSettle();
        expect(
          find.byType(LayrzSelectionToolbar),
          findsOneWidget,
          reason: 'long-press selection must still work when this fix never runs (no sheet opened)',
        );
      },
    );
  });
}
