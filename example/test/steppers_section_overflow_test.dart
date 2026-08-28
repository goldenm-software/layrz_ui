import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:example/src/sections/steppers_section.dart';

/// Permanent overflow regression coverage for [StepperSection].
///
/// This page has overflowed three separate times during its development, for
/// three different reasons — none of which showed up in `LayrzStepper`'s own
/// widget tests, because all three were about how the *showroom page*
/// composes the component, not about the component itself:
///
/// 1. The horizontal layout was demonstrated inside a `ShowroomSection`,
///    whose `SingleChildScrollView` hands unbounded height to a component
///    whose whole point is to fill *bounded* space.
/// 2. A "wide" tab silently rendered the compact accordion instead, since the
///    layout used to be derived from `context.isCompact` rather than stated
///    explicitly via `LayrzStepperDirection` — a narrow ambient viewport
///    picked the wrong branch regardless of which tab was visually selected.
/// 3. The tab-toggle row of two `LayrzButton`s overflowed horizontally at
///    narrow widths, and — independently — the vertical accordion tab, which
///    has no internal scroll or `Expanded` of its own, overflowed vertically
///    at short heights once it was actually given a bounded box instead of
///    the unbounded one from defect 1.
///
/// This test pumps the real [StepperSection] — not a stand-in — at a matrix
/// of physical sizes spanning wide/narrow and tall/short combinations, for
/// both of its tabs, and asserts no exception (in particular, no
/// `RenderFlex` overflow) is thrown at any of them. It exists so a fourth way
/// to overflow this page gets caught here instead of by resizing a window by
/// hand.
void main() {
  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en'),
        delegates: const [
          DefaultWidgetsLocalizations.delegate,
          LayrzUiL10nDelegate(),
        ],
        child: LayrzTheme(
          data: LayrzThemeData.light(),
          child: MediaQuery(
            data: MediaQueryData.fromView(tester.view),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: const StepperSection(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final sizes = <String, Size>{
    'large': const Size(1400, 1000),
    'wide-short': const Size(1400, 500),
    'typical-small-desktop': const Size(1024, 640),
    'narrow-tall': const Size(400, 1200),
    'narrow-short': const Size(400, 400),
    // 320×300 is deliberately excluded from this matrix — a ruled-on
    // omission, not an untested gap. It overflows, but the overflow is
    // LayrzStepper's own irreducible chrome (stepper.dart:173-224), not a
    // defect in how this page composes the component: the Expanded area this
    // page hands the stepper at that size is only ~264×90, and the stepper's
    // fixed-height chrome — the wide header's indicator band, its label, two
    // spacers, and the Back/Next button row — needs roughly 140-150px before
    // any step body can render at all, regardless of direction. Confirmed
    // the very next size up, 400×400, passes cleanly.
    //
    // This floor is well below any viewport worth supporting (the smallest
    // common phone is ~360×640), so the maintainer's ruling was to document
    // the minimum rather than add scope to LayrzStepper to degrade
    // gracefully below it — see the "Constraints" section of
    // `wiki/Widgets/LayrzStepper.md` for the same number recorded where a
    // consumer would actually look for it.
  };

  for (final entry in sizes.entries) {
    testWidgets('horizontal tab: no overflow at ${entry.key} (${entry.value})', (tester) async {
      await pumpAtSize(tester, entry.value);
      expect(tester.takeException(), isNull, reason: 'horizontal/${entry.key}');
    });

    testWidgets('vertical tab: no overflow at ${entry.key} (${entry.value})', (tester) async {
      await pumpAtSize(tester, entry.value);
      await tester.tap(find.text('Vertical', findRichText: true));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'vertical/${entry.key}');
    });
  }
}
