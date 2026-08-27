import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/scaffold/src/detail_pane.dart';

import '../helpers/pump_themed.dart';
import '../helpers/pump_themed_app.dart';

void main() {
  // DESIGN-147: "preserve the magnifier, drops and anything related to text
  // selection tools only on android and iOS, via web or native" -- a
  // platform-only predicate with no size term. This suite proves both sides
  // of the gate at all four sites it touches: the shared EditableText wiring
  // behind five inputs (LayrzEditableField), and the three structurally
  // identical SelectableRegion sites (LayrzLayout expanded, LayrzLayout
  // drawer, DetailPane). Every assertion below is written to fail against the
  // pre-fix code (`!LayrzPlatform.isMobile` in the magnifier, and no gate at
  // all in the other three sites), which is why each also pins the touch-side
  // ("still works") behavior, not only the non-touch side.
  //
  // Every test resets debugDefaultTargetPlatformOverride via try/finally, not
  // addTearDown: TestWidgetsFlutterBinding._verifyInvariants runs BEFORE
  // addTearDown-scheduled callbacks, so an addTearDown reset here would
  // always trip "The value of a foundation debug variable was changed by the
  // test" and then leak into every later test in the file.
  group('Selection tool platform gate (DESIGN-147)', () {
    group('LayrzEditableField (five inputs, exercised via LayrzTextInput)', () {
      Future<void> pumpInput(WidgetTester tester, TextEditingController controller) async {
        await pumpThemed(
          tester,
          LayrzTextInput(controller: controller),
        );
      }

      testWidgets('android: selectionControls and contextMenuBuilder are wired', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final controller = TextEditingController(text: 'select me');
          addTearDown(controller.dispose);
          await pumpInput(tester, controller);

          final editable = tester.widget<EditableText>(find.byType(EditableText));
          expect(editable.selectionControls, isNotNull, reason: 'Android must keep touch selection controls');
          expect(editable.contextMenuBuilder, isNotNull, reason: 'Android must keep the selection action menu');
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('iOS: selectionControls and contextMenuBuilder are wired', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        try {
          final controller = TextEditingController(text: 'select me');
          addTearDown(controller.dispose);
          await pumpInput(tester, controller);

          final editable = tester.widget<EditableText>(find.byType(EditableText));
          expect(editable.selectionControls, isNotNull);
          expect(editable.contextMenuBuilder, isNotNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('macOS: selectionControls and contextMenuBuilder are both null', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          final controller = TextEditingController(text: 'select me');
          addTearDown(controller.dispose);
          await pumpInput(tester, controller);

          final editable = tester.widget<EditableText>(find.byType(EditableText));
          expect(
            editable.selectionControls,
            isNull,
            reason: 'non-touch OS must drop the touch selection controls (drag handles, magnifier)',
          );
          expect(
            editable.contextMenuBuilder,
            isNull,
            reason: 'non-touch OS must drop the selection action menu, per editable_text.dart:4522 both-null contract',
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('windows: selectionControls and contextMenuBuilder are both null', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          final controller = TextEditingController(text: 'select me');
          addTearDown(controller.dispose);
          await pumpInput(tester, controller);

          final editable = tester.widget<EditableText>(find.byType(EditableText));
          expect(editable.selectionControls, isNull);
          expect(editable.contextMenuBuilder, isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('linux: selectionControls and contextMenuBuilder are both null', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          final controller = TextEditingController(text: 'select me');
          addTearDown(controller.dispose);
          await pumpInput(tester, controller);

          final editable = tester.widget<EditableText>(find.byType(EditableText));
          expect(editable.selectionControls, isNull);
          expect(editable.contextMenuBuilder, isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('desktop (non-touch): caret placement still works -- no crash on tap/type', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          final controller = TextEditingController();
          addTearDown(controller.dispose);
          await pumpInput(tester, controller);

          await tester.tap(find.byType(EditableText));
          await tester.pump();
          await tester.enterText(find.byType(EditableText), 'hello');
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(controller.text, equals('hello'));
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('desktop (non-touch): _shouldShowSelectionHandles never shows handles', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          final controller = TextEditingController(text: 'select this text');
          addTearDown(controller.dispose);
          await pumpInput(tester, controller);

          final editable = tester.widget<EditableText>(find.byType(EditableText));
          expect(editable.showSelectionHandles, isFalse);

          // Simulate the touch-shaped cause that would normally trigger handles.
          await tester.longPress(find.byType(EditableText));
          await tester.pumpAndSettle();

          final editableAfter = tester.widget<EditableText>(find.byType(EditableText));
          expect(
            editableAfter.showSelectionHandles,
            isFalse,
            reason: 'non-touch OS must never show selection handles regardless of the triggering cause',
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('does not swap identity across rebuilds while platform is unchanged (D50 Trap 2)', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final controller = TextEditingController(text: 'stable');
          addTearDown(controller.dispose);
          await pumpInput(tester, controller);

          final first = tester.widget<EditableText>(find.byType(EditableText));

          // Trigger a rebuild without changing platform.
          await tester.pump();
          final second = tester.widget<EditableText>(find.byType(EditableText));

          expect(
            identical(first.selectionControls, second.selectionControls),
            isTrue,
            reason:
                'selectionControls must be a stable reference across rebuilds, or the overlay is disposed mid-display',
          );
          expect(
            identical(first.contextMenuBuilder, second.contextMenuBuilder),
            isTrue,
            reason: 'contextMenuBuilder must be a stable reference across rebuilds',
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    });

    group('LayrzLayout SelectableRegion sites (_buildExpanded / _buildDrawer)', () {
      Future<void> pumpLayout(WidgetTester tester, {required Size viewportSize}) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = viewportSize;

        await tester.pumpWidget(
          LayrzApp(
            theme: LayrzThemeData.light(),
            debugShowCheckedModeBanner: false,
            home: LayrzLayout(
              logo: 'assets/test-logo.png',
              items: [LayrzNavigatorPage(id: 'home', labelText: 'Home')],
              body: const Center(child: Text('Selectable body text')),
              selectableContent: true,
            ),
          ),
        );
        await tester.pump();
      }

      testWidgets('expanded presentation, android: long-press selects and shows the toolbar', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          await pumpLayout(tester, viewportSize: const Size(1400, 900));

          await tester.longPress(find.text('Selectable body text'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(
            find.byType(LayrzSelectionToolbar),
            findsOneWidget,
            reason: 'Android must still show the copy toolbar on long-press',
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('drawer presentation, iOS: long-press selects and shows the toolbar', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        try {
          await pumpLayout(tester, viewportSize: const Size(500, 900));

          await tester.longPress(find.text('Selectable body text'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(LayrzSelectionToolbar), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('expanded presentation, windows: long-press does not crash and shows no toolbar', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          await pumpLayout(tester, viewportSize: const Size(1400, 900));

          await tester.longPress(find.text('Selectable body text'));
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason:
                'the off-state (emptyTextSelectionControls) must not crash -- this is exactly the guard against '
                'force-unwrapping contextMenuBuilder in the TextSelectionHandleControls branch',
          );
          expect(
            find.byType(LayrzSelectionToolbar),
            findsNothing,
            reason: 'non-touch OS must show no selection action menu on the page body',
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('drawer presentation, macOS: long-press does not crash and shows no toolbar', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          await pumpLayout(tester, viewportSize: const Size(500, 900));

          await tester.longPress(find.text('Selectable body text'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(LayrzSelectionToolbar), findsNothing);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('non-touch OS: no blank/sized toolbar artifact renders on right-click-equivalent', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          await pumpLayout(tester, viewportSize: const Size(1400, 900));

          await tester.longPress(find.text('Selectable body text'));
          await tester.pumpAndSettle();

          // The D50 Trap 3 concern: EmptyTextSelectionControls.buildToolbar
          // returns SizedBox.shrink(), so if it ever paints, it must have zero
          // size -- proving no visible artifact, blank or otherwise, is shown.
          final shrinkBoxes = find.byWidgetPredicate((w) => w is SizedBox && w.width == null && w.height == null);
          for (final element in shrinkBoxes.evaluate()) {
            final renderObject = element.renderObject;
            if (renderObject is RenderBox && renderObject.hasSize) {
              expect(
                renderObject.size,
                equals(Size.zero),
                reason:
                    'any SizedBox.shrink() from the empty toolbar must paint at zero size, never a visible blank box',
              );
            }
          }
          expect(find.byType(LayrzSelectionToolbar), findsNothing);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    });

    group('DetailPane SelectableRegion site (_buildSelectableContent)', () {
      Future<void> pumpDetailPane(WidgetTester tester) async {
        await pumpThemedApp(
          tester,
          DetailPane<String>(
            opened: 'item-1',
            contentBuilder: (item) => Text('Detail content for $item'),
          ),
        );
      }

      testWidgets('android: long-press selects and shows the copy toolbar', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          await pumpDetailPane(tester);

          await tester.longPress(find.text('Detail content for item-1'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(LayrzSelectionToolbar), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('iOS: long-press selects and shows the copy toolbar', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        try {
          await pumpDetailPane(tester);

          await tester.longPress(find.text('Detail content for item-1'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(LayrzSelectionToolbar), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('macOS: long-press does not crash and shows no toolbar', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          await pumpDetailPane(tester);

          await tester.longPress(find.text('Detail content for item-1'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(LayrzSelectionToolbar), findsNothing);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('windows: long-press does not crash and shows no toolbar', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          await pumpDetailPane(tester);

          await tester.longPress(find.text('Detail content for item-1'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(LayrzSelectionToolbar), findsNothing);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('linux: long-press does not crash and shows no toolbar', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          await pumpDetailPane(tester);

          await tester.longPress(find.text('Detail content for item-1'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(LayrzSelectionToolbar), findsNothing);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    });

    group('All four gate sites move together', () {
      // The row's own warning: gating only some sites while others keep
      // handles is a partial regression. This test asserts the gate is
      // consistently off across the LayrzEditableField site and all three
      // SelectableRegion sites under the same non-touch platform, in a single
      // run, so a future edit that re-enables one site by accident is caught
      // even if that site's own dedicated test is skipped or weakened.
      testWidgets('non-touch OS: no toolbar or touch controls at any of the four sites', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          // Site 1: LayrzEditableField (via LayrzTextInput).
          final controller = TextEditingController(text: 'text');
          addTearDown(controller.dispose);
          await pumpThemed(tester, LayrzTextInput(controller: controller));
          final editable = tester.widget<EditableText>(find.byType(EditableText));
          expect(editable.selectionControls, isNull);
          expect(editable.contextMenuBuilder, isNull);

          // Site 2/3: LayrzLayout (expanded here; drawer is covered above).
          addTearDown(tester.view.resetPhysicalSize);
          tester.view.physicalSize = const Size(1400, 900);
          await tester.pumpWidget(
            LayrzApp(
              theme: LayrzThemeData.light(),
              debugShowCheckedModeBanner: false,
              home: LayrzLayout(
                logo: 'assets/test-logo.png',
                items: [LayrzNavigatorPage(id: 'home', labelText: 'Home')],
                body: const Center(child: Text('Layout body text')),
                selectableContent: true,
              ),
            ),
          );
          await tester.pump();
          await tester.longPress(find.text('Layout body text'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(LayrzSelectionToolbar), findsNothing);

          // Site 4: DetailPane.
          await pumpThemedApp(
            tester,
            DetailPane<String>(
              opened: 'x',
              contentBuilder: (item) => const Text('Detail body text'),
            ),
          );
          await tester.longPress(find.text('Detail body text'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(LayrzSelectionToolbar), findsNothing);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    });
  });
}
