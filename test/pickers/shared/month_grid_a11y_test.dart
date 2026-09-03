import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/shared/month_grid.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

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
  group('LayrzPickersMonthGrid — Accessibility', () {
    guardedTestWidgets('a selectable month cell exposes a "Month Year" label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzPickersMonthGrid(
            displayedYear: 2026,
            onYearChanged: (_) {},
            reference: DateTime(2026),
            onMonthTap: (_) {},
          ),
        );

        final labels = _dumpSemanticsLabels(tester);
        expect(labels.any((l) => l.contains('September 2026')), isTrue);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a disabled month cell is marked unavailable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzPickersMonthGrid(
            displayedYear: 2026,
            onYearChanged: (_) {},
            reference: DateTime(2026),
            minimum: DateTime(2026, 6),
            onMonthTap: (_) {},
          ),
        );

        final labels = _dumpSemanticsLabels(tester);
        final disabled = labels.firstWhere((l) => l.contains('January 2026'));
        expect(disabled, contains('Unavailable'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the year navigation chevrons carry their own semantics labels', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzPickersMonthGrid(
            displayedYear: 2026,
            onYearChanged: (_) {},
            reference: DateTime(2026),
            onMonthTap: (_) {},
          ),
        );

        final labels = _dumpSemanticsLabels(tester);
        expect(labels, contains('Previous year'));
        expect(labels, contains('Next year'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a selected month cell announces its selected state', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzPickersMonthGrid(
            displayedYear: 2026,
            onYearChanged: (_) {},
            reference: DateTime(2026),
            selectedMonth: DateTime(2026, 9),
            onMonthTap: (_) {},
          ),
        );

        final labels = _dumpSemanticsLabels(tester);
        final selected = labels.firstWhere((l) => l.contains('September 2026'));
        expect(selected, contains('Selected'));
      } finally {
        handle.dispose();
      }
    });
  });
}
