import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/pump_themed_app.dart';

/// Collects every semantics label under [tester]'s current tree.
///
/// Mirrors `time_input_a11y_test.dart`'s own `dumpSemanticsLabels` -- used
/// here, rather than `find.bySemanticsLabel`, because that matcher also
/// matches literal text on renderable widgets and has already produced a
/// false green in this repo (DESIGN-161).
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

/// A bounded-width anchor comfortably clear of
/// `LayrzPickersTimeField.kNarrowWidth`'s per-field narrow threshold for
/// both the Start and End clusters, mirroring `time_range_input_test.dart`'s
/// `_kSafeAnchorWidth`. At this width each cluster's 3 field slots fall
/// under 280px per field, so the panel renders the SHORT `h`/`m`/`s` label
/// form -- see [_wideThreeSlot] for the width that renders full words.
Widget _bounded(Widget child) => SizedBox(width: 700, child: child);

/// A wide anchor field -- kept for historical width parity with
/// `time_input_a11y_test.dart`'s own `_wideThreeSlot`, but no longer
/// controls the field-label form for THIS widget. DESIGN-49 moved
/// `LayrzTimeRangeInput`'s desktop surface into [LayrzPickerDrawer], whose
/// width is fixed at [LayrzPickerDrawer.width] (420px) regardless of how
/// wide the anchor field itself is -- so the panel always renders the SHORT
/// `h`/`m`/`s` label form now, not the full-word form this anchor width used
/// to produce when the surface was `LayrzAnchoredPanel` (which matched the
/// anchor's own width). `LayrzTimeInput`'s single-cluster surface still uses
/// the anchored panel and keeps the full-word behavior this width name
/// describes -- see that widget's own `time_input_a11y_test.dart`.
Widget _wideThreeSlot(Widget child) => SizedBox(width: 1200, child: child);

void main() {
  group('LayrzTimeRangeInput — Accessibility', () {
    testWidgets('anchor carries the label exactly once', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          _bounded(
            LayrzTimeRangeInput(
              labelText: 'Business hours',
              startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
              endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
              onChanged: (_, _) {},
            ),
          ),
        );

        final labels = dumpSemanticsLabels(tester);
        expect(labels.where((l) => l == 'Business hours').length, 1);
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
            LayrzTimeRangeInput(
              labelText: 'Business hours',
              startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
              endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
              onChanged: (_, _) {},
            ),
          ),
        );

        expect(
          tester.getSemantics(
            find.descendant(of: find.byType(LayrzTimeRangeInput), matching: find.byType(Semantics)).first,
          ),
          matchesSemantics(
            label: 'Business hours',
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
            LayrzTimeRangeInput(
              labelText: 'Business hours',
              startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
              endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
              onChanged: (_, _) {},
              disabled: true,
            ),
          ),
        );

        expect(
          tester.getSemantics(
            find.descendant(of: find.byType(LayrzTimeRangeInput), matching: find.byType(Semantics)).first,
          ),
          matchesSemantics(
            label: 'Business hours\n09:00 – 17:00',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
            isFocusable: true,
            hasFocusAction: true,
            // Disabled anchors report no tap action -- see `onTap: widget.disabled ? null : ...`.
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
            LayrzTimeRangeInput(
              labelText: 'Business hours',
              startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
              endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
              onChanged: (_, _) {},
            ),
          ),
        );

        await tester.tap(find.byType(LayrzTimeRangeInput));
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(
          labels.where((l) => l == 'Business hours').length,
          1,
          reason: 'the chrome is constructed with labelText: null so it must not add a second labeled node',
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('start and end clusters expose distinguishable semantic labels', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          _bounded(
            LayrzTimeRangeInput(
              labelText: 'Business hours',
              startValue: const LayrzTimeOfDay(hour: 9, minute: 5),
              endValue: const LayrzTimeOfDay(hour: 17, minute: 10),
              onChanged: (_, _) {},
            ),
          ),
        );

        await tester.tap(find.byType(LayrzTimeRangeInput));
        await tester.pumpAndSettle();

        final l10n = LayrzUiL10n.of(tester.element(find.byType(LayrzTimeRangeInput)));
        final labels = dumpSemanticsLabels(tester);

        expect(
          labels.any((l) => l.contains(l10n.timePickerStart)),
          isTrue,
          reason: 'the start cluster must be identifiable without guessing which group is which',
        );
        expect(
          labels.any((l) => l.contains(l10n.timePickerEnd)),
          isTrue,
          reason: 'the end cluster must be identifiable without guessing which group is which',
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('hour and minute fields expose distinct semantic labels for both clusters', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // The anchor field's own width no longer matters here (see
        // _wideThreeSlot's updated doc): LayrzPickerDrawer is fixed at
        // LayrzPickerDrawer.width (420px), which is below
        // LayrzPickersTimeField.kNarrowWidth for a 2-slot cluster, so the
        // panel renders the SHORT h/m label form regardless of _bounded vs
        // _wideThreeSlot.
        await pumpThemedApp(
          tester,
          _wideThreeSlot(
            LayrzTimeRangeInput(
              labelText: 'Business hours',
              startValue: const LayrzTimeOfDay(hour: 9, minute: 5),
              endValue: const LayrzTimeOfDay(hour: 17, minute: 10),
              onChanged: (_, _) {},
            ),
          ),
        );

        await tester.tap(find.byType(LayrzTimeRangeInput));
        await tester.pumpAndSettle();

        final l10n = LayrzUiL10n.of(tester.element(find.byType(LayrzTimeRangeInput)));
        final labels = dumpSemanticsLabels(tester);

        final hourShortLabels = labels.where(
          (l) => l == l10n.timePickerHourShortSingular || l == l10n.timePickerHourShortPlural,
        );
        final minuteShortLabels = labels.where(
          (l) => l == l10n.timePickerMinuteShortSingular || l == l10n.timePickerMinuteShortPlural,
        );
        expect(hourShortLabels.length, greaterThanOrEqualTo(2));
        expect(minuteShortLabels.length, greaterThanOrEqualTo(2));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('Cancel and Save buttons are exposed as semantics buttons', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          _bounded(
            LayrzTimeRangeInput(
              labelText: 'Business hours',
              startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
              endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
              onChanged: (_, _) {},
            ),
          ),
        );

        await tester.tap(find.byType(LayrzTimeRangeInput));
        await tester.pumpAndSettle();

        final l10n = const LayrzUiL10nDefault();
        expect(findButtonLabel(l10n.actionCancel), findsOneWidget);
        expect(findButtonLabel(l10n.actionSave), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('meridiem AM/PM options are exposed as selectable semantics buttons for both clusters', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          _bounded(
            LayrzTimeRangeInput(
              labelText: 'Business hours',
              startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
              endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
              onChanged: (_, _) {},
              use24HourFormat: false,
            ),
          ),
        );

        await tester.tap(find.byType(LayrzTimeRangeInput));
        await tester.pumpAndSettle();

        final amNodes = find.text('AM').evaluate();
        final pmNodes = find.text('PM').evaluate();
        expect(amNodes.length, 2, reason: 'one meridiem control per cluster');
        expect(pmNodes.length, 2, reason: 'one meridiem control per cluster');

        for (final element in amNodes) {
          final ancestor = find.ancestor(of: find.byWidget(element.widget), matching: find.byType(Semantics)).first;
          final node = tester.getSemantics(ancestor);
          expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
        }
      } finally {
        handle.dispose();
      }
    });

    testWidgets('errors are exposed in the footer slot semantics', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          _bounded(
            LayrzTimeRangeInput(
              labelText: 'Business hours',
              startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
              endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
              onChanged: (_, _) {},
              errors: const ['Range spans a break'],
            ),
          ),
        );

        final labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l.contains('Range spans a break')), isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('mobile bottom sheet carries a name identifying what is being picked', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
          ),
        );

        await tester.tap(find.byType(LayrzTimeRangeInput));
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(
          labels.any((l) => l.contains('Business hours')),
          isTrue,
          reason: 'LayrzBottomSheet.show must be called with semanticLabel so the sheet is named for screen readers',
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('mobile bottom sheet falls back to hintText when labelText is null', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzTimeRangeInput(
            hintText: 'No range chosen',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
          ),
        );

        await tester.tap(find.byType(LayrzTimeRangeInput));
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l.contains('No range chosen')), isTrue);
      } finally {
        handle.dispose();
      }
    });
  });
}
