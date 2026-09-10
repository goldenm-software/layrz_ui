import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

/// Builds a fixed list of three [LayrzWorkspaceTab]s for reuse across tests.
///
/// The third tab is `closable: false`, so tests can assert the non-closable
/// path alongside the two default-closable tabs. Each tab's `left` is a
/// distinctly-labeled [Text] so panel-content assertions can target it by
/// its own text without colliding with the tab's own strip label.
List<LayrzWorkspaceTab> _buildTabs() {
  return const [
    LayrzWorkspaceTab(id: 'a', label: 'Alpha', left: Text('Alpha panel content')),
    LayrzWorkspaceTab(id: 'b', label: 'Beta', left: Text('Beta panel content')),
    LayrzWorkspaceTab(id: 'c', label: 'Gamma', closable: false, left: Text('Gamma panel content')),
  ];
}

/// Sets a wide desktop viewport (well above the 960px compact threshold) and
/// registers its reset, so every test in this file exercises the same fixed
/// layout regardless of suite ordering.
void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('LayrzWorkspaceTabs — selection', () {
    guardedTestWidgets('tapping a tab fires onTabSelected with its id', (tester) async {
      _setWideViewport(tester);
      String? selected;

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'a',
            onTabSelected: (id) => selected = id,
          ),
        ),
      );

      await tester.tap(find.text('Beta'));
      await tester.pump();

      expect(selected, 'b');
    });

    guardedTestWidgets('tapping the already-active tab still fires onTabSelected with its own id', (tester) async {
      _setWideViewport(tester);
      String? selected;

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'a',
            onTabSelected: (id) => selected = id,
          ),
        ),
      );

      await tester.tap(find.text('Alpha'));
      await tester.pump();

      expect(selected, 'a');
    });
  });

  group('LayrzWorkspaceTabs — close', () {
    guardedTestWidgets('the close affordance is visible on an inactive closable tab without hovering it', (
      tester,
    ) async {
      _setWideViewport(tester);
      String? closed;

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'a',
            onTabSelected: (_) {},
            onTabClosed: (id) => closed = id,
          ),
        ),
      );

      // Beta ('b') is inactive and closable, and no pointer has hovered it —
      // the close (×) affordance must already be visible: it is no longer
      // hover-gated.
      expect(find.text('Beta'), findsOneWidget);
      expect(find.bySemanticsLabel('Close Beta'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Close Beta'));
      await tester.pump();

      expect(closed, 'b');
    });

    guardedTestWidgets('the close affordance is visible on the active closable tab too', (tester) async {
      _setWideViewport(tester);

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'a',
            onTabSelected: (_) {},
            onTabClosed: (_) {},
          ),
        ),
      );

      expect(find.bySemanticsLabel('Close Alpha'), findsOneWidget);
    });

    guardedTestWidgets("the close affordance's position does not shift when the tab is hovered", (tester) async {
      _setWideViewport(tester);

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'a',
            onTabSelected: (_) {},
            onTabClosed: (_) {},
          ),
        ),
      );

      final unhoveredCenter = tester.getCenter(find.bySemanticsLabel('Close Beta'));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Beta')));
      await tester.pump();

      final hoveredCenter = tester.getCenter(find.bySemanticsLabel('Close Beta'));

      expect(hoveredCenter, unhoveredCenter);
    });

    guardedTestWidgets('a non-closable tab renders no close affordance and emits nothing', (tester) async {
      _setWideViewport(tester);
      String? closed;

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'c',
            onTabSelected: (_) {},
            onTabClosed: (id) => closed = id,
          ),
        ),
      );

      // Gamma (id 'c') is closable: false and is the active tab -- if a
      // close affordance rendered at all it would show here, since active
      // tabs always reveal it. It must not.
      expect(find.bySemanticsLabel('Close Gamma'), findsNothing);
      expect(closed, isNull);
    });

    guardedTestWidgets('a null onTabClosed hides every tab\'s close affordance, even the active one', (
      tester,
    ) async {
      _setWideViewport(tester);

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'a',
            onTabSelected: (_) {},
          ),
        ),
      );

      expect(find.bySemanticsLabel('Close Alpha'), findsNothing);
      expect(find.bySemanticsLabel('Close Beta'), findsNothing);
    });
  });

  group('LayrzWorkspaceTabs — new tab', () {
    guardedTestWidgets('the new-tab affordance fires onNewTab when pressed', (tester) async {
      _setWideViewport(tester);
      var newTabCount = 0;

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'a',
            onTabSelected: (_) {},
            onNewTab: () => newTabCount++,
          ),
        ),
      );

      expect(find.bySemanticsLabel('New tab'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('New tab'));
      await tester.pump();

      expect(newTabCount, 1);
    });

    guardedTestWidgets('a null onNewTab hides the new-tab affordance entirely', (tester) async {
      _setWideViewport(tester);

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'a',
            onTabSelected: (_) {},
          ),
        ),
      );

      expect(find.bySemanticsLabel('New tab'), findsNothing);
    });
  });

  group('LayrzWorkspaceTabs — reorder', () {
    guardedTestWidgets('dragging a tab across a neighbour fires onReorder with the crossed indices', (
      tester,
    ) async {
      _setWideViewport(tester);
      final events = <(int, int)>[];

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'a',
            onTabSelected: (_) {},
            onReorder: (oldIndex, newIndex) => events.add((oldIndex, newIndex)),
          ),
        ),
      );

      final betaCenter = tester.getCenter(find.text('Beta'));
      final gammaCenter = tester.getCenter(find.text('Gamma'));

      final gesture = await tester.startGesture(betaCenter);
      // Drag past Gamma's centre so the pointer resolves onto Gamma's box.
      await gesture.moveTo(gammaCenter + const Offset(20, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(events, isNotEmpty);
      expect(events.first, (1, 2));
    });

    guardedTestWidgets('a null onReorder disables dragging -- no reorder event and no drag visuals', (
      tester,
    ) async {
      _setWideViewport(tester);

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'a',
            onTabSelected: (_) {},
          ),
        ),
      );

      final betaCenter = tester.getCenter(find.text('Beta'));
      final gammaCenter = tester.getCenter(find.text('Gamma'));

      final gesture = await tester.startGesture(betaCenter);
      await gesture.moveTo(gammaCenter + const Offset(20, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // Nothing to assert on a callback that does not exist -- the
      // meaningful assertion is that no exception was thrown driving a full
      // drag gesture with reordering disabled, and the labels are unchanged.
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
    });
  });

  group('LayrzWorkspaceTabs — active vs inactive rendering', () {
    guardedTestWidgets('the active tab is bold; an inactive tab is not', (tester) async {
      _setWideViewport(tester);

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'a',
            onTabSelected: (_) {},
          ),
        ),
      );

      final activeText = tester.widget<Text>(find.text('Alpha'));
      final inactiveText = tester.widget<Text>(find.text('Beta'));

      expect(activeText.style?.fontWeight, FontWeight.w600);
      expect(inactiveText.style?.fontWeight, isNot(FontWeight.w600));
    });

    guardedTestWidgets('switching activeId flips which tab is bold', (tester) async {
      _setWideViewport(tester);

      var activeId = 'a';
      late StateSetter setState;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setter) {
            setState = setter;
            return SizedBox(
              width: 700,
              height: 400,
              child: LayrzWorkspaceTabs(
                tabs: _buildTabs(),
                activeId: activeId,
                onTabSelected: (_) {},
              ),
            );
          },
        ),
      );

      expect(tester.widget<Text>(find.text('Alpha')).style?.fontWeight, FontWeight.w600);
      expect(tester.widget<Text>(find.text('Beta')).style?.fontWeight, isNot(FontWeight.w600));

      setState(() => activeId = 'b');
      await tester.pump();

      expect(tester.widget<Text>(find.text('Alpha')).style?.fontWeight, isNot(FontWeight.w600));
      expect(tester.widget<Text>(find.text('Beta')).style?.fontWeight, FontWeight.w600);
    });

    guardedTestWidgets(
      'the active tab + card silhouette is layered twice -- fill+stroke beneath the strip, stroke-only above it',
      (tester) async {
        _setWideViewport(tester);

        await pumpThemed(
          tester,
          SizedBox(
            width: 700,
            height: 400,
            child: LayrzWorkspaceTabs(
              tabs: _buildTabs(),
              activeId: 'a',
              onTabSelected: (_) {},
            ),
          ),
        );
        // The active tab's rect is reported to the silhouette post-frame;
        // let that settle so its tab-bump span is resolved too.
        await tester.pump();

        // Move the roving keyboard-traversal highlight off the active tab
        // (it starts tracking the active tab by default -- see
        // `_LayrzWorkspaceTabStripState._syncFocusedIndex`), so this test
        // exercises the active tab's *default* look, not its focus-ring
        // override. See the "ArrowRight then Enter activates the next tab"
        // keyboard test above for the same pattern.
        await tester.tap(find.text('Alpha'));
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        final tokens = LayrzTheme.of(tester.element(find.text('Alpha'))).tokens;

        final silhouettePainters = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter)
            .whereType<LayrzWorkspaceSilhouettePainter>()
            .toList();
        // Exactly two: a fill+stroke copy beneath the strip and a
        // stroke-only copy above it, so the active tab's border is never
        // cropped by an adjacent inactive tab's opaque fill -- see
        // `LayrzWorkspaceTabs`'s `Stack` and its `_silhouettePainter` helper.
        expect(silhouettePainters, hasLength(2));

        final fillLayer = silhouettePainters.firstWhere((p) => !p.strokeOnly);
        final strokeLayer = silhouettePainters.firstWhere((p) => p.strokeOnly);

        // Both layers build the identical path from the identical geometry,
        // differing only in `strokeOnly`.
        for (final silhouette in [fillLayer, strokeLayer]) {
          expect(silhouette.fillColor, tokens.colors.sf1);
          expect(silhouette.borderColor, tokens.colors.primary.shade500);
          expect(silhouette.borderWidth, 1.5);
          expect(silhouette.tabLeft, isNotNull);
          expect(silhouette.tabRight, isNotNull);
          expect(silhouette.tabHeight, greaterThan(0.0));
        }
        expect(fillLayer.strokeOnly, isFalse);
        expect(strokeLayer.strokeOnly, isTrue);

        // The active tab's own `LayrzWorkspaceTabChromePainter` (rendered by
        // its `LayrzWorkspaceTabItem`, unfocused here) contributes no fill
        // and no border of its own -- the silhouette above is the only
        // thing painting that region.
        final activeTabItem = tester
            .widgetList<LayrzWorkspaceTabItem>(find.byType(LayrzWorkspaceTabItem))
            .firstWhere((item) => item.tab.label == 'Alpha');
        expect(activeTabItem.isActive, isTrue);

        final activeChromePainter = tester
            .widgetList<CustomPaint>(
              find.descendant(of: find.byWidget(activeTabItem), matching: find.byType(CustomPaint)),
            )
            .map((w) => w.painter)
            .whereType<LayrzWorkspaceTabChromePainter>()
            .single;
        expect(activeChromePainter.fillColor, const Color(0x00000000));
        expect(activeChromePainter.borderColor, isNull);
      },
    );

    guardedTestWidgets(
      'the active tab draws no closed chrome border of its own even when it holds keyboard focus',
      (tester) async {
        _setWideViewport(tester);

        await pumpThemed(
          tester,
          SizedBox(
            width: 700,
            height: 400,
            child: LayrzWorkspaceTabs(
              tabs: _buildTabs(),
              activeId: 'a',
              onTabSelected: (_) {},
            ),
          ),
        );
        await tester.pump();

        // The strip's roving keyboard-traversal highlight tracks the active
        // tab by default (`_LayrzWorkspaceTabStripState._syncFocusedIndex`),
        // so giving the strip focus alone is enough to put the *active* tab
        // (Alpha) into the focused index -- unlike the sibling test above,
        // this one does NOT press ArrowRight, so the active tab stays the
        // focused one.
        await tester.tap(find.text('Alpha'));
        await tester.pump();

        final activeTabItem = tester
            .widgetList<LayrzWorkspaceTabItem>(find.byType(LayrzWorkspaceTabItem))
            .firstWhere((item) => item.tab.label == 'Alpha');
        expect(activeTabItem.isActive, isTrue);
        expect(activeTabItem.isFocused, isTrue);

        // Even focused, the active tab's own chrome painter must still pass
        // a null border -- `LayrzWorkspaceTabItem.build` hardcodes
        // `!widget.isActive && widget.isFocused` for both `borderColor` and
        // `borderWidth`, so an active+focused tab never draws a closed focus
        // ring of its own; only an inactive+focused tab does.
        final activeChromePainter = tester
            .widgetList<CustomPaint>(
              find.descendant(of: find.byWidget(activeTabItem), matching: find.byType(CustomPaint)),
            )
            .map((w) => w.painter)
            .whereType<LayrzWorkspaceTabChromePainter>()
            .single;
        expect(activeChromePainter.borderColor, isNull);

        // Contrast: an inactive tab that is the focused index DOES draw a
        // closed focus ring border.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        final nowFocusedTabItem = tester
            .widgetList<LayrzWorkspaceTabItem>(find.byType(LayrzWorkspaceTabItem))
            .firstWhere((item) => item.tab.label == 'Beta');
        expect(nowFocusedTabItem.isActive, isFalse);
        expect(nowFocusedTabItem.isFocused, isTrue);

        final inactiveFocusedChromePainter = tester
            .widgetList<CustomPaint>(
              find.descendant(of: find.byWidget(nowFocusedTabItem), matching: find.byType(CustomPaint)),
            )
            .map((w) => w.painter)
            .whereType<LayrzWorkspaceTabChromePainter>()
            .single;
        expect(inactiveFocusedChromePainter.borderColor, isNotNull);
      },
    );
  });

  group('LayrzWorkspaceTabs — browser frame', () {
    guardedTestWidgets('the whole widget sits inside a rounded sf2 frame with sp1 padding', (tester) async {
      _setWideViewport(tester);

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'a',
            onTabSelected: (_) {},
          ),
        ),
      );

      final tokens = LayrzTheme.of(tester.element(find.byType(LayrzWorkspaceTabs))).tokens;

      final frame = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(LayrzWorkspaceTabs), matching: find.byType(DecoratedBox)).first,
      );
      final decoration = frame.decoration as BoxDecoration;
      expect(decoration.color, tokens.colors.sf2);
      expect(decoration.borderRadius, tokens.radius.br3);

      final padding = tester.widget<Padding>(
        find.descendant(of: find.byType(DecoratedBox), matching: find.byType(Padding)).first,
      );
      expect(padding.padding, tokens.spacing.pd1);
    });

    guardedTestWidgets('the sf1 card fills to the frame\'s inner edge (the frame\'s radius minus its sp1 inset)', (
      tester,
    ) async {
      _setWideViewport(tester);

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'a',
            onTabSelected: (_) {},
          ),
        ),
      );
      await tester.pump();

      final tokens = LayrzTheme.of(tester.element(find.byType(LayrzWorkspaceTabs))).tokens;
      final expectedCardRadius = tokens.radius.innerRadiusValue(
        outerRadius: tokens.radius.r3,
        spacer: tokens.spacing.sp1,
      );

      // Both the fill+stroke and stroke-only silhouette layers share the
      // identical geometry, so either one attests to the shared panelRadius.
      final silhouettePainters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<LayrzWorkspaceSilhouettePainter>()
          .toList();
      expect(silhouettePainters, hasLength(2));
      for (final silhouette in silhouettePainters) {
        expect(silhouette.panelRadius, expectedCardRadius);
      }
    });
  });

  group('LayrzWorkspaceTabs — empty state', () {
    guardedTestWidgets('an empty tabs list renders just the new-tab affordance', (tester) async {
      _setWideViewport(tester);

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: const [],
            activeId: 'missing',
            onTabSelected: (_) {},
            onNewTab: () {},
          ),
        ),
      );

      expect(find.bySemanticsLabel('New tab'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);
    });

    guardedTestWidgets('an empty tabs list with no onNewTab renders no tab and no new-tab affordance', (
      tester,
    ) async {
      _setWideViewport(tester);

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: const [],
            activeId: 'missing',
            onTabSelected: (_) {},
          ),
        ),
      );

      expect(find.bySemanticsLabel('New tab'), findsNothing);
    });
  });

  group('LayrzWorkspaceTabs — accessibility', () {
    guardedTestWidgets('the active tab exposes button semantics marked selected', (tester) async {
      _setWideViewport(tester);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 700,
            height: 400,
            child: LayrzWorkspaceTabs(
              tabs: _buildTabs(),
              activeId: 'a',
              onTabSelected: (_) {},
            ),
          ),
        );

        expect(
          tester.getSemantics(find.text('Alpha')),
          matchesSemantics(
            label: 'Alpha',
            isButton: true,
            hasSelectedState: true,
            isSelected: true,
            hasTapAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('an inactive tab exposes button semantics marked not selected', (tester) async {
      _setWideViewport(tester);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 700,
            height: 400,
            child: LayrzWorkspaceTabs(
              tabs: _buildTabs(),
              activeId: 'a',
              onTabSelected: (_) {},
            ),
          ),
        );

        expect(
          tester.getSemantics(find.text('Beta')),
          matchesSemantics(
            label: 'Beta',
            isButton: true,
            hasSelectedState: true,
            isSelected: false,
            hasTapAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the close affordance is labeled "Close <label>" and is a button', (tester) async {
      _setWideViewport(tester);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 700,
            height: 400,
            child: LayrzWorkspaceTabs(
              tabs: _buildTabs(),
              activeId: 'a',
              onTabSelected: (_) {},
              onTabClosed: (_) {},
            ),
          ),
        );

        expect(
          tester.getSemantics(find.bySemanticsLabel('Close Alpha')),
          matchesSemantics(label: 'Close Alpha', isButton: true, hasTapAction: true),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the new-tab affordance is labeled "New tab" and is a button', (tester) async {
      _setWideViewport(tester);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 700,
            height: 400,
            child: LayrzWorkspaceTabs(
              tabs: _buildTabs(),
              activeId: 'a',
              onTabSelected: (_) {},
              onNewTab: () {},
            ),
          ),
        );

        expect(
          tester.getSemantics(find.bySemanticsLabel('New tab')),
          matchesSemantics(label: 'New tab', isButton: true, hasTapAction: true),
        );
      } finally {
        handle.dispose();
      }
    });
  });

  group('LayrzWorkspaceTabs — keyboard', () {
    guardedTestWidgets('ArrowRight then Enter activates the next tab', (tester) async {
      _setWideViewport(tester);
      String? selected;

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'a',
            onTabSelected: (id) => selected = id,
          ),
        ),
      );

      // Give the strip's Focus node primary focus so key events route to it.
      await tester.tap(find.text('Alpha'));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(selected, 'b');
    });
  });

  group('LayrzWorkspaceTabs — text selection', () {
    guardedTestWidgets('a tab\'s label sits under a SelectionContainer.disabled ancestor', (tester) async {
      _setWideViewport(tester);

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'a',
            onTabSelected: (_) {},
          ),
        ),
      );

      final labelElement = tester.element(find.text('Alpha'));
      final registrar = SelectionContainer.maybeOf(labelElement);

      // `SelectionContainer.disabled` installs a registrar whose
      // `SelectionRegistrar` is null-safe but non-functional for the
      // widgets beneath it, so the label's own registrar resolves to null —
      // the same signature `LayrzTabView`'s disabled pills produce.
      expect(registrar, isNull);
    });
  });

  group('LayrzWorkspaceTabs — connected content panel', () {
    guardedTestWidgets('the active tab\'s left content renders in the panel', (tester) async {
      _setWideViewport(tester);

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: _buildTabs(),
            activeId: 'a',
            onTabSelected: (_) {},
          ),
        ),
      );

      expect(find.text('Alpha panel content'), findsOneWidget);
      expect(find.text('Beta panel content'), findsNothing);
      expect(find.text('Gamma panel content'), findsNothing);
    });

    guardedTestWidgets('switching activeId swaps the panel content', (tester) async {
      _setWideViewport(tester);

      var activeId = 'a';
      late StateSetter setState;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setter) {
            setState = setter;
            return SizedBox(
              width: 700,
              height: 400,
              child: LayrzWorkspaceTabs(
                tabs: _buildTabs(),
                activeId: activeId,
                onTabSelected: (_) {},
              ),
            );
          },
        ),
      );

      expect(find.text('Alpha panel content'), findsOneWidget);
      expect(find.text('Beta panel content'), findsNothing);

      setState(() => activeId = 'b');
      await tester.pump();

      expect(find.text('Alpha panel content'), findsNothing);
      expect(find.text('Beta panel content'), findsOneWidget);
    });

    guardedTestWidgets('a tab with no right renders only left, filling the panel', (tester) async {
      _setWideViewport(tester);

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: const [
              LayrzWorkspaceTab(id: 'solo', label: 'Solo', left: Text('Solo left pane')),
            ],
            activeId: 'solo',
            onTabSelected: (_) {},
          ),
        ),
      );

      expect(find.text('Solo left pane'), findsOneWidget);
      expect(find.byType(LayrzWorkspaceSplitView), findsNothing);
    });

    guardedTestWidgets('a tab with a non-null right renders both left and right in a split view', (tester) async {
      _setWideViewport(tester);

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
          height: 400,
          child: LayrzWorkspaceTabs(
            tabs: const [
              LayrzWorkspaceTab(
                id: 'split',
                label: 'Split',
                left: Text('Split left pane'),
                right: Text('Split right pane'),
              ),
            ],
            activeId: 'split',
            onTabSelected: (_) {},
          ),
        ),
      );

      expect(find.byType(LayrzWorkspaceSplitView), findsOneWidget);
      expect(find.text('Split left pane'), findsOneWidget);
      expect(find.text('Split right pane'), findsOneWidget);
    });
  });

  group('LayrzWorkspaceSplitView — resizable divider', () {
    guardedTestWidgets('dragging the divider changes the split ratio', (tester) async {
      _setWideViewport(tester);
      double ratio = 0.5;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setter) {
            return SizedBox(
              width: 700,
              height: 300,
              child: LayrzWorkspaceSplitView(
                left: const ColoredBox(color: Color(0xFFEEEEEE), child: Text('Left pane')),
                right: const ColoredBox(color: Color(0xFFDDDDDD), child: Text('Right pane')),
                ratio: ratio,
                onRatioChanged: (value) => setter(() => ratio = value),
              ),
            );
          },
        ),
      );

      final dividerCenter = tester.getCenter(find.bySemanticsLabel('Resize split'));

      final gesture = await tester.startGesture(dividerCenter);
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(ratio, greaterThan(0.5));
    });

    guardedTestWidgets('dragging past the minimum pane extent clamps rather than collapsing the pane', (
      tester,
    ) async {
      _setWideViewport(tester);
      double ratio = 0.5;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setter) {
            return SizedBox(
              width: 700,
              height: 300,
              child: LayrzWorkspaceSplitView(
                left: const ColoredBox(color: Color(0xFFEEEEEE), child: Text('Left pane')),
                right: const ColoredBox(color: Color(0xFFDDDDDD), child: Text('Right pane')),
                ratio: ratio,
                onRatioChanged: (value) => setter(() => ratio = value),
              ),
            );
          },
        ),
      );

      final dividerCenter = tester.getCenter(find.bySemanticsLabel('Resize split'));

      // Drag far past the left edge -- a naive implementation would collapse
      // the left pane to zero (or negative) width; the clamp must keep it at
      // least kLayrzWorkspaceSplitMinPaneExtent wide.
      final gesture = await tester.startGesture(dividerCenter);
      await gesture.moveBy(const Offset(-2000, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final usableWidth = 700 - 10.0; // 700 total minus the token-driven divider width (sp2).
      final minRatio = kLayrzWorkspaceSplitMinPaneExtent / usableWidth;
      expect(ratio, greaterThanOrEqualTo(minRatio - 0.01));
      expect(ratio, lessThan(0.5));
    });

    guardedTestWidgets('the divider exposes an adjustable separator-style semantics node', (tester) async {
      _setWideViewport(tester);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 700,
            height: 300,
            child: LayrzWorkspaceSplitView(
              left: const Text('Left pane'),
              right: const Text('Right pane'),
              ratio: 0.5,
              onRatioChanged: (_) {},
            ),
          ),
        );

        expect(
          tester.getSemantics(find.bySemanticsLabel('Resize split')),
          matchesSemantics(
            label: 'Resize split',
            isSlider: true,
            value: '50%',
            hasIncreaseAction: true,
            hasDecreaseAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
