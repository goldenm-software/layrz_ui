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
/// path alongside the two default-closable tabs.
List<LayrzWorkspaceTab> _buildTabs() {
  return const [
    LayrzWorkspaceTab(id: 'a', label: 'Alpha'),
    LayrzWorkspaceTab(id: 'b', label: 'Beta'),
    LayrzWorkspaceTab(id: 'c', label: 'Gamma', closable: false),
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
  });

  group('LayrzWorkspaceTabs — empty state', () {
    guardedTestWidgets('an empty tabs list renders just the new-tab affordance', (tester) async {
      _setWideViewport(tester);

      await pumpThemed(
        tester,
        SizedBox(
          width: 700,
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
}
