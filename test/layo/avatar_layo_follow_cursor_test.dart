import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Reads the live [LayoPainter.featureOffset] the [AvatarLayo]'s inner
/// [Layo] is currently painting with — mirrors `_findFeatureOffset` in
/// `layo_follow_cursor_test.dart`, applied to the [CustomPaint] found inside
/// an [AvatarLayo] rather than a bare [Layo].
Offset _findFeatureOffset(WidgetTester tester) {
  final painter = tester.widget<CustomPaint>(find.byType(CustomPaint).first).painter;
  return (painter! as LayoPainter).featureOffset;
}

/// How long enough time must be pumped for the inner `Layo`'s own private
/// gaze-easing controller to fully settle -- matches `_kGazeEaseDuration` in
/// `layo.dart` (not itself exported, so this test keeps its own copy), used
/// together with a small leading pump so the controller's own first tick
/// (started synchronously inside a [ValueNotifier] listener callback) lands
/// before the full-duration pump measures one complete span on the
/// controller's own clock.
const Duration _kTestGazeEaseDuration = Duration(milliseconds: 220);

/// Runs [body] with [defaultTargetPlatform] overridden to a non-touch
/// (desktop) platform for the duration of the call, resetting the override
/// in a `finally` block -- not `addTearDown`, since
/// [TestWidgetsFlutterBinding]'s own invariant check runs before
/// `addTearDown` callbacks fire. Mirrors `_asDesktop` in
/// `layo_follow_cursor_test.dart`.
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
/// `LayrzApp.enableLayoCursorTracking: true` — mirrors `_pumpWithCursorScope`
/// in `layo_follow_cursor_test.dart`.
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
  group('AvatarLayo.followCursor', () {
    guardedTestWidgets('defaults to false: zero featureOffset, no LayoCursorScope dependency', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _asDesktop(() async {
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: AvatarLayo(width: 96)),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(_findFeatureOffset(tester), Offset.zero);
      });
    });

    guardedTestWidgets('followCursor: true on an unsupported emotion fails the constructor assertion', (
      tester,
    ) async {
      expect(
        () => AvatarLayo(followCursor: true, emotion: LayoEmotion.love),
        throwsAssertionError,
      );
    });

    guardedTestWidgets('debug-assert fallback: followCursor true with NO LayoCursorScope above fires a debug assert', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _asDesktop(() async {
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: AvatarLayo(width: 96, followCursor: true)),
          ),
        );

        // The inner Layo mounts as part of AvatarLayo's own subtree, so its
        // didChangeDependencies runs during this same pump -- the
        // missing-scope assert fires from that inner Layo, not from
        // AvatarLayo itself (AvatarLayo is a StatelessWidget with no
        // lifecycle hook of its own to run this check from).
        final exception = tester.takeException();
        expect(exception, isA<AssertionError>());
        expect((exception as AssertionError).message, contains('enableLayoCursorTracking'));
      });
    });

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
            child: Center(child: AvatarLayo(width: 96)),
          ),
        );

        expect(tester.takeException(), isNull);
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
          await _pumpWithCursorScope(tester, AvatarLayo(width: 96, emotion: emotion, followCursor: true));

          expect(tester.takeException(), isNull);
          expect(_findFeatureOffset(tester), Offset.zero);
        });
      });

      guardedTestWidgets('followCursor: true on $emotion produces a non-zero featureOffset toward the cursor', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _asDesktop(() async {
          final notifier = await _pumpWithCursorScope(
            tester,
            AvatarLayo(width: 96, emotion: emotion, followCursor: true),
          );

          final avatarBox = tester.getRect(find.byType(AvatarLayo));
          final target = Offset(avatarBox.center.dx + avatarBox.width, avatarBox.center.dy);

          notifier.value = target;
          await tester.pump(const Duration(milliseconds: 10));
          await tester.pump(_kTestGazeEaseDuration);

          final offset = _findFeatureOffset(tester);
          expect(offset, isNot(Offset.zero));
          expect(offset.dx, greaterThan(0.0));
        });
      });
    }
  });
}
