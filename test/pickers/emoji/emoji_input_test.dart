import 'package:emojis/emoji.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/pickers/src/emoji/emoji_input.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzEmojiInput — construction', () {
    guardedTestWidgets('asserts at least one of labelText/hintText is provided', (tester) async {
      expect(
        () => LayrzEmojiInput(),
        throwsAssertionError,
      );
    });

    guardedTestWidgets('can be created with only hintText', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzEmojiInput(hintText: 'Pick an emoji'));

      expect(find.byType(LayrzEmojiInput), findsOneWidget);
    });

    guardedTestWidgets('constructing with a non-null value does not throw', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzEmojiInput(labelText: 'Reaction', value: '😀'));

      expect(tester.takeException(), isNull);
      expect(find.byType(LayrzEmojiInput), findsOneWidget);
    });
  });

  group('LayrzEmojiInput — rendering', () {
    guardedTestWidgets('renders the label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzEmojiInput(labelText: 'Reaction'));

      expect(findButtonLabel('Reaction'), findsOneWidget);
    });

    guardedTestWidgets('shows hint text when value is null', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzEmojiInput(labelText: 'Reaction', hintText: 'Pick an emoji'));

      expect(find.text('Pick an emoji'), findsWidgets);
    });

    guardedTestWidgets('displays the picked emoji character when value is non-null', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzEmojiInput(labelText: 'Reaction', value: '😀'));

      expect(find.text('😀'), findsOneWidget);
    });

    guardedTestWidgets('renders the emoticon affordance icon', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzEmojiInput(labelText: 'Reaction'));

      expect(find.byIcon(MdiIcons.emoticonOutline), findsOneWidget);
    });

    guardedTestWidgets('opens with no Save/Cancel footer -- commit-on-tap, unlike the date/month pickers', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzEmojiInput(labelText: 'Reaction'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(findButtonLabel('Save'), findsNothing);
      expect(findButtonLabel('Cancel'), findsNothing);
    });

    // CHANGED (LayrzPickerDialogHeader migration): `LayrzResponsiveModal.show`
    // itself still has no `title:` slot, but every picker surface -- this one
    // included -- now composes its own `LayrzPickerDialogHeader` inside the
    // builder content instead (see that class's own doc for why), which DOES
    // render `labelText` as a visible title `Text`. This asserts exactly one
    // such title renders, not that none does.
    guardedTestWidgets('the open surface renders exactly one visible title via LayrzPickerDialogHeader', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzEmojiInput(labelText: 'Preferred reaction'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // With no value set, the anchor field's own labelText renders as
      // hintText (via `LayrzInputChrome`) rather than a floating label, so
      // only the surface's own `LayrzPickerDialogHeader` title contributes
      // a "Preferred reaction" Text once the surface is open.
      expect(find.text('Preferred reaction'), findsOneWidget);
    });
  });

  group('LayrzEmojiInput — commit on tap', () {
    guardedTestWidgets('picking an emoji fires onChanged with that character and closes the drawer (desktop)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? changed;
      await pumpThemedApp(tester, LayrzEmojiInput(labelText: 'Reaction', onChanged: (c) => changed = c));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final target = Emoji.byShortName('grinning')!;
      await tester.enterText(find.byType(EditableText).first, 'grinning');
      await tester.pump();

      await tester.tap(find.text(target.char).first);
      await tester.pumpAndSettle();

      expect(changed, target.char);
      // The drawer is gone -- no more emoji surface/search field on screen.
      expect(find.byType(EditableText), findsNothing);
    });

    guardedTestWidgets('picking an emoji fires onChanged and closes the sheet (compact/mobile)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? changed;
      await pumpThemedApp(tester, LayrzEmojiInput(labelText: 'Reaction', onChanged: (c) => changed = c));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final target = Emoji.byShortName('grinning')!;
      await tester.enterText(find.byType(EditableText).first, 'grinning');
      await tester.pump();

      await tester.tap(find.text(target.char).first);
      await tester.pumpAndSettle();

      expect(changed, target.char);
      expect(find.byType(EditableText), findsNothing);
    });

    guardedTestWidgets('the closed field reflects the pick even without an external value update', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzEmojiInput(labelText: 'Reaction'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final target = Emoji.byShortName('grinning')!;
      await tester.enterText(find.byType(EditableText).first, 'grinning');
      await tester.pump();
      await tester.tap(find.text(target.char).first);
      await tester.pumpAndSettle();

      expect(find.text(target.char), findsOneWidget);
    });

    guardedTestWidgets('disabled input never opens the surface', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzEmojiInput(labelText: 'Reaction', disabled: true));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsNothing);
    });
  });

  group('LayrzEmojiInput — errors', () {
    guardedTestWidgets('displays error text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzEmojiInput(labelText: 'Reaction', errors: const ['Required']),
      );

      expect(find.text('Required'), findsOneWidget);
    });

    guardedTestWidgets('hides error text when hideDetails is true', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzEmojiInput(labelText: 'Reaction', errors: const ['Required'], hideDetails: true),
      );

      expect(find.text('Required'), findsNothing);
    });

    // The readOnly trap: LayrzInputStyleSpec.resolve ranks `readOnly` above
    // `error`, so hardcoding `readOnly: true` on the anchor would silently
    // suppress the danger border even with errors present -- see
    // `buildPickerFieldRow`'s own doc. This asserts the chrome still renders
    // with errors present at all (a proxy the state resolves without the
    // readOnly precedence bug swallowing it).
    guardedTestWidgets('an errored field still renders its content (no readOnly precedence bug)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzEmojiInput(labelText: 'Reaction', value: '😀', errors: const ['Required']),
      );

      expect(find.text('😀'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
    });
  });
}
