import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  guardedTestWidgets('a cell too short for any event slot shows +N next to the date without overflowing', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      SizedBox(
        width: 60,
        height: 40,
        child: LayrzCalendarDayCell(
          date: DateTime(2026, 9, 1),
          isToday: false,
          isOutsideMonth: false,
          isDisabled: false,
          entries: [LayrzCalendarEntry(title: '3 visits', start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 1))],
          maxVisibleSlots: 0,
        ),
      ),
    );

    expect(find.text('3 visits'), findsNothing);
    expect(find.text('+1'), findsOneWidget);
  });
}
