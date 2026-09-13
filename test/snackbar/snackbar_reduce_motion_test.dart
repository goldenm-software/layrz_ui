import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';
import 'helpers/pump_messenger.dart';

void main() {
  /// Sets a wide desktop viewport so tests don't accidentally exercise the
  /// compact-only default 800×600 test surface (CLAUDE.md testing traps).
  void setWideViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Pumps past the entry slide+fade+scale animation (260ms, DESIGN-60
  /// §Motion) so a freshly-shown toast is fully settled. Mirrors the helper
  /// of the same name in `snackbar_messenger_test.dart`.
  Future<void> pumpPastEntry(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('LayrzSnackbarMessenger — reduce-motion (disableAnimations)', () {
    testWidgets(
      'under reduce-motion, the toast survives well past the instant an AnimationController would collapse to',
      (tester) async {
        setWideViewport(tester);
        final context = await _pumpMessengerWithReducedMotion(tester);

        LayrzSnackbarMessenger.of(context).show(
          const LayrzSnackbar(
            titleText: 'Saved',
            descriptionText: 'Your changes were saved successfully.',
            duration: Duration(seconds: 3),
          ),
        );
        await pumpPastEntry(tester);
        expect(find.text('Saved'), findsOneWidget);

        // An AnimationController under disableAnimations collapses to ~0
        // duration, so the old (buggy) behavior dismissed within about a
        // millisecond. Advancing well beyond that — but comfortably short of
        // the real 3s duration — must still find the toast present.
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          find.text('Saved'),
          findsOneWidget,
          reason:
              'reduce-motion must not shorten the configured duration — the toast must still be present '
              'well past the ~1ms an AnimationController would have collapsed to',
        );
      },
    );

    testWidgets('under reduce-motion, the toast auto-dismisses once the real duration elapses', (tester) async {
      setWideViewport(tester);
      final context = await _pumpMessengerWithReducedMotion(tester);

      LayrzSnackbarMessenger.of(context).show(
        const LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
          duration: Duration(seconds: 3),
        ),
      );
      await pumpPastEntry(tester);
      expect(find.text('Saved'), findsOneWidget);

      // pumpPastEntry already consumed 300ms; a margin past the remaining
      // 2.7s absorbs scheduling jitter, matching the sibling
      // controller-driven tests' own margin convention. Critically, this must
      // NOT fire at ~1ms (the old AnimationBehavior.normal collapse) — see
      // the preceding test for that instant-dismiss regression guard.
      await tester.pump(const Duration(milliseconds: 2800));
      await tester.pump();

      expect(
        find.text('Saved'),
        findsNothing,
        reason: 'the drain controller must still dismiss on schedule under reduce-motion',
      );
    });

    testWidgets('under reduce-motion, the progress bar DRAINS from 1.0 to 0.0 at the real duration speed', (
      tester,
    ) async {
      setWideViewport(tester);
      final context = await _pumpMessengerWithReducedMotion(tester);

      LayrzSnackbarMessenger.of(context).show(
        const LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
          duration: Duration(seconds: 3),
        ),
      );

      double readProgress() => tester.widget<LayrzSnackbarView>(find.byType(LayrzSnackbarView)).progress;

      // Read immediately after the very first frame — before any real time
      // has elapsed — so this assertion is independent of the entry
      // animation's own settle time.
      await tester.pump();
      expect(readProgress(), 1.0, reason: 'the hairline must start at full width under reduce-motion');

      // Halfway through the real 3s duration, progress must be roughly
      // halfway drained — not frozen at 1.0 (the old, now-reversed behavior)
      // and not instantly collapsed to ~0 (the bug AnimationBehavior.preserve
      // exists to prevent).
      await tester.pump(const Duration(milliseconds: 1500));
      final halfway = readProgress();
      expect(
        halfway,
        allOf(lessThan(1.0), greaterThan(0.0)),
        reason: 'under reduce-motion the hairline must actively drain, not stay frozen at 1.0',
      );
      expect(halfway, closeTo(0.5, 0.05), reason: 'at half the real duration the drain must be roughly half done');

      // Just short of the full duration, progress must have drained to
      // (near) empty — proving the visible speed matches the real duration,
      // not a collapsed ~5%-scaled one.
      await tester.pump(const Duration(milliseconds: 1400));
      final nearEnd = readProgress();
      expect(
        nearEnd,
        closeTo(0.0, 0.05),
        reason: 'just before the real duration elapses the drain must be near empty',
      );
    });

    testWidgets('under reduce-motion, hover-pause still holds the toast open past its duration', (tester) async {
      setWideViewport(tester);
      final context = await _pumpMessengerWithReducedMotion(tester);

      LayrzSnackbarMessenger.of(context).show(
        const LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
          duration: Duration(seconds: 3),
        ),
      );
      await pumpPastEntry(tester);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);

      await mouse.moveTo(tester.getCenter(find.text('Saved')));
      await tester.pump();

      // Advance well past the un-paused 3s duration — the drain controller's
      // pause (AnimationController.stop) must genuinely freeze in place
      // rather than merely delay.
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Saved'), findsOneWidget, reason: 'hover must pause the reduce-motion drain controller too');

      // Move away — the remaining duration should resume and eventually fire.
      await mouse.moveTo(const Offset(-100, -100));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3100));
      await tester.pump();

      expect(
        find.text('Saved'),
        findsNothing,
        reason: 'the drain controller must resume for the remaining duration and fire',
      );
    });

    testWidgets('a persistent snackbar (duration: null) never drains or auto-dismisses under reduce-motion', (
      tester,
    ) async {
      setWideViewport(tester);
      final context = await _pumpMessengerWithReducedMotion(tester);

      LayrzSnackbarMessenger.of(context).show(
        const LayrzSnackbar(
          titleText: 'Persistent',
          descriptionText: 'This stays until dismissed manually.',
          duration: null,
        ),
      );
      await pumpPastEntry(tester);

      expect(find.text('Persistent'), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
      expect(
        find.text('Persistent'),
        findsOneWidget,
        reason: 'a persistent snackbar must never auto-dismiss, reduce-motion or not',
      );
    });
  });

  group('LayrzSnackbarMessenger — normal motion still uses the AnimationController path', () {
    testWidgets('with disableAnimations: false, the toast still auto-dismisses via the drain controller', (
      tester,
    ) async {
      setWideViewport(tester);
      final context = await pumpMessenger(tester);

      LayrzSnackbarMessenger.of(context).show(
        const LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
          duration: Duration(seconds: 3),
        ),
      );
      await pumpPastEntry(tester);
      expect(find.text('Saved'), findsOneWidget);

      // The progress bar must be genuinely animating (not frozen at 1.0),
      // proving the normal path is unaffected by the reduce-motion change.
      double readProgress() => tester.widget<LayrzSnackbarView>(find.byType(LayrzSnackbarView)).progress;
      final firstProgress = readProgress();
      await tester.pump(const Duration(milliseconds: 800));
      final secondProgress = readProgress();
      expect(secondProgress, lessThan(firstProgress), reason: 'the controller-driven hairline must still drain');

      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();

      expect(find.text('Saved'), findsNothing, reason: 'normal motion must still auto-dismiss via the controller');
    });
  });
}

/// Pumps a [LayrzSnackbarMessenger] tree wrapped in a [MediaQuery] override
/// forcing `disableAnimations: true` — `LayrzSnackbarMessengerState.show`
/// reads this at the moment each snackbar is shown, so the override must be
/// a genuine ancestor of the messenger, not shadowed by a later [MediaQuery]
/// insertion between it and `show()`'s `context`.
///
/// Deliberately built directly on [pumpThemed] (the same tree [pumpMessenger]
/// itself wraps) rather than on [pumpMessenger] or [LayrzApp]: [LayrzApp]
/// installs its own root [MediaQuery] via [WidgetsApp] below wherever it is
/// pumped, which would shadow an outer override placed above it — so this
/// helper puts the override directly around the messenger tree instead,
/// where nothing sits between it and [LayrzSnackbarMessengerState.context].
Future<BuildContext> _pumpMessengerWithReducedMotion(WidgetTester tester) async {
  late BuildContext capturedContext;

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
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Center(
                  child: LayrzSnackbarMessenger(
                    child: Builder(
                      builder: (context) {
                        capturedContext = context;
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  return capturedContext;
}
