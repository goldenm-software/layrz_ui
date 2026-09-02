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
/// `day_grid_a11y_test.dart`'s copy of it — walking the tree instead of
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
  group('LayrzDateInput — Accessibility', () {
    guardedTestWidgets('the anchor exposes the label as a button, enabled and focusable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date of birth'));

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Date of birth') ?? false),
        );
        expect(finder, findsOneWidget);

        expect(
          tester.getSemantics(finder),
          matchesSemantics(
            label: 'Date of birth',
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
        await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date', disabled: true));

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Date') ?? false),
        );
        expect(finder, findsOneWidget);

        // A disabled anchor drops `isEnabled` (the `hasEnabledState` flag
        // still applies) and its `tap` action -- `onTap: null` on both the
        // Semantics node and the GestureDetector, per `disabled ? null :
        // ...` in `_LayrzDateInputState.build`. It stays focusable (a
        // screen-reader user can still land on it and hear it announced as
        // disabled) even though it can no longer be activated.
        expect(
          tester.getSemantics(finder),
          matchesSemantics(
            label: 'Date',
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
        await pumpThemedApp(tester, LayrzDateInput(labelText: 'Appointment date'));

        final labels = dumpSemanticsLabels(tester);
        expect(labels.where((l) => l == 'Appointment date').length, 1);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a selectable day cell in the open desktop panel exposes a full date label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date', value: DateTime(2026, 9, 1)));

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l.contains('September 15, 2026')), isTrue);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the selected day announces "Selected" in its semantics label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date', value: DateTime(2026, 9, 15)));

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        final selectedLabel = labels.firstWhere((l) => l.contains('September 15, 2026'));
        expect(selectedLabel, contains('Selected'));
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
          LayrzDateInput(
            labelText: 'Date',
            value: DateTime(2026, 9, 1),
            disabledDays: {DateTime(2026, 9, 15)},
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        final disabledLabel = labels.firstWhere((l) => l.contains('September 15, 2026'));
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
          await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date', value: DateTime(2026, 9, 1)));

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

    guardedTestWidgets('this widget carries no semantics node with "Save" or "Cancel" as its label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date'));

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l == 'Save'), isFalse);
        expect(labels.any((l) => l == 'Cancel'), isFalse);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('remains accessible at a compact (mobile) viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date', value: DateTime(2026, 9, 1)));

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Date') ?? false),
        );
        expect(finder, findsWidgets);

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l.contains('September 15, 2026')), isTrue);
      } finally {
        handle.dispose();
      }
    });
  });
}
