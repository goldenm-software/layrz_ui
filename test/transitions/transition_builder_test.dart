import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzTransitionBuilder', () {
    testWidgets('is assignable to PageRouteBuilder.transitionsBuilder', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        Localizations(
          locale: const Locale('en'),
          delegates: const [DefaultWidgetsLocalizations.delegate],
          child: Navigator(
            key: navigatorKey,
            onGenerateRoute: (settings) => PageRouteBuilder<void>(
              pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
              transitionsBuilder: LayrzPageTransitions.fade,
            ),
          ),
        ),
      );

      // The typedef-assignability itself is checked at compile time by
      // `transitionsBuilder: LayrzPageTransitions.fade` above -- a builder
      // with the wrong shape would fail to compile, not fail this
      // assertion. This confirms the route actually builds and renders.
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('every LayrzPageTransitions builder has the LayrzTransitionBuilder shape', (
      tester,
    ) async {
      const LayrzTransitionBuilder fade = LayrzPageTransitions.fade;
      const LayrzTransitionBuilder slide = LayrzPageTransitions.slide;
      const LayrzTransitionBuilder scale = LayrzPageTransitions.scale;
      const LayrzTransitionBuilder rotation = LayrzPageTransitions.rotation;
      const LayrzTransitionBuilder none = LayrzPageTransitions.none;

      expect(fade, isNotNull);
      expect(slide, isNotNull);
      expect(scale, isNotNull);
      expect(rotation, isNotNull);
      expect(none, isNotNull);
    });
  });
}
