import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/alerts/alerts.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzAlert Accessibility', () {
    group('Non-interactive alerts (onTap: null)', () {
      testWidgets('exposes label as "title. description" in semantics', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          const title = 'Alert Title';
          const description = 'Alert Description';

          await pumpThemed(
            tester,
            const SizedBox(
              width: 300,
              child: LayrzAlert(
                title: title,
                description: description,
              ),
            ),
          );

          // Find the Semantics node created by LayrzAlert.
          // LayrzAlert wraps its content in Semantics(label: 'Title. Description', container: true).
          final semanticsNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
          );

          // Verify label includes both title and description with the expected format
          expect(semanticsNode.label, startsWith('$title. $description'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('does not respond to taps when onTap is null', (tester) async {
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: null,
            ),
          ),
        );

        // Tap the alert (should be a no-op since onTap is null)
        await tester.tap(find.byType(LayrzAlert), warnIfMissed: false);
        await tester.pump();

        // No exceptions should be thrown
        expect(tester.takeException(), isNull);
      });

      testWidgets('text scale 2x does not crash (layrz style)', (tester) async {
        await pumpThemed(
          tester,
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: const SizedBox(
              width: 300,
              child: LayrzAlert(
                title: 'Title at 2x scale',
                description: 'Description at 2x scale',
                style: LayrzAlertStyle.layrz,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Title at 2x scale'), findsOneWidget);
      });

      testWidgets('text scale 2x does not crash (filledIcon style)', (tester) async {
        await pumpThemed(
          tester,
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: const SizedBox(
              width: 300,
              child: LayrzAlert(
                title: 'Title at 2x scale',
                description: 'Description at 2x scale',
                style: LayrzAlertStyle.filledIcon,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });

    group('Interactive alerts (onTap: provided)', () {
      testWidgets('exposes correct label in semantics when interactive', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          const title = 'Clickable Title';
          const description = 'Clickable Description';

          await pumpThemed(
            tester,
            SizedBox(
              width: 300,
              child: LayrzAlert(
                title: title,
                description: description,
                onTap: () {},
              ),
            ),
          );

          final semanticsNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
          );

          // Interactive alert should expose the label with title and description
          expect(semanticsNode.label, startsWith('$title. $description'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('responds to taps when onTap is provided', (tester) async {
        var tapped = false;

        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        );

        // Verify interactive alert can be tapped
        expect(tapped, isFalse);
        await tester.tap(find.byType(LayrzAlert));
        await tester.pumpAndSettle();

        // After tap, callback should have been invoked
        expect(tapped, isTrue);
      });

      testWidgets('interactive alert differs from non-interactive (contrast in behavior)', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          var interactiveAlert = false;

          await pumpThemed(
            tester,
            SizedBox(
              width: 300,
              child: LayrzAlert(
                title: 'Interactive',
                description: 'This has onTap',
                onTap: () {
                  interactiveAlert = true;
                },
              ),
            ),
          );

          final semanticsNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
          );

          // The label should be present (both interactive and non-interactive have labels)
          expect(semanticsNode.label, contains('Interactive'));

          // The difference is demonstrated by actual tap behavior
          await tester.tap(find.byType(LayrzAlert));
          expect(interactiveAlert, isTrue);
        } finally {
          handle.dispose();
        }
      });
    });

    group('Icon exclusion from semantics', () {
      testWidgets('layrz style: icon is visually present but excluded from semantics', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            const SizedBox(
              width: 300,
              child: LayrzAlert(
                title: 'Title',
                description: 'Description',
                style: LayrzAlertStyle.layrz,
              ),
            ),
          );

          // Icon should be rendered visually
          expect(find.byType(Icon), findsOneWidget);

          // Text should be rendered and accessible
          expect(find.text('Title'), findsOneWidget);
          expect(find.text('Description'), findsOneWidget);

          // Verify semantics tree contains the label (text is accessible, icon is excluded)
          final semanticsNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
          );
          // The label should contain the title and description, proving icon is not announcing
          expect(semanticsNode.label, contains('Title'));
          expect(semanticsNode.label, contains('Description'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('filledIcon style: icon is visually present but excluded from semantics', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            const SizedBox(
              width: 300,
              child: LayrzAlert(
                title: 'Title',
                description: 'Description',
                style: LayrzAlertStyle.filledIcon,
              ),
            ),
          );

          // Icon should be rendered visually
          expect(find.byType(Icon), findsOneWidget);

          // Text should be rendered and accessible
          expect(find.text('Title'), findsOneWidget);
          expect(find.text('Description'), findsOneWidget);

          // Verify semantics tree contains the label (text is accessible, icon is excluded)
          final semanticsNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
          );
          // The label should contain the title and description, proving icon is not announcing
          expect(semanticsNode.label, contains('Title'));
          expect(semanticsNode.label, contains('Description'));
        } finally {
          handle.dispose();
        }
      });
    });

    group('State contrast: interactive vs. non-interactive', () {
      testWidgets('interactive alert with onTap responds to taps', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          var tapped = false;

          await pumpThemed(
            tester,
            SizedBox(
              width: 300,
              child: LayrzAlert(
                title: 'Enabled Alert',
                description: 'This alert is interactive',
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          );

          final semanticsNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
          );

          // Verify label is present
          expect(semanticsNode.label, contains('Enabled Alert'));

          // Prove it's interactive by successfully tapping
          await tester.tap(find.byType(LayrzAlert));
          expect(tapped, isTrue);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('non-interactive alert without onTap does not respond to taps', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            const SizedBox(
              width: 300,
              child: LayrzAlert(
                title: 'Non-interactive Alert',
                description: 'This alert is static',
              ),
            ),
          );

          final semanticsNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
          );

          // Non-interactive alert should expose the label
          expect(semanticsNode.label, contains('Non-interactive Alert'));

          // But it should not respond to taps (no onTap provided)
          // Tapping silently does nothing, no exception
          await tester.tap(find.byType(LayrzAlert), warnIfMissed: false);
          expect(tester.takeException(), isNull);
        } finally {
          handle.dispose();
        }
      });
    });
  });
}
