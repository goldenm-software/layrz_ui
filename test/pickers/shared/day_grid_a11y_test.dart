import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/shared/day_grid.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// Collects every semantics label under [tester]'s current tree.
///
/// Mirrors `combobox_input_a11y_test.dart`'s own helper — see that file for
/// the DESIGN-161 rationale for walking the tree instead of using
/// `find.bySemanticsLabel`.
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
  group('LayrzPickersDayGrid — Accessibility', () {
    guardedTestWidgets('a selectable day cell exposes a full date label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzPickersDayGrid(displayedMonth: DateTime(2026, 9), onDayTap: (_) {}),
        );

        final labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l.contains('September 15, 2026')), isTrue);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a disabled day cell is marked not enabled', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzPickersDayGrid(
            displayedMonth: DateTime(2026, 9),
            disabledDays: {DateTime(2026, 9, 15)},
            onDayTap: (_) {},
          ),
        );

        final labels = dumpSemanticsLabels(tester);
        final disabledLabel = labels.firstWhere((l) => l.contains('September 15, 2026'));
        expect(disabledLabel, contains('Unavailable'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a rejected interior day cell announces it is not selectable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzPickersDayGrid(
            displayedMonth: DateTime(2026, 9),
            rangeStart: DateTime(2026, 9, 5),
            rangeEnd: DateTime(2026, 9, 20),
            rejectedDates: {DateTime(2026, 9, 10)},
            onDayTap: (_) {},
          ),
        );

        final labels = dumpSemanticsLabels(tester);
        final rejectedLabel = labels.firstWhere((l) => l.contains('September 10, 2026'));
        expect(rejectedLabel, contains('Within selected range, not selectable'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a selected day cell announces its selected state', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzPickersDayGrid(
            displayedMonth: DateTime(2026, 9),
            selectedDate: DateTime(2026, 9, 15),
            onDayTap: (_) {},
          ),
        );

        final labels = dumpSemanticsLabels(tester);
        final selectedLabel = labels.firstWhere((l) => l.contains('September 15, 2026'));
        expect(selectedLabel, contains('Selected'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a selectable cell exposes button and enabled semantics', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzPickersDayGrid(displayedMonth: DateTime(2026, 9), onDayTap: (_) {}),
        );

        // The compact cell for "September 15, 2026" carries an enabled,
        // tappable button semantics node.
        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('September 15, 2026') ?? false),
        );
        expect(finder, findsOneWidget);

        expect(
          tester.getSemantics(finder),
          matchesSemantics(
            label: 'Tuesday, September 15, 2026',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasFocusAction: true,
            hasTapAction: true,
            hasSelectedState: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
