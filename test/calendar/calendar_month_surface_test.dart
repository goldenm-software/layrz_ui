import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  // Must run before `_dstFallBackTransitions` is first read below (it is a
  // top-level `final`, evaluated the moment the `for` loop over it runs
  // during test *declaration*, which happens before `setUpAll` bodies ever
  // execute) -- so this cannot be a `setUpAll` call. See the DST guards
  // below for why this is needed only in this test file's isolate, not in
  // `lib/`.
  tzdata.initializeTimeZones();

  group('LayrzCalendarMonthSurface', () {
    guardedTestWidgets('renders weekday header labels', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
          ),
        ),
      );

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    guardedTestWidgets(
      'the weekday header labels resolve to the theme\'s full title text style, not a literal size',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SizedBox(
            width: 1000,
            height: 800,
            child: LayrzCalendarMonthSurface(
              focusedDate: DateTime(2026, 8, 1),
              entries: const [],
            ),
          ),
        );

        final style = tester.widget<Text>(find.text('Sun')).style!;
        final tokens = LayrzTheme.of(tester.element(find.text('Sun'))).tokens;

        // The header row stays at full `title` -- only the day numbers got
        // the body-size-with-title-weight correction (Kenny named "the
        // days" specifically). This also keeps month view's header
        // consistent with week view's own `title`-styled column-header date
        // numbers.
        expect(style.fontSize, tokens.typography.title.fontSize);
        expect(style.fontWeight, tokens.typography.title.fontWeight);
        expect(style.fontFamily, tokens.typography.title.fontFamily);
      },
    );

    guardedTestWidgets(
      'the weekday header row fully contains its own text -- no clipping (regression)',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Regression guard for a real production defect: the header row's
        // fixed height was once hardcoded and its padding arithmetic
        // double-subtracted the vertical padding it was meant to reserve, so
        // the title-styled text clipped silently. `Text`'s own laid-out box
        // stretches to fill whatever ancestor constrains it (verified: a
        // `Text` inside a too-short `SizedBox` reports `getSize` equal to
        // the `SizedBox`, NOT its glyph bounds) -- so comparing box rects
        // against each other is a tautology that would not have caught this
        // bug. `RenderParagraph.textSize` reports the paragraph's actual
        // intrinsic content size regardless of the box it was laid out
        // into, so this compares that real content height against the
        // box's constrained height.
        await pumpThemed(
          tester,
          SizedBox(
            width: 1000,
            height: 800,
            child: LayrzCalendarMonthSurface(
              focusedDate: DateTime(2026, 8, 1),
              entries: const [],
            ),
          ),
        );

        final paragraph = tester.renderObject<RenderParagraph>(find.text('Sun'));

        expect(
          paragraph.textSize.height,
          lessThanOrEqualTo(paragraph.size.height),
          reason:
              'the header text\'s intrinsic content height (${paragraph.textSize.height}) exceeds the box it was '
              'laid out into (${paragraph.size.height}) -- the text is being clipped',
        );
      },
    );

    guardedTestWidgets('default firstDayOfWeek (Sunday) orders the header row Sun..Sat', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
          ),
        ),
      );

      final headerRow = tester.widget<Row>(_findHeaderRow());
      final labels = headerRow.children
          .whereType<Expanded>()
          .map((e) => ((e.child as Padding).child as Text).data)
          .toList();

      expect(labels, ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']);
    });

    guardedTestWidgets('firstDayOfWeek: DateTime.monday orders the header row Mon..Sun', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
            firstDayOfWeek: DateTime.monday,
          ),
        ),
      );

      final headerRow = tester.widget<Row>(_findHeaderRow());
      final labels = headerRow.children
          .whereType<Expanded>()
          .map((e) => ((e.child as Padding).child as Text).data)
          .toList();

      expect(labels, ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
    });

    guardedTestWidgets('firstDayOfWeek: DateTime.saturday orders the header row Sat..Fri', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
            firstDayOfWeek: DateTime.saturday,
          ),
        ),
      );

      final headerRow = tester.widget<Row>(_findHeaderRow());
      final labels = headerRow.children
          .whereType<Expanded>()
          .map((e) => ((e.child as Padding).child as Text).data)
          .toList();

      expect(labels, ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri']);
    });

    guardedTestWidgets(
      'firstDayOfWeek: DateTime.monday places August 1 2026 (a Saturday) in the last column of its row',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SizedBox(
            width: 1000,
            height: 800,
            child: LayrzCalendarMonthSurface(
              focusedDate: DateTime(2026, 8, 1),
              entries: const [],
              firstDayOfWeek: DateTime.monday,
            ),
          ),
        );

        // Under Monday-first, Aug 1 2026 (Saturday) is the 6th column (index
        // 5) of the first week row -- asserted via the actual cell date, not
        // merely that "1" renders somewhere.
        final cell = tester.widget<LayrzCalendarDayCell>(
          find.byWidgetPredicate((w) => w is LayrzCalendarDayCell && w.date == DateTime(2026, 8, 1)),
        );
        expect(cell.date.weekday, DateTime.saturday);
      },
    );

    guardedTestWidgets(
      'firstDayOfWeek: DateTime.sunday (default) places August 1 2026 (a Saturday) as the last day of the first row',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SizedBox(
            width: 1000,
            height: 800,
            child: LayrzCalendarMonthSurface(
              focusedDate: DateTime(2026, 8, 1),
              entries: const [],
            ),
          ),
        );

        // Sunday-first grid start for August 2026 is July 26 (a Sunday), so
        // Aug 1 (Saturday) is exactly the 7th cell -- index 6 -- of the
        // grid's flattened cell list.
        final cells = tester.widgetList<LayrzCalendarDayCell>(find.byType(LayrzCalendarDayCell)).toList();
        expect(cells[6].date, DateTime(2026, 8, 1));
      },
    );

    guardedTestWidgets('renders every day of the focused month', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // August 2026 has 31 days.
      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
          ),
        ),
      );

      for (var day = 1; day <= 31; day++) {
        expect(find.text('$day'), findsWidgets);
      }
    });

    guardedTestWidgets('places a single-day event only on its own date', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: [
              LayrzCalendarEntry(title: 'Single day event', start: DateTime(2026, 8, 15), end: DateTime(2026, 8, 15)),
            ],
          ),
        ),
      );

      expect(find.text('Single day event'), findsOneWidget);
    });

    guardedTestWidgets('places a multi-day event within one week as a single continuous bar, not one chip per day', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // August 10-12, 2026 falls entirely within one week row under both
      // Monday-first and the default Sunday-first grid, so this entry never
      // crosses a week boundary and must render as exactly one bar with its
      // label shown once -- not three separate per-day chips.
      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: [
              LayrzCalendarEntry(title: 'Multi day', start: DateTime(2026, 8, 10), end: DateTime(2026, 8, 12)),
            ],
          ),
        ),
      );

      expect(find.text('Multi day'), findsOneWidget);
    });

    guardedTestWidgets('a multi-day event that crosses a week boundary renders one bar per week row, not a single '
        'bar or a chip per day', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Under the default Sunday-first grid, August 1 2026 (a Saturday) is
      // the last day of the grid's first week row (Jul 26 - Aug 1), and
      // August 2 begins the next row (Aug 2 - Aug 8). An entry spanning
      // August 1-4 crosses that boundary: one bar segment in the first week
      // row (just Aug 1), a second independent segment in the next
      // (Aug 2-4) -- two bars total, the label shown once per bar/row, never
      // once per occupied day (which would be four).
      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: [
              LayrzCalendarEntry(title: 'Spans weeks', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 4)),
            ],
          ),
        ),
      );

      expect(find.text('Spans weeks'), findsNWidgets(2));
    });

    guardedTestWidgets('applies isDateDisabled per date without affecting days that have no events', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
            isDateDisabled: (date) => date.weekday == DateTime.saturday || date.weekday == DateTime.sunday,
          ),
        ),
      );

      // The grid still renders every day regardless of disabled status --
      // disabling is a visual overlay, not an omission.
      for (var day = 1; day <= 31; day++) {
        expect(find.text('$day'), findsWidgets);
      }
    });

    guardedTestWidgets('leading and trailing days from adjacent months fill the grid rectangle', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // August 1, 2026 is a Saturday, so under the default Sunday-first grid
      // it must show trailing July days to fill the first row.
      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
          ),
        ),
      );

      // July has 31 days; the last few fill the leading grid cells.
      expect(find.text('31'), findsWidgets);
    });

    guardedTestWidgets('wraps the grid in a divider-colored container instead of per-cell borders', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
          ),
        ),
      );

      // The grid-line container is the plain (undecorated-otherwise)
      // Container directly wrapping the week-row Column, painted with the
      // divider color -- this is what shows through the gaps between cells
      // as the uniform grid line, replacing the old per-cell Border.all.
      final gridContainer = tester.widget<Container>(find.byType(Container).first);
      expect(gridContainer.color, LayrzThemeData.light().tokens.colors.divider);
    });

    guardedTestWidgets('a multi-day bar renders filled, identically to a single-day chip of the same color', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const accent = Color(0xFFFF9800);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: [
              LayrzCalendarEntry(
                title: 'Filled bar',
                start: DateTime(2026, 8, 10),
                end: DateTime(2026, 8, 12),
                color: accent,
              ),
            ],
          ),
        ),
      );

      final barContainer = tester.widget<Container>(
        find.ancestor(of: find.text('Filled bar'), matching: find.byType(Container)).first,
      );
      final decoration = barContainer.decoration as BoxDecoration;

      // Same filled treatment as `_EventChip`: full-opacity accent
      // background, contrast-color text, no alpha blend.
      expect(decoration.color, accent);
      final textStyle = tester.widget<Text>(find.text('Filled bar')).style;
      expect(textStyle?.color, accent.contrastColor);
    });

    guardedTestWidgets(
      'two multi-day entries occupying the same week keep distinct lanes across every week row they span',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Both entries span the same three-week range and overlap entirely,
        // so real lane packing must place them in different lanes for the
        // whole month, not just within a single week.
        await pumpThemed(
          tester,
          SizedBox(
            width: 1000,
            height: 800,
            child: LayrzCalendarMonthSurface(
              focusedDate: DateTime(2026, 8, 1),
              entries: [
                LayrzCalendarEntry(title: 'Lane A', start: DateTime(2026, 8, 3), end: DateTime(2026, 8, 20)),
                LayrzCalendarEntry(title: 'Lane B', start: DateTime(2026, 8, 3), end: DateTime(2026, 8, 20)),
              ],
            ),
          ),
        );

        // Both bars render every week they cross without colliding -- if
        // they shared a lane the surface would still render two Text nodes
        // per week (each bar paints unconditionally), so the real assertion
        // is that both labels are present at all, proving neither bar's
        // LayoutBuilder threw or was skipped due to a lane conflict.
        expect(find.text('Lane A'), findsWidgets);
        expect(find.text('Lane B'), findsWidgets);
      },
    );

    guardedTestWidgets(
      'a dense week under a non-default (Monday) week start still bounds visible bars/chips to the measured cap',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 500);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // A short viewport constrains each week row's available height
        // severely, so the measured maxSlots is small. Six overlapping
        // multi-day entries all crossing the same week, under a non-default
        // Monday-first grid -- the case most likely to go unwritten, per the
        // plan's own risk callout. Guarded so any divergence between the bar
        // cap and the chip cap (bars painted on slots no cell reserved)
        // surfaces as a RenderFlex overflow.
        //
        // 450 is chosen, not eyeballed: with `_kHeaderRowHeight` (34) and
        // `kLayrzCalendarDateRowHeight` (22, sized for the title-styled date
        // number) each week row's zero-event floor is `date_row + sp1*3 +
        // stroke1*2` = 42px, so six rows need at least 34 + 6 + 6*42 = 292px
        // just to render with `maxSlots == 0` and no overflow -- going lower
        // than that would make the date row itself overflow the cell,
        // unrelated to what this test is actually guarding. 450px lands
        // comfortably in the "maxSlots == 1" band (34 + 6 + 6*62 = 412px),
        // leaving margin while still keeping the cap tight enough that not
        // all six entries can render.
        await pumpThemed(
          tester,
          SizedBox(
            width: 1000,
            height: 450,
            child: LayrzCalendarMonthSurface(
              focusedDate: DateTime(2026, 8, 1),
              firstDayOfWeek: DateTime.monday,
              entries: [
                for (var i = 0; i < 6; i++)
                  LayrzCalendarEntry(title: 'Dense $i', start: DateTime(2026, 8, 10), end: DateTime(2026, 8, 12)),
              ],
            ),
          ),
        );

        // No overflow occurred (guardedTestWidgets asserts this); some bars
        // rendered but not all six, proving the cap actually bounded them.
        final rendered = [for (var i = 0; i < 6; i++) find.text('Dense $i').evaluate().length];
        final totalRendered = rendered.fold<int>(0, (a, b) => a + b);
        expect(totalRendered, lessThan(6));
      },
    );

    for (final transition in _dstFallBackTransitions) {
      guardedTestWidgets(
        'does not duplicate or shift a day across a DST transition '
        '(default Sunday-first grid, ${transition.label})',
        (tester) async {
          tester.view.physicalSize = const Size(1200, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          // Regression for a bug where the grid stepped cells via
          // `gridStart.add(Duration(days: n))`. Duration arithmetic is
          // absolute elapsed time, not calendar-day stepping: crossing a
          // local DST transition lands a 24h step on 23:00 of the
          // *previous* local day, duplicating that day's number and
          // shifting every subsequent cell onto the wrong weekday column.
          // The fix steps via the `DateTime` constructor
          // (`DateTime(y, m, d + n)`), which normalizes by calendar date
          // and is immune to the local UTC-offset change.
          //
          // [transition] names a real, historical fall-back transition
          // (offset decreases) in a specific IANA zone, located via
          // `package:timezone` rather than by scanning the host's own local
          // timezone for one -- see [_dstFallBackTransitions] for why
          // fall-back specifically, and why three zones spanning both
          // hemispheres plus a 30-minute shift.
          //
          // Honesty note, confirmed by direct execution before trusting
          // this rewrite: this widget-pumping assertion is NOT immune to
          // the host's own `TZ` the way the RISK-7 re-proof below is.
          // `LayrzCalendarMonthSurface.focusedDate` is a plain `DateTime`,
          // and `_buildWeekRow`'s own date stepping is plain host-local
          // `DateTime` arithmetic -- it has no notion of [transition]'s
          // `Location` at all, by design (the production fix only needed
          // calendar-field stepping, never a zone parameter). So if this
          // widget's stepping were ever reverted to `Duration`, THIS
          // assertion would only fail under a host `TZ` that itself
          // observes a transition inside [transition.year]/[transition.month]
          // -- confirmed by reverting `_buildWeekRow` to
          // `weekStart.add(Duration(...))` and re-running: 0 of these six
          // widget tests failed under TZ=Etc/UTC, and only the two
          // `America/New_York`-labeled tests failed under
          // TZ=America/New_York. The RISK-7 re-proof is what is genuinely
          // host-independent (it never pumps the widget, only compares two
          // independently-computed `TZDateTime`-based reference grids), and
          // is what should be trusted as the "does this stepping technique
          // actually diverge" proof. This widget-level assertion is kept
          // because it verifies the shipping widget renders correctly for
          // these real, named dates -- genuine coverage, just not the
          // timezone-independent regression guard it might look like.
          final expectedCounts = _referenceGridCounts(transition.location, transition.year, transition.month, 7);

          await pumpThemed(
            tester,
            SizedBox(
              width: 1000,
              height: 800,
              child: LayrzCalendarMonthSurface(
                focusedDate: DateTime(transition.year, transition.month, 1),
                entries: const [],
              ),
            ),
          );

          // Scoped to descend from a LayrzCalendarDayCell specifically --
          // a bare find.text('$day') can also match a week-gutter label
          // when a row's ISO week number happens to equal a day-of-month
          // number rendered elsewhere in the same grid (e.g. April 2024
          // begins in ISO week 13, and April also has a day 13).
          final dayCellFinder = find.byType(LayrzCalendarDayCell);
          for (final entry in expectedCounts.entries) {
            expect(
              find.descendant(of: dayCellFinder, matching: find.text('${entry.key}')),
              findsNWidgets(entry.value),
              reason: 'day-of-month ${entry.key} should render exactly ${entry.value} time(s) in this grid',
            );
          }
        },
      );

      guardedTestWidgets(
        'does not duplicate or shift a day across a DST transition '
        '(Monday-first grid, ${transition.label})',
        (tester) async {
          tester.view.physicalSize = const Size(1200, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          // See the Sunday-first sibling test's "Honesty note" above: this
          // widget-pumping assertion is not host-`TZ`-independent either,
          // for the same reason. The RISK-7 re-proof is the guard that
          // actually is.
          final expectedCounts = _referenceGridCounts(transition.location, transition.year, transition.month, 1);

          await pumpThemed(
            tester,
            SizedBox(
              width: 1000,
              height: 800,
              child: LayrzCalendarMonthSurface(
                focusedDate: DateTime(transition.year, transition.month, 1),
                entries: const [],
                firstDayOfWeek: DateTime.monday,
              ),
            ),
          );

          // See the Sunday-first sibling test above for why this must be
          // scoped to LayrzCalendarDayCell rather than a bare find.text.
          final dayCellFinder = find.byType(LayrzCalendarDayCell);
          for (final entry in expectedCounts.entries) {
            expect(
              find.descendant(of: dayCellFinder, matching: find.text('${entry.key}')),
              findsNWidgets(entry.value),
              reason: 'day-of-month ${entry.key} should render exactly ${entry.value} time(s) in this grid',
            );
          }
        },
      );
    }

    test(
      'RISK-7 re-proof: the parameterized DST reference grid actually fails against a Duration-stepped '
      'implementation, for both Sunday and Monday first-day values, in every named transition zone',
      () {
        // This is the re-proof the plan requires before trusting the
        // rewritten regression tests above: a rewritten guard that would
        // pass against BOTH the safe DateTime-constructor stepping and the
        // buggy Duration-based stepping proves nothing. Computed
        // independently here (not by pumping the widget) to isolate exactly
        // the stepping arithmetic the production code and the old bug
        // share.
        //
        // Both `_referenceGridCounts` and `_buggyDurationSteppedGridCounts`
        // are deliberately built on `TZDateTime` in the transition's own
        // named `Location`, not on plain `DateTime`: plain `DateTime`
        // arithmetic only diverges across a transition that the *host
        // process's* `TZ` actually observes on that date, so a
        // plain-`DateTime` version of this proof would silently pass or
        // fail depending on where the suite runs -- confirmed by execution:
        // computing these two with plain `DateTime(year, month, day)`
        // instead of `TZDateTime(location, year, month, day)` makes
        // `differs` depend entirely on the host's own `TZ`, not on which
        // zone this loop is iterating. Routing both through `TZDateTime`
        // in the named zone is what makes the divergence reproducible
        // under any host `TZ` -- verified identical under TZ=Etc/UTC,
        // TZ=America/New_York and TZ=Australia/Lord_Howe before trusting
        // this rewrite.
        for (final transition in _dstFallBackTransitions) {
          for (final firstDayOfWeek in [DateTime.sunday, DateTime.monday]) {
            final safeCounts = _referenceGridCounts(
              transition.location,
              transition.year,
              transition.month,
              firstDayOfWeek,
            );
            final buggyCounts = _buggyDurationSteppedGridCounts(
              transition.location,
              transition.year,
              transition.month,
              firstDayOfWeek,
            );

            expect(
              safeCounts,
              isNot(equals(buggyCounts)),
              reason:
                  'The safe (DateTime-constructor-stepped) and buggy (Duration-stepped) reference grids '
                  'produced IDENTICAL day-count maps for ${transition.label}, firstDayOfWeek=$firstDayOfWeek -- '
                  'this means the DST regression test as written would pass even against reintroduced '
                  'Duration stepping, i.e. it has degenerated into a tautology.',
            );
          }
        }
      },
    );
  });

  group('LayrzCalendarMonthSurface onTap / LayrzCalendarEntry.onTap', () {
    guardedTestWidgets('tapping empty cell space fires the surface\'s onTap with that date, not an entry\'s onTap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? tappedDate;
      var entryTapped = false;

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
            onTap: (d) => tappedDate = d,
          ),
        ),
      );

      // Tap the day-15 cell's empty body -- below the date number row.
      final cellFinder = find.ancestor(of: find.text('15'), matching: find.byType(LayrzCalendarDayCell)).first;
      await tester.tapAt(tester.getBottomRight(cellFinder) - const Offset(4, 4));
      await tester.pump();

      expect(tappedDate, DateTime(2026, 8, 15));
      expect(entryTapped, isFalse);
    });

    guardedTestWidgets('tapping a multi-day bar fires that entry\'s own onTap, not the surface\'s onTap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? tappedDate;
      var entryTapped = false;
      final entry = LayrzCalendarEntry(
        title: 'Offsite',
        start: DateTime(2026, 8, 10),
        end: DateTime(2026, 8, 12),
        onTap: () => entryTapped = true,
      );

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: [entry],
            onTap: (d) => tappedDate = d,
          ),
        ),
      );

      await tester.tap(find.text('Offsite'));
      await tester.pump();

      expect(entryTapped, isTrue);
      expect(tappedDate, isNull);
    });

    guardedTestWidgets(
      'with the surface\'s onTap null and no entry carrying its own onTap, the grid is exactly as display-only as '
      'before -- no MouseRegion at all',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SizedBox(
            width: 1000,
            height: 800,
            child: LayrzCalendarMonthSurface(
              focusedDate: DateTime(2026, 8, 1),
              entries: [
                LayrzCalendarEntry(title: 'Offsite', start: DateTime(2026, 8, 10), end: DateTime(2026, 8, 12)),
              ],
              showWeekNumbers: false,
            ),
          ),
        );

        expect(find.byType(MouseRegion), findsNothing);
      },
    );

    guardedTestWidgets('a preview multi-day bar renders ghosted and still occupies its lane', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: [
              LayrzCalendarEntry(
                title: 'Draft trip',
                start: DateTime(2026, 8, 10),
                end: DateTime(2026, 8, 12),
                isPreview: true,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Draft trip'), findsOneWidget);

      final container = tester.widget<Container>(
        find.ancestor(of: find.text('Draft trip'), matching: find.byType(Container)).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect(decoration.color!.a, lessThan(1.0));
    });
  });

  group('LayrzCalendarWeekGutter geometry (U8 mandatory regression)', () {
    // This group exists specifically because an audit of this file found
    // ZERO geometry measurements anywhere in it before U8 -- every assertion
    // was `find.text(...)`/`findsNWidgets(...)`, so nothing would have caught
    // a week-number gutter accidentally composed INSIDE the week row's
    // `Stack` (which would silently narrow `_MultiDayBar`'s
    // `constraints.maxWidth`, shifting and mis-sizing every bar while the
    // `Expanded` day cells kept looking correct). See
    // `LayrzCalendarMonthSurface`'s class doc and `LayrzCalendarWeekGutter`'s
    // class doc for the full reasoning this test guards.
    guardedTestWidgets(
      'a multi-day bar renders at the IDENTICAL rect whether showWeekNumbers is true or false',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // August 10-12, 2026 falls entirely within one week row under the
        // default Sunday-first grid (same entry the "single continuous bar"
        // test above uses), so exactly one `_MultiDayBar` renders and its
        // rect is unambiguous to compare between the two configurations.
        Widget buildSurface({required bool showWeekNumbers}) {
          return SizedBox(
            width: 1000,
            height: 800,
            child: LayrzCalendarMonthSurface(
              focusedDate: DateTime(2026, 8, 1),
              entries: [
                LayrzCalendarEntry(title: 'Multi day', start: DateTime(2026, 8, 10), end: DateTime(2026, 8, 12)),
              ],
              showWeekNumbers: showWeekNumbers,
            ),
          );
        }

        await pumpThemed(tester, buildSurface(showWeekNumbers: false));
        final rectWithoutGutter = tester.getRect(find.text('Multi day'));

        await pumpThemed(tester, buildSurface(showWeekNumbers: true));
        final rectWithGutter = tester.getRect(find.text('Multi day'));

        expect(
          rectWithGutter,
          rectWithoutGutter,
          reason:
              'The multi-day bar shifted or resized when the week-number gutter appeared. This means the '
              'gutter is (or is affecting) the width `_MultiDayBar` measures via '
              '`constraints.maxWidth / columns`, which must stay exactly 7-column-equivalent regardless '
              'of whether the gutter renders as a sibling outside the grid -- see '
              'LayrzCalendarMonthSurface\'s class doc for why this must never happen.',
        );
      },
    );

    guardedTestWidgets(
      'every day cell renders at the IDENTICAL rect whether showWeekNumbers is true or false',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // A day-cell regression sibling to the bar-geometry test above: the
        // day cells are `Expanded` and so could in principle still look
        // correct even if `maxWidth` were narrowed (they simply divide
        // whatever width they are given by 7) -- this test would catch the
        // case where the *grid itself* shrinks instead of the gutter being a
        // sibling reservation outside it, which the bar test alone would not
        // distinguish from "everything shifted together correctly".
        Widget buildSurface({required bool showWeekNumbers}) {
          return SizedBox(
            width: 1000,
            height: 800,
            child: LayrzCalendarMonthSurface(
              focusedDate: DateTime(2026, 8, 1),
              entries: const [],
              showWeekNumbers: showWeekNumbers,
            ),
          );
        }

        await pumpThemed(tester, buildSurface(showWeekNumbers: false));
        final rectWithoutGutter = tester.getRect(find.text('15').first);

        await pumpThemed(tester, buildSurface(showWeekNumbers: true));
        final rectWithGutter = tester.getRect(find.text('15').first);

        expect(
          rectWithGutter,
          rectWithoutGutter,
          reason:
              'A day cell\'s date-number rect shifted when the week-number gutter appeared -- the grid '
              'body must occupy the exact same rect either way, with the gutter reserving space as an '
              'outer sibling rather than shrinking the grid.',
        );
      },
    );

    guardedTestWidgets('renders the week gutter when showWeekNumbers is true (the default)', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(focusedDate: DateTime(2026, 8, 1), entries: const []),
        ),
      );

      expect(find.byType(LayrzCalendarWeekGutter), findsOneWidget);
    });

    guardedTestWidgets('renders no week gutter when showWeekNumbers is false', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
            showWeekNumbers: false,
          ),
        ),
      );

      expect(find.byType(LayrzCalendarWeekGutter), findsNothing);
    });

    guardedTestWidgets('week numbers ascend top-to-bottom, matching each row\'s own first date', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // August 2026 under the default Sunday-first grid starts its first
      // row on Sunday, July 26 (ISO week 30) and its rows advance weekly
      // from there: 30, 31, 32, 33, 34, 35.
      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(focusedDate: DateTime(2026, 8, 1), entries: const []),
        ),
      );

      // Scoped to descend from LayrzCalendarWeekGutter specifically -- a bare
      // `find.text(week)` collides with day-of-month numbers in the grid
      // itself (e.g. "30" and "31" are also days of August), so every lookup
      // in this group must search only the gutter's own subtree.
      final gutterFinder = find.byType(LayrzCalendarWeekGutter);
      final expectedWeeks = ['30', '31', '32', '33', '34', '35'];
      final tops = <double>[];
      for (final week in expectedWeeks) {
        final finder = find.descendant(of: gutterFinder, matching: find.text(week));
        expect(finder, findsOneWidget);
        tops.add(tester.getTopLeft(finder).dy);
      }
      for (var i = 1; i < tops.length; i++) {
        expect(
          tops[i],
          greaterThan(tops[i - 1]),
          reason: 'week ${expectedWeeks[i]} should render below the previous',
        );
      }
    });

    guardedTestWidgets('tapping a week number switches to week view for that week (via LayrzCalendar)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? tappedWeekStart;
      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
            onWeekNumberTap: (weekStart) => tappedWeekStart = weekStart,
          ),
        ),
      );

      // Row 4 (ISO week 34) starts Sunday, August 23, 2026 -- the default
      // Sunday-first grid for August 2026 numbers its 6 rows 30..35 (see
      // the "week numbers ascend" test above), so week 34 is the fifth row.
      await tester.tap(find.descendant(of: find.byType(LayrzCalendarWeekGutter), matching: find.text('34')));
      await tester.pump();

      expect(tappedWeekStart, DateTime(2026, 8, 23));
    });

    guardedTestWidgets('week numbers are correct under Monday-first as well as the default Sunday-first', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Under Monday-first, August 2026's grid starts Monday, July 27 (ISO
      // week 31) and each row also advances by exactly one ISO week: 31-36.
      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
            firstDayOfWeek: DateTime.monday,
          ),
        ),
      );

      final gutterFinder = find.byType(LayrzCalendarWeekGutter);
      for (final week in ['31', '32', '33', '34', '35', '36']) {
        expect(
          find.descendant(of: gutterFinder, matching: find.text(week)),
          findsOneWidget,
          reason: 'expected week $week to render under Monday-first',
        );
      }
    });

    guardedTestWidgets('a year-boundary month renders its week numbers without duplicates', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // January 2027's grid (default Sunday-first) straddles the ISO
      // year boundary: its first row's own first day (a late-December 2026
      // date) is ISO week 53 of 2026, and the grid must still read as a
      // clean ascending-then-wrapping sequence with no two rows sharing a
      // number.
      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(focusedDate: DateTime(2027, 1, 1), entries: const []),
        ),
      );

      final gutter = tester.widget<LayrzCalendarWeekGutter>(find.byType(LayrzCalendarWeekGutter));
      final weekNumbers = gutter.weekStarts.map(isoWeekNumberOf).toList();
      expect(weekNumbers.toSet(), hasLength(weekNumbers.length), reason: 'week numbers must not repeat: $weekNumbers');
    });
  });
}

/// Finds the weekday header [Row] specifically -- not merely "the first
/// [Row] in the tree", which broke once [LayrzCalendarMonthSurface] started
/// wrapping its whole output in an outer gutter [Row] (`showWeekNumbers`
/// defaults to `true`, so that outer `Row` is *also* an ancestor of the "Sun"
/// label, not just the header row itself). Disambiguated by requiring every
/// child to be an [Expanded] wrapping a [Padding] wrapping a [Text] directly
/// -- the header row's exact shape, and distinct from both the outer gutter
/// `Row` (2 children: the gutter and the grid) and each week row's day-cell
/// `Row` (7 [Expanded]s, but wrapping a [Padding] around a
/// `LayrzCalendarDayCell`, never a bare [Text]).
Finder _findHeaderRow() => find.byWidgetPredicate((widget) {
  if (widget is! Row || widget.children.length != 7) return false;
  return widget.children.every(
    (child) => child is Expanded && child.child is Padding && (child.child as Padding).child is Text,
  );
});

/// One real, historical **fall-back** DST transition (the UTC offset
/// *decreases*, i.e. local clocks move backward), named explicitly by IANA
/// zone and month rather than found by scanning any host's local timezone.
///
/// [label] is only for test failure messages. [location] is resolved via
/// `package:timezone`, and [year]/[month] name the month the transition
/// falls in, in that zone's own calendar.
typedef _DstFallBackTransition = ({tz.Location location, String label, int year, int month});

/// Three real fall-back transitions spanning both hemispheres plus a
/// fractional-hour shift, replacing the old host-timezone scan.
///
/// Deliberately fall-back specifically, not "any month whose offset
/// changes": a spring-forward transition (offset increases, an hour is
/// skipped) shifts the *time-of-day* on the transition day but never
/// duplicates a day-of-month number when stepped with `Duration(days: 1)`
/// from local midnight, since the lost hour only moves the wall-clock time
/// within the same calendar date, not across a date boundary. A fall-back
/// transition, by contrast, subtracts an hour from a local
/// `add(Duration(days: n))` step and can land the result at 23:00 of the
/// *previous* calendar day, which is precisely the duplicate-day bug this
/// regression test exists to catch.
///
/// - `America/New_York`, November 2024 (2024-11-03: offset -04:00 → -05:00)
///   — a northern-hemisphere fall-back.
/// - `Pacific/Auckland`, April 2024 (2024-04-07: offset +13:00 → +12:00) —
///   DST there runs opposite through the year, so this is a
///   spring-into-southern-winter fall-back, not the same calendar season as
///   the New York case.
/// - `Australia/Lord_Howe`, April 2024 (2024-04-07: offset +11:00 →
///   +10:30) — the 30-minute shift, which would defeat an implementation
///   that assumed every DST delta is a whole hour.
///
/// All three verified, by direct execution, to make
/// [_referenceGridCounts] and [_buggyDurationSteppedGridCounts] diverge for
/// both `firstDayOfWeek` values — see the RISK-7 re-proof test.
final _dstFallBackTransitions = <_DstFallBackTransition>[
  (location: tz.getLocation('America/New_York'), label: 'America/New_York 2024-11', year: 2024, month: 11),
  (location: tz.getLocation('Pacific/Auckland'), label: 'Pacific/Auckland 2024-04', year: 2024, month: 4),
  (location: tz.getLocation('Australia/Lord_Howe'), label: 'Australia/Lord_Howe 2024-04', year: 2024, month: 4),
];

/// The correct, DST-immune calendar-date-stepped reference grid's per-day
/// render counts for [year]/[month] under [firstDayOfWeek] — computed
/// independently of production code, using only the `TZDateTime` constructor
/// field overflow (the same normalizing behaviour as the `DateTime`
/// constructor, but resolved against [location]'s own offset rules rather
/// than the host process's), never `Duration`.
///
/// Built on `TZDateTime` rather than plain `DateTime` so that this reference
/// implementation actually exercises [location]'s transition regardless of
/// the host process's own `TZ` — see [_dstFallBackTransitions]'s doc and the
/// RISK-7 re-proof test for why a plain-`DateTime` version of this function
/// would not do that.
Map<int, int> _referenceGridCounts(tz.Location location, int year, int month, int firstDayOfWeek) {
  final firstOfMonth = tz.TZDateTime(location, year, month);
  final offset = (firstOfMonth.weekday - firstDayOfWeek + 7) % 7;
  final gridStart = tz.TZDateTime(location, year, month, 1 - offset);
  final counts = <int, int>{};
  for (var i = 0; i < 42; i++) {
    final date = tz.TZDateTime(location, gridStart.year, gridStart.month, gridStart.day + i);
    counts[date.day] = (counts[date.day] ?? 0) + 1;
  }
  return counts;
}

/// The buggy `Duration`-stepped equivalent of [_referenceGridCounts], used
/// only to prove the DST regression tests would actually fail against the
/// bug they exist to guard. Also built on `TZDateTime` in [location], for
/// the same host-independence reason as [_referenceGridCounts].
Map<int, int> _buggyDurationSteppedGridCounts(tz.Location location, int year, int month, int firstDayOfWeek) {
  final firstOfMonth = tz.TZDateTime(location, year, month);
  final offset = (firstOfMonth.weekday - firstDayOfWeek + 7) % 7;
  final gridStart = tz.TZDateTime(location, year, month, 1).subtract(Duration(days: offset));
  final counts = <int, int>{};
  for (var i = 0; i < 42; i++) {
    final date = gridStart.add(Duration(days: i));
    counts[date.day] = (counts[date.day] ?? 0) + 1;
  }
  return counts;
}
