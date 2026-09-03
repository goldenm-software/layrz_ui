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
        expect(editableFinder, findsNWidgets(3));

        for (final element in editableFinder.evaluate().take(2)) {
          final semantics = tester.getSemantics(find.byWidget(element.widget));
          expect(semantics.getSemanticsData().flagsCollection.isTextField, isTrue);
        }
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the meridiem control exposes button semantics with a selected state', (tester) async {
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
          matchesSemantics(label: 'AM', isButton: true, hasSelectedState: true, isSelected: true, hasTapAction: true),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the PM option is not selected when AM is active', (tester) async {
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
          matchesSemantics(label: 'PM', isButton: true, hasSelectedState: true, isSelected: false, hasTapAction: true),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
