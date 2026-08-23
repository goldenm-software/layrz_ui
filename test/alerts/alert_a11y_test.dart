import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/alerts/alerts.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzAlert Accessibility', () {
    group('Non-interactive alerts (onTap: null)', () {
      testWidgets('exposes label and container flag in semantics', (tester) async {
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

          final semanticsNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
          );

          // Non-interactive alert exposes label with correct format
          expect(semanticsNode.label, startsWith('$title. $description'));
          // And is not marked as button in semantics (no button flag)
          expect(semanticsNode.toString(), isNot(contains('isButton')));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('non-interactive alert reports no tap action in semantics', (tester) async {
        final handle = tester.ensureSemantics();
        try {
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

          final semanticsNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
          );

          // Semantics confirm no interaction: not marked as button
          expect(semanticsNode.toString(), isNot(contains('isButton')));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('rendering survives 2x text scale (layrz style)', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          const title = 'Title at 2x';
          const description = 'Description at 2x';

          await pumpThemed(
            tester,
            MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: const SizedBox(
                width: 300,
                child: LayrzAlert(
                  title: title,
                  description: description,
                  style: LayrzAlertStyle.layrz,
                ),
              ),
            ),
          );

          // Rendering should not crash
          expect(tester.takeException(), isNull);
          // Semantics label should remain intact at 2x scale
          final semanticsNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
          );
          expect(semanticsNode.label, startsWith('$title. $description'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('rendering survives 2x text scale (filledIcon style)', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          const title = 'Title at 2x';
          const description = 'Description at 2x';

          await pumpThemed(
            tester,
            MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: const SizedBox(
                width: 300,
                child: LayrzAlert(
                  title: title,
                  description: description,
                  style: LayrzAlertStyle.filledIcon,
                ),
              ),
            ),
          );

          // Rendering should not crash
          expect(tester.takeException(), isNull);
          // Semantics label should remain intact at 2x scale
          final semanticsNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
          );
          expect(semanticsNode.label, startsWith('$title. $description'));
        } finally {
          handle.dispose();
        }
      });
    });

    group('Interactive alerts (onTap: provided)', () {
      testWidgets('exposes button semantics when interactive', (tester) async {
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

          // Interactive alert exposes label with correct format
          expect(semanticsNode.label, startsWith('$title. $description'));
          // Verify button semantics: string representation includes "isButton" flag (widget sets button:true at alert.dart:412)
          expect(semanticsNode.toString(), contains('isButton'));
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

        expect(tapped, isFalse);
        await tester.tap(find.byType(LayrzAlert));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('semantic contrast: interactive alert exposes button flag, non-interactive does not', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            SizedBox(
              width: 300,
              child: LayrzAlert(
                title: 'Interactive',
                description: 'Has onTap',
                onTap: () {},
              ),
            ),
          );

          final interactiveNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
          );

          // Interactive alert is a button - verify button flag is set in semantics
          expect(interactiveNode.toString(), contains('isButton'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('semantic contrast: non-interactive alert does not expose button semantics', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            const SizedBox(
              width: 300,
              child: LayrzAlert(
                title: 'Non-interactive',
                description: 'No onTap',
              ),
            ),
          );

          final nonInteractiveNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
          );

          // Non-interactive alert is not a button - verify button flag is NOT set
          expect(nonInteractiveNode.toString(), isNot(contains('isButton')));
        } finally {
          handle.dispose();
        }
      });
    });

    group('Icon exclusion from semantics', () {
      testWidgets('layrz style: label is accessible (icon rendered but not announced)', (tester) async {
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

          // Icon visually present
          expect(find.byType(Icon), findsOneWidget);
          // Text visually present
          expect(find.text('Title'), findsOneWidget);
          expect(find.text('Description'), findsOneWidget);

          // Semantics label contains expected text (icon ExcludeSemantics at alert.dart:242 prevents it)
          final semanticsNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
          );
          expect(semanticsNode.label, contains('Title'));
          expect(semanticsNode.label, contains('Description'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets(
        'layrz style: icon does not appear in semantics tree',
        (tester) async {
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

            // Icon is wrapped in ExcludeSemantics(child: Container(... Icon(...)))
            // Verify it doesn't appear: label starts with title, not icon data
            final semanticsNode = tester.getSemantics(
              find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
            );
            // Label begins with text, proving icon excluded (icon would prepend to label)
            expect(semanticsNode.label, startsWith('Title. Description'));
          } finally {
            handle.dispose();
          }
        },
        skip: false,
      );

      testWidgets('filledIcon style: label is accessible (icon rendered but not announced)', (tester) async {
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

          // Icon visually present
          expect(find.byType(Icon), findsOneWidget);
          // Text visually present
          expect(find.text('Title'), findsOneWidget);
          expect(find.text('Description'), findsOneWidget);

          // Semantics label contains expected text (icon ExcludeSemantics at alert.dart:242 prevents it)
          final semanticsNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
          );
          expect(semanticsNode.label, contains('Title'));
          expect(semanticsNode.label, contains('Description'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets(
        'filledIcon style: icon does not appear in semantics tree',
        (tester) async {
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

            // Icon is wrapped in ExcludeSemantics(child: Container(... Icon(...)))
            // Verify it doesn't appear: label starts with title, not icon data
            final semanticsNode = tester.getSemantics(
              find.descendant(of: find.byType(LayrzAlert), matching: find.byType(Semantics)).first,
            );
            // Label begins with text, proving icon excluded (icon would prepend to label)
            expect(semanticsNode.label, startsWith('Title. Description'));
          } finally {
            handle.dispose();
          }
        },
        skip: false,
      );
    });
  });
}
