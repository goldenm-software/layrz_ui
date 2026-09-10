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
      "the active tab's open border colour and width match the panel border's, for a seamless outline",
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
        // The active tab's rect is reported to the panel post-frame; let
        // that settle so the panel's gap span is resolved too.
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

        final tabChromePainters = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter)
            .whereType<LayrzWorkspaceTabChromePainter>()
            .where((p) => p.mergeBottom)
            .toList();
        expect(tabChromePainters, hasLength(1), reason: 'exactly one tab should render as the active (merged) one');
        final activeTabPainter = tabChromePainters.single;

        final panelPainter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter)
            .whereType<LayrzWorkspacePanelBorderPainter>()
            .single;

        expect(activeTabPainter.borderColor, tokens.colors.divider);
        expect(activeTabPainter.borderColor, panelPainter.borderColor);
        expect(activeTabPainter.borderWidth, tokens.border.stroke1);
        expect(activeTabPainter.borderWidth, panelPainter.borderWidth);
      },
    );
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
