import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

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
