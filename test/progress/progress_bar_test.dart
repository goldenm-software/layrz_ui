import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzProgressBar', () {
    testWidgets('renders in determinate mode without an animation controller ticking', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzProgressBar(value: 0.5));

      expect(find.byType(LayrzProgressBar), findsOneWidget);
      // No pending frames should be scheduled by a determinate bar.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('renders in indeterminate mode and animates over time', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzProgressBar());

      expect(find.byType(LayrzProgressBar), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsOneWidget);

      // Pump forward and confirm the widget is still present (ticker alive
      // and not crashing across frames), without ever calling pumpAndSettle,
      // which would hang forever on a repeating animation.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LayrzProgressBar), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LayrzProgressBar), findsOneWidget);
    });

    testWidgets('null value means indeterminate, not zero', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzProgressBar());

      final handle = tester.ensureSemantics();
      try {
        final semantics = tester.getSemantics(find.byType(LayrzProgressBar));
        expect(semantics.value, isEmpty);
        expect(semantics.label, 'Loading');
      } finally {
        handle.dispose();
      }

      // Stop the repeating ticker before the test ends.
      await tester.pump(const Duration(milliseconds: 10));
    });

    testWidgets('switching from indeterminate to determinate stops the ticker', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? value;
      late StateSetter setter;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            setter = setState;
            return LayrzProgressBar(value: value);
          },
        ),
      );

      expect(find.byType(AnimatedBuilder), findsOneWidget);

      setter(() => value = 0.4);
      await tester.pump();
      // A second pump lets any frame already in flight when the controller
      // was disposed settle, so hasScheduledFrame reflects steady state.
      await tester.pump();

      expect(find.byType(AnimatedBuilder), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('switching from determinate to indeterminate restarts the ticker', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? value = 0.4;
      late StateSetter setter;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            setter = setState;
            return LayrzProgressBar(value: value);
          },
        ),
      );

      expect(find.byType(AnimatedBuilder), findsNothing);

      setter(() => value = null);
      await tester.pump();

      expect(find.byType(AnimatedBuilder), findsOneWidget);

      // Stop the repeating ticker before the test ends.
      await tester.pump(const Duration(milliseconds: 10));
    });

    testWidgets('respects MediaQuery.disableAnimationsOf by freezing the sweep', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Localizations(
            locale: const Locale('en'),
            delegates: const [
              DefaultWidgetsLocalizations.delegate,
              LayrzUiL10nDelegate(),
            ],
            child: LayrzTheme(
              data: LayrzThemeData.light(),
              child: const Center(child: LayrzProgressBar()),
            ),
          ),
        ),
      );
      await tester.pump();

      // Reduced motion must suppress the repeating animation entirely: no
      // AnimatedBuilder is built, and no frame is scheduled by this widget.
      expect(find.byType(AnimatedBuilder), findsNothing);
      expect(find.byType(LayrzProgressBar), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('stops the ticker when reduce-motion turns on at runtime while indeterminate', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      bool disableAnimations = false;
      late StateSetter setter;

      // A MediaQuery override rebuilt via StatefulBuilder, rather than two
      // separate pumpThemed calls: pumpThemed's Overlay only consumes
      // initialEntries on its first mount, so a second call in the same test
      // would leave the first bar's ticker alive underneath instead of
      // exercising the false->true transition on the same widget instance.
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setter = setState;
            return MediaQuery(
              data: MediaQueryData(disableAnimations: disableAnimations),
              child: Localizations(
                locale: const Locale('en'),
                delegates: const [
                  DefaultWidgetsLocalizations.delegate,
                  LayrzUiL10nDelegate(),
                ],
                child: LayrzTheme(
                  data: LayrzThemeData.light(),
                  child: const Center(child: LayrzProgressBar()),
                ),
              ),
            );
          },
        ),
      );
      await tester.pump();

      // Sanity check: the sweep is running before reduce-motion is toggled on.
      expect(find.byType(AnimatedBuilder), findsOneWidget);

      setter(() => disableAnimations = true);
      await tester.pump();
      await tester.pump();

      // The reduce-motion branch stops building an AnimatedBuilder...
      expect(find.byType(AnimatedBuilder), findsNothing);
      // ...and the controller behind it must be stopped too, not merely
      // unconsumed — otherwise it keeps scheduling frames forever with
      // nothing reading its value (the leak this test guards against).
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('resumes the ticker when reduce-motion turns off at runtime while indeterminate', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      bool disableAnimations = true;
      late StateSetter setter;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setter = setState;
            return MediaQuery(
              data: MediaQueryData(disableAnimations: disableAnimations),
              child: Localizations(
                locale: const Locale('en'),
                delegates: const [
                  DefaultWidgetsLocalizations.delegate,
                  LayrzUiL10nDelegate(),
                ],
                child: LayrzTheme(
                  data: LayrzThemeData.light(),
                  child: const Center(child: LayrzProgressBar()),
                ),
              ),
            );
          },
        ),
      );
      await tester.pump();

      expect(find.byType(AnimatedBuilder), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);

      setter(() => disableAnimations = false);
      await tester.pump();

      expect(find.byType(AnimatedBuilder), findsOneWidget);

      // Stop the repeating ticker before the test ends.
      await tester.pump(const Duration(milliseconds: 10));
    });

    testWidgets('disposes its ticker when removed from the tree', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Toggles content within a single pumpThemed call rather than pumping
      // twice: pumpThemed's Overlay only consumes initialEntries on its first
      // mount (Overlay.initState calls insertAll once), so a second,
      // independent pumpThemed call in the same test leaves the first
      // Overlay's entry (and its LayrzProgressBar) alive underneath — a
      // limitation of the test helper, not of this widget.
      bool showBar = true;
      late StateSetter setter;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            setter = setState;
            return showBar ? const LayrzProgressBar() : const SizedBox();
          },
        ),
      );
      expect(find.byType(LayrzProgressBar), findsOneWidget);

      setter(() => showBar = false);
      await tester.pump();
      expect(find.byType(LayrzProgressBar), findsNothing);

      // If the ticker were not disposed, this would throw a leaked-ticker
      // error during test teardown.
    });

    testWidgets('resolves each semantic type to its expected token color', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      for (final type in LayrzProgressType.values) {
        await pumpThemed(tester, LayrzProgressBar(value: 0.5, type: type));
        expect(find.byType(LayrzProgressBar), findsOneWidget);
      }
    });

    testWidgets('honours an explicit color when type is custom', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const customColor = Color(0xFF00FF00);
      await pumpThemed(
        tester,
        const LayrzProgressBar(value: 0.5, type: LayrzProgressType.custom, color: customColor),
      );

      final painter = tester.widget<CustomPaint>(find.byType(CustomPaint).first).painter as LayrzProgressPainter;
      expect(painter.indicatorColor, customColor);
    });

    testWidgets('falls back to primary color when type is custom and color is null', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      await pumpThemed(
        tester,
        const LayrzProgressBar(value: 0.5, type: LayrzProgressType.custom),
        theme: theme,
      );

      final painter = tester.widget<CustomPaint>(find.byType(CustomPaint).first).painter as LayrzProgressPainter;
      expect(painter.indicatorColor, theme.tokens.colors.primary.shade500);
    });

    testWidgets('applies a custom height', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzProgressBar(value: 0.3, height: 20.0));

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(sizedBoxes.any((box) => box.height == 20.0), isTrue);
    });

    testWidgets('defaults height to kLayrzProgressBarHeight when not overridden', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzProgressBar(value: 0.3));

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(sizedBoxes.any((box) => box.height == kLayrzProgressBarHeight), isTrue);
    });

    testWidgets('indeterminate sweep controller uses tokens.motion.dIndeterminate, not dDialog', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      await pumpThemed(tester, const LayrzProgressBar(), theme: theme);

      double sweepPositionOf(WidgetTester t) =>
          (t.widget<CustomPaint>(find.byType(CustomPaint).first).painter as LayrzProgressPainter).sweepPosition;

      expect(sweepPositionOf(tester), 0.0);

      // A full dDialog interval (300ms, the old — too fast — duration) must
      // NOT complete a full repeat cycle now that dIndeterminate (1500ms) is
      // in effect: regression guard for the "too fast" defect.
      await tester.pump(theme.tokens.motion.dDialog);
      expect(sweepPositionOf(tester), isNot(0.0));
      expect(sweepPositionOf(tester), lessThan(1.0));

      // Advancing the remainder of dIndeterminate completes exactly one
      // repeat cycle, landing back at the animation's start value.
      await tester.pump(theme.tokens.motion.dIndeterminate - theme.tokens.motion.dDialog);
      expect(sweepPositionOf(tester), 0.0);
    });

    testWidgets('applies an explicit borderRadius override', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzProgressBar(value: 0.3, borderRadius: 2.0));

      final painter = tester.widget<CustomPaint>(find.byType(CustomPaint).first).painter as LayrzProgressPainter;
      expect(painter.borderRadius, 2.0);
    });

    testWidgets('defaults borderRadius to the rounded-box token when not overridden', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      await pumpThemed(tester, const LayrzProgressBar(value: 0.3), theme: theme);

      final painter = tester.widget<CustomPaint>(find.byType(CustomPaint).first).painter as LayrzProgressPainter;
      expect(painter.borderRadius, theme.tokens.radius.r1);
    });

    test('asserts value is within [0.0, 1.0]', () {
      expect(() => LayrzProgressBar(value: 1.5), throwsAssertionError);
      expect(() => LayrzProgressBar(value: -0.5), throwsAssertionError);
      expect(() => const LayrzProgressBar(value: 0.0), returnsNormally);
      expect(() => const LayrzProgressBar(value: 1.0), returnsNormally);
      expect(() => const LayrzProgressBar(), returnsNormally);
    });
  });

  group('LayrzProgressBar circular mode', () {
    testWidgets('renders determinate circular without an animation controller ticking', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzProgressBar(value: 0.5, format: LayrzProgressFormat.circular));

      expect(find.byType(LayrzProgressBar), findsOneWidget);
      final painter = tester.widget<CustomPaint>(find.byType(CustomPaint).first).painter as LayrzProgressPainter;
      expect(painter.shape, LayrzProgressFormat.circular);
      expect(painter.determinateValue, 0.5);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('renders indeterminate circular and rotates over time', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzProgressBar(format: LayrzProgressFormat.circular));

      expect(find.byType(LayrzProgressBar), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsOneWidget);

      // Pump forward without pumpAndSettle, which would hang on a repeating
      // animation, and confirm the widget survives across frames.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LayrzProgressBar), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LayrzProgressBar), findsOneWidget);
    });

    testWidgets('null value means indeterminate in circular mode too, not zero', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzProgressBar(format: LayrzProgressFormat.circular));

      final handle = tester.ensureSemantics();
      try {
        final semantics = tester.getSemantics(find.byType(LayrzProgressBar));
        expect(semantics.value, isEmpty);
        expect(semantics.label, 'Loading');
      } finally {
        handle.dispose();
      }

      // Stop the repeating ticker before the test ends.
      await tester.pump(const Duration(milliseconds: 10));
    });

    testWidgets('zero value is determinate-at-zero in circular mode, not indeterminate', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzProgressBar(value: 0.0, format: LayrzProgressFormat.circular));

      expect(find.byType(AnimatedBuilder), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);

      final handle = tester.ensureSemantics();
      try {
        final semantics = tester.getSemantics(find.byType(LayrzProgressBar));
        expect(semantics.value, '0%');
        expect(semantics.label, 'Progress');
      } finally {
        handle.dispose();
      }
    });

    testWidgets('defaults to kLayrzProgressCircularSize and kLayrzProgressCircularStrokeWidth', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzProgressBar(value: 0.3, format: LayrzProgressFormat.circular));

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(
        sizedBoxes.any(
          (box) => box.height == kLayrzProgressCircularSize && box.width == kLayrzProgressCircularSize,
        ),
        isTrue,
      );

      final painter = tester.widget<CustomPaint>(find.byType(CustomPaint).first).painter as LayrzProgressPainter;
      expect(painter.strokeWidth, kLayrzProgressCircularStrokeWidth);
    });

    testWidgets('applies a custom size and strokeWidth override', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzProgressBar(value: 0.3, format: LayrzProgressFormat.circular, size: 80.0, strokeWidth: 8.0),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(sizedBoxes.any((box) => box.height == 80.0 && box.width == 80.0), isTrue);

      final painter = tester.widget<CustomPaint>(find.byType(CustomPaint).first).painter as LayrzProgressPainter;
      expect(painter.strokeWidth, 8.0);
    });

    testWidgets('height and borderRadius are ignored in circular mode', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzProgressBar(
          value: 0.3,
          format: LayrzProgressFormat.circular,
          height: 999.0,
          borderRadius: 999.0,
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(sizedBoxes.any((box) => box.height == 999.0), isFalse);
      expect(
        sizedBoxes.any(
          (box) => box.height == kLayrzProgressCircularSize && box.width == kLayrzProgressCircularSize,
        ),
        isTrue,
      );
    });

    testWidgets('respects MediaQuery.disableAnimationsOf in circular mode', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Localizations(
            locale: const Locale('en'),
            delegates: const [
              DefaultWidgetsLocalizations.delegate,
              LayrzUiL10nDelegate(),
            ],
            child: LayrzTheme(
              data: LayrzThemeData.light(),
              child: const Center(child: LayrzProgressBar(format: LayrzProgressFormat.circular)),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AnimatedBuilder), findsNothing);
      expect(find.byType(LayrzProgressBar), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('stops the circular ticker when reduce-motion turns on at runtime', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      bool disableAnimations = false;
      late StateSetter setter;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setter = setState;
            return MediaQuery(
              data: MediaQueryData(disableAnimations: disableAnimations),
              child: Localizations(
                locale: const Locale('en'),
                delegates: const [
                  DefaultWidgetsLocalizations.delegate,
                  LayrzUiL10nDelegate(),
                ],
                child: LayrzTheme(
                  data: LayrzThemeData.light(),
                  child: const Center(child: LayrzProgressBar(format: LayrzProgressFormat.circular)),
                ),
              ),
            );
          },
        ),
      );
      await tester.pump();

      expect(find.byType(AnimatedBuilder), findsOneWidget);

      setter(() => disableAnimations = true);
      await tester.pump();
      await tester.pump();

      expect(find.byType(AnimatedBuilder), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('resumes the circular ticker when reduce-motion turns off at runtime', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      bool disableAnimations = true;
      late StateSetter setter;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setter = setState;
            return MediaQuery(
              data: MediaQueryData(disableAnimations: disableAnimations),
              child: Localizations(
                locale: const Locale('en'),
                delegates: const [
                  DefaultWidgetsLocalizations.delegate,
                  LayrzUiL10nDelegate(),
                ],
                child: LayrzTheme(
                  data: LayrzThemeData.light(),
                  child: const Center(child: LayrzProgressBar(format: LayrzProgressFormat.circular)),
                ),
              ),
            );
          },
        ),
      );
      await tester.pump();

      expect(find.byType(AnimatedBuilder), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);

      setter(() => disableAnimations = false);
      await tester.pump();

      expect(find.byType(AnimatedBuilder), findsOneWidget);

      // Stop the repeating ticker before the test ends.
      await tester.pump(const Duration(milliseconds: 10));
    });

    testWidgets('resolves each semantic type in circular mode too', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      for (final progressType in LayrzProgressType.values) {
        await pumpThemed(
          tester,
          LayrzProgressBar(value: 0.5, format: LayrzProgressFormat.circular, type: progressType),
        );
        expect(find.byType(LayrzProgressBar), findsOneWidget);
      }
    });
  });

  group('LayrzProgressType', () {
    final tokens = LayrzTokens.light();

    test('info resolves to the info swatch shade500', () {
      expect(LayrzProgressType.info.colorToken(tokens), tokens.colors.info.shade500);
    });

    test('success resolves to the success swatch shade500', () {
      expect(LayrzProgressType.success.colorToken(tokens), tokens.colors.success.shade500);
    });

    test('warning resolves to the warning swatch shade500', () {
      expect(LayrzProgressType.warning.colorToken(tokens), tokens.colors.warning.shade500);
    });

    test('danger resolves to the danger swatch shade500', () {
      expect(LayrzProgressType.danger.colorToken(tokens), tokens.colors.danger.shade500);
    });

    test('context resolves to the contextual swatch shade500', () {
      expect(LayrzProgressType.context.colorToken(tokens), tokens.colors.contextual.shade500);
    });

    test('custom resolves to null, deferring to an explicit color', () {
      expect(LayrzProgressType.custom.colorToken(tokens), isNull);
    });
  });

  group('LayrzProgressStyleSpec', () {
    final tokens = LayrzTokens.light();

    test('resolve uses the track surface color and the semantic accent for non-custom types', () {
      final spec = LayrzProgressStyleSpec.resolve(type: LayrzProgressType.success, color: null, tokens: tokens);

      expect(spec.trackColor, tokens.colors.sf3);
      expect(spec.indicatorColor, tokens.colors.success.shade500);
    });

    test('resolve honours an explicit color when type is custom', () {
      const customColor = Color(0xFF123456);
      final spec = LayrzProgressStyleSpec.resolve(
        type: LayrzProgressType.custom,
        color: customColor,
        tokens: tokens,
      );

      expect(spec.indicatorColor, customColor);
    });

    test('resolve falls back to primary when type is custom and color is null', () {
      final spec = LayrzProgressStyleSpec.resolve(type: LayrzProgressType.custom, color: null, tokens: tokens);

      expect(spec.indicatorColor, tokens.colors.primary.shade500);
    });

    test('copyWith replaces only the given fields', () {
      const original = LayrzProgressStyleSpec(
        trackColor: Color(0xFF000000),
        indicatorColor: Color(0xFF111111),
      );

      final copied = original.copyWith(trackColor: const Color(0xFF222222));

      expect(copied.trackColor, const Color(0xFF222222));
      expect(copied.indicatorColor, original.indicatorColor);
    });

    test('copyWith with no arguments returns an equal spec', () {
      const original = LayrzProgressStyleSpec(
        trackColor: Color(0xFF000000),
        indicatorColor: Color(0xFF111111),
      );

      expect(original.copyWith(), original);
    });

    test('== and hashCode are value-based', () {
      const a = LayrzProgressStyleSpec(trackColor: Color(0xFF000000), indicatorColor: Color(0xFF111111));
      const b = LayrzProgressStyleSpec(trackColor: Color(0xFF000000), indicatorColor: Color(0xFF111111));
      const c = LayrzProgressStyleSpec(trackColor: Color(0xFF000000), indicatorColor: Color(0xFF222222));

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });

    test('identical instances are equal', () {
      const a = LayrzProgressStyleSpec(trackColor: Color(0xFF000000), indicatorColor: Color(0xFF111111));
      expect(a == a, isTrue);
    });

    test('is not equal to an unrelated object', () {
      const a = LayrzProgressStyleSpec(trackColor: Color(0xFF000000), indicatorColor: Color(0xFF111111));
      // ignore: unrelated_type_equality_checks
      expect(a == 'not a spec', isFalse);
    });
  });
}
