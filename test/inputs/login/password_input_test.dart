import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/inputs/src/login/password_input.dart';
import 'package:layrz_ui/src/inputs/src/login/password_strength_meter.dart';
import 'package:layrz_ui/src/inputs/src/text/text_input.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzPasswordInput', () {
    testWidgets('renders default label from l10n when labelText is omitted at wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzPasswordInput());

      expect(findButtonLabel('Password'), findsOneWidget);
      expect(find.byType(LayrzPasswordInput), findsOneWidget);
    });

    testWidgets('renders default label from l10n when labelText is omitted at compact viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzPasswordInput());

      expect(findButtonLabel('Password'), findsOneWidget);
      expect(find.byType(LayrzPasswordInput), findsOneWidget);
    });

    testWidgets('renders custom labelText when supplied', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzPasswordInput(labelText: 'Contraseña'));

      expect(findButtonLabel('Contraseña'), findsOneWidget);
    });

    testWidgets('native path renders LayrzTextInput with the shieldKeyOutline prefix icon', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzPasswordInput());

      final textInput = tester.widget<LayrzTextInput>(find.byType(LayrzTextInput));
      expect(textInput.prefixIcon, MdiIcons.shieldKeyOutline);
    });

    testWidgets('field starts obscured', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzPasswordInput());

      final textInput = tester.widget<LayrzTextInput>(find.byType(LayrzTextInput));
      expect(textInput.obscureText, isTrue);

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.obscureText, isTrue);
    });

    testWidgets('the eye toggle starts as eyeOutline and shows the "Show password" label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzPasswordInput());

      final icons = tester.widgetList<Icon>(find.byType(Icon)).where((icon) => icon.icon == MdiIcons.eyeOutline);
      expect(icons, isNotEmpty);
      expect(find.bySemanticsLabel('Show password'), findsOneWidget);
    });

    testWidgets('tapping the toggle flips obscure, swaps the icon, and swaps the accessible label', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzPasswordInput());

      expect(find.bySemanticsLabel('Show password'), findsOneWidget);
      final eyeOutlineFinder = find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.eyeOutline);
      expect(eyeOutlineFinder, findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Show password'));
      await tester.pumpAndSettle();

      final textInput = tester.widget<LayrzTextInput>(find.byType(LayrzTextInput));
      expect(textInput.obscureText, isFalse);

      final eyeOffFinder = find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.eyeOffOutline);
      expect(eyeOffFinder, findsOneWidget);
      expect(find.bySemanticsLabel('Hide password'), findsOneWidget);
      expect(find.bySemanticsLabel('Show password'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Hide password'));
      await tester.pumpAndSettle();

      final textInputAgain = tester.widget<LayrzTextInput>(find.byType(LayrzTextInput));
      expect(textInputAgain.obscureText, isTrue);
      expect(find.bySemanticsLabel('Show password'), findsOneWidget);
    });

    testWidgets('toggling announces the visibility change via a live region', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzPasswordInput());

        await tester.tap(find.bySemanticsLabel('Show password'));
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('Password shown'), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Hide password'));
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('Password hidden'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('disabled: the eye toggle no longer flips obscure on tap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzPasswordInput(disabled: true));

      final textInput = tester.widget<LayrzTextInput>(find.byType(LayrzTextInput));
      expect(textInput.disabled, isTrue);
      expect(textInput.obscureText, isTrue);

      await tester.tap(find.bySemanticsLabel('Show password'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final textInputAfter = tester.widget<LayrzTextInput>(find.byType(LayrzTextInput));
      expect(textInputAfter.obscureText, isTrue);
    });

    testWidgets('strength meter is absent by default', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzPasswordInput());

      expect(find.byType(LayrzPasswordStrengthMeter), findsNothing);
    });

    testWidgets('strength meter renders below the field when showStrengthMeter is true', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzPasswordInput(showStrengthMeter: true));

      expect(find.byType(LayrzPasswordStrengthMeter), findsOneWidget);
    });

    testWidgets('strength meter re-scores as the user types when showStrengthMeter is true', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzPasswordInput(controller: controller, showStrengthMeter: true),
      );

      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Str0ng!Password12');
      await tester.pumpAndSettle();

      final meter = tester.widget<LayrzPasswordStrengthMeter>(find.byType(LayrzPasswordStrengthMeter));
      expect(meter.password, 'Str0ng!Password12');
    });

    testWidgets('default autofill hints include password', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzPasswordInput());

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.autofillHints, [AutofillHints.password]);
    });

    testWidgets('autofillHints override replaces the default set', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzPasswordInput(autofillHints: [AutofillHints.newPassword]),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.autofillHints, [AutofillHints.newPassword]);
    });

    testWidgets('controller pass-through: caller-supplied controller reflects typed text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController();
      await pumpThemed(tester, LayrzPasswordInput(controller: controller));

      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'sup3rSecret!');
      await tester.pumpAndSettle();

      expect(controller.text, 'sup3rSecret!');
    });

    testWidgets('onChanged fires with the new value', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? changed;
      await pumpThemed(
        tester,
        LayrzPasswordInput(onChanged: (value) => changed = value),
      );

      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'hunter2');
      await tester.pumpAndSettle();

      expect(changed, 'hunter2');
    });

    testWidgets('onSubmit fires when the user submits the field', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? submitted;
      await pumpThemed(
        tester,
        LayrzPasswordInput(onSubmit: (value) => submitted = value),
      );

      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'submit-me');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(submitted, 'submit-me');
    });

    testWidgets('errors pass-through renders the error message at a wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzPasswordInput(errors: ['Password is required']),
      );

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('disabled pass-through prevents input and marks the field disabled', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      int changeCount = 0;
      await pumpThemed(
        tester,
        LayrzPasswordInput(
          disabled: true,
          onChanged: (_) => changeCount++,
        ),
      );

      final textInput = tester.widget<LayrzTextInput>(find.byType(LayrzTextInput));
      expect(textInput.disabled, isTrue);

      await tester.tap(find.byType(LayrzPasswordInput), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(changeCount, 0);
    });

    testWidgets('focusNode pass-through requests focus on the shared node', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemed(tester, LayrzPasswordInput(focusNode: focusNode));

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('dense pass-through is forwarded to LayrzTextInput', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzPasswordInput(dense: true));

      final textInput = tester.widget<LayrzTextInput>(find.byType(LayrzTextInput));
      expect(textInput.dense, isTrue);
    });

    testWidgets('isRequired pass-through shows the required asterisk', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzPasswordInput(isRequired: true));

      expect(findButtonLabel('*'), findsOneWidget);
    });

    testWidgets('renders correctly at a compact viewport with the toggle still functional', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzPasswordInput());

      await tester.tap(find.bySemanticsLabel('Show password'));
      await tester.pumpAndSettle();

      final textInput = tester.widget<LayrzTextInput>(find.byType(LayrzTextInput));
      expect(textInput.obscureText, isFalse);
    });
  });
}
