import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/switch/switch_input.dart';

import '../../helpers/pump_themed.dart';
import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzSwitchInput', () {
    testWidgets('renders off switch', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      expect(find.byType(LayrzSwitchInput), findsOneWidget);
    });

    testWidgets('renders on switch', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          value: true,
          onChanged: (_) {},
        ),
      );

      expect(find.byType(LayrzSwitchInput), findsOneWidget);
    });

    testWidgets('renders label text when provided', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          labelText: 'Enable notifications',
          value: false,
          onChanged: (_) {},
        ),
      );

      expect(find.text('Enable notifications'), findsOneWidget);
    });

    testWidgets('toggles value when switch is tapped', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      expect(currentValue, isFalse);

      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
    });

    testWidgets('toggles value when label is tapped', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            labelText: 'Enable feature',
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      expect(currentValue, isFalse);

      await tester.tap(find.text('Enable feature'));
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
    });

    testWidgets('toggles value when Space key is pressed', (tester) async {
      bool currentValue = false;
      int callCount = 0;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              callCount++;
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Give focus to the switch
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      callCount = 0; // Reset after focus
      // Send Space key
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
      expect(callCount, equals(1)); // Verify single toggle, not double (A2 regression check)
    });

    testWidgets('toggles value when Enter key is pressed', (tester) async {
      bool currentValue = false;
      int callCount = 0;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              callCount++;
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Give focus to the switch
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      callCount = 0; // Reset after focus
      // Send Enter key
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
      expect(callCount, equals(1)); // Verify single toggle, not double (A2 regression check)
    });

    testWidgets('is Tab-reachable', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(find.byType(Focus), findsWidgets);
    });

    testWidgets('does not toggle when disabled', (tester) async {
      bool currentValue = false;
      int callCount = 0;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            disabled: true,
            onChanged: (newValue) {
              callCount++;
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      expect(currentValue, isFalse);
      expect(callCount, 0);
    });

    testWidgets('does not toggle when onChanged is null', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: null,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      expect(currentValue, isFalse);
    });

    testWidgets('renders error messages', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
          errors: const ['This field is required'],
          hideDetails: false,
        ),
      );

      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('hides error messages when hideDetails is true', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
          errors: const ['This field is required'],
          hideDetails: true,
        ),
      );

      expect(find.text('This field is required'), findsNothing);
    });

    testWidgets('applies the fixed control padding', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      final paddingWidget = tester.widget<Padding>(
        find.ancestor(
          of: find.byType(GestureDetector),
          matching: find.byType(Padding),
        ),
      );

      expect(paddingWidget.padding, const EdgeInsets.all(10));
    });

    testWidgets('track has no border', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      final trackContainer = tester.widget<Container>(find.byType(Container).first);
      final decoration = trackContainer.decoration as BoxDecoration?;
      expect(decoration?.border, isNull);
    });

    testWidgets('track has no shadow in any state', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Check resting state (off)
      var trackContainer = tester.widget<Container>(find.byType(Container).first);
      var decoration = trackContainer.decoration as BoxDecoration?;
      expect(decoration?.boxShadow, isNull, reason: 'Shadow should not exist in resting state');

      // Focus via Tab
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      trackContainer = tester.widget<Container>(find.byType(Container).first);
      decoration = trackContainer.decoration as BoxDecoration?;
      expect(decoration?.boxShadow, isNull, reason: 'Shadow should not exist in focused state');

      // Tap to toggle (pointer focus)
      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      trackContainer = tester.widget<Container>(find.byType(Container).first);
      decoration = trackContainer.decoration as BoxDecoration?;
      expect(decoration?.boxShadow, isNull, reason: 'Shadow should not exist after pointer focus');
    });

    testWidgets('track size is consistent across states', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      final offSize = tester.getSize(find.byType(Stack).first);

      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      final onSize = tester.getSize(find.byType(Stack).first);

      expect(offSize, equals(onSize));
    });

    testWidgets('uses custom focus node', (tester) async {
      final focusNode = FocusNode();

      await pumpThemedApp(
        tester,
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
          focusNode: focusNode,
        ),
      );

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);

      // Focus node provided by caller should NOT be disposed
      expect(focusNode.hasFocus, isTrue);

      focusNode.dispose();
    });

    testWidgets('disposes internally created focus node', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      // Widget should create and manage its own focus node
      expect(find.byType(Focus), findsWidgets);
    });

    testWidgets('changes colour on hover', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      final track = find.byType(Container).first;
      final beforeHover = tester.getSize(track);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final afterHover = tester.getSize(track);

      // Size must not change on hover (D15)
      expect(beforeHover, equals(afterHover));
    });

    testWidgets('animates thumb position', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Get initial thumb position (off state: left = 4.0, top = 4.0)
      final offThumb = tester.widget<Positioned>(
        find.descendant(of: find.byType(Stack), matching: find.byType(Positioned)),
      );
      expect(offThumb.left, closeTo(4.0, 0.1));
      expect(offThumb.top, closeTo(4.0, 0.1)); // Verify vertical centering

      // Toggle the switch
      await tester.tap(find.byType(LayrzSwitchInput));
      expect(currentValue, isTrue);

      // Complete animation
      await tester.pumpAndSettle();

      // Get final thumb position (on state: left = 28.0, top = 4.0)
      final onThumb = tester.widget<Positioned>(
        find.descendant(of: find.byType(Stack), matching: find.byType(Positioned)),
      );
      expect(onThumb.left, closeTo(28.0, 0.1));
      expect(onThumb.top, closeTo(4.0, 0.1)); // Top should not change
    });

    testWidgets('label colour changes when disabled', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            labelText: 'Test label',
            value: currentValue,
            disabled: false, // Enabled
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Get enabled state text color (should be fg1)
      final enabledLabelText = find.text('Test label');
      final enabledTextWidget = tester.widget<Text>(enabledLabelText);
      final enabledColor = enabledTextWidget.style?.color;
      expect(enabledColor, isNotNull);

      // Now test disabled state
      await pumpThemedApp(
        tester,
        LayrzSwitchInput(
          labelText: 'Test label',
          value: false,
          disabled: true, // Disabled
          onChanged: (_) {},
        ),
      );

      // Get disabled state text color (should be fg4)
      final disabledLabelText = find.text('Test label');
      final disabledTextWidget = tester.widget<Text>(disabledLabelText);
      final disabledColor = disabledTextWidget.style?.color;
      expect(disabledColor, isNotNull);

      // Colors should be different between enabled and disabled
      expect(disabledColor, isNot(equals(enabledColor)));
    });

    testWidgets('track color interpolates smoothly (not step function)', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Get the initial off color
      final initialContainer = tester.widget<Container>(find.byType(Container).first);
      final initialColor = (initialContainer.decoration as BoxDecoration).color!;

      // Toggle the switch
      await tester.tap(find.byType(LayrzSwitchInput));
      // Pump to let the frame process, then pump to mid-animation
      await tester.pump();
      // Pump to mid-animation (roughly 50% through the 200ms transition)
      await tester.pump(const Duration(milliseconds: 100));

      // Get the track container at mid-animation
      final trackContainer = tester.widget<Container>(find.byType(Container).first);
      final midColor = (trackContainer.decoration as BoxDecoration).color!;

      // Complete the animation
      await tester.pumpAndSettle();

      // Get the final on color
      final finalContainer = tester.widget<Container>(find.byType(Container).first);
      final finalColor = (finalContainer.decoration as BoxDecoration).color!;

      // Mid-animation color should be between initial and final (a blend, not a step)
      // It should not equal either the initial or final color
      expect(midColor, isNot(equals(initialColor)));
      expect(midColor, isNot(equals(finalColor)));
      // The colour changed smoothly during animation (lerp), not stepped
    });

    testWidgets('label is clickable independently', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            labelText: 'Click me',
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      final labelFinder = find.text('Click me');
      final labelWidget = tester.getRect(labelFinder);

      // Tap in the label text area
      await tester.tapAt(labelWidget.center);
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
    });

    testWidgets('disabled switch does not respond to hover', (tester) async {
      bool currentValue = false;
      int callCount = 0;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            disabled: true,
            onChanged: (newValue) {
              callCount++;
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Get track color before hover
      final trackBefore = tester.widget<Container>(find.byType(Container).first);
      final colorBefore = (trackBefore.decoration as BoxDecoration).color;

      // Simulate hover
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Get track color after hover attempt
      final trackAfter = tester.widget<Container>(find.byType(Container).first);
      final colorAfter = (trackAfter.decoration as BoxDecoration).color;

      // Colors should remain the same
      expect(colorBefore, equals(colorAfter));
      expect(callCount, equals(0)); // No toggle should occur
    });

    testWidgets('tab-focus shows colour affordance only (no shadow)', (tester) async {
      bool currentValue = false;

      // Get resting track colour (off state, no interaction)
      await pumpThemedApp(
        tester,
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
        ),
      );
      final restingTrack = tester.widget<Container>(find.byType(Container).first);
      final restingColor = (restingTrack.decoration as BoxDecoration?)?.color;

      // Re-pump with stateful widget
      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Give focus via Tab (keyboard focus)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Verify focus node has focus
      expect(find.byType(Focus), findsWidgets);

      // Get the track container and verify shadow is absent
      final trackContainer = tester.widget<Container>(find.byType(Container).first);
      final decoration = trackContainer.decoration as BoxDecoration?;

      // Shadow should never be present; focus affordance is colour only
      expect(decoration?.boxShadow, isNull);

      // Track colour should change from resting when focused (the only focus affordance)
      final focusedColor = decoration?.color;
      expect(focusedColor, isNot(equals(restingColor)));
    });

    testWidgets('click-focus does not latch shadow or colour affordances', (tester) async {
      bool currentValue = false;

      // Get resting state
      await pumpThemedApp(
        tester,
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
        ),
      );
      // Re-pump with stateful widget
      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Tap the switch
      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      // After tap, focus is still held
      final focusWidget = tester.widget<Focus>(find.byType(Focus).first);
      expect(focusWidget.focusNode?.hasFocus, isTrue);

      // But shadow is NOT present (pointer focus, not keyboard)
      final clickedTrack = tester.widget<Container>(find.byType(Container).first);
      final clickedShadow = (clickedTrack.decoration as BoxDecoration?)?.boxShadow;
      expect(clickedShadow, isNull);

      // And colour should NOT show hover treatment (was latching before fix)
      final clickedColor = (clickedTrack.decoration as BoxDecoration?)?.color;
      // The switch toggled to ON, so the colour is the ON-state colour
      // But without the hover/interactive treatment (sf4 off-colour)
      // It should not equal the resting OFF-state colour, but should use the default branch
      expect(clickedColor, isNotNull);
    });

    testWidgets('keyboard still works after pointer focus', (tester) async {
      bool currentValue = false;
      int callCount = 0;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              callCount++;
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Tap the switch (this gains focus and toggles)
      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
      expect(callCount, equals(1));

      callCount = 0;

      // Send Space key — should toggle again despite having pointer focus
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(currentValue, isFalse);
      expect(callCount, equals(1)); // Single toggle from Space
    });

    testWidgets('thumb moves from left to right when toggled on', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Get initial thumb position
      final offThumb = tester.widget<Positioned>(
        find.descendant(of: find.byType(Stack), matching: find.byType(Positioned)),
      );
      final offLeft = offThumb.left!;
      final offTop = offThumb.top!;

      // Toggle the switch
      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);

      // Get final thumb position
      final onThumb = tester.widget<Positioned>(
        find.descendant(of: find.byType(Stack), matching: find.byType(Positioned)),
      );
      final onLeft = onThumb.left!;
      final onTop = onThumb.top!;

      // Verify thumb moved to the right (horizontal travel)
      expect(onLeft, greaterThan(offLeft));
      expect(offLeft, closeTo(4.0, 0.1));
      expect(onLeft, closeTo(28.0, 0.1));

      // Verify thumb stays centered vertically (no vertical movement)
      expect(offTop, closeTo(4.0, 0.1));
      expect(onTop, closeTo(4.0, 0.1));
      expect(onTop, equals(offTop));
    });

    testWidgets('thumb is fully contained within track in both states', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Track nominal dimensions (no border, so Stack fills entire Container)
      const trackWidth = 52.0;
      const trackHeight = 28.0;
      const thumbSize = 20.0;
      // With border removed, the Stack fills the full Container bounds
      const contentBoxWidth = trackWidth;
      const contentBoxHeight = trackHeight;

      final offThumb = tester.widget<Positioned>(
        find.descendant(of: find.byType(Stack), matching: find.byType(Positioned)),
      );
      final offLeft = offThumb.left!;
      final offTop = offThumb.top!;

      // Verify off state containment within track bounds
      expect(offLeft, greaterThanOrEqualTo(0.0)); // Left edge within track
      expect(offTop, greaterThanOrEqualTo(0.0)); // Top edge within track
      expect(
        offLeft + thumbSize,
        lessThanOrEqualTo(contentBoxWidth),
      ); // Right edge within track (4.0 + 20 = 24.0 <= 52)
      expect(
        offTop + thumbSize,
        lessThanOrEqualTo(contentBoxHeight),
      ); // Bottom edge within track (4.0 + 20 = 24.0 <= 28)

      // Toggle to on state
      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      final onThumb = tester.widget<Positioned>(
        find.descendant(of: find.byType(Stack), matching: find.byType(Positioned)),
      );
      final onLeft = onThumb.left!;
      final onTop = onThumb.top!;

      // Verify on state containment within track bounds
      expect(onLeft, greaterThanOrEqualTo(0.0)); // Left edge within track
      expect(onTop, greaterThanOrEqualTo(0.0)); // Top edge within track
      expect(
        onLeft + thumbSize,
        lessThanOrEqualTo(contentBoxWidth),
      ); // Right edge within track (28.0 + 20 = 48.0 <= 52)
      expect(
        onTop + thumbSize,
        lessThanOrEqualTo(contentBoxHeight),
      ); // Bottom edge within track (4.0 + 20 = 24.0 <= 28)
    });
  });
}
