import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

/// Collects every semantics label under [tester]'s current tree.
///
/// Mirrors `combobox_input_a11y_test.dart`'s own `dumpSemanticsLabels` --
/// used here, rather than `find.bySemanticsLabel`, because that matcher also
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
/// [LayrzPickersTimeField.kNarrowWidth]'s per-field narrow threshold for the
/// 2-slot (no seconds) case, mirroring `time_input_test.dart`'s
/// `_kSafeAnchorWidth`. Most of this file's tests don't assert on which
/// label form renders, so this width is enough for them; the one test that
/// does (the 3-slot distinct-labels test below) uses its own wider
/// [_wideThreeSlot] instead.
Widget _bounded(Widget child) => SizedBox(width: 700, child: child);

/// An anchor width, retained for historical contrast with [_narrowThreeSlot]
/// even though both now produce the identical panel width.
///
/// **DESIGN-98 note, corrected (Finding 3):** since this widget's desktop
/// path always opens the fixed 420px [LayrzEndDrawer] regardless of the
/// anchor's own width, this `SizedBox` has had no effect on the panel's
/// actual measured width since the drawer migration -- the panel always
/// receives the drawer's own padded width (~372px) either way. An earlier
/// pass concluded from this that the full-word label form was "no longer
/// reachable from this widget at all." That conclusion no longer holds:
/// `LayrzPickersTimeFieldsPanel`'s `fieldsPerRow` is now derived FROM
/// `LayrzPickersTimeField.kNarrowWidth` itself (see that panel's own class
/// doc), so at ~372px it wraps the three time fields to one per row, each
/// spanning the panel's own full width -- comfortably above the 280px
/// threshold. The full-word form IS reachable again; see the test below.
Widget _wideThreeSlot(Widget child) => SizedBox(width: 1000, child: child);

/// An anchor width, retained for historical contrast with [_wideThreeSlot]
/// even though both now produce the identical panel width -- see that
/// helper's own doc for why the anchor's width has no bearing on the
/// panel's actual measured width once hosted in the fixed-width
/// [LayrzEndDrawer].
Widget _narrowThreeSlot(Widget child) => SizedBox(width: 700, child: child);

void main() {
  group('LayrzTimeInput — Accessibility', () {
    testWidgets('anchor carries the label exactly once', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          _bounded(
            LayrzTimeInput(
              labelText: 'Meeting time',
              value: const LayrzTimeOfDay(hour: 9, minute: 5),
              onChanged: (_) {},
            ),
          ),
        );

        final labels = dumpSemanticsLabels(tester);
        expect(labels.where((l) => l == 'Meeting time').length, 1);
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
            LayrzTimeInput(
              labelText: 'Meeting time',
              value: const LayrzTimeOfDay(hour: 9, minute: 5),
              onChanged: (_) {},
            ),
          ),
        );

        expect(
          tester.getSemantics(
            find.descendant(of: find.byType(LayrzTimeInput), matching: find.byType(Semantics)).first,
          ),
          matchesSemantics(
            label: 'Meeting time',
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
            LayrzTimeInput(
              labelText: 'Meeting time',
              value: const LayrzTimeOfDay(hour: 9, minute: 5),
              onChanged: (_) {},
              disabled: true,
            ),
          ),
        );

        expect(
          tester.getSemantics(
            find.descendant(of: find.byType(LayrzTimeInput), matching: find.byType(Semantics)).first,
          ),
          matchesSemantics(
            label: 'Meeting time\n09:05',
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
            LayrzTimeInput(
              labelText: 'Meeting time',
              value: const LayrzTimeOfDay(hour: 9, minute: 5),
              onChanged: (_) {},
            ),
          ),
        );

        await tester.tap(find.byType(LayrzTimeInput));
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(
          labels.where((l) => l == 'Meeting time').length,
          1,
          reason: 'the chrome is constructed with labelText: null so it must not add a second labeled node',
        );
      } finally {
        handle.dispose();
      }
    });

    // CHANGED (Finding 3, DESIGN-98): this test previously asserted the
    // full-word label form was "no longer reachable from this widget at
    // all" once the drawer replaced the wide-anchor container -- see
    // _wideThreeSlot's own doc for why that conclusion no longer holds.
    // `LayrzPickersTimeFieldsPanel` now derives `fieldsPerRow` from
    // `LayrzPickersTimeField.kNarrowWidth`, so at the drawer's own ~372px
    // panel width it wraps the three time fields to one per row, each at
    // the full ~372px -- comfortably above the 280px threshold. The
    // full-word label form IS reachable again inside the drawer; this test
    // now asserts that restored state instead of its retired opposite.
    testWidgets(
      'hour, minute and (when shown) second fields expose the unabridged label form inside the drawer, regardless '
      'of anchor width (DESIGN-98, Finding 3)',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await pumpThemedApp(
            tester,
            _wideThreeSlot(
              LayrzTimeInput(
                labelText: 'Meeting time',
                value: const LayrzTimeOfDay(hour: 9, minute: 5, second: 10),
                onChanged: (_) {},
                showSeconds: true,
              ),
            ),
          );

          await tester.tap(find.byType(LayrzTimeInput));
          await tester.pumpAndSettle();

          final l10n = LayrzUiL10n.of(tester.element(find.byType(LayrzTimeInput)));
          final labels = dumpSemanticsLabels(tester);

          expect(labels.any((l) => l.contains(l10n.timePickerHours)), isTrue);
          expect(labels.any((l) => l.contains(l10n.timePickerMinutes)), isTrue);
          expect(labels.any((l) => l.contains(l10n.timePickerSeconds)), isTrue);
          expect(
            labels.any((l) => l.contains(l10n.timePickerHourShortSingular)),
            isFalse,
            reason: 'one field per row at drawer width clears kNarrowWidth -- the short form must not render',
          );
        } finally {
          handle.dispose();
        }
      },
    );

    // CHANGED (Finding 3, DESIGN-98): same restored-behavior correction as
    // the test above -- see _narrowThreeSlot's own doc. Both this test and
    // the one above now exercise the identical panel width (the anchor's
    // own width has had no bearing on it since the drawer migration), so
    // both now assert the same restored long-form outcome; kept as two
    // separate tests rather than merged, per instructions not to delete a
    // threshold test because it became awkward.
    testWidgets(
      'hour, minute and second fields expose the unabridged label form inside the drawer, at a narrow anchor',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await pumpThemedApp(
            tester,
            _narrowThreeSlot(
              LayrzTimeInput(
                labelText: 'Meeting time',
                value: const LayrzTimeOfDay(hour: 9, minute: 5, second: 10),
                onChanged: (_) {},
                showSeconds: true,
              ),
            ),
          );

          await tester.tap(find.byType(LayrzTimeInput));
          await tester.pumpAndSettle();

          final l10n = LayrzUiL10n.of(tester.element(find.byType(LayrzTimeInput)));
          final labels = dumpSemanticsLabels(tester);

          expect(labels.any((l) => l.contains(l10n.timePickerHours)), isTrue);
          expect(labels.any((l) => l.contains(l10n.timePickerMinutes)), isTrue);
          expect(labels.any((l) => l.contains(l10n.timePickerSeconds)), isTrue);
          expect(
            labels.any((l) => l.contains(l10n.timePickerHourShortSingular)),
            isFalse,
            reason: 'one field per row at drawer width clears kNarrowWidth -- the short form must not render',
          );
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets('meridiem AM/PM options are exposed as selectable semantics buttons', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          _bounded(
            LayrzTimeInput(
              labelText: 'Meeting time',
              value: const LayrzTimeOfDay(hour: 14, minute: 5),
              onChanged: (_) {},
              use24HourFormat: false,
            ),
          ),
        );

        await tester.tap(find.byType(LayrzTimeInput));
        await tester.pumpAndSettle();

        // `find.text('AM')` resolves to the *inner* `ExcludeSemantics`-wrapped
        // glyph (an empty-label node -- see this control's own
        // `ExcludeSemantics` wrapper), not the outer button-level `Semantics`
        // that actually carries the label/isButton/isSelected flags. Walk up
        // to the nearest ancestor `Semantics` widget instead.
        final amNode = tester.getSemantics(
          find.ancestor(of: find.text('AM'), matching: find.byType(Semantics)).first,
        );
        final pmNode = tester.getSemantics(
          find.ancestor(of: find.text('PM'), matching: find.byType(Semantics)).first,
        );

        expect(amNode.getSemanticsData().flagsCollection.isButton, isTrue);
        expect(pmNode.getSemanticsData().flagsCollection.isButton, isTrue);
        // isSelected is a Tristate (true/false/mixed), not a plain bool.
        expect(
          pmNode.getSemanticsData().flagsCollection.isSelected,
          Tristate.isTrue,
          reason: '14:05 is in the afternoon, so PM must report selected',
        );
        expect(amNode.getSemanticsData().flagsCollection.isSelected, Tristate.isFalse);
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
            LayrzTimeInput(
              labelText: 'Meeting time',
              value: const LayrzTimeOfDay(hour: 9, minute: 5),
              onChanged: (_) {},
              errors: const ['Time is outside business hours'],
            ),
          ),
        );

        final labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l.contains('Time is outside business hours')), isTrue);
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
          LayrzTimeInput(
            labelText: 'Meeting time',
            value: const LayrzTimeOfDay(hour: 9, minute: 5),
            onChanged: (_) {},
          ),
        );

        await tester.tap(find.byType(LayrzTimeInput));
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(
          labels,
          contains('Meeting time'),
          reason: "the sheet's subtree must still carry the picker's own name while open",
        );

        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    });
  });
}
