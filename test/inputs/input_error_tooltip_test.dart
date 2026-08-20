import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_font_handler.dart';
import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzTextInput error display on compact widths', () {
    /// Test that inline errors are hidden below sm breakpoint (< 960px).
    testWidgets('inline errors hidden when compact width (< 960px)', (WidgetTester tester) async {
      // Set viewport to compact width (xs band)
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);

      final controller = TextEditingController();
      const errors = ['Username contains invalid characters'];

      final widget = LayrzTextInput(
        labelText: 'Username',
        controller: controller,
        errors: errors,
      );

      await pumpThemedApp(tester, widget);

      // The inline error text should NOT be visible
      expect(find.text('Username contains invalid characters'), findsNothing);

      // The error icon should be visible (on the right of the field)
      expect(find.byIcon(MdiIcons.alertOutline), findsWidgets);
    });

    /// Test that inline errors are shown at md breakpoint and above (>= 960px).
    testWidgets('inline errors shown when not compact (>= 960px)', (WidgetTester tester) async {
      // Set viewport to desktop width (md band)
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 800);

      final controller = TextEditingController();
      const errors = ['Username contains invalid characters'];

      final widget = LayrzTextInput(
        labelText: 'Username',
        controller: controller,
        errors: errors,
      );

      await pumpThemedApp(tester, widget);

      // The inline error text SHOULD be visible at desktop width
      expect(find.text('Username contains invalid characters'), findsWidgets);
    });

    /// Test that tapping the error icon opens tooltip when compact.
    testWidgets('tapping error icon opens tooltip on compact width', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 800);

      final controller = TextEditingController();
      const errors = ['Invalid email format', 'Email already in use'];

      final widget = LayrzTextInput(
        labelText: 'Email',
        controller: controller,
        errors: errors,
      );

      await pumpThemedApp(
        tester,
        widget,
        theme: LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
        ),
      );

      // Tooltip should not be visible initially
      expect(find.text('Invalid email format'), findsNothing);
      expect(find.text('Email already in use'), findsNothing);

      // The error icon should be visible
      final iconFinder = find.byIcon(MdiIcons.alertOutline);
      expect(iconFinder, findsOneWidget);

      // Tap the error icon to open the tooltip
      await tester.tap(iconFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Both errors should now appear in the tooltip (joined with newlines)
      expect(find.text('Invalid email format\nEmail already in use'), findsOneWidget);
    });

    /// Test that tapping elsewhere closes the error tooltip.
    testWidgets('tapping elsewhere closes error tooltip on compact width', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 800);

      final controller = TextEditingController();
      const errors = ['This is an error'];

      final widget = LayrzTextInput(
        labelText: 'Username',
        controller: controller,
        errors: errors,
      );

      await pumpThemedApp(tester, widget);

      // Open tooltip
      await tester.tap(find.byIcon(MdiIcons.alertOutline));
      await tester.pumpAndSettle();

      expect(find.text('This is an error'), findsOneWidget);

      // Tap elsewhere (outside the tooltip and error icon) to close it
      await tester.tapAt(const Offset(100, 400));
      await tester.pumpAndSettle();

      // Tooltip should be closed
      expect(find.text('This is an error'), findsNothing);
    });

    /// Test that the input field can still be focused when error tooltip is shown.
    testWidgets('field can be focused when error icon has tooltip', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 800);

      final controller = TextEditingController();
      const errors = ['Error message'];

      final widget = LayrzTextInput(
        labelText: 'Username',
        controller: controller,
        errors: errors,
      );

      await pumpThemedApp(tester, widget);

      // Find the text input field itself (not the error icon)
      final inputFinder = find.byType(EditableText).first;

      // The field should be focusable
      await tester.tap(inputFinder);
      await tester.pumpAndSettle();

      // Field should now have focus (we can verify by typing)
      await tester.enterText(inputFinder, 'test');
      await tester.pumpAndSettle();

      expect(controller.text, equals('test'));
    });

    /// Test that character counter takes full width when errors are hidden.
    testWidgets('character counter full width when errors hidden on compact', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 800);

      final controller = TextEditingController();
      const errors = ['Error message'];

      final widget = LayrzTextInput(
        labelText: 'Username',
        controller: controller,
        errors: errors,
        maxLength: 30,
      );

      await pumpThemedApp(tester, widget);

      // Add some text
      await tester.enterText(find.byType(EditableText).first, 'test');
      await tester.pumpAndSettle();

      // Character counter should be visible on the right
      expect(find.text('4/30'), findsWidgets);

      // Inline error should not be visible
      expect(find.text('Error message'), findsNothing);
    });

    /// Regression test: error icon without tooltip at desktop width.
    testWidgets('error icon shown without tooltip at desktop width', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 800);

      final controller = TextEditingController();
      const errors = ['Username contains invalid characters'];

      final widget = LayrzTextInput(
        labelText: 'Username',
        controller: controller,
        errors: errors,
      );

      await pumpThemedApp(tester, widget);

      // Error icon should be visible
      expect(find.byIcon(MdiIcons.alertOutline), findsWidgets);

      // Inline error text should be visible
      expect(find.text('Username contains invalid characters'), findsWidgets);

      // Tapping the error icon should NOT open a tooltip (no tooltip in desktop mode)
      await tester.tap(find.byIcon(MdiIcons.alertOutline));
      await tester.pumpAndSettle();

      // The error text should still be visible as-is (not in a tooltip)
      expect(find.text('Username contains invalid characters'), findsWidgets);
    });
  });
}
