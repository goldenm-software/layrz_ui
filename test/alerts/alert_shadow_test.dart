import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_font_handler.dart';
import '../helpers/pump_themed.dart';

/// Helper to find the AnimatedContainer inside a LayrzAlert.
Finder _findAnimatedContainer() => find.descendant(
  of: find.byType(LayrzAlert),
  matching: find.byType(AnimatedContainer),
);

void main() {
  group('LayrzAlert Shadow Behavior', () {
    group('Inert alert (onTap: null)', () {
      testWidgets('inert alert has no shadow at rest', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: null,
            ),
          ),
          theme: themeData,
        );

        // Find the Container with the actual decoration (not the AnimatedContainer)
        final containers = find.byType(Container);
        for (final element in containers.evaluate()) {
          final container = element.widget as Container;
          if (container.decoration is BoxDecoration) {
            final decoration = container.decoration as BoxDecoration;
            expect(
              decoration.boxShadow,
              anyOf(isNull, isEmpty),
              reason: 'Inert alert must have no shadow at rest',
            );
          }
        }
      });

      testWidgets('inert alert has no shadow when hovered (if AnimatedContainer exists)', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: null,
            ),
          ),
          theme: themeData,
        );

        // Inert alerts don't have AnimatedContainer, so this is a structural check
        final animatedContainers = find.byType(AnimatedContainer);
        expect(
          animatedContainers,
          findsNothing,
          reason: 'Inert alerts should not have AnimatedContainer',
        );
      });
    });

    group('Interactive alert at rest (onTap non-null)', () {
      testWidgets('interactive alert at rest has no shadow', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: () {},
            ),
          ),
          theme: themeData,
        );

        await tester.pumpAndSettle();

        final container = tester.widget<AnimatedContainer>(_findAnimatedContainer());
        final decoration = container.decoration as BoxDecoration?;

        expect(
          decoration?.boxShadow,
          anyOf(isNull, isEmpty),
          reason: 'Interactive alert at rest must have no shadow',
        );
      });

      testWidgets('hovering produces elevation2 shadow', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: () {},
            ),
          ),
          theme: themeData,
        );

        await tester.pumpAndSettle();

        // Move mouse over the alert
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        await gesture.moveTo(tester.getCenter(find.byType(LayrzAlert)));
        await tester.pumpAndSettle();

        final container = tester.widget<AnimatedContainer>(_findAnimatedContainer());
        final decoration = container.decoration as BoxDecoration?;
        final resolvedShadow = themeData.tokens.shadow.elevation2;

        expect(
          decoration?.boxShadow,
          isNotEmpty,
          reason: 'Hovering must produce a shadow',
        );

        expect(
          decoration?.boxShadow,
          equals(resolvedShadow),
          reason: 'Hovering must produce elevation2 shadow',
        );
      });

      testWidgets('focus produces elevation2 shadow', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        await tester.pumpWidget(
          LayrzApp(
            theme: themeData,
            debugShowCheckedModeBanner: false,
            home: Center(
              child: SizedBox(
                width: 300,
                child: LayrzAlert(
                  title: 'Title',
                  description: 'Description',
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Focus via Tab key
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        final container = tester.widget<AnimatedContainer>(_findAnimatedContainer());
        final decoration = container.decoration as BoxDecoration?;
        final resolvedShadow = themeData.tokens.shadow.elevation2;

        expect(
          decoration?.boxShadow,
          isNotEmpty,
          reason: 'Focused alert must produce a shadow',
        );

        expect(
          decoration?.boxShadow,
          equals(resolvedShadow),
          reason: 'Focused alert must produce elevation2 shadow',
        );
      });

      testWidgets('pressing produces elevation1 shadow', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: () {},
            ),
          ),
          theme: themeData,
        );

        await tester.pumpAndSettle();

        // First, move mouse over to hover (which produces elevation2)
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await gesture.moveTo(tester.getCenter(find.byType(LayrzAlert)));
        await tester.pumpAndSettle();

        // Verify hovered state has elevation2
        var container = tester.widget<AnimatedContainer>(_findAnimatedContainer());
        var decoration = container.decoration as BoxDecoration?;
        expect(
          decoration?.boxShadow,
          equals(themeData.tokens.shadow.elevation2),
          reason: 'Hovered state must have elevation2 shadow',
        );

        // Now press (while hovered)
        final center = tester.getCenter(find.byType(LayrzAlert));
        final pressGesture = await tester.startGesture(center);
        await tester.pumpAndSettle();

        // Pressed should now have elevation1 (even while hovered)
        container = tester.widget<AnimatedContainer>(_findAnimatedContainer());
        decoration = container.decoration as BoxDecoration?;

        expect(
          decoration?.boxShadow,
          isNotEmpty,
          reason: 'Pressed alert must produce a shadow',
        );

        expect(
          decoration?.boxShadow,
          equals(themeData.tokens.shadow.elevation1),
          reason: 'Pressed alert must produce elevation1 shadow',
        );

        await pressGesture.up();
      });

      testWidgets('shadow animates during hover transition', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: () {},
            ),
          ),
          theme: themeData,
        );

        await tester.pumpAndSettle();

        // Verify AnimatedContainer has correct animation settings
        final container = tester.widget<AnimatedContainer>(_findAnimatedContainer());
        expect(
          container.duration,
          equals(themeData.tokens.motion.dHover),
          reason: 'Shadow animation must use dHover duration',
        );

        expect(
          container.curve,
          equals(themeData.tokens.motion.easingEnter),
          reason: 'Shadow animation must use easingEnter curve',
        );
      });
    });

    group('All styles support shadow on hover', () {
      for (final style in LayrzAlertStyle.values) {
        testWidgets('$style style shows shadow on hover', (tester) async {
          final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
          await pumpThemed(
            tester,
            SizedBox(
              width: 300,
              child: LayrzAlert(
                title: 'Title',
                description: 'Description',
                style: style,
                onTap: () {},
              ),
            ),
            theme: themeData,
          );

          await tester.pumpAndSettle();

          // Move mouse over the alert
          final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
          await gesture.addPointer(location: Offset.zero);
          addTearDown(gesture.removePointer);
          await tester.pump();

          await gesture.moveTo(tester.getCenter(find.byType(LayrzAlert)));
          await tester.pumpAndSettle();

          final container = tester.widget<AnimatedContainer>(_findAnimatedContainer());
          final decoration = container.decoration as BoxDecoration?;

          expect(
            decoration?.boxShadow,
            isNotEmpty,
            reason: '$style style must show shadow on hover',
          );
        });
      }
    });

    group('filledIcon style shadow visibility (ClipRRect test)', () {
      testWidgets('filledIcon style shadow is not clipped by inner ClipRRect', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              style: LayrzAlertStyle.filledIcon,
              onTap: () {},
            ),
          ),
          theme: themeData,
        );

        await tester.pumpAndSettle();

        // Move mouse over to trigger shadow
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        await gesture.moveTo(tester.getCenter(find.byType(LayrzAlert)));
        await tester.pumpAndSettle();

        // Verify AnimatedContainer has shadow decoration
        final container = tester.widget<AnimatedContainer>(_findAnimatedContainer());
        final decoration = container.decoration as BoxDecoration?;

        expect(
          decoration?.boxShadow,
          isNotEmpty,
          reason: 'filledIcon style must show shadow even with ClipRRect child',
        );

        // Verify that ClipRRect is present as a child (structure check)
        final clipRRects = find.descendant(
          of: find.byType(LayrzAlert),
          matching: find.byType(ClipRRect),
        );
        expect(
          clipRRects,
          findsOneWidget,
          reason: 'filledIcon style must have ClipRRect for two-panel layout',
        );
      });
    });

    group('Shadow state transitions', () {
      testWidgets('shadow transitions from none to elevation2 on hover', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: () {},
            ),
          ),
          theme: themeData,
        );

        await tester.pumpAndSettle();

        // Initial state: no shadow
        var container = tester.widget<AnimatedContainer>(_findAnimatedContainer());
        var decoration = container.decoration as BoxDecoration?;
        expect(
          decoration?.boxShadow,
          anyOf(isNull, isEmpty),
          reason: 'Initial state must have no shadow',
        );

        // Hover: elevation2 shadow
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await gesture.moveTo(tester.getCenter(find.byType(LayrzAlert)));
        await tester.pumpAndSettle();

        container = tester.widget<AnimatedContainer>(_findAnimatedContainer());
        decoration = container.decoration as BoxDecoration?;
        expect(
          decoration?.boxShadow,
          equals(themeData.tokens.shadow.elevation2),
          reason: 'Hovered state must have elevation2 shadow',
        );

        // Move away: back to no shadow
        await gesture.moveTo(const Offset(2000, 2000));
        await tester.pumpAndSettle();

        container = tester.widget<AnimatedContainer>(_findAnimatedContainer());
        decoration = container.decoration as BoxDecoration?;
        expect(
          decoration?.boxShadow,
          anyOf(isNull, isEmpty),
          reason: 'Back to rest: must have no shadow',
        );
      });

      testWidgets('shadow transitions from elevation2 (hover) to elevation1 (press)', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: () {},
            ),
          ),
          theme: themeData,
        );

        await tester.pumpAndSettle();

        // Hover
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await gesture.moveTo(tester.getCenter(find.byType(LayrzAlert)));
        await tester.pumpAndSettle();

        var container = tester.widget<AnimatedContainer>(_findAnimatedContainer());
        var decoration = container.decoration as BoxDecoration?;
        expect(decoration?.boxShadow, equals(themeData.tokens.shadow.elevation2));

        // Press while hovered
        final center = tester.getCenter(find.byType(LayrzAlert));
        final pressGesture = await tester.startGesture(center);
        await tester.pumpAndSettle();

        container = tester.widget<AnimatedContainer>(_findAnimatedContainer());
        decoration = container.decoration as BoxDecoration?;
        expect(
          decoration?.boxShadow,
          equals(themeData.tokens.shadow.elevation1),
          reason: 'Pressed (even while hovered) must have elevation1 shadow',
        );

        await pressGesture.up();
      });
    });
  });
}
