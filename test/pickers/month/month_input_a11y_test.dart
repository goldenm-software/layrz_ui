import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

/// Collects every semantics label under [tester]'s current tree.
///
/// Mirrors `combobox_input_a11y_test.dart`'s own `dumpSemanticsLabels` --
/// used here, rather than `find.bySemanticsLabel`, because that matcher also
/// matches literal text on renderable widgets and has already produced a
/// false green in this repo.
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
  group('LayrzMonthInput — Accessibility', () {
    guardedTestWidgets('the anchor field exposes the label exactly once as a button', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          const LayrzMonthInput(labelText: 'Month'),
        );

        final labels = _dumpSemanticsLabels(tester);
        expect(labels.where((l) => l == 'Month').length, 1);

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Month',
        );
        expect(
          tester.getSemantics(finder),
          matchesSemantics(
            label: 'Month',
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

    guardedTestWidgets('a disabled anchor field is marked disabled and reports no tap action', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          const LayrzMonthInput(labelText: 'Month', disabled: true),
        );

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Month',
        );
        expect(
          tester.getSemantics(finder),
          matchesSemantics(
            label: 'Month',
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
          const LayrzMonthInput(labelText: 'Month', value: LayrzMonth(year: 2026, month: 1)),
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

    guardedTestWidgets('a selected month cell announces its selected state once open', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          const LayrzMonthInput(labelText: 'Month', value: LayrzMonth(year: 2026, month: 9)),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        // Two nodes contain "September 2026": the anchor's own summary text
        // and the grid cell -- only the grid cell also carries ", Selected".
        final labels = _dumpSemanticsLabels(tester);
        final selected = labels.firstWhere((l) => l.contains('September 2026') && l.contains('Selected'));
        expect(selected, 'September 2026, Selected');
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
          const LayrzMonthInput(
            labelText: 'Month',
            value: LayrzMonth(year: 2026, month: 6),
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

    guardedTestWidgets('compact viewport: anchor field semantics match the desktop branch', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          const LayrzMonthInput(labelText: 'Month'),
        );

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Month',
        );
        expect(
          tester.getSemantics(finder),
          matchesSemantics(
            label: 'Month',
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
