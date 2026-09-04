import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/login/form.dart';

import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzForm', () {
    /// Every `TextInput.finishAutofillContext(shouldSave: ...)` call observed via
    /// [WidgetTester.testTextInput]'s method-call log, extracted as the raw `shouldSave`
    /// argument each call carried, in call order.
    ///
    /// [WidgetTester.testTextInput] is `flutter_test`'s own mock handler for
    /// [SystemChannels.textInput] — it is what `TestWidgetsFlutterBinding` registers at
    /// the top of every test, so installing a second, competing mock handler on the same
    /// channel is unreliable (the binding's own registration wins the race). Reading its
    /// `log` is the supported way to observe channel traffic in a widget test.
    List<bool> finishAutofillContextCalls(WidgetTester tester) => tester.testTextInput.log
        .where((call) => call.method == 'TextInput.finishAutofillContext')
        .map((call) => call.arguments as bool)
        .toList();

    testWidgets('wraps child in an AutofillGroup on the native path at a wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzForm(
          onSubmit: () async => true,
          child: const Text('field placeholder'),
        ),
      );

      expect(find.byType(AutofillGroup), findsOneWidget);
      expect(
        find.descendant(of: find.byType(AutofillGroup), matching: find.text('field placeholder')),
        findsOneWidget,
      );
    });

    testWidgets('wraps child in an AutofillGroup on the native path at a compact viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzForm(
          onSubmit: () async => true,
          child: const Text('field placeholder'),
        ),
      );

      expect(find.byType(AutofillGroup), findsOneWidget);
    });

    testWidgets('imposes no layout of its own: child keeps its natural size and position', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const childKey = Key('form-child');

      await pumpThemed(
        tester,
        LayrzForm(
          onSubmit: () async => true,
          child: const SizedBox(key: childKey, width: 123, height: 45),
        ),
      );

      final childSize = tester.getSize(find.byKey(childKey));
      expect(childSize, const Size(123, 45));
    });

    testWidgets('submit() calls finishAutofillContext(shouldSave: true) when onSubmit resolves true', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final formKey = GlobalKey();

      await pumpThemed(
        tester,
        LayrzForm(
          key: formKey,
          onSubmit: () async => true,
          child: const Text('field placeholder'),
        ),
      );

      final form = formKey.currentWidget! as LayrzForm;
      final result = await form.submit();
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(finishAutofillContextCalls(tester), [true]);
    });

    testWidgets(
      'submit() calls finishAutofillContext(shouldSave: false) and NEVER offers a save when onSubmit resolves false',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final formKey = GlobalKey();

        await pumpThemed(
          tester,
          LayrzForm(
            key: formKey,
            onSubmit: () async => false,
            child: const Text('field placeholder'),
          ),
        );

        final form = formKey.currentWidget! as LayrzForm;
        final result = await form.submit();
        await tester.pumpAndSettle();

        expect(result, isFalse);
        // THE MUST-NEVER: no shouldSave:true was ever sent — a failed submission must
        // never be offered to the password manager for saving.
        final calls = finishAutofillContextCalls(tester);
        expect(calls, [false]);
        expect(calls, isNot(contains(true)));
      },
    );

    testWidgets('submit() discards the autofill context (shouldSave: false) when onSubmit throws', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final formKey = GlobalKey();

      await pumpThemed(
        tester,
        LayrzForm(
          key: formKey,
          onSubmit: () async => throw StateError('network error'),
          child: const Text('field placeholder'),
        ),
      );

      final form = formKey.currentWidget! as LayrzForm;

      await expectLater(form.submit, throwsStateError);
      await tester.pumpAndSettle();

      final calls = finishAutofillContextCalls(tester);
      expect(calls, [false]);
      expect(calls, isNot(contains(true)));
    });

    testWidgets(
      'disposing the AutofillGroup after a failed submit does NOT trigger a save '
      '(overrides the SDK default onDisposeAction)',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final formKey = GlobalKey();

        await pumpThemed(
          tester,
          LayrzForm(
            key: formKey,
            onSubmit: () async => false,
            child: const Text('field placeholder'),
          ),
        );

        final form = formKey.currentWidget! as LayrzForm;
        await form.submit();
        await tester.pumpAndSettle();
        expect(finishAutofillContextCalls(tester), [false]);

        // Tear down the tree (as popping a route would) and confirm the SDK's own
        // AutofillGroup disposal — which defaults to committing a save — never fires a
        // second, unwanted shouldSave:true.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(finishAutofillContextCalls(tester), isNot(contains(true)));
      },
    );

    testWidgets('submit() never calls finishAutofillContext before onSubmit completes', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final formKey = GlobalKey();
      final completer = Completer<bool>();

      await pumpThemed(
        tester,
        LayrzForm(
          key: formKey,
          onSubmit: () => completer.future,
          child: const Text('field placeholder'),
        ),
      );

      final form = formKey.currentWidget! as LayrzForm;
      final pendingSubmit = form.submit();

      // While onSubmit is still pending, finishAutofillContext must not have fired yet
      // — eager commit before the result is known is the must-never failure.
      await tester.pump(const Duration(milliseconds: 50));
      expect(finishAutofillContextCalls(tester), isEmpty);

      completer.complete(true);
      final result = await pendingSubmit;
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(finishAutofillContextCalls(tester), [true]);
    });
  });
}
