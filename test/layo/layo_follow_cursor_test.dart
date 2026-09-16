import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Reads the live [LayoPainter.featureOffset] the mounted [Layo] is
/// currently painting with — the single source of truth for whether
/// [Layo.followCursor] is having any visible effect, now that the effect is
/// a pure feature translation inside [LayoPainter] rather than a
/// widget-level [Transform].
Offset _findFeatureOffset(WidgetTester tester) {
  final painter = tester.widget<CustomPaint>(find.byType(CustomPaint).first).painter;
  return (painter! as LayoPainter).featureOffset;
}

/// How long enough time must be pumped for `_LayoState`'s own private
/// gaze-easing controller to fully settle -- matches `_kGazeEaseDuration` in
/// `layo.dart` (not itself exported, so this test keeps its own copy). Used
/// together with a small leading pump (see the call sites) so the
/// controller's own first tick, started synchronously from inside a
/// [ValueNotifier] listener callback, lands before the full-duration pump
/// measures one complete span on the controller's own clock.
const Duration _kTestGazeEaseDuration = Duration(milliseconds: 220);

/// Runs [body] with [defaultTargetPlatform] overridden to a non-touch
/// (desktop) platform for the duration of the call, resetting the override
/// in a `finally` block -- not `addTearDown`, since
/// [TestWidgetsFlutterBinding]'s own invariant check runs before
/// `addTearDown` callbacks fire, so a leaked override fails the binding's
/// own assertion rather than the test's. [Layo.followCursor] is gated off
/// entirely on a touch platform (see [LayrzPlatform.isTouchOS]), and the
/// Flutter test binding's own default target platform is
/// [TargetPlatform.android] -- a touch platform -- so every test exercising
/// the desktop/mouse path must force a non-touch override explicitly rather
/// than relying on the binding's default.
Future<void> _asDesktop(Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

/// Pumps [child] wrapped in a [LayoCursorScope] backed by a fresh
/// [ValueNotifier], simulating an app that opted into
/// `LayrzApp.enableLayoCursorTracking: true` -- without needing a full
/// [LayrzApp] in the tree. Returns the notifier so the test can drive it
/// directly, mirroring how `LayrzApp`'s own installed [MouseRegion] would.
Future<ValueNotifier<Offset?>> _pumpWithCursorScope(WidgetTester tester, Widget child) async {
  final notifier = ValueNotifier<Offset?>(null);
  addTearDown(notifier.dispose);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: LayoCursorScope(
        notifier: notifier,
        child: Center(child: child),
      ),
    ),
  );
  return notifier;
}

void main() {
  group('Layo.followCursor', () {
    guardedTestWidgets('defaults to false: zero featureOffset and no LayoCursorScope dependency', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _asDesktop(() async {
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Layo(width: 200)),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(_findFeatureOffset(tester), Offset.zero);
      });
    });

    guardedTestWidgets('defaults to false on an unsupported emotion too: renders unchanged with zero featureOffset', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _asDesktop(() async {
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Layo(width: 200, emotion: LayoEmotion.love)),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Layo), findsOneWidget);
        expect(_findFeatureOffset(tester), Offset.zero);
      });
    });

    guardedTestWidgets('followCursor: true on an unsupported emotion fails the constructor assertion', (
      tester,
    ) async {
      expect(
        () => Layo(followCursor: true, emotion: LayoEmotion.love),
        throwsAssertionError,
      );
    });

    guardedTestWidgets('followCursor: true swapped to an unsupported emotion at runtime fails the update assertion', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _asDesktop(() async {
        await _pumpWithCursorScope(tester, const Layo(width: 200, followCursor: true));
        expect(tester.takeException(), isNull);

        // Constructing the replacement `Layo(followCursor: true, emotion:
        // LayoEmotion.love)` itself re-runs the constructor's own assert (it
        // fires as soon as the object is built, before `pumpWidget` -- and
        // therefore before `didUpdateWidget` -- ever runs), so
        // `expect(..., throwsAssertionError)` must wrap the construction
        // itself rather than the `pumpWidget` call.
        expect(
          () => Layo(width: 200, followCursor: true, emotion: LayoEmotion.love),
          throwsAssertionError,
        );
      });
    });

    guardedTestWidgets('touch platform: no tracking is attached even with followCursor: true and a scope present', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // No _asDesktop override here -- the Flutter test binding's own
      // default target platform is TargetPlatform.android, a touch
      // platform, so this test exercises that path by simply not
      // overriding it.
      expect(LayrzPlatform.isTouchOS, isTrue, reason: 'sanity check: the default test platform must be touch-OS');

      final notifier = await _pumpWithCursorScope(tester, const Layo(width: 200, followCursor: true));
      expect(tester.takeException(), isNull);

      notifier.value = const Offset(9999, 9999);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(_kTestGazeEaseDuration);

      expect(
        _findFeatureOffset(tester),
        Offset.zero,
        reason:
            'LayrzPlatform.isTouchOS gates tracking off entirely -- there is no pointer to follow on '
            'Android/iOS, so the features must stay neutral regardless of what the notifier reports',
      );
    });

    guardedTestWidgets(
      'debug-assert fallback: followCursor true with NO LayoCursorScope above fires a debug assert, never a throw '
      'the app sees',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _asDesktop(() async {
          await tester.pumpWidget(
            const Directionality(
              textDirection: TextDirection.ltr,
              child: Center(child: Layo(width: 200, followCursor: true)),
            ),
          );

          // `didChangeDependencies` runs during the pump above (no
          // `LayoCursorScope` ancestor exists in this tree), so the
          // missing-scope `assert` fires synchronously within that same
          // pump. It surfaces here as a captured exception -- an `assert`
          // failure the test binding reports through
          // `WidgetTester.takeException`, never an exception the pump call
          // itself throws -- which is exactly the "loud in debug, no thrown
          // exception" contract `Layo.followCursor`'s doc comment
          // describes: in debug mode the mistake is surfaced clearly for a
          // developer to see and fix, but nothing propagates as an
          // uncaught runtime error the app itself would crash on.
          final exception = tester.takeException();
          expect(exception, isA<AssertionError>());
          expect((exception as AssertionError).message, contains('enableLayoCursorTracking'));
        });
      },
    );

    guardedTestWidgets('followCursor: false with no LayoCursorScope never trips the missing-scope assert', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _asDesktop(() async {
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Layo(width: 200)),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(_findFeatureOffset(tester), Offset.zero);
      });
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.angry, LayoEmotion.question]) {
      guardedTestWidgets('followCursor: true on $emotion with a scope present: zero featureOffset at rest', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _asDesktop(() async {
          await _pumpWithCursorScope(tester, Layo(width: 200, emotion: emotion, followCursor: true));

          expect(tester.takeException(), isNull);
          expect(
            _findFeatureOffset(tester),
            Offset.zero,
            reason: 'the features must rest at neutral before any cursor position is ever reported',
          );
        });
      });

      guardedTestWidgets(
        'followCursor: true on $emotion eases the features toward the global cursor, then back to zero when null',
        (tester) async {
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await _asDesktop(() async {
            final notifier = await _pumpWithCursorScope(
              tester,
              Layo(width: 200, emotion: emotion, followCursor: true),
            );

            final layoBox = tester.getRect(find.byType(Layo));
            // A point well to the right of the Layo's own center, in GLOBAL
            // coordinates -- matching what a real MouseRegion.onHover would
            // report via PointerEvent.position.
            final target = Offset(layoBox.center.dx + layoBox.width, layoBox.center.dy);

            notifier.value = target;
            // A tiny settling pump first, THEN the full ease duration: the
            // easing AnimationController is started synchronously from
            // inside the notifier's listener callback, so its ticker's very
            // first tick only covers the remainder of the frame already in
            // flight.
            await tester.pump(const Duration(milliseconds: 10));
            await tester.pump(_kTestGazeEaseDuration);

            final movedOffset = _findFeatureOffset(tester);
            expect(
              movedOffset,
              isNot(Offset.zero),
              reason: 'the applied featureOffset must become non-zero once a cursor position is known',
            );
            expect(movedOffset.dx, greaterThan(0.0), reason: 'a cursor to the right must shift the features right');

            // The gaze direction is clamped to [-1, 1] per axis, and the
            // painter scales that by a fixed maximum fraction of the dark
            // screen window's own extent -- so the offset can never exceed
            // that bound regardless of how far off-screen the cursor moves.
            const maxShiftX = 0.03 * (317.04 - 78.45);
            const maxShiftY = 0.03 * (308.80 - 123.02);
            expect(movedOffset.dx.abs(), lessThanOrEqualTo(maxShiftX + 1e-9));
            expect(movedOffset.dy.abs(), lessThanOrEqualTo(maxShiftY + 1e-9));

            // Now report no cursor position at all (matching a real
            // MouseRegion's onExit) and let it ease back.
            notifier.value = null;
            await tester.pump(const Duration(milliseconds: 10));
            await tester.pump(_kTestGazeEaseDuration);

            expect(
              _findFeatureOffset(tester),
              Offset.zero,
              reason: 'the features must ease back to zero once no cursor position is known',
            );
          });
        },
      );

      guardedTestWidgets('followCursor: true on $emotion clamps an extreme cursor position to the max shift', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _asDesktop(() async {
          final notifier = await _pumpWithCursorScope(
            tester,
            Layo(width: 200, emotion: emotion, followCursor: true),
          );

          // Far beyond the Layo's own bounds in every direction -- the
          // clamp must still hold the offset to the fixed maximum.
          notifier.value = const Offset(1000000, 1000000);
          await tester.pump(const Duration(milliseconds: 10));
          await tester.pump(_kTestGazeEaseDuration);

          const maxShiftX = 0.03 * (317.04 - 78.45);
          const maxShiftY = 0.03 * (308.80 - 123.02);
          final offset = _findFeatureOffset(tester);
          expect(offset.dx, closeTo(maxShiftX, 1e-6));
          expect(offset.dy, closeTo(maxShiftY, 1e-6));
        });
      });
    }
  });
}
