import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/pickers/src/shared/weekday_header.dart';

import '../../helpers/pump_themed.dart';

void main() {
  group('orderedPickerWeekdays', () {
    test('starts at DateTime.monday when firstDayOfWeek is monday', () {
      expect(orderedPickerWeekdays(DateTime.monday), [
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      ]);
    });

    test('starts at DateTime.sunday when firstDayOfWeek is sunday', () {
      expect(orderedPickerWeekdays(DateTime.sunday), [
        DateTime.sunday,
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
      ]);
    });

    test('asserts firstDayOfWeek is within bounds', () {
      expect(() => orderedPickerWeekdays(0), throwsA(isA<AssertionError>()));
      expect(() => orderedPickerWeekdays(8), throwsA(isA<AssertionError>()));
    });
  });

  group('weekdayInitialFor', () {
    const l10n = LayrzUiL10nDefault();

    test('returns the single-letter initial for every weekday', () {
      expect(weekdayInitialFor(DateTime.monday, l10n), 'M');
      expect(weekdayInitialFor(DateTime.tuesday, l10n), 'T');
      expect(weekdayInitialFor(DateTime.wednesday, l10n), 'W');
      expect(weekdayInitialFor(DateTime.thursday, l10n), 'T');
      expect(weekdayInitialFor(DateTime.friday, l10n), 'F');
      expect(weekdayInitialFor(DateTime.saturday, l10n), 'S');
      expect(weekdayInitialFor(DateTime.sunday, l10n), 'S');
    });
  });

  group('weekdayFullNameFor', () {
    const l10n = LayrzUiL10nDefault();

    test('returns the full weekday name', () {
      expect(weekdayFullNameFor(DateTime.wednesday, l10n), 'Wednesday');
      expect(weekdayFullNameFor(DateTime.sunday, l10n), 'Sunday');
    });
  });

  group('LayrzPickersWeekdayHeader — widget', () {
    testWidgets('renders seven single-letter initials starting at Monday by default', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzPickersWeekdayHeader(firstDayOfWeek: DateTime.monday));

      expect(find.text('M'), findsNWidgets(1));
      expect(find.text('T'), findsNWidgets(2));
      expect(find.text('W'), findsNWidgets(1));
      expect(find.text('F'), findsNWidgets(1));
      expect(find.text('S'), findsNWidgets(2));
    });

    testWidgets('carries full weekday names as screen-reader labels, not the visible initials', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzPickersWeekdayHeader(firstDayOfWeek: DateTime.monday));

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
        expect(labels, contains('Monday'));
        expect(labels, contains('Wednesday'));
        expect(labels, contains('Sunday'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('reserves gutterWidth as a leading gap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzPickersWeekdayHeader(firstDayOfWeek: DateTime.monday, gutterWidth: 28.0),
      );

      expect(find.byType(LayrzPickersWeekdayHeader), findsOneWidget);
    });
  });
}
