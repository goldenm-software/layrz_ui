import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzTextInput error display (always below field)', () {
    /// Test that errors are visible at compact width (< 960px).
    testWidgets('errors visible at compact width', (WidgetTester tester) async {
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

      // Errors should be visible below the field at compact width
      expect(find.text('Username contains invalid characters'), findsOneWidget);

      // The error icon should be visible (on the right of the field)
      expect(find.byIcon(MdiIcons.alertOutline), findsOneWidget);
    });

    /// Test that errors are visible at regular width (>= 960px).
    testWidgets('errors visible at regular width', (WidgetTester tester) async {
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

      // Errors should be visible below the field at regular width
      expect(find.text('Username contains invalid characters'), findsOneWidget);

      // The error icon should be visible
      expect(find.byIcon(MdiIcons.alertOutline), findsOneWidget);
    });

    /// Test that the error icon is not wrapped in a tooltip and tapping does nothing.
    testWidgets('error icon is plain, no tooltip on tap', (WidgetTester tester) async {
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
        theme: LayrzThemeData.light(),
      );

      // Both errors should be visible below the field
      expect(find.text('Invalid email format, Email already in use'), findsOneWidget);

      // The error icon should be visible
      final iconFinder = find.byIcon(MdiIcons.alertOutline);
      expect(iconFinder, findsOneWidget);

      // Tap the error icon — it should not open a tooltip
      await tester.tap(iconFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Errors should still be visible in their original position below the field
      expect(find.text('Invalid email format, Email already in use'), findsOneWidget);
    });

    /// Test that hideDetails still suppresses the error block.
    testWidgets('hideDetails suppresses error block', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 800);

      final controller = TextEditingController();
      const errors = ['This error should be hidden'];

      final widget = LayrzTextInput(
        labelText: 'Username',
        controller: controller,
        errors: errors,
        hideDetails: true,
      );

      await pumpThemedApp(tester, widget);

      // Error text should NOT be visible when hideDetails is true
      expect(find.text('This error should be hidden'), findsNothing);

      // But the error icon should still be visible (state indicator)
      expect(find.byIcon(MdiIcons.alertOutline), findsOneWidget);
    });

    /// Test that error text is rendered at compact width.
    testWidgets('error text rendered at compact width', (WidgetTester tester) async {
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

      // Error text should be visible at compact width
      expect(find.text('Username contains invalid characters'), findsOneWidget);

      // Error icon should be present (state indicator)
      expect(find.byIcon(MdiIcons.alertOutline), findsOneWidget);
    });

    /// Test that character counter still works when errors are visible.
    testWidgets('character counter displayed alongside errors', (WidgetTester tester) async {
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

      // Character counter should be visible
      expect(find.text('4/30'), findsOneWidget);

      // Inline error should also be visible
      expect(find.text('Error message'), findsOneWidget);
    });

    /// Test that the field is focusable when errors are displayed.
    testWidgets('field can be focused when errors displayed', (WidgetTester tester) async {
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

      // Find the text input field itself
      final inputFinder = find.byType(EditableText).first;

      // The field should be focusable
      await tester.tap(inputFinder);
      await tester.pumpAndSettle();

      // Field should now have focus (we can verify by typing)
      await tester.enterText(inputFinder, 'test');
      await tester.pumpAndSettle();

      expect(controller.text, equals('test'));
    });

    /// Test that multiple errors are displayed comma-separated.
    testWidgets('multiple errors shown comma-separated', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 800);

      final controller = TextEditingController();
      const errors = ['Error one', 'Error two', 'Error three'];

      final widget = LayrzTextInput(
        labelText: 'Username',
        controller: controller,
        errors: errors,
      );

      await pumpThemedApp(tester, widget);

      // All errors should be visible, comma-separated
      expect(find.text('Error one, Error two, Error three'), findsOneWidget);
    });
  });
}
