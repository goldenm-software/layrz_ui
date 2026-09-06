import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/pickers/src/multi_select/multi_select_input.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

/// Collects every semantics label under [tester]'s current tree.
///
/// Mirrors `date_input_a11y_test.dart`'s identical helper -- walking the tree
/// instead of using `find.bySemanticsLabel`, which also matches literal text
/// on renderable widgets and has already produced a false green in this repo.
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
  final items = <LayrzSelectItem<String>>[
    const LayrzSelectItem(value: 'apple', child: Text('Apple'), searchableStrings: {'Apple'}),
    const LayrzSelectItem(value: 'banana', child: Text('Banana'), searchableStrings: {'Banana'}),
    const LayrzSelectItem(value: 'cherry', child: Text('Cherry'), searchableStrings: {'Cherry'}),
  ];

  group('LayrzMultiSelectInput — Accessibility', () {
    guardedTestWidgets('the anchor exposes the label as a button, enabled and focusable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzMultiSelectInput<String>(items: items, itemExtent: 40, labelText: 'Fruits'));

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

    guardedTestWidgets('a disabled anchor is marked not enabled and reports no tap action', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzMultiSelectInput<String>(items: items, itemExtent: 40, labelText: 'Fruits', disabled: true),
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
        await pumpThemedApp(tester, LayrzMultiSelectInput<String>(items: items, itemExtent: 40, labelText: 'Fruits'));

        final labels = dumpSemanticsLabels(tester);
        expect(labels.where((l) => l == 'Fruits').length, 1);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a row in the open surface exposes a button, selected state toggling with the draft', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzMultiSelectInput<String>(items: items, itemExtent: 40, labelText: 'Fruits'));

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final rowFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && (widget.properties.selected ?? false) == false && widget.properties.button == true,
        );
        expect(rowFinder, findsWidgets);

        await tester.tap(find.text('Apple'));
        await tester.pumpAndSettle();

        final selectedRowFinder = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.selected == true,
        );
        expect(selectedRowFinder, findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the drawer exposes Cancel, Select all, and Save semantics once opened', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzMultiSelectInput<String>(items: items, itemExtent: 40, labelText: 'Fruits'));

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(
          labels.any((l) => l.contains('Cancel')),
          isTrue,
          reason: 'staged-with-Save always carries a Cancel action',
        );
        expect(labels.any((l) => l.contains('Select all')), isTrue);
        expect(labels.any((l) => l.contains('Save')), isTrue);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the drawer renders labelText as a visible title', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzMultiSelectInput<String>(items: items, itemExtent: 40, labelText: 'Fruits'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.text('Fruits'), findsWidgets, reason: 'the drawer must render a visible title Text');
    });

    guardedTestWidgets('falls back to hintText for the drawer\'s semantic label when labelText is null', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzMultiSelectInput<String>(items: items, itemExtent: 40, hintText: 'Pick some fruit'),
        );

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l.contains('Pick some fruit')), isTrue);
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
        await pumpThemedApp(
          tester,
          LayrzMultiSelectInput<String>(items: items, itemExtent: 40, labelText: 'Fruits', value: const ['apple']),
        );

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Fruits') ?? false),
        );
        expect(finder, findsWidgets);

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l.contains('Save')), isTrue);
        expect(labels.any((l) => l.contains('Cancel')), isTrue);
      } finally {
        handle.dispose();
      }
    });
  });
}
