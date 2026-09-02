import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/pickers/src/shared/grid_keyboard_handler.dart';
import 'package:layrz_ui/src/pickers/src/shared/month_grid.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// Requests focus on the month cell labeled [label] via [Focus.of],
/// resolving to that cell's own [FocusNode] — see the identical helper in
/// `grid_keyboard_test.dart` for why this reaches the real node rather than
/// the grid's outer per-cell `Focus(onKeyEvent: ...)` wrapper.
void _focusMonth(WidgetTester tester, String label) {
  final context = tester.element(find.text(label).first);
  Focus.of(context, scopeOk: true).requestFocus();
}

/// The [DateTime] (year/month only) currently holding primary focus, read
/// back from the binding's [FocusManager].
DateTime? _focusedMonth() {
  final node = WidgetsBinding.instance.focusManager.primaryFocus;
  final label = node?.debugLabel;
  if (label == null) return null;
  return DateTime.parse(label);
}

void main() {
  group('buildMonthGridKeyboardHandler — arrow/Home/End movement', () {
    guardedTestWidgets('ArrowRight moves focus one month forward', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
          keyboardHandler: buildMonthGridKeyboardHandler(
            isDisabled: (_) => false,
            onSelect: (_) {},
            onYearChanged: (_) {},
          ),
        ),
      );

      _focusMonth(tester, 'March');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(_focusedMonth(), DateTime(2026, 4));
    });

    guardedTestWidgets('ArrowLeft moves focus one month back', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
          keyboardHandler: buildMonthGridKeyboardHandler(
            isDisabled: (_) => false,
            onSelect: (_) {},
            onYearChanged: (_) {},
          ),
        ),
      );

      _focusMonth(tester, 'March');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(_focusedMonth(), DateTime(2026, 2));
    });

    guardedTestWidgets('ArrowDown moves focus one row (3 months) forward', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
          keyboardHandler: buildMonthGridKeyboardHandler(
            isDisabled: (_) => false,
            onSelect: (_) {},
            onYearChanged: (_) {},
          ),
        ),
      );

      // February is row 0 (Jan-Mar); ArrowDown should land on May (row 1).
      _focusMonth(tester, 'February');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(_focusedMonth(), DateTime(2026, 5));
    });

    guardedTestWidgets('ArrowUp moves focus one row (3 months) back', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
          keyboardHandler: buildMonthGridKeyboardHandler(
            isDisabled: (_) => false,
            onSelect: (_) {},
            onYearChanged: (_) {},
          ),
        ),
      );

      _focusMonth(tester, 'May');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(_focusedMonth(), DateTime(2026, 2));
    });

    guardedTestWidgets('Home moves focus to the first month of the current row', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
          keyboardHandler: buildMonthGridKeyboardHandler(
            isDisabled: (_) => false,
            onSelect: (_) {},
            onYearChanged: (_) {},
          ),
        ),
      );

      _focusMonth(tester, 'August');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();

      expect(_focusedMonth(), DateTime(2026, 7));
    });

    guardedTestWidgets('End moves focus to the last month of the current row', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
          keyboardHandler: buildMonthGridKeyboardHandler(
            isDisabled: (_) => false,
            onSelect: (_) {},
            onYearChanged: (_) {},
          ),
        ),
      );

      _focusMonth(tester, 'August');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();

      expect(_focusedMonth(), DateTime(2026, 9));
    });
  });

  group('buildMonthGridKeyboardHandler — Enter/Space selection', () {
    guardedTestWidgets('Enter selects the focused, selectable month', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? selected;
      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
          keyboardHandler: buildMonthGridKeyboardHandler(
            isDisabled: (_) => false,
            onSelect: (d) => selected = d,
            onYearChanged: (_) {},
          ),
        ),
      );

      _focusMonth(tester, 'March');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(selected, DateTime(2026, 3));
    });

    guardedTestWidgets('Enter on a disabled month does NOT select it', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final disabled = DateTime(2026, 3);
      DateTime? selected;
      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          disabledMonths: {disabled},
          onMonthTap: (_) {},
          keyboardHandler: buildMonthGridKeyboardHandler(
            isDisabled: (d) => d.year == disabled.year && d.month == disabled.month,
            onSelect: (d) => selected = d,
            onYearChanged: (_) {},
          ),
        ),
      );

      _focusMonth(tester, 'March');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(selected, isNull);
    });
  });

  group('buildMonthGridKeyboardHandler — disabled cells are skipped, not landed on', () {
    guardedTestWidgets('ArrowRight skips a disabled month in between', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final disabled = DateTime(2026, 4);
      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          disabledMonths: {disabled},
          onMonthTap: (_) {},
          keyboardHandler: buildMonthGridKeyboardHandler(
            isDisabled: (d) => d.year == disabled.year && d.month == disabled.month,
            onSelect: (_) {},
            onYearChanged: (_) {},
          ),
        ),
      );

      _focusMonth(tester, 'March');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      // April is disabled -- focus must land on May, not April.
      expect(_focusedMonth(), DateTime(2026, 5));
    });
  });

  group('buildMonthGridKeyboardHandler — PageUp/PageDown year navigation', () {
    guardedTestWidgets('PageDown steps the displayed year forward and refocuses the same month', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var displayedYear = 2026;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Localizations(
              locale: const Locale('en'),
              delegates: const [
                DefaultWidgetsLocalizations.delegate,
                LayrzUiL10nDelegate(),
              ],
              child: LayrzTheme(
                data: LayrzThemeData.light(),
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (context) => Center(
                        child: LayrzPickersMonthGrid(
                          displayedYear: displayedYear,
                          onYearChanged: (year) => setState(() => displayedYear = year),
                          reference: DateTime(2026),
                          onMonthTap: (_) {},
                          keyboardHandler: buildMonthGridKeyboardHandler(
                            isDisabled: (_) => false,
                            onSelect: (_) {},
                            onYearChanged: (year) => setState(() => displayedYear = year),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      await tester.pump();

      _focusMonth(tester, 'March');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      await tester.pump();

      expect(displayedYear, 2027);
      expect(_focusedMonth(), DateTime(2027, 3));
    });

    guardedTestWidgets('PageUp steps the displayed year back and refocuses the same month', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var displayedYear = 2026;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Localizations(
              locale: const Locale('en'),
              delegates: const [
                DefaultWidgetsLocalizations.delegate,
                LayrzUiL10nDelegate(),
              ],
              child: LayrzTheme(
                data: LayrzThemeData.light(),
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (context) => Center(
                        child: LayrzPickersMonthGrid(
                          displayedYear: displayedYear,
                          onYearChanged: (year) => setState(() => displayedYear = year),
                          reference: DateTime(2026),
                          onMonthTap: (_) {},
                          keyboardHandler: buildMonthGridKeyboardHandler(
                            isDisabled: (_) => false,
                            onSelect: (_) {},
                            onYearChanged: (year) => setState(() => displayedYear = year),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      await tester.pump();

      _focusMonth(tester, 'March');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pump();
      await tester.pump();

      expect(displayedYear, 2025);
      expect(_focusedMonth(), DateTime(2025, 3));
    });
  });

  group('buildMonthGridKeyboardHandler — negative assertions', () {
    guardedTestWidgets('an unrelated key is ignored and does not move focus', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
          keyboardHandler: buildMonthGridKeyboardHandler(
            isDisabled: (_) => false,
            onSelect: (_) {},
            onYearChanged: (_) {},
          ),
        ),
      );

      _focusMonth(tester, 'March');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();

      expect(_focusedMonth(), DateTime(2026, 3));
    });

    guardedTestWidgets('arrow keys never invoke onSelect', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var selectCount = 0;
      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
          keyboardHandler: buildMonthGridKeyboardHandler(
            isDisabled: (_) => false,
            onSelect: (_) => selectCount++,
            onYearChanged: (_) {},
          ),
        ),
      );

      _focusMonth(tester, 'March');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(selectCount, 0);
    });
  });
}
