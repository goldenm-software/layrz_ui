import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/pickers/src/shared/focus_ring.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// Wraps [child] in a real, attachable [Focus] using [focusNode] — the
/// [FocusNode] a bare, unattached `FocusNode()` cannot receive via
/// [FocusNode.requestFocus] on its own, since a node only joins the focus
/// tree once some [Focus] widget in the tree attaches it. Every test in
/// this file needs [focusNode] to genuinely gain/lose focus (not merely
/// call an inert `requestFocus()`), because [LayrzFocusRing] itself never
/// attaches the node — it only listens to whichever [Focus] ancestor
/// (here, or in the real grids, the cell's own) already has.
Widget _attached(FocusNode focusNode, Widget child) {
  return Focus(
    focusNode: focusNode,
    child: LayrzFocusRing(focusNode: focusNode, child: child),
  );
}

void main() {
  group('LayrzFocusRing — D15 geometry compliance', () {
    guardedTestWidgets('the wrapped child has an identical size focused vs unfocused', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemed(
        tester,
        _attached(
          focusNode,
          Container(key: const ValueKey('cell'), width: 32.0, height: 32.0, color: const Color(0xFF00FF00)),
        ),
      );

      final unfocusedSize = tester.getSize(find.byKey(const ValueKey('cell')));

      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      final focusedSize = tester.getSize(find.byKey(const ValueKey('cell')));

      expect(focusedSize, unfocusedSize, reason: 'D15: a focus ring must never change the wrapped cell\'s own size.');
      expect(focusedSize, const Size(32.0, 32.0));
    });

    guardedTestWidgets("the ring's own overlay box matches the child's box exactly (no inset/outset)", (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemed(
        tester,
        _attached(
          focusNode,
          Container(key: const ValueKey('cell'), width: 40.0, height: 40.0, color: const Color(0xFF0000FF)),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // LayrzFocusRing itself (the Stack) must occupy exactly the child's
      // rect -- Positioned.fill over a Stack sized by its one non-positioned
      // child, per the class doc's D15 note.
      final ringRect = tester.getRect(find.byType(LayrzFocusRing));
      final childRect = tester.getRect(find.byKey(const ValueKey('cell')));

      expect(ringRect, childRect);
    });
  });

  group('LayrzFocusRing — focus-visible behaviour', () {
    guardedTestWidgets('no border is painted while unfocused', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemed(tester, _attached(focusNode, const SizedBox(width: 32.0, height: 32.0)));

      final decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      final ringBox = decoratedBoxes.firstWhere((box) => box.decoration is BoxDecoration);
      final decoration = ringBox.decoration as BoxDecoration;

      expect(decoration.border, isNull);
    });

    guardedTestWidgets('a border is painted while focused, using the theme primary colour', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      final theme = LayrzThemeData.light();

      await pumpThemed(
        tester,
        _attached(focusNode, const SizedBox(width: 32.0, height: 32.0)),
        theme: theme,
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      final decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      final ringBox = decoratedBoxes.firstWhere((box) => (box.decoration as BoxDecoration).border != null);
      final decoration = ringBox.decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
      expect(decoration.border!.top.color, theme.tokens.colors.primary.shade500);
    });

    guardedTestWidgets('the border disappears again once focus moves away', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final ringFocusNode = FocusNode();
      final otherFocusNode = FocusNode();
      addTearDown(ringFocusNode.dispose);
      addTearDown(otherFocusNode.dispose);

      await pumpThemed(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _attached(ringFocusNode, const SizedBox(width: 32.0, height: 32.0)),
            Focus(focusNode: otherFocusNode, child: const SizedBox(width: 10.0, height: 10.0)),
          ],
        ),
      );

      ringFocusNode.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(ringFocusNode.hasFocus, isTrue);

      var decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      var ringBox = decoratedBoxes.firstWhere((box) => (box.decoration as BoxDecoration).border != null);
      expect((ringBox.decoration as BoxDecoration).border, isNotNull);

      otherFocusNode.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(ringFocusNode.hasFocus, isFalse);

      decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      final stillHasBorder = decoratedBoxes.any((box) => (box.decoration as BoxDecoration).border != null);
      expect(stillHasBorder, isFalse);
    });

    guardedTestWidgets('a custom borderWidth is honoured while focused', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemed(
        tester,
        Focus(
          focusNode: focusNode,
          child: LayrzFocusRing(
            focusNode: focusNode,
            borderWidth: 3.5,
            child: const SizedBox(width: 32.0, height: 32.0),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      final decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      final ringBox = decoratedBoxes.firstWhere((box) => (box.decoration as BoxDecoration).border != null);
      final decoration = ringBox.decoration as BoxDecoration;

      expect(decoration.border!.top.width, 3.5);
    });
  });

  group('LayrzFocusRing — focusNode swap lifecycle', () {
    guardedTestWidgets('swapping to a new focusNode via didUpdateWidget stops reacting to the old one', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final firstNode = FocusNode();
      final secondNode = FocusNode();
      addTearDown(firstNode.dispose);
      addTearDown(secondNode.dispose);

      late StateSetter setInnerState;
      var useSecondNode = false;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            setInnerState = setState;
            return _attached(useSecondNode ? secondNode : firstNode, const SizedBox(width: 32.0, height: 32.0));
          },
        ),
      );

      firstNode.requestFocus();
      await tester.pumpAndSettle();
      expect(firstNode.hasFocus, isTrue);

      var decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      expect(decoratedBoxes.any((box) => (box.decoration as BoxDecoration).border != null), isTrue);

      // Swap LayrzFocusRing's own focusNode parameter from firstNode to
      // secondNode via setState -- this is didUpdateWidget's real trigger
      // (same State, same tree position, new focusNode value), unlike a
      // full pumpWidget replacement which tears the old tree down instead
      // of updating it in place.
      setInnerState(() => useSecondNode = true);
      await tester.pumpAndSettle();

      // secondNode was never focused, so no border should paint regardless
      // of whatever became of firstNode's own focus state.
      decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      expect(decoratedBoxes.any((box) => (box.decoration as BoxDecoration).border != null), isFalse);

      // firstNode is no longer the node LayrzFocusRing listens to -- even
      // if the SDK still lets it be re-focused as a detached node, that
      // must not resurrect a border in this tree.
      firstNode.requestFocus();
      await tester.pumpAndSettle();

      decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      expect(decoratedBoxes.any((box) => (box.decoration as BoxDecoration).border != null), isFalse);

      // Focusing secondNode now, after the swap, DOES paint the border --
      // proving LayrzFocusRing is actively listening to the new node.
      secondNode.requestFocus();
      await tester.pumpAndSettle();

      decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      expect(decoratedBoxes.any((box) => (box.decoration as BoxDecoration).border != null), isTrue);
    });
  });

  group('LayrzFocusRing — accessibility', () {
    guardedTestWidgets('the ring does not alter the semantics of its child', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          _attached(
            focusNode,
            Semantics(
              label: 'A test cell',
              button: true,
              child: const SizedBox(width: 32.0, height: 32.0),
            ),
          ),
        );

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'A test cell',
        );
        expect(finder, findsOneWidget);
        expect(
          tester.getSemantics(finder),
          matchesSemantics(label: 'A test cell', isButton: true, isFocusable: true, hasFocusAction: true),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
