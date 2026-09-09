import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  final items = <LayrzSelectItem<String>>[
    const LayrzSelectItem(value: 'apple', child: Text('Apple'), searchableStrings: {'Apple'}),
    const LayrzSelectItem(value: 'banana', child: Text('Banana'), searchableStrings: {'Banana'}),
  ];

  void setDesktopViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  void setCompactViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('LayrzDualListInput — Accessibility (desktop)', () {
    guardedTestWidgets('an Available row exposes a button, enabled, with a tap action', (tester) async {
      setDesktopViewport(tester);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzDualListInput<String>(labelText: 'Fruits', items: items, itemExtent: 48),
        );

        // The row's own Semantics(button: true, ...) is an ancestor of the
        // Text's own leaf semantics node, not merged with it (same shape as
        // `_MultiSelectItemRow`'s row in `multi_select_surface.dart`, whose
        // own a11y test asserts flags without a label for the same reason)
        // -- scoped by button flag rather than label.
        final rowFinder = find.ancestor(
          of: find.text('Apple'),
          matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.button == true),
        );
        final semantics = tester.getSemantics(rowFinder);
        expect(
          semantics,
          matchesSemantics(
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
        // The label itself is still reachable in the tree, on the Text's own
        // leaf semantics node.
        expect(find.bySemanticsLabel('Apple'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a disabled row reports no tap action', (tester) async {
      setDesktopViewport(tester);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzDualListInput<String>(labelText: 'Fruits', items: items, itemExtent: 48, disabled: true),
        );

        final rowFinder = find.ancestor(
          of: find.text('Apple'),
          matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.button == true),
        );
        final semantics = tester.getSemantics(rowFinder);
        expect(
          semantics,
          matchesSemantics(
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
            hasTapAction: false,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the move-all-to-selected affordance exposes its label, enabled, and is tappable', (
      tester,
    ) async {
      setDesktopViewport(tester);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzDualListInput<String>(labelText: 'Fruits', items: items, itemExtent: 48),
        );

        final finder = find.byWidgetPredicate(
          (widget) => widget is LayrzButton && widget.labelText == 'Toggle all to selected',
        );
        expect(finder, findsOneWidget);

        // LayrzButton's own Semantics node (`button.dart`) does not itself
        // carry a `tap` semantics action -- its GestureDetector sits inside
        // an `excludeSemantics: true` region, matching every existing
        // `button_a11y_test.dart` convention of asserting tappability via a
        // real tap rather than `matchesSemantics(hasTapAction: ...)`.
        expect(
          tester.getSemantics(finder),
          matchesSemantics(label: 'Toggle all to selected', isButton: true, hasEnabledState: true, isEnabled: true),
        );

        await tester.tap(finder);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('remains accessible at a desktop viewport with no thrown exception', (tester) async {
      setDesktopViewport(tester);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzDualListInput<String>(labelText: 'Fruits', items: items, itemExtent: 48, value: const ['apple']),
        );

        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    });
  });

  group('LayrzDualListInput — Accessibility (compact delegate)', () {
    guardedTestWidgets('the compact MultiSelect delegate anchor exposes the label as a button', (tester) async {
      setCompactViewport(tester);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzDualListInput<String>(labelText: 'Fruits', items: items, itemExtent: 48),
        );

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Fruits') ?? false),
        );
        expect(finder, findsOneWidget);

        expect(
          tester.getSemantics(finder),
          matchesSemantics(
            label: 'Fruits',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
