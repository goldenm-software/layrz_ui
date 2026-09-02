import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/pickers/src/shared/day_grid.dart';
import 'package:layrz_ui/src/pickers/src/shared/grid_keyboard_handler.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// Requests focus on the day cell labeled "$day" via [Focus.of], resolving
/// to that cell's own [FocusNode] (the innermost `Focus` ancestor of the
/// cell's rendered text) rather than the grid's outer per-cell
/// `Focus(onKeyEvent: ...)` wrapper, which attaches no node of its own.
void _focusDay(WidgetTester tester, int day) {
  final context = tester.element(find.text('$day').first);
  Focus.of(context, scopeOk: true).requestFocus();
}

/// The [DateTime] currently holding primary focus, read back from the
/// binding's [FocusManager] rather than assumed — the substantive
/// assertion every test in this file makes, per the implementation plan's
/// "assert focus actually moved" requirement.
DateTime? _focusedDate() {
  final node = WidgetsBinding.instance.focusManager.primaryFocus;
  final label = node?.debugLabel;
  if (label == null) return null;
  return DateTime.parse(label);
}

void main() {
  group('buildDayGridKeyboardHandler — arrow/Home/End movement', () {
    guardedTestWidgets('ArrowRight moves focus one day forward', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          onDayTap: (_) {},
          keyboardHandler: buildDayGridKeyboardHandler(isDisabled: (_) => false, onSelect: (_) {}),
        ),
      );

      _focusDay(tester, 15);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(_focusedDate(), DateTime(2026, 9, 16));
    });

    guardedTestWidgets('ArrowLeft moves focus one day back', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          onDayTap: (_) {},
          keyboardHandler: buildDayGridKeyboardHandler(isDisabled: (_) => false, onSelect: (_) {}),
        ),
      );

      _focusDay(tester, 15);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(_focusedDate(), DateTime(2026, 9, 14));
    });

    guardedTestWidgets('ArrowDown moves focus one week forward', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          onDayTap: (_) {},
          keyboardHandler: buildDayGridKeyboardHandler(isDisabled: (_) => false, onSelect: (_) {}),
        ),
      );

      _focusDay(tester, 8);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(_focusedDate(), DateTime(2026, 9, 15));
    });

    guardedTestWidgets('ArrowUp moves focus one week back', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          onDayTap: (_) {},
          keyboardHandler: buildDayGridKeyboardHandler(isDisabled: (_) => false, onSelect: (_) {}),
        ),
      );

      _focusDay(tester, 15);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(_focusedDate(), DateTime(2026, 9, 8));
    });

    guardedTestWidgets('Home moves focus to the start of the current week row', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // September 2026: the 1st is a Tuesday, and the grid is Monday-first
      // by default, so the week containing the 15th (a Tuesday) runs
      // Monday the 14th through Sunday the 20th.
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          onDayTap: (_) {},
          keyboardHandler: buildDayGridKeyboardHandler(isDisabled: (_) => false, onSelect: (_) {}),
        ),
      );

      _focusDay(tester, 15);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();

      expect(_focusedDate(), DateTime(2026, 9, 14));
    });

    guardedTestWidgets('End moves focus to the end of the current week row', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          onDayTap: (_) {},
          keyboardHandler: buildDayGridKeyboardHandler(isDisabled: (_) => false, onSelect: (_) {}),
        ),
      );

      _focusDay(tester, 15);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();

      expect(_focusedDate(), DateTime(2026, 9, 20));
    });
  });

  group('buildDayGridKeyboardHandler — Enter/Space selection', () {
    guardedTestWidgets('Enter selects the focused, selectable day', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? selected;
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          onDayTap: (_) {},
          keyboardHandler: buildDayGridKeyboardHandler(isDisabled: (_) => false, onSelect: (d) => selected = d),
        ),
      );

      _focusDay(tester, 15);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(selected, DateTime(2026, 9, 15));
    });

    guardedTestWidgets('Space selects the focused, selectable day', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? selected;
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          onDayTap: (_) {},
          keyboardHandler: buildDayGridKeyboardHandler(isDisabled: (_) => false, onSelect: (d) => selected = d),
        ),
      );

      _focusDay(tester, 15);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(selected, DateTime(2026, 9, 15));
    });

    guardedTestWidgets('Enter on a disabled day does NOT select it', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final disabled = DateTime(2026, 9, 15);
      DateTime? selected;
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          disabledDays: {disabled},
          onDayTap: (_) {},
          keyboardHandler: buildDayGridKeyboardHandler(
            isDisabled: (d) => d.year == disabled.year && d.month == disabled.month && d.day == disabled.day,
            onSelect: (d) => selected = d,
          ),
        ),
      );

      _focusDay(tester, 15);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(selected, isNull);
    });
  });

  group('buildDayGridKeyboardHandler — disabled cells are skipped, not landed on', () {
    guardedTestWidgets('ArrowRight skips a disabled day in between', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final disabled = DateTime(2026, 9, 16);
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          disabledDays: {disabled},
          onDayTap: (_) {},
          keyboardHandler: buildDayGridKeyboardHandler(
            isDisabled: (d) => d.year == disabled.year && d.month == disabled.month && d.day == disabled.day,
            onSelect: (_) {},
          ),
        ),
      );

      _focusDay(tester, 15);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      // The 16th is disabled -- focus must land on the 17th, not the 16th.
      expect(_focusedDate(), DateTime(2026, 9, 17));
    });
  });

  group('buildDayGridKeyboardHandler — PageUp/PageDown month navigation', () {
    guardedTestWidgets('PageDown steps the displayed month forward and refocuses the same day', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var displayedMonth = DateTime(2026, 9);

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
                        child: LayrzPickersDayGrid(
                          displayedMonth: displayedMonth,
                          onDayTap: (_) {},
                          keyboardHandler: buildDayGridKeyboardHandler(isDisabled: (_) => false, onSelect: (_) {}),
                          onDisplayedMonthChanged: (months) => setState(
                            () => displayedMonth = DateTime(displayedMonth.year, displayedMonth.month + months),
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

      _focusDay(tester, 15);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      await tester.pump();

      expect(displayedMonth.month, 10);
      expect(_focusedDate(), DateTime(2026, 10, 15));
    });

    guardedTestWidgets('PageUp steps the displayed month back and clamps the day to the shorter month', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var displayedMonth = DateTime(2026, 3);

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
                        child: LayrzPickersDayGrid(
                          displayedMonth: displayedMonth,
                          onDayTap: (_) {},
                          keyboardHandler: buildDayGridKeyboardHandler(isDisabled: (_) => false, onSelect: (_) {}),
                          onDisplayedMonthChanged: (months) => setState(
                            () => displayedMonth = DateTime(displayedMonth.year, displayedMonth.month + months),
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

      // March 31 has no equivalent in February (28 days in 2026, not a leap
      // year) -- the handler must clamp to Feb 28, not throw or silently
      // pick a different day.
      _focusDay(tester, 31);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pump();
      await tester.pump();

      expect(displayedMonth.month, 2);
      expect(_focusedDate(), DateTime(2026, 2, 28));
    });
  });

  group('buildDayGridKeyboardHandler — negative assertions', () {
    guardedTestWidgets('an unrelated key is ignored and does not move focus', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          onDayTap: (_) {},
          keyboardHandler: buildDayGridKeyboardHandler(isDisabled: (_) => false, onSelect: (_) {}),
        ),
      );

      _focusDay(tester, 15);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();

      expect(_focusedDate(), DateTime(2026, 9, 15));
    });

    guardedTestWidgets('arrow keys never invoke onSelect', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var selectCount = 0;
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          onDayTap: (_) {},
          keyboardHandler: buildDayGridKeyboardHandler(isDisabled: (_) => false, onSelect: (_) => selectCount++),
        ),
      );

      _focusDay(tester, 15);
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
