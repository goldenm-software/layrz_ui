import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/otp/otp_slot.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/pump_themed.dart';
import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzOtpInput', () {
    testWidgets('renders six OtpSlot widgets', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(tester, const LayrzOtpInput());

      expect(find.byType(OtpSlot), findsNWidgets(6));
    });

    testWidgets('typing digits emits onChanged with the accumulated string', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      final changes = <String>[];
      await pumpThemed(
        tester,
        LayrzOtpInput(onChanged: changes.add),
      );

      await tester.enterText(find.byType(EditableText), '1');
      expect(changes.last, '1');

      await tester.enterText(find.byType(EditableText), '12');
      expect(changes.last, '12');

      await tester.enterText(find.byType(EditableText), '123');
      expect(changes.last, '123');
    });

    testWidgets('entering the 6th digit fires onCompleted exactly once with the full code', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      var completedCount = 0;
      String? completedValue;
      await pumpThemed(
        tester,
        LayrzOtpInput(
          onCompleted: (value) {
            completedCount++;
            completedValue = value;
          },
        ),
      );

      await tester.enterText(find.byType(EditableText), '12345');
      expect(completedCount, 0, reason: 'partial input must never fire onCompleted');

      await tester.enterText(find.byType(EditableText), '123456');
      expect(completedCount, 1);
      expect(completedValue, '123456');
    });

    testWidgets('onCompleted does not fire again on rebuilds while already complete', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      var completedCount = 0;
      final key = GlobalKey();
      await pumpThemed(
        tester,
        LayrzOtpInput(
          key: key,
          value: '123456',
          onCompleted: (_) => completedCount++,
        ),
      );
      // The initial mount, with an already-complete value, seeds `_wasComplete` to true in
      // initState (per the source), so onCompleted must never fire for it.
      expect(completedCount, 0);

      // Force an unrelated rebuild (same value) and confirm onCompleted stays silent.
      await pumpThemed(
        tester,
        LayrzOtpInput(
          key: key,
          value: '123456',
          errors: const [],
          onCompleted: (_) => completedCount++,
        ),
      );
      await tester.pump();

      expect(completedCount, 0);
    });

    testWidgets('onCompleted does not fire on partial input', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      var completedCount = 0;
      await pumpThemed(
        tester,
        LayrzOtpInput(onCompleted: (_) => completedCount++),
      );

      await tester.enterText(find.byType(EditableText), '1');
      await tester.enterText(find.byType(EditableText), '12');
      await tester.enterText(find.byType(EditableText), '1234');

      expect(completedCount, 0);
    });

    testWidgets('non-digit characters are filtered out', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        LayrzOtpInput(controller: controller),
      );

      await tester.enterText(find.byType(EditableText), '1a2b3c');
      expect(controller.text, '123');
    });

    testWidgets('more than 6 digits are truncated to 6', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        LayrzOtpInput(controller: controller),
      );

      await tester.enterText(find.byType(EditableText), '123456789');
      expect(controller.text, '123456');
    });

    testWidgets('external value prop flows into the slots', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(tester, const LayrzOtpInput(value: '482913'));

      final slots = tester.widgetList<OtpSlot>(find.byType(OtpSlot)).toList();
      expect(slots.map((s) => s.character).toList(), ['4', '8', '2', '9', '1', '3']);
    });

    testWidgets('external value prop does not re-echo onChanged', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      var onChangedCallCount = 0;
      final key = GlobalKey();
      await pumpThemed(
        tester,
        LayrzOtpInput(
          key: key,
          value: '123',
          onChanged: (_) => onChangedCallCount++,
        ),
      );
      expect(onChangedCallCount, 0, reason: 'the initial seed from `value` must not itself fire onChanged');

      // A `value` prop change flowing through didUpdateWidget must not re-emit onChanged --
      // the `_isInternalUpdate` guard exists specifically to suppress this echo.
      await pumpThemed(
        tester,
        LayrzOtpInput(
          key: key,
          value: '456',
          onChanged: (_) => onChangedCallCount++,
        ),
      );
      await tester.pump();

      expect(onChangedCallCount, 0);
    });

    testWidgets('errors render the error text in the footer', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(
        tester,
        const LayrzOtpInput(errors: ['Invalid code']),
      );

      expect(find.text('Invalid code'), findsOneWidget);
    });

    testWidgets('errors mark every slot as errored', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(
        tester,
        const LayrzOtpInput(value: '123', errors: ['Invalid code']),
      );

      final slots = tester.widgetList<OtpSlot>(find.byType(OtpSlot)).toList();
      expect(slots, hasLength(6));
      expect(slots.every((slot) => slot.hasErrors), isTrue);
    });

    testWidgets('disabled: typing does not change the value and onChanged is never called', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      // `_handleControllerChanged` now gates on the digits actually changing since the
      // last emission (see `_lastEmittedText` in `otp_input.dart`), so the keyboard
      // connection `enterText`/`showKeyboard` establish on the hidden field -- which
      // fires a selection/composing-region-only controller notification with no text
      // change -- no longer spuriously emits `onChanged("")`. `changes` should therefore
      // stay entirely empty here, not merely empty-valued.
      final changes = <String>[];
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        LayrzOtpInput(
          disabled: true,
          controller: controller,
          onChanged: changes.add,
        ),
      );

      await tester.enterText(find.byType(EditableText), '123456');
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(changes, isEmpty);
    });

    testWidgets('disabled: tap does not focus the field', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemed(
        tester,
        LayrzOtpInput(disabled: true, focusNode: focusNode),
      );

      await tester.tap(find.byType(LayrzOtpInput));
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('disabled slots report the disabled flag', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(tester, const LayrzOtpInput(disabled: true));

      final slots = tester.widgetList<OtpSlot>(find.byType(OtpSlot)).toList();
      expect(slots.every((slot) => slot.disabled), isTrue);
    });

    testWidgets('readOnly: typing does not change the value, but the field can still be focused', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      // See the identical note on the `disabled` typing test above: `_handleControllerChanged`
      // gates on an actual digits change since the last emission, so gaining real focus via
      // the tap below -- a selection-only controller notification, no text change -- must
      // not emit `onChanged` either, exactly like the subsequent (blocked) typing attempt.
      final changes = <String>[];
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemed(
        tester,
        LayrzOtpInput(
          readOnly: true,
          controller: controller,
          focusNode: focusNode,
          onChanged: changes.add,
        ),
      );

      await tester.tap(find.byType(LayrzOtpInput));
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue, reason: 'readOnly must still allow focus, unlike disabled');
      expect(changes, isEmpty, reason: 'a bare focus gain with no text change must not emit onChanged');

      await tester.enterText(find.byType(EditableText), '123456');
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(changes, isEmpty);
    });

    testWidgets('readOnly slots report the readOnly flag', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(tester, const LayrzOtpInput(readOnly: true));

      final slots = tester.widgetList<OtpSlot>(find.byType(OtpSlot)).toList();
      expect(slots.every((slot) => slot.readOnly), isTrue);
    });

    testWidgets('labelText renders', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(tester, const LayrzOtpInput(labelText: 'Verification code'));

      expect(findButtonLabel('Verification code'), findsOneWidget);
    });

    testWidgets('isRequired renders the required indicator', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(
        tester,
        const LayrzOtpInput(labelText: 'Verification code', isRequired: true),
      );

      expect(findButtonLabel('Verification code'), findsOneWidget);
      expect(findButtonLabel('*'), findsOneWidget);
    });

    testWidgets('no label is rendered when labelText is null', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(tester, const LayrzOtpInput());

      expect(findButtonLabel('*'), findsNothing);
    });

    testWidgets('hideDetails suppresses the footer', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(
        tester,
        const LayrzOtpInput(errors: ['Invalid code'], hideDetails: true),
      );

      expect(find.text('Invalid code'), findsNothing);
    });

    testWidgets('helperText renders when errors are empty', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(tester, const LayrzOtpInput(helperText: 'Sent via SMS'));

      expect(find.text('Sent via SMS'), findsOneWidget);
    });

    testWidgets('helperText is hidden when errors are non-empty', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(
        tester,
        const LayrzOtpInput(helperText: 'Sent via SMS', errors: ['Invalid code']),
      );

      expect(find.text('Sent via SMS'), findsNothing);
      expect(find.text('Invalid code'), findsOneWidget);
    });

    testWidgets('autofocus requests focus as soon as built', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemedApp(
        tester,
        LayrzOtpInput(autofocus: true, focusNode: focusNode),
      );
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('calls onFocusChanged when focus changes', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      var focusChanged = false;
      await pumpThemed(
        tester,
        LayrzOtpInput(onFocusChanged: (_) => focusChanged = true),
      );

      await tester.tap(find.byType(LayrzOtpInput));
      await tester.pumpAndSettle();

      expect(focusChanged, isTrue);
    });

    group('controller/focusNode ownership', () {
      testWidgets('a caller-supplied controller is not disposed by the widget', (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await pumpThemed(tester, LayrzOtpInput(controller: controller));

        await pumpThemed(tester, const SizedBox.shrink());

        // A disposed ChangeNotifier throws on addListener -- the only black-box way to
        // observe from outside the widget whether it was disposed.
        expect(() => controller.addListener(() {}), returnsNormally);
      });

      testWidgets('a widget-created controller is disposed on unmount', (tester) async {
        await pumpThemed(tester, const LayrzOtpInput());

        final internal = tester.widget<EditableText>(find.byType(EditableText)).controller;

        await pumpThemed(tester, const SizedBox.shrink());

        expect(() => internal.addListener(() {}), throwsA(isA<FlutterError>()));
      });

      testWidgets('a caller-supplied focusNode is not disposed by the widget', (tester) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        await pumpThemed(tester, LayrzOtpInput(focusNode: focusNode));

        await pumpThemed(tester, const SizedBox.shrink());

        expect(() => focusNode.addListener(() {}), returnsNormally);
      });

      testWidgets('a widget-created focusNode is disposed on unmount (no exception)', (tester) async {
        await pumpThemed(tester, const LayrzOtpInput());

        await pumpThemed(tester, const SizedBox.shrink());
        // If the internal focus node wasn't disposed, no exception is thrown here either way
        // -- this mirrors LayrzNumberInput's equivalent test, asserting a clean unmount.
        expect(tester.takeException(), isNull);
      });
    });
  });
}
