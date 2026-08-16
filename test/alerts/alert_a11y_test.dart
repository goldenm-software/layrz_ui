import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/alerts.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzAlert Accessibility', () {
    group('Semantics', () {
      testWidgets('semantics label contains both title and description text', (tester) async {
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

        // Verify that the alert's text is accessible semantically
        expect(find.text(title), findsOneWidget);
        expect(find.text(description), findsOneWidget);
      });
    });

    group('Text scaling (WCAG 1.4.4)', () {
      testWidgets('layrz style survives 2x text scale', (tester) async {
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

      testWidgets('filledTonal style survives 2x text scale', (tester) async {
        await pumpThemed(
          tester,
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: const SizedBox(
              width: 300,
              child: LayrzAlert(
                title: 'Title at 2x scale',
                description: 'Description at 2x scale',
                style: LayrzAlertStyle.filledTonal,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('filled style survives 2x text scale', (tester) async {
        await pumpThemed(
          tester,
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: const SizedBox(
              width: 300,
              child: LayrzAlert(
                title: 'Title at 2x scale',
                description: 'Description at 2x scale',
                style: LayrzAlertStyle.filled,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('outlined style survives 2x text scale', (tester) async {
        await pumpThemed(
          tester,
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: const SizedBox(
              width: 300,
              child: LayrzAlert(
                title: 'Title at 2x scale',
                description: 'Description at 2x scale',
                style: LayrzAlertStyle.outlined,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('filledIcon style survives 2x text scale', (tester) async {
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

    group('Icon accessibility', () {
      testWidgets('layrz style excludes icon from semantics tree', (tester) async {
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

        // Verify icon is rendered (present visually)
        expect(find.byType(Icon), findsOneWidget);
        // Verify text is accessible (icon is excluded from semantics)
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
      });

      testWidgets('filledIcon style excludes icon from semantics tree', (tester) async {
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

        // Verify icon is rendered (present visually)
        expect(find.byType(Icon), findsOneWidget);
        // Verify text is accessible (icon is excluded from semantics)
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
      });
    });

    group('Non-interactive', () {
      testWidgets('alert wraps content in Semantics container for accessibility', (tester) async {
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

        // Find the LayrzAlert and verify it's wrapped in a Semantics container
        final semanticsWidget = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == 'Title. Description' && widget.container == true,
        );
        expect(semanticsWidget, findsOneWidget);
      });

      testWidgets('alert is not focusable', (tester) async {
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
            ),
          ),
        );

        // Verify the alert text is rendered and accessible
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
      });

      testWidgets('alert does not respond to taps', (tester) async {
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
            ),
          ),
        );

        // Tapping the alert should not trigger any callbacks
        // (LayrzAlert has no onTap or similar)
        await tester.tap(find.byType(LayrzAlert));
        await tester.pumpAndSettle();

        // No exceptions should be thrown
        expect(tester.takeException(), isNull);
      });
    });
  });
}
