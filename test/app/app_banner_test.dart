import 'package:flutter/gestures.dart' show HitTestResult;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/app/src/app_banner_painter.dart';

/// Sets an explicit, wide desktop viewport for a [testWidgets] body and
/// registers the matching teardown, per the repo's mandatory viewport rule.
void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Finds a [CustomPaint] whose painter is a [LayrzAppBannerPainter].
Finder _watermarkFinder() {
  return find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter is LayrzAppBannerPainter);
}

void main() {
  group('LayrzAppBanner value semantics', () {
    test('equal instances with the same fields are ==', () {
      const a = LayrzAppBanner(labelText: 'STAGING', color: Color(0xFF112233));
      const b = LayrzAppBanner(labelText: 'STAGING', color: Color(0xFF112233));

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different labelText are not ==', () {
      const a = LayrzAppBanner(labelText: 'STAGING');
      const b = LayrzAppBanner(labelText: 'INTERNAL');

      expect(a, isNot(equals(b)));
    });

    test('instances with different color are not ==', () {
      const a = LayrzAppBanner(labelText: 'STAGING', color: Color(0xFF112233));
      const b = LayrzAppBanner(labelText: 'STAGING', color: Color(0xFF445566));

      expect(a, isNot(equals(b)));
    });

    test('a null color and a non-null color are not ==', () {
      const a = LayrzAppBanner(labelText: 'STAGING');
      const b = LayrzAppBanner(labelText: 'STAGING', color: Color(0xFF112233));

      expect(a, isNot(equals(b)));
    });

    test('copyWith replaces only the given fields', () {
      const original = LayrzAppBanner(labelText: 'STAGING', color: Color(0xFF112233));
      final copy = original.copyWith(labelText: 'INTERNAL');

      expect(copy.labelText, equals('INTERNAL'));
      expect(copy.color, equals(original.color));
    });

    test('copyWith with no arguments returns an equal instance', () {
      const original = LayrzAppBanner(labelText: 'STAGING', color: Color(0xFF112233));
      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    test('copyWith can override color independently of labelText', () {
      const original = LayrzAppBanner(labelText: 'STAGING');
      final copy = original.copyWith(color: const Color(0xFFAABBCC));

      expect(copy.labelText, equals(original.labelText));
      expect(copy.color, equals(const Color(0xFFAABBCC)));
    });
  });

  group('LayrzAppBannerPainter', () {
    test('shouldRepaint is true when labelText changes', () {
      const oldPainter = LayrzAppBannerPainter(labelText: 'STAGING', color: Color(0xFF9E9E9E));
      const newPainter = LayrzAppBannerPainter(labelText: 'INTERNAL', color: Color(0xFF9E9E9E));

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint is true when color changes', () {
      const oldPainter = LayrzAppBannerPainter(labelText: 'STAGING', color: Color(0xFF9E9E9E));
      const newPainter = LayrzAppBannerPainter(labelText: 'STAGING', color: Color(0xFF112233));

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint is false when nothing changes', () {
      const oldPainter = LayrzAppBannerPainter(labelText: 'STAGING', color: Color(0xFF9E9E9E));
      const newPainter = LayrzAppBannerPainter(labelText: 'STAGING', color: Color(0xFF9E9E9E));

      expect(newPainter.shouldRepaint(oldPainter), isFalse);
    });
  });

  group('LayrzApp debug watermark', () {
    testWidgets('with a non-null banner, the watermark CustomPaint renders', (tester) async {
      _setWideViewport(tester);

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          banner: const LayrzAppBanner(labelText: 'STAGING'),
          home: const SizedBox(width: 100, height: 100),
        ),
      );
      await tester.pump();

      expect(_watermarkFinder(), findsOneWidget);
    });

    testWidgets('with banner null, no watermark CustomPaint is present', (tester) async {
      _setWideViewport(tester);

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          home: const SizedBox(width: 100, height: 100),
        ),
      );
      await tester.pump();

      expect(_watermarkFinder(), findsNothing);
    });

    testWidgets(
      'a non-null banner suppresses the SDK CheckedModeBanner even when debugShowCheckedModeBanner is true',
      (tester) async {
        _setWideViewport(tester);

        await tester.pumpWidget(
          LayrzApp(
            title: 'Test App',
            banner: const LayrzAppBanner(labelText: 'STAGING'),
            debugShowCheckedModeBanner: true,
            home: const SizedBox(width: 100, height: 100),
          ),
        );
        await tester.pump();

        expect(find.byType(CheckedModeBanner), findsNothing);
        expect(_watermarkFinder(), findsOneWidget);
      },
    );

    testWidgets(
      'with banner null and debugShowCheckedModeBanner true, the SDK CheckedModeBanner renders (normal path)',
      (tester) async {
        _setWideViewport(tester);

        await tester.pumpWidget(
          LayrzApp(
            title: 'Test App',
            debugShowCheckedModeBanner: true,
            home: const SizedBox(width: 100, height: 100),
          ),
        );
        await tester.pump();

        expect(find.byType(CheckedModeBanner), findsOneWidget);
        expect(_watermarkFinder(), findsNothing);
      },
    );

    testWidgets('the watermark does not block pointers: an IgnorePointer wraps its CustomPaint', (tester) async {
      _setWideViewport(tester);

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          banner: const LayrzAppBanner(labelText: 'STAGING'),
          home: const SizedBox(width: 100, height: 100),
        ),
      );
      await tester.pump();

      final ignorePointer = tester.widget<IgnorePointer>(
        find.ancestor(of: _watermarkFinder(), matching: find.byType(IgnorePointer)).first,
      );
      expect(ignorePointer.ignoring, isTrue);
    });

    testWidgets('the watermark does not block taps on content behind it', (tester) async {
      _setWideViewport(tester);

      const buttonKey = Key('behind-watermark-button');

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          banner: const LayrzAppBanner(labelText: 'STAGING'),
          home: Center(
            child: GestureDetector(
              key: buttonKey,
              onTap: () {},
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hit-tests the raw render tree at the button's own center, rather than
      // going through `tester.tap`'s synthetic pointer-event/gesture-arena
      // machinery — `Navigator` briefly flips its own internal
      // `AbsorbPointer` around pointer-down handling in the test binding
      // (`_handlePointerDown`/`_cancelActivePointers` in
      // package:flutter/src/widgets/navigator.dart, reproduced identically
      // with `banner: null` and even with a bare `WidgetsApp`), which is a
      // pre-existing Flutter test-harness characteristic unrelated to the
      // watermark. A direct hit test sidesteps that entirely and asks the
      // real question: does the render tree at this point still reach the
      // `RenderSemanticsGestureHandler` behind the watermark's paint layer.
      final result = HitTestResult();
      tester.binding.hitTestInView(result, tester.getCenter(find.byKey(buttonKey)), tester.view.viewId);

      final hitGestureHandler = result.path.any(
        (entry) => entry.target.runtimeType.toString() == 'RenderSemanticsGestureHandler',
      );
      expect(hitGestureHandler, isTrue);
    });

    testWidgets('a color override on LayrzAppBanner is passed through to the painter', (tester) async {
      _setWideViewport(tester);
      const overrideColor = Color(0xFF112233);

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          banner: const LayrzAppBanner(labelText: 'STAGING', color: overrideColor),
          home: const SizedBox(width: 100, height: 100),
        ),
      );
      await tester.pump();

      final customPaint = tester.widget<CustomPaint>(_watermarkFinder());
      final painter = customPaint.painter! as LayrzAppBannerPainter;
      expect(painter.color, equals(overrideColor));
    });

    testWidgets('with no color override, the painter receives the theme token default', (tester) async {
      _setWideViewport(tester);
      final theme = LayrzThemeData.light();

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          theme: theme,
          banner: const LayrzAppBanner(labelText: 'STAGING'),
          home: const SizedBox(width: 100, height: 100),
        ),
      );
      await tester.pump();

      final customPaint = tester.widget<CustomPaint>(_watermarkFinder());
      final painter = customPaint.painter! as LayrzAppBannerPainter;
      expect(painter.color, equals(theme.tokens.colors.watermark));
    });

    testWidgets('the watermark CustomPaint is excluded from the semantics tree', (tester) async {
      _setWideViewport(tester);
      final handle = tester.ensureSemantics();

      try {
        await tester.pumpWidget(
          LayrzApp(
            title: 'Test App',
            banner: const LayrzAppBanner(labelText: 'STAGING'),
            home: const SizedBox(width: 100, height: 100),
          ),
        );
        await tester.pump();

        final excludeSemantics = find.ancestor(
          of: _watermarkFinder(),
          matching: find.byType(ExcludeSemantics),
        );
        expect(excludeSemantics, findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });
}
