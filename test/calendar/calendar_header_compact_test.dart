import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import 'calendar_header_test.dart' show pumpHeaderAtWidth;

LayrzCalendarHeader _header() => LayrzCalendarHeader(
  mode: LayrzCalendarMode.month,
  focusedDate: DateTime(2026, 9, 1),
  onPrevious: () {},
  onNext: () {},
  onToday: () {},
  onModeChanged: (_) {},
);

Iterable<LayrzButtonStyle> _styles(WidgetTester tester) =>
    tester.widgetList<LayrzButton>(find.byType(LayrzButton)).map((button) => button.style);

void main() {
  guardedTestWidgets('a narrow header keeps a text Today and shows the view modes as fab buttons below', (
    tester,
  ) async {
    await pumpHeaderAtWidth(tester, _header(), 380);

    final styles = _styles(tester).toList();
    expect(styles.where((style) => style == LayrzButtonStyle.filledFab).length, 1); // selected mode
    expect(styles.where((style) => style == LayrzButtonStyle.outlinedFab).length, 2);

    final today = tester.widget<LayrzButton>(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Today'));
    expect(today.style, isNot(anyOf(LayrzButtonStyle.filledFab, LayrzButtonStyle.textFab)));

    final todayTop = tester.getTopLeft(find.byWidget(today)).dy;
    final monthTop = tester
        .getTopLeft(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'View as month'))
        .dy;
    expect(monthTop, greaterThan(todayTop));

    // The fabs spread across the width: the last one ends near the header's right edge.
    final dayRect = tester.getRect(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'View as day'));
    final headerRect = tester.getRect(find.byType(LayrzCalendarHeader));
    expect(headerRect.right - dayRect.right, lessThan(headerRect.width / 6));
  });

  guardedTestWidgets('a wide header keeps the labeled buttons', (tester) async {
    await pumpHeaderAtWidth(tester, _header(), 900);

    expect(_styles(tester), containsAll([LayrzButtonStyle.filled, LayrzButtonStyle.outlined]));
    expect(
      _styles(tester).where((style) => style == LayrzButtonStyle.filledFab || style == LayrzButtonStyle.outlinedFab),
      isEmpty,
    );
  });
}
