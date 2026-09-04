import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/inputs/src/login/username_input.dart';
import 'package:layrz_ui/src/inputs/src/text/text_input.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzUsernameInput', () {
    testWidgets('renders default label from l10n when labelText is omitted at wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzUsernameInput());

      expect(findButtonLabel('Username'), findsOneWidget);
      expect(find.byType(LayrzUsernameInput), findsOneWidget);
    });

    testWidgets('renders default label from l10n when labelText is omitted at compact viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzUsernameInput());

      expect(findButtonLabel('Username'), findsOneWidget);
      expect(find.byType(LayrzUsernameInput), findsOneWidget);
    });

    testWidgets('renders custom labelText when supplied', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzUsernameInput(labelText: 'Correo electrónico'));

      expect(findButtonLabel('Correo electrónico'), findsOneWidget);
    });

    testWidgets('native path renders LayrzTextInput with the shieldAccountOutline prefix icon', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzUsernameInput());

      final textInput = tester.widget<LayrzTextInput>(find.byType(LayrzTextInput));
      expect(textInput.prefixIcon, MdiIcons.shieldAccountOutline);
    });

    testWidgets('native path configures the email keyboard and disables autocorrect', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzUsernameInput());

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.keyboardType, TextInputType.emailAddress);
      expect(editable.autocorrect, isFalse);
    });

    testWidgets('default autofill hints include both username and email', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzUsernameInput());

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.autofillHints, containsAll(<String>[AutofillHints.username, AutofillHints.email]));
      expect(editable.autofillHints, hasLength(2));
    });

    testWidgets('autofillHints override replaces the default set', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzUsernameInput(autofillHints: [AutofillHints.telephoneNumber]),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.autofillHints, [AutofillHints.telephoneNumber]);
    });

    testWidgets('controller pass-through: caller-supplied controller reflects typed text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController();
      await pumpThemed(tester, LayrzUsernameInput(controller: controller));

      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'jane.doe@example.com');
      await tester.pumpAndSettle();

      expect(controller.text, 'jane.doe@example.com');
    });

    testWidgets('onChanged fires with the new value', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? changed;
      await pumpThemed(
        tester,
        LayrzUsernameInput(onChanged: (value) => changed = value),
      );

      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'someone');
      await tester.pumpAndSettle();

      expect(changed, 'someone');
    });

    testWidgets('errors pass-through renders the error message at a wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzUsernameInput(errors: ['Username is required']),
      );

      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('disabled pass-through prevents input and marks the field disabled', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      int changeCount = 0;
      await pumpThemed(
        tester,
        LayrzUsernameInput(
          disabled: true,
          onChanged: (_) => changeCount++,
        ),
      );

      final textInput = tester.widget<LayrzTextInput>(find.byType(LayrzTextInput));
      expect(textInput.disabled, isTrue);

      await tester.tap(find.byType(LayrzUsernameInput), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(changeCount, 0);
    });

    testWidgets('focusNode pass-through requests focus on the shared node', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemed(tester, LayrzUsernameInput(focusNode: focusNode));

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('onSubmit fires when the user submits the field', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? submitted;
      await pumpThemed(
        tester,
        LayrzUsernameInput(onSubmit: (value) => submitted = value),
      );

      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'submit-me');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(submitted, 'submit-me');
    });

    testWidgets('dense pass-through is forwarded to LayrzTextInput', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzUsernameInput(dense: true));

      final textInput = tester.widget<LayrzTextInput>(find.byType(LayrzTextInput));
      expect(textInput.dense, isTrue);
    });

    testWidgets('isRequired pass-through shows the required asterisk', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzUsernameInput(isRequired: true));

      expect(findButtonLabel('*'), findsOneWidget);
    });
  });
}
