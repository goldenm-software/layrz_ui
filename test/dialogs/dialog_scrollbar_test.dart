import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

void main() {
  group('LayrzDialog content scrollbar', () {
    // Regression test for "The Scrollbar's ScrollController has no
    // ScrollPosition attached." Before the fix, dialog.dart wrapped `content`
    // in a bare LayrzScrollbar(child: SingleChildScrollView(...)) with no
    // controller on either widget, so the scrollbar fell back to
    // PrimaryScrollController -- which nothing in the dialog route attaches
    // a ScrollPosition to -- and RawScrollbar's assertion fired on the very
    // first frame the scrollbar tried to paint. This test pumps a dialog
    // whose content is tall enough to actually need scrolling and settles
    // the frame, which is exactly the point at which the assertion used to
    // throw. Verified by reverting the dialog.dart fix locally: this test
    // fails with exactly that AssertionError before the fix, and passes
    // after it.
    guardedTestWidgets('does not assert and exposes a valid ScrollPosition', (tester) async {
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzDialog.show<void>(
                    context,
                    title: const Text('Scrollable dialog'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(60, (i) => Text('Line $i')),
                    ),
                    maxHeight: 300,
                  );
                },
                child: const SizedBox(width: 100, height: 100, child: Text('Open')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final scrollable = tester.widget<Scrollable>(find.byType(Scrollable));
      expect(
        scrollable.controller,
        isNotNull,
        reason: 'the SingleChildScrollView must carry an explicit controller, not PrimaryScrollController',
      );
      expect(
        scrollable.controller!.hasClients,
        isTrue,
        reason: 'the controller must actually be attached to the Scrollable it was given to',
      );
      expect(
        scrollable.controller!.position,
        isA<ScrollPosition>(),
        reason: 'a valid ScrollPosition must be attached for the scrollbar to paint against',
      );

      final scrollbar = tester.widget<LayrzScrollbar>(find.byType(LayrzScrollbar));
      expect(
        scrollbar.controller,
        same(scrollable.controller),
        reason: 'LayrzScrollbar and the SingleChildScrollView must share the exact same controller instance',
      );

      // Actually drive a scroll gesture to prove the scrollbar's underlying
      // RawScrollbar can paint against this ScrollPosition without asserting.
      await tester.drag(find.text('Line 0'), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    guardedTestWidgets('short content that does not need scrolling still has a valid controller', (tester) async {
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzDialog.show<void>(context, content: const Text('Short body'));
                },
                child: const SizedBox(width: 100, height: 100, child: Text('Open')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final scrollable = tester.widget<Scrollable>(find.byType(Scrollable));
      expect(scrollable.controller, isNotNull);
      expect(scrollable.controller!.hasClients, isTrue);
    });
  });
}
