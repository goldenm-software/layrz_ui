import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/find_button_label.dart';
import '../helpers/no_overflow.dart';

void main() {
  group('LayrzDialog.show slots', () {
    guardedTestWidgets('renders title, content and actions together', (tester) async {
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
                    title: const Text('My title'),
                    content: const Text('My content'),
                    actions: const [SizedBox(width: 10, height: 10, child: Text('OK'))],
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

      expect(find.text('My title'), findsOneWidget);
      expect(find.text('My content'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    // Regression test for a crash where opening a dialog whose `actions`
    // contained a real LayrzButton threw "LayoutBuilder does not support
    // returning intrinsic dimensions." The slot Column used to be wrapped in
    // an IntrinsicWidth, which must query intrinsic width across its whole
    // subtree -- and LayrzButton builds its content through a LayoutBuilder,
    // which refuses that query by design. Every prior test in this group used
    // bare widgets (Text/SizedBox) as actions, so a LayoutBuilder never
    // entered the subtree and none of them caught this. This test must use a
    // real LayrzButton (not a stand-in) to reproduce the crash and to prove
    // the fix -- verified by reverting the dialog.dart fix locally and
    // confirming this test fails with exactly that FlutterError before the
    // fix, and passes after it.
    guardedTestWidgets('opens without crashing when actions contain real LayrzButtons', (tester) async {
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzDialog.show<bool>(
                    context,
                    title: const Text('Confirm removal'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      LayrzButton.cancel(labelText: 'Cancel', onTap: () => Navigator.of(context).pop(false)),
                      LayrzButton.delete(labelText: 'Delete', onTap: () => Navigator.of(context).pop(true)),
                    ],
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
      expect(find.text('Confirm removal'), findsOneWidget);
      expect(findButtonLabel('Cancel'), findsOneWidget);
      expect(findButtonLabel('Delete'), findsOneWidget);
    });

    // Same crash class, but with the LayrzButton living in the `content`
    // slot instead of `actions` -- the IntrinsicWidth wrapped the whole slot
    // Column, so a LayrzButton anywhere inside title/content/actions could
    // trigger it, not only in the actions row.
    guardedTestWidgets('opens without crashing when content contains a real LayrzButton', (tester) async {
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
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Retry the operation?'),
                        LayrzButton.info(labelText: 'Learn more', onTap: () {}),
                      ],
                    ),
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
      expect(find.text('Retry the operation?'), findsOneWidget);
      expect(findButtonLabel('Learn more'), findsOneWidget);
    });

    guardedTestWidgets('renders only the slots that are supplied', (tester) async {
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzDialog.show<void>(context, content: const Text('Only content'));
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

      expect(find.text('Only content'), findsOneWidget);
    });

    guardedTestWidgets('renders the child escape hatch when supplied instead of slots', (tester) async {
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzDialog.show<void>(context, child: const Text('Custom child'));
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

      expect(find.text('Custom child'), findsOneWidget);
    });

    testWidgets('asserts when child is combined with title/content/actions', (tester) async {
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) {
                return Text(
                  (() {
                    try {
                      LayrzDialog.show<void>(
                        context,
                        title: const Text('Title'),
                        child: const Text('Child'),
                      );
                      return 'no-assert';
                    } on AssertionError {
                      return 'asserted';
                    }
                  })(),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('asserted'), findsOneWidget);
    });
  });

  group('LayrzDialog.show return value', () {
    testWidgets('resolves with the value passed to Navigator.pop', (tester) async {
      String? result;

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () async {
                  result = await LayrzDialog.show<String>(
                    context,
                    content: Builder(
                      builder: (innerContext) => GestureDetector(
                        onTap: () => Navigator.of(innerContext).pop('picked'),
                        child: const SizedBox(width: 50, height: 50, child: Text('Pick')),
                      ),
                    ),
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

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();

      expect(result, equals('picked'));
    });

    testWidgets('resolves with null when dismissed via the barrier', (tester) async {
      String? result = 'unset';

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () async {
                  result = await LayrzDialog.show<String>(
                    context,
                    content: const Text('Body'),
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

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });

  group('LayrzDialog.show sizing', () {
    guardedTestWidgets('long content scrolls internally instead of overflowing', (tester) async {
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
                    title: const Text('Long content'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(50, (i) => Text('Line $i')),
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

      // The guardedTestWidgets wrapper itself asserts no overflow occurred;
      // reaching this point with the dialog open proves scrolling absorbed
      // content that is much taller than maxHeight.
      expect(find.text('Long content'), findsOneWidget);
    });

    guardedTestWidgets('honors custom maxWidth and maxHeight', (tester) async {
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
                    content: const Text('Body'),
                    maxWidth: 200,
                    maxHeight: 150,
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

      final constrainedBox = tester
          .widgetList<ConstrainedBox>(find.byType(ConstrainedBox))
          .firstWhere(
            (box) => box.constraints.maxWidth == 200 && box.constraints.maxHeight == 150,
          );
      expect(constrainedBox, isNotNull);
    });
  });

  group('LayrzDialog.show navigator selection', () {
    guardedTestWidgets('useRootNavigator: true pushes on the root navigator', (tester) async {
      final rootObserverPops = <String>[];

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Navigator(
            onGenerateRoute: (settings) => PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (context, animation, secondaryAnimation) => Center(
                child: Builder(
                  builder: (innerContext) => GestureDetector(
                    onTap: () {
                      LayrzDialog.show<void>(
                        innerContext,
                        content: const Text('Root-navigated dialog'),
                        useRootNavigator: true,
                      );
                    },
                    child: const SizedBox(width: 100, height: 100, child: Text('Open')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Root-navigated dialog'), findsOneWidget);
      rootObserverPops.clear();
    });
  });
}
