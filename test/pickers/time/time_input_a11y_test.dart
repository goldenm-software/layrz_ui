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

/// An anchor wide enough that every one of 3 slots (hour/minute/second)
/// clears [LayrzPickersTimeField.kNarrowWidth] (280px), so the shared
/// `LayrzPickersTimeFieldsPanel` renders the full-word label form rather
/// than the short `h`/`m`/`s` abbreviation. 3 slots need at least
/// 3*280 + 2*6 = 852px; 1000px keeps clear margin above that.
Widget _wideThreeSlot(Widget child) => SizedBox(width: 1000, child: child);

/// An anchor narrow enough that every slot falls below
/// [LayrzPickersTimeField.kNarrowWidth], so the panel renders the short
/// `h`/`m`/`s` abbreviation form.
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

    testWidgets(
      'hour, minute and (when shown) second fields expose distinct short-form semantic labels regardless of anchor width (DESIGN-98)',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          // DESIGN-98: this widget now opens LayrzEndDrawer on desktop, a
          // fixed 420px width (LayrzEndDrawer.width) regardless of the
          // anchor's own width -- previously LayrzAnchoredPanel matched the
          // anchor's width via widthPolicy: matchAnchor, so a wide anchor
          // (see the old _wideThreeSlot helper) could clear
          // LayrzPickersTimeField.kNarrowWidth (280px) for all 3 slots and
          // reach the full-word label form. The drawer's own padded width
          // (~392px) can never clear 3*280px=840px, so the full-word form is
          // no longer reachable from this widget at all -- _wideThreeSlot's
          // width is asserted here to be irrelevant, not merely unused.
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

          expect(labels.any((l) => l.contains(l10n.timePickerHourShortSingular)), isTrue);
          expect(labels.any((l) => l.contains(l10n.timePickerMinuteShortSingular)), isTrue);
          expect(labels.any((l) => l.contains(l10n.timePickerSecondShortSingular)), isTrue);
          expect(
            labels.any((l) => l.contains(l10n.timePickerHours)),
            isFalse,
            reason: 'the drawer\'s fixed width forces the short form even with a wide anchor',
          );
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets(
      'hour, minute and second fields expose distinct short-form semantic labels at a narrow anchor',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          // Narrow enough (see _narrowThreeSlot) that all 3 slots fall below
          // LayrzPickersTimeField.kNarrowWidth, so the panel renders the
          // short h/m/s abbreviation form instead of the full words.
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

          expect(labels.any((l) => l.contains(l10n.timePickerHourShortSingular)), isTrue);
          expect(labels.any((l) => l.contains(l10n.timePickerMinuteShortSingular)), isTrue);
          expect(labels.any((l) => l.contains(l10n.timePickerSecondShortSingular)), isTrue);
          expect(
            labels.any((l) => l.contains(l10n.timePickerHours)),
            isFalse,
            reason: 'the narrow branch must render the short form, not the full word',
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
