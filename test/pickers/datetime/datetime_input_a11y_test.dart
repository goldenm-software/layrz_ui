import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../../helpers/find_button_label.dart';
import '../../helpers/pump_themed_app.dart';

/// Collects every semantics label under [tester]'s current tree.
///
/// Mirrors `combobox_input_a11y_test.dart`'s/`time_input_a11y_test.dart`'s
/// own `dumpSemanticsLabels` -- used here, rather than `find.bySemanticsLabel`,
/// because that matcher also matches literal text on renderable widgets and
/// has already produced a false green in this repo (DESIGN-161).
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

/// Locates the [SemanticsNode] carrying [label] with `selected` reported,
/// used to check which of the two tab headers is currently selected without
/// relying on `find.bySemanticsLabel` (see this file's own doc above).
SemanticsNode? findSemanticsNodeWithLabel(WidgetTester tester, String label) {
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
  SemanticsNode? found;
  void walk(SemanticsNode node) {
    if (node.getSemanticsData().label == label) found = node;
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(root);
  return found;
}

Widget _bounded(Widget child) => SizedBox(width: 900, child: child);

void main() {
  tzdata.initializeTimeZones();

  group('LayrzDateTimeInput — Accessibility', () {
    testWidgets('anchor carries the label exactly once', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          _bounded(
            LayrzDateTimeInput(labelText: 'Meeting start', value: DateTime(2026, 9, 5, 9, 30), onChanged: (_) {}),
          ),
        );

        final labels = dumpSemanticsLabels(tester);
        expect(labels.where((l) => l == 'Meeting start').length, 1);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('anchor semantics report as a focusable, enabled button', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          _bounded(
            LayrzDateTimeInput(labelText: 'Meeting start', value: DateTime(2026, 9, 5, 9, 30), onChanged: (_) {}),
          ),
        );

        expect(
          tester.getSemantics(
            find.descendant(of: find.byType(LayrzDateTimeInput), matching: find.byType(Semantics)).first,
          ),
          matchesSemantics(
            label: 'Meeting start',
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

    testWidgets('disabled anchor reports enabled: false and no tap action', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          _bounded(
            LayrzDateTimeInput(
              labelText: 'Meeting start',
              value: DateTime(2026, 9, 5, 9, 30),
              onChanged: (_) {},
              disabled: true,
            ),
          ),
        );

        expect(
          tester.getSemantics(
            find.descendant(of: find.byType(LayrzDateTimeInput), matching: find.byType(Semantics)).first,
          ),
          matchesSemantics(
            label: 'Meeting start\n2026-09-05 09:30',
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

    testWidgets('label is announced once even while the panel is open (no duplicate node)', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          _bounded(
            LayrzDateTimeInput(labelText: 'Meeting start', value: DateTime(2026, 9, 5, 9, 30), onChanged: (_) {}),
          ),
        );

        await tester.tap(find.byType(LayrzDateTimeInput));
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(
          labels.where((l) => l == 'Meeting start').length,
          1,
          reason: 'the chrome is constructed with labelText: null so it must not add a second labeled node',
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the tab strip reports which tab is selected via real semantics properties', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          _bounded(LayrzDateTimeInput(labelText: 'Meeting start')),
        );

        await tester.tap(find.byType(LayrzDateTimeInput));
        await tester.pumpAndSettle();

        final dateNode = findSemanticsNodeWithLabel(tester, 'Date');
        final timeNode = findSemanticsNodeWithLabel(tester, 'Time');
        expect(dateNode, isNotNull);
        expect(timeNode, isNotNull);
        expect(dateNode!.getSemanticsData().flagsCollection.isSelected, Tristate.isTrue);
        expect(timeNode!.getSemanticsData().flagsCollection.isSelected, Tristate.isFalse);

        await tester.tap(findButtonLabel('Time'));
        await tester.pumpAndSettle();

        final dateNodeAfter = findSemanticsNodeWithLabel(tester, 'Date');
        final timeNodeAfter = findSemanticsNodeWithLabel(tester, 'Time');
        expect(dateNodeAfter!.getSemanticsData().flagsCollection.isSelected, Tristate.isFalse);
        expect(timeNodeAfter!.getSemanticsData().flagsCollection.isSelected, Tristate.isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the tab strip headers report as buttons', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          _bounded(LayrzDateTimeInput(labelText: 'Meeting start')),
        );

        await tester.tap(find.byType(LayrzDateTimeInput));
        await tester.pumpAndSettle();

        final dateNode = findSemanticsNodeWithLabel(tester, 'Date');
        expect(dateNode!.getSemanticsData().flagsCollection.isButton, isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('Save and Cancel are announced as buttons once the panel is open', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          _bounded(LayrzDateTimeInput(labelText: 'Meeting start')),
        );

        await tester.tap(find.byType(LayrzDateTimeInput));
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(labels, contains('Save'));
        expect(labels, contains('Cancel'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('error text is exposed to semantics when errors is non-empty', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          _bounded(LayrzDateTimeInput(labelText: 'Meeting start', errors: const ['Required'])),
        );

        final labels = dumpSemanticsLabels(tester);
        expect(labels, contains('Required'));
      } finally {
        handle.dispose();
      }
    });
  });
}
