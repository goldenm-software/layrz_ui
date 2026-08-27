import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

void main() {
  // Regression coverage for "the text inside is unselectable". Before the
  // fix, LayrzDialog's content slot rendered no SelectableRegion of its own
  // and a dialog route sits outside LayrzLayout's subtree (which is the only
  // place a SelectableRegion existed), so dialog content had no selection
  // mechanism at all -- unlike LayrzBottomSheet, which was suspected to
  // "already work" but in fact never wrapped its own content in a
  // SelectableRegion either; it only reads as selectable when shown from
  // inside a LayrzLayout body, by inheriting THAT ancestor's region. Since a
  // dialog is not guaranteed to be shown from inside a LayrzLayout, it needs
  // its own SelectableRegion the same way DetailPane has its own -- these
  // tests assert that mechanism directly (content is inside a
  // SelectableRegion) and that the DESIGN-147 platform gate is respected,
  // mirroring the model in test/selection/selection_gate_test.dart.
  group('LayrzDialog content selection', () {
    Future<void> openDialog(WidgetTester tester) async {
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzDialog.show<void>(
                    context,
                    title: const Text('Selectable dialog'),
                    content: const Text('Selectable dialog content'),
                  );
                },
                child: const SizedBox(width: 100, height: 100, child: Text('Open')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    guardedTestWidgets('content is wrapped in its own SelectableRegion', (tester) async {
      await openDialog(tester);

      expect(
        find.ancestor(
          of: find.text('Selectable dialog content'),
          matching: find.byType(SelectableRegion),
        ),
        findsOneWidget,
        reason:
            'dialog content must be inside a SelectableRegion so it is selectable regardless of '
            'whether the dialog was shown from inside a LayrzLayout',
      );

      // The title slot is short, non-prose label content (mirrors button
      // labels/headers elsewhere in the system) and is deliberately NOT
      // wrapped -- only `content` gets its own SelectableRegion.
      expect(
        find.ancestor(
          of: find.text('Selectable dialog'),
          matching: find.byType(SelectableRegion),
        ),
        findsNothing,
      );
    });

    testWidgets('android: long-press selects and shows the copy toolbar', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await openDialog(tester);

        await tester.longPress(find.text('Selectable dialog content'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byType(LayrzSelectionToolbar),
          findsOneWidget,
          reason: 'Android must show the copy toolbar on long-press',
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('iOS: long-press selects and shows the copy toolbar', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await openDialog(tester);

        await tester.longPress(find.text('Selectable dialog content'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(LayrzSelectionToolbar), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('macOS: selectionControls is emptyTextSelectionControls, no toolbar on long-press', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await openDialog(tester);

        final region = tester.widget<SelectableRegion>(find.byType(SelectableRegion));
        expect(
          region.selectionControls,
          equals(emptyTextSelectionControls),
          reason: 'non-touch OS must drop touch selection controls, matching DetailPane/LayrzLayout\'s own gate',
        );

        await tester.longPress(find.text('Selectable dialog content'));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'the off-state must not crash -- guards against force-unwrapping contextMenuBuilder',
        );
        expect(find.byType(LayrzSelectionToolbar), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('windows: selectionControls is emptyTextSelectionControls, no toolbar on long-press', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await openDialog(tester);

        final region = tester.widget<SelectableRegion>(find.byType(SelectableRegion));
        expect(region.selectionControls, equals(emptyTextSelectionControls));

        await tester.longPress(find.text('Selectable dialog content'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(LayrzSelectionToolbar), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('linux: selectionControls is emptyTextSelectionControls, no toolbar on long-press', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await openDialog(tester);

        final region = tester.widget<SelectableRegion>(find.byType(SelectableRegion));
        expect(region.selectionControls, equals(emptyTextSelectionControls));

        await tester.longPress(find.text('Selectable dialog content'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(LayrzSelectionToolbar), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('android: selectionControls is the shared LayrzTextSelectionControls instance', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await openDialog(tester);

        final region = tester.widget<SelectableRegion>(find.byType(SelectableRegion));
        expect(region.selectionControls, same(LayrzTextSelectionControls.instance));
        expect(region.contextMenuBuilder, isNotNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
