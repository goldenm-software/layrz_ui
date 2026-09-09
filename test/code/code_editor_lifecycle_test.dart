import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

/// Pumps [child] directly under [LayrzTheme] (no [Overlay]), so a second call
/// with the *same* widget tree position genuinely reaches
/// [State.didUpdateWidget] on re-pump.
///
/// [pumpThemed] wraps its child in an [Overlay] whose `initialEntries` are
/// only inserted once, in [OverlayState.initState] — a second [pumpThemed]
/// call keeps showing the *first* call's overlay entry (and thus its
/// captured child) no matter what the second call's widget says. This helper
/// sidesteps that entirely for the one test here that needs a real
/// [State.didUpdateWidget] pass rather than a fresh mount.
Future<void> _pumpDirect(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    Localizations(
      locale: const Locale('en'),
      delegates: const [
        DefaultWidgetsLocalizations.delegate,
        LayrzUiL10nDelegate(),
      ],
      child: LayrzTheme(
        data: LayrzThemeData.light(),
        child: Center(child: child),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('LayrzCodeEditor controller/focusNode lifecycle', () {
    testWidgets('an internally-created controller is disposed on unmount', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1'),
      );

      final controller = tester.widget<EditableText>(find.byType(EditableText)).controller;

      // Unmount by pumping an empty tree.
      await tester.pumpWidget(const SizedBox.shrink());

      // A disposed ChangeNotifier throws on further listener mutation.
      expect(() => controller.addListener(() {}), throwsFlutterError);
    });

    testWidgets('a caller-supplied controller is not disposed on unmount', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController(text: 'x = 1');

      await pumpThemed(
        tester,
        LayrzCodeEditor(language: LayrzCodeLanguage.python, controller: controller),
      );

      await tester.pumpWidget(const SizedBox.shrink());

      // Still usable: does not throw.
      expect(() => controller.addListener(() {}), returnsNormally);
      controller.dispose();
    });

    testWidgets('an internally-created focusNode is disposed on unmount', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1'),
      );

      final focusNode = tester.widget<EditableText>(find.byType(EditableText)).focusNode;

      await tester.pumpWidget(const SizedBox.shrink());

      expect(() => focusNode.addListener(() {}), throwsFlutterError);
    });

    testWidgets('a caller-supplied focusNode is not disposed on unmount', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();

      await pumpThemed(
        tester,
        LayrzCodeEditor(language: LayrzCodeLanguage.python, focusNode: focusNode),
      );

      await tester.pumpWidget(const SizedBox.shrink());

      expect(() => focusNode.addListener(() {}), returnsNormally);
      focusNode.dispose();
    });

    testWidgets('swapping the controller in didUpdateWidget disposes the old owned one', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpDirect(
        tester,
        const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1'),
      );
      final firstController = tester.widget<EditableText>(find.byType(EditableText)).controller;

      final newController = TextEditingController(text: 'y = 2');
      addTearDown(newController.dispose);

      await _pumpDirect(
        tester,
        LayrzCodeEditor(language: LayrzCodeLanguage.python, controller: newController),
      );

      expect(() => firstController.addListener(() {}), throwsFlutterError);
      expect(tester.widget<EditableText>(find.byType(EditableText)).controller, same(newController));
    });

    testWidgets('changing language while owning the controller recreates it, preserving the text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpDirect(
        tester,
        const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1'),
      );
      final firstController = tester.widget<EditableText>(find.byType(EditableText)).controller;
      expect(firstController.text, 'x = 1');

      // No `controller` is ever supplied on either pump, so `LayrzCodeEditor`
      // owns it throughout — this exercises the `_ownsController` branch of
      // `didUpdateWidget` (as opposed to the controller-swap branch covered
      // above), which recreates the internal `LayrzHighlightingController`
      // under the new grammar while carrying the current text forward.
      await _pumpDirect(
        tester,
        const LayrzCodeEditor(language: LayrzCodeLanguage.lcl, value: 'x = 1'),
      );

      final secondController = tester.widget<EditableText>(find.byType(EditableText)).controller;
      expect(secondController.text, 'x = 1');
      expect(secondController, isNot(same(firstController)));

      // The old, now-orphaned controller was disposed as part of the
      // recreation, mirroring the controller-swap assertion above.
      expect(() => firstController.addListener(() {}), throwsFlutterError);
    });

    testWidgets('swapping the focusNode in didUpdateWidget disposes the old owned one', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpDirect(
        tester,
        const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1'),
      );
      final firstFocusNode = tester.widget<EditableText>(find.byType(EditableText)).focusNode;

      final newFocusNode = FocusNode();

      await _pumpDirect(
        tester,
        LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1', focusNode: newFocusNode),
      );

      expect(() => firstFocusNode.addListener(() {}), throwsFlutterError);
      expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode, same(newFocusNode));

      // Caller-supplied, so LayrzCodeEditor never disposes it — unmount the
      // tree first, then dispose it ourselves.
      await tester.pumpWidget(const SizedBox.shrink());
      newFocusNode.dispose();
    });

    testWidgets('an external value change writes through to the internally-owned controller', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpDirect(
        tester,
        const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1'),
      );
      final controller = tester.widget<EditableText>(find.byType(EditableText)).controller;
      expect(controller.text, 'x = 1');

      // A new `value` distinct from what the controller currently holds
      // exercises the `didUpdateWidget` branch that writes it through to the
      // controller — the caller-driven counterpart to the user typing.
      await _pumpDirect(
        tester,
        const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'y = 2'),
      );

      expect(controller.text, 'y = 2');
    });
  });
}
