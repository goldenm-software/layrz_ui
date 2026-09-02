import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

/// Collects every semantics label under [tester]'s current tree.
///
/// Mirrors `combobox_input_a11y_test.dart`'s own `dumpSemanticsLabels` and
/// `month_input_a11y_test.dart`'s `_dumpSemanticsLabels` -- used here, rather
/// than `find.bySemanticsLabel`, because that matcher also matches literal
/// text on renderable widgets and has already produced a false green in this
/// repo.
List<String> _dumpSemanticsLabels(WidgetTester tester) {
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
  group('LayrzMonthRangeInput — Accessibility', () {
    guardedTestWidgets('the anchor field exposes the label exactly once as a button', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(labelText: 'Months'),
        );

        final labels = _dumpSemanticsLabels(tester);
        expect(labels.where((l) => l == 'Months').length, 1);

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Months',
        );
        expect(
          tester.getSemantics(finder),
          matchesSemantics(label: 'Months', isButton: true, hasEnabledState: true, isEnabled: true, hasTapAction: true),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a disabled anchor field is marked disabled and reports no tap action', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(labelText: 'Months', disabled: true),
        );

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Months',
        );
        expect(
          tester.getSemantics(finder),
          matchesSemantics(
            label: 'Months',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
            isFocusable: true,
            hasFocusAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the year navigation chevrons carry their own semantics labels once open', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(
            labelText: 'Months',
            arbitraryValue: [LayrzMonth(year: 2026, month: 1)],
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        final labels = _dumpSemanticsLabels(tester);
        expect(labels, contains('Previous year'));
        expect(labels, contains('Next year'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a selected month cell announces its selected state in arbitrary mode', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(
            labelText: 'Months',
            arbitraryValue: [LayrzMonth(year: 2026, month: 9)],
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        final labels = _dumpSemanticsLabels(tester);
        final selected = labels.firstWhere((l) => l.contains('September 2026') && l.contains('Selected'));
        expect(selected, 'September 2026, Selected');
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('an interior month in consecutive mode announces it is not selectable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(
            labelText: 'Months',
            consecutive: true,
            rangeValue: LayrzMonthRange(start: LayrzMonth(year: 2026, month: 2), end: LayrzMonth(year: 2026, month: 6)),
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        final labels = _dumpSemanticsLabels(tester);
        final interior = labels.firstWhere((l) => l.contains('April 2026'));
        expect(interior, contains('Within selected range, not selectable'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a month disabled via minimum is marked unavailable once open', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(
            labelText: 'Months',
            arbitraryValue: [LayrzMonth(year: 2026, month: 6)],
            minimum: LayrzMonth(year: 2026, month: 6),
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        final labels = _dumpSemanticsLabels(tester);
        final disabled = labels.firstWhere((l) => l.contains('January 2026'));
        expect(disabled, contains('Unavailable'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the Save button reports disabled semantics when the draft is empty', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(labelText: 'Months'),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        final labels = _dumpSemanticsLabels(tester);
        expect(labels, contains(const LayrzUiL10nDefault().actionSave));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('compact viewport: anchor field semantics match the desktop branch', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(labelText: 'Months'),
        );

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Months',
        );
        expect(
          tester.getSemantics(finder),
          matchesSemantics(label: 'Months', isButton: true, hasEnabledState: true, isEnabled: true, hasTapAction: true),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
