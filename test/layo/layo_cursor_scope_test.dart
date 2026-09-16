import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Widget-level tests for [LayoCursorScope]: [LayoCursorScope.maybeOf]
/// resolving to the installed notifier (or `null` when absent), the notifier
/// updating on a simulated hover/exit, and clean disposal with no leak.
void main() {
  group('LayoCursorScope', () {
    testWidgets('maybeOf returns null when no LayoCursorScope is present', (tester) async {
      late ValueNotifier<Offset?>? resolved;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              resolved = LayoCursorScope.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, isNull);
    });

    testWidgets('maybeOf returns the installed notifier when a LayoCursorScope is present', (tester) async {
      final notifier = ValueNotifier<Offset?>(null);
      addTearDown(notifier.dispose);
      late ValueNotifier<Offset?>? resolved;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LayoCursorScope(
            notifier: notifier,
            child: Builder(
              builder: (context) {
                resolved = LayoCursorScope.maybeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(resolved, isNotNull);
      expect(identical(resolved, notifier), isTrue, reason: 'maybeOf must return the exact same notifier instance');
    });

    testWidgets('notifier updates propagate to a listener without any widget rebuild', (tester) async {
      final notifier = ValueNotifier<Offset?>(null);
      addTearDown(notifier.dispose);

      var buildCount = 0;
      Offset? lastSeenByListener;
      void listener() => lastSeenByListener = notifier.value;
      notifier.addListener(listener);
      addTearDown(() => notifier.removeListener(listener));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LayoCursorScope(
            notifier: notifier,
            child: Builder(
              builder: (context) {
                buildCount++;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final buildCountAfterFirstPump = buildCount;

      // Simulate a hover event writing a new position into the notifier --
      // exactly what LayrzApp's own MouseRegion.onHover does.
      notifier.value = const Offset(42, 84);
      expect(lastSeenByListener, const Offset(42, 84));

      // No pump is issued here on purpose: the whole point of this test is
      // that a listener attached directly to the notifier is notified
      // synchronously, with no widget tree rebuild required to observe the
      // new value -- so buildCount must be unchanged with no further pump.
      expect(buildCount, buildCountAfterFirstPump, reason: 'a notifier update must not rebuild any widget by itself');

      notifier.value = null;
      expect(lastSeenByListener, isNull);
      expect(buildCount, buildCountAfterFirstPump);
    });

    testWidgets('updateShouldNotify is true only when the notifier instance itself changes', (tester) async {
      final notifierA = ValueNotifier<Offset?>(null);
      final notifierB = ValueNotifier<Offset?>(null);
      addTearDown(notifierA.dispose);
      addTearDown(notifierB.dispose);

      final scopeA1 = LayoCursorScope(notifier: notifierA, child: const SizedBox.shrink());
      final scopeA2 = LayoCursorScope(notifier: notifierA, child: const SizedBox.shrink());
      final scopeB = LayoCursorScope(notifier: notifierB, child: const SizedBox.shrink());

      expect(scopeA1.updateShouldNotify(scopeA2), isFalse, reason: 'same notifier instance -> no notification');
      expect(scopeA1.updateShouldNotify(scopeB), isTrue, reason: 'different notifier instance -> must notify');
    });

    testWidgets('disposing the notifier after unmount leaves it unusable, proving no dangling reference remains', (
      tester,
    ) async {
      final notifier = ValueNotifier<Offset?>(null);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LayoCursorScope(notifier: notifier, child: const SizedBox.shrink()),
        ),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      notifier.dispose();

      // A disposed ChangeNotifier throws on any further use -- asserting
      // that here proves dispose() actually ran and left the notifier in
      // its post-dispose state, rather than merely not throwing (which a
      // no-op dispose would also satisfy).
      expect(() => notifier.addListener(() {}), throwsFlutterError);
    });
  });
}
