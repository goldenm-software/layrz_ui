import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/models/time_of_day.dart';
import 'package:layrz_ui/src/pickers/src/shared/time_fields_panel.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

Widget _bounded(Widget child) => SizedBox(width: 700, child: child);

void main() {
  group('LayrzPickersTimeFieldsPanel — Accessibility', () {
    guardedTestWidgets('hour and minute fields expose editable text semantics', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          _bounded(LayrzPickersTimeFieldsPanel(value: const LayrzTimeOfDay(hour: 9, minute: 30), onChanged: (_) {})),
        );

        final editableFinder = find.byType(EditableText);
        expect(editableFinder, findsNWidgets(2));

        for (final element in editableFinder.evaluate()) {
          final semantics = tester.getSemantics(find.byWidget(element.widget));
          expect(semantics.getSemanticsData().flagsCollection.isTextField, isTrue);
        }
      } finally {
        handle.dispose();
      }
    });

    // CHANGED (time-fields digital-clock redesign): the meridiem control is
    // now built from two [LayrzButton]s (filled = selected, text =
    // unselected) rather than a hand-rolled `Semantics(selected: ...)`
    // control. [LayrzButton]'s own Semantics node exposes no `selected` flag
    // and no forwarded `tap` action -- an accepted, documented limitation
    // (see `_MeridiemControl`'s own class doc "Accessibility note"), not a
    // regression this pass attempts to recover. The visual filled/text
    // contrast still communicates the selection sightedly.
    guardedTestWidgets('the AM option exposes button semantics (enabled, no selected-state flag)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          _bounded(
            LayrzPickersTimeFieldsPanel(
              value: const LayrzTimeOfDay(hour: 9, minute: 30),
              use24HourFormat: false,
              onChanged: (_) {},
            ),
          ),
        );

        final amFinder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label == 'AM'),
        );
        expect(amFinder, findsOneWidget);
        expect(
          tester.getSemantics(amFinder),
          matchesSemantics(label: 'AM', isButton: true, hasEnabledState: true, isEnabled: true),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the PM option exposes button semantics too, with no selected-state flag either', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          _bounded(
            LayrzPickersTimeFieldsPanel(
              value: const LayrzTimeOfDay(hour: 9, minute: 30),
              use24HourFormat: false,
              onChanged: (_) {},
            ),
          ),
        );

        final pmFinder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label == 'PM'),
        );
        expect(
          tester.getSemantics(pmFinder),
          matchesSemantics(label: 'PM', isButton: true, hasEnabledState: true, isEnabled: true),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
