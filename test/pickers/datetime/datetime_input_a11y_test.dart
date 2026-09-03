import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:timezone/data/latest.dart' as tzdata;

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

    // DESIGN-49 removed the tab strip entirely -- the calendar and time
    // fields are always both visible together in the drawer, so there is no
    // longer a "Date"/"Time" tab pair whose selection semantics could be
    // tested. See `datetime_presentation_test.dart` and
    // `datetime_input_test.dart`'s "presentation is deprecated and ignored"
    // group for the coverage that replaces these two removed tests.

    testWidgets('the drawer route announces its own semantic label', (tester) async {
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
        expect(
          labels,
          contains('Meeting start'),
          reason:
              'LayrzPickerDrawer.show is called with semanticLabel: '
              'labelText, naming the route for screen readers',
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('Save and Cancel are announced as buttons once the drawer is open', (tester) async {
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
