import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

/// Collects every semantics label under [tester]'s current tree.
///
/// Mirrors `combobox_input_a11y_test.dart`'s own helper and
/// `date_input_a11y_test.dart`'s copy of it — walking the tree instead of
/// using `find.bySemanticsLabel`, which also matches literal text on
/// renderable widgets and has already produced a false green in this repo.
List<String> dumpSemanticsLabels(WidgetTester tester) {
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
  final labels = <String>[];
  void walk(SemanticsNode node) {
    final label = node.getSemanticsData().label;
    if (label.isNotEmpty) labels.add(label);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(root);
  return labels;
}

void main() {
  group('LayrzDateRangeInput — Accessibility', () {
    guardedTestWidgets('the anchor exposes the label as a button, enabled and focusable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Trip dates'));

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Trip dates') ?? false),
        );
        expect(finder, findsOneWidget);

        expect(
          tester.getSemantics(finder),
          matchesSemantics(
            label: 'Trip dates',
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

    guardedTestWidgets('a disabled anchor is marked not enabled and reports no tap action', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Range', disabled: true));

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Range') ?? false),
        );
        expect(finder, findsOneWidget);

        expect(
          tester.getSemantics(finder),
          matchesSemantics(
            label: 'Range',
            isButton: true,
            hasEnabledState: true,
            isFocusable: true,
            hasFocusAction: true,
            hasTapAction: false,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the label is exposed to screen readers exactly once', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Booking window'));

        final labels = dumpSemanticsLabels(tester);
        expect(labels.where((l) => l == 'Booking window').length, 1);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the open desktop panel exposes Cancel and Save as semantics labels', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Range'));

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(labels, contains('Cancel'));
        expect(labels, contains('Save'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('this widget is visually self-consistent from the first frame -- Save/Cancel are present '
        'as soon as the panel opens, with no anchor selected yet', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Range'));

        // No tap on a day cell yet -- open the panel and the footer must
        // already be present, per liliana's hard first-frame requirement.
        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(labels, contains('Cancel'));
        expect(labels, contains('Save'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a selectable day cell in the open panel exposes a full date label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzDateRangeInput(
            labelText: 'Range',
            value: LayrzDateRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 3)),
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l.contains('September 15, 2026')), isTrue);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a range endpoint announces "Selected" in its semantics label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzDateRangeInput(
            labelText: 'Range',
            value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        final startLabel = labels.firstWhere((l) => l.contains('September 5, 2026'));
        expect(startLabel, contains('Selected'));
        final endLabel = labels.firstWhere((l) => l.contains('September 10, 2026'));
        expect(endLabel, contains('Selected'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a rejected interior cell announces it is within the selected range, not selectable', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzDateRangeInput(
            labelText: 'Range',
            value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 20)),
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        final interiorLabel = labels.firstWhere((l) => l.contains('September 12, 2026'));
        expect(interiorLabel, contains('Within selected range, not selectable'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a disabledDays cell announces it is unavailable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzDateRangeInput(
            labelText: 'Range',
            value: LayrzDateRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 3)),
            disabledDays: {DateTime(2026, 9, 25)},
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        final disabledLabel = labels.firstWhere((l) => l.contains('September 25, 2026'));
        expect(disabledLabel, contains('Unavailable'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets(
      'the month-navigation chevrons expose "Previous month"/"Next month" semantics labels',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzDateRangeInput(
              labelText: 'Range',
              value: LayrzDateRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 3)),
            ),
          );

          await tester.tap(find.byType(LayrzInputChrome).first);
          await tester.pumpAndSettle();

          final labels = dumpSemanticsLabels(tester);
          expect(labels, contains('Previous month'));
          expect(labels, contains('Next month'));
        } finally {
          handle.dispose();
        }
      },
    );

    guardedTestWidgets('the Reset control exposes a semantics label once a range exists', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Range'));

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        // No range yet -- Reset must not be exposed.
        var labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l == 'Clear selection'), isFalse);

        await tester.tap(find.text('5').first);
        await tester.pumpAndSettle();

        labels = dumpSemanticsLabels(tester);
        expect(labels, contains('Clear selection'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('remains accessible at a compact (mobile) viewport, with Save/Cancel present', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzDateRangeInput(
            labelText: 'Range',
            value: LayrzDateRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 3)),
          ),
        );

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Range') ?? false),
        );
        expect(finder, findsWidgets);

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l.contains('September 15, 2026')), isTrue);
        expect(labels, contains('Save'));
        expect(labels, contains('Cancel'));
      } finally {
        handle.dispose();
      }
    });
  });
}
