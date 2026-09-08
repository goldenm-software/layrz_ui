import 'package:emojis/emoji.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_mdi_remap/flutter_mdi_remap.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/images/src/avatar.dart';
import 'package:layrz_ui/src/images/src/avatar_source.dart';
import 'package:layrz_ui/src/pickers/src/dynamic_avatar/dynamic_avatar_tile.dart';
import 'package:layrz_ui/src/pickers/src/dynamic_avatar/dynamic_avatar_input.dart';
import 'package:layrz_ui/src/pickers/src/image/image_input.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzDynamicAvatarInput — construction', () {
    guardedTestWidgets('asserts at least one of labelText/hintText is provided', (tester) async {
      expect(
        () => LayrzDynamicAvatarInput(),
        throwsAssertionError,
      );
    });

    guardedTestWidgets('can be created with only hintText', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDynamicAvatarInput(hintText: 'Pick an avatar'));

      expect(find.byType(LayrzDynamicAvatarInput), findsOneWidget);
    });

    guardedTestWidgets('constructing with a non-null value does not throw', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDynamicAvatarInput(labelText: 'Avatar', value: const LayrzAvatarEmoji('😀')),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(LayrzDynamicAvatarInput), findsOneWidget);
    });
  });

  group('LayrzDynamicAvatarInput — rendering', () {
    guardedTestWidgets('renders the label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));

      expect(findButtonLabel('Avatar'), findsOneWidget);
    });

    guardedTestWidgets('the empty tile shows the add-avatar affordance icon and no clear badge', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar', hintText: 'Pick an avatar'));

      expect(find.byIcon(MdiIcons.accountPlusOutline), findsOneWidget);
      expect(find.byWidgetPredicate((widget) => widget is LayrzAvatar), findsNothing);
    });

    guardedTestWidgets('the closed field is a LayrzDynamicAvatarTile', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));

      expect(find.byType(LayrzDynamicAvatarTile), findsOneWidget);
    });

    guardedTestWidgets('isRequired renders a trailing asterisk in the label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar', isRequired: true));

      expect(findButtonLabel('Avatar*'), findsOneWidget);
    });

    guardedTestWidgets('the closed-field preview renders a LayrzAvatar for a non-null value', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDynamicAvatarInput(labelText: 'Avatar', value: const LayrzAvatarEmoji('😀')),
      );

      final avatarFinder = find.byWidgetPredicate(
        (widget) => widget is LayrzAvatar && widget.source == const LayrzAvatarEmoji('😀'),
      );
      expect(avatarFinder, findsOneWidget);
    });

    guardedTestWidgets('opens the dialog surface on a wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));

      await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
      await tester.pumpAndSettle();

      expect(find.text('URL'), findsOneWidget);
      expect(find.text('Icon'), findsOneWidget);
      expect(find.text('Emoji'), findsOneWidget);
    });

    guardedTestWidgets('opens the bottom-sheet surface on a compact viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));

      await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
      await tester.pumpAndSettle();

      expect(find.text('URL'), findsOneWidget);
      expect(find.text('Icon'), findsOneWidget);
      expect(find.text('Emoji'), findsOneWidget);
    });
  });

  group('LayrzDynamicAvatarInput — closed-field clear badge', () {
    // The clear affordance is an icon-only circular badge overlaid on the
    // tile's top-right corner (mirroring `LayrzImageInput`'s own), announced
    // via `Semantics(label: 'Remove avatar')` -- `tester.tap` on that
    // semantics finder hit-tests through to the badge's own `GestureDetector`
    // beneath it.
    Finder clearBadgeFinder() => find.bySemanticsLabel('Remove avatar');

    guardedTestWidgets('no clear badge is shown when the value is null (empty tile)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));

        expect(clearBadgeFinder(), findsNothing);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the clear badge appears once a value is set', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzDynamicAvatarInput(labelText: 'Avatar', value: const LayrzAvatarEmoji('😀')),
        );

        expect(clearBadgeFinder(), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('tapping the clear badge fires onChanged with null without opening the surface', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        LayrzAvatarSource? changed = const LayrzAvatarEmoji('😀');
        var callCount = 0;
        await pumpThemedApp(
          tester,
          LayrzDynamicAvatarInput(
            labelText: 'Avatar',
            value: const LayrzAvatarEmoji('😀'),
            onChanged: (c) {
              callCount++;
              changed = c;
            },
          ),
        );

        await tester.tap(clearBadgeFinder());
        await tester.pumpAndSettle();

        expect(callCount, 1);
        expect(changed, isNull);
        // The surface never opened -- no tab labels on screen.
        expect(find.text('URL'), findsNothing);
        // The tile returns to its empty state.
        expect(clearBadgeFinder(), findsNothing);
        expect(find.byIcon(MdiIcons.accountPlusOutline), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a disabled populated field does not render an interactive clear badge', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        var called = false;
        await pumpThemedApp(
          tester,
          LayrzDynamicAvatarInput(
            labelText: 'Avatar',
            value: const LayrzAvatarEmoji('😀'),
            disabled: true,
            onChanged: (_) => called = true,
          ),
        );

        await tester.tap(clearBadgeFinder());
        await tester.pumpAndSettle();

        expect(called, isFalse);
      } finally {
        handle.dispose();
      }
    });
  });

  group('LayrzDynamicAvatarInput — Icon tab', () {
    guardedTestWidgets('picking an icon fires onChanged with a matching LayrzAvatarIcon and closes the surface', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzAvatarSource? changed;
      await pumpThemedApp(
        tester,
        LayrzDynamicAvatarInput(labelText: 'Avatar', onChanged: (c) => changed = c),
      );

      await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Icon'));
      await tester.pumpAndSettle();

      final target = allMdiRemapIcons().first;
      await tester.enterText(find.byType(EditableText).first, target.name);
      await tester.pump();

      await tester.tap(find.byIcon(target.data).first);
      await tester.pumpAndSettle();

      expect(changed, isA<LayrzAvatarIcon>());
      expect((changed as LayrzAvatarIcon).icon.name, target.name);
      // The surface is gone -- no more search field on screen.
      expect(find.byType(EditableText), findsNothing);
    });

    guardedTestWidgets('searching for a nonsense query shows the empty state', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));

      await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Icon'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, 'zzzznonexistentqueryzzzz');
      await tester.pump();

      expect(find.text('No icon found'), findsOneWidget);
    });

    guardedTestWidgets('the search field clear button resets the query', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));

      await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Icon'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, 'account');
      await tester.pump();

      // `.last` -- the header's own close ("X") button also renders
      // `MdiIcons.close`; the search field's clear icon is the last one in
      // tree order.
      await tester.tap(find.byIcon(MdiIcons.close).last);
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText).first);
      expect(editable.controller.text, isEmpty);
    });
  });

  group('LayrzDynamicAvatarInput — Emoji tab', () {
    guardedTestWidgets('picking an emoji fires onChanged with a matching LayrzAvatarEmoji and closes the surface', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzAvatarSource? changed;
      await pumpThemedApp(
        tester,
        LayrzDynamicAvatarInput(labelText: 'Avatar', onChanged: (c) => changed = c),
      );

      await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Emoji'));
      await tester.pumpAndSettle();

      final target = Emoji.byShortName('grinning')!;
      // Two EditableText fields can be present after switching tabs (URL
      // field is disposed once its tab is not built, so only the emoji
      // search field's EditableText remains here).
      await tester.enterText(find.byType(EditableText).first, 'grinning');
      await tester.pump();

      await tester.tap(find.text(target.char).first);
      await tester.pumpAndSettle();

      expect(changed, LayrzAvatarEmoji(target.char));
      expect(find.byType(EditableText), findsNothing);
    });

    guardedTestWidgets('searching for a nonsense query shows the empty state', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));

      await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Emoji'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, 'zzzznonexistentqueryzzzz');
      await tester.pump();

      expect(find.text('No emoji found'), findsOneWidget);
    });

    guardedTestWidgets('the search field clear button resets the query', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));

      await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Emoji'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, 'grinning');
      await tester.pump();

      // `.last` -- the header's own close ("X") button also renders
      // `MdiIcons.close`; the search field's clear icon is the last one in
      // tree order.
      await tester.tap(find.byIcon(MdiIcons.close).last);
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText).first);
      expect(editable.controller.text, isEmpty);
    });

    guardedTestWidgets('tapping a group filter chip narrows the grid to that group', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzAvatarSource? changed;
      await pumpThemedApp(
        tester,
        LayrzDynamicAvatarInput(labelText: 'Avatar', onChanged: (c) => changed = c),
      );

      await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Emoji'));
      await tester.pumpAndSettle();

      // "Flags" is near the end of the group-filter row, so it sits
      // off-screen until dragged into view.
      await tester.drag(find.byType(ListView).first, const Offset(-2000, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Flags'));
      await tester.pumpAndSettle();

      final target = Emoji.byGroup(EmojiGroup.flags).first;
      await tester.tap(find.text(target.char).first);
      await tester.pumpAndSettle();

      expect(changed, LayrzAvatarEmoji(target.char));
    });
  });

  group('LayrzDynamicAvatarInput — URL tab', () {
    guardedTestWidgets('submitting a URL fires onChanged with a LayrzAvatarUrl and closes the surface', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzAvatarSource? changed;
      await pumpThemedApp(
        tester,
        LayrzDynamicAvatarInput(labelText: 'Avatar', onChanged: (c) => changed = c),
      );

      await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
      await tester.pumpAndSettle();

      // URL is the first (initial) tab -- already selected on open.
      await tester.enterText(find.byType(EditableText).first, 'https://example.com/a.png');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(changed, const LayrzAvatarUrl('https://example.com/a.png'));
      expect(find.byType(EditableText), findsNothing);
    });

    guardedTestWidgets('submitting an empty/whitespace URL does not commit or close the surface', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzAvatarSource? changed;
      await pumpThemedApp(
        tester,
        LayrzDynamicAvatarInput(labelText: 'Avatar', onChanged: (c) => changed = c),
      );

      await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(changed, isNull);
      // The surface remains open -- its URL field is still present.
      expect(find.byType(EditableText), findsOneWidget);
    });
  });

  group('LayrzDynamicAvatarInput — Upload tab', () {
    guardedTestWidgets('the Upload tab renders an image tile', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));

      await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Base64'));
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.imagePlusOutline), findsOneWidget);
      // The base64 emit path itself is driven by `file_picker`'s native
      // system dialog, which cannot be invoked from a widget test -- this
      // tab's rendering is asserted here; the base64-to-LayrzAvatarBase64
      // mapping the surface wires onto LayrzImageInput.onChanged is
      // exercised directly below by invoking that callback, without going
      // through the OS picker.
    });

    guardedTestWidgets('a base64 string emitted by LayrzImageInput commits a LayrzAvatarBase64 and closes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzAvatarSource? changed;
      await pumpThemedApp(
        tester,
        LayrzDynamicAvatarInput(labelText: 'Avatar', onChanged: (c) => changed = c),
      );

      await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Base64'));
      await tester.pumpAndSettle();

      final imageInput = tester.widget<LayrzImageInput>(find.byType(LayrzImageInput));
      imageInput.onChanged?.call('data:image/png;base64,AAAA');
      await tester.pumpAndSettle();

      expect(changed, const LayrzAvatarBase64('data:image/png;base64,AAAA'));
      expect(find.byType(LayrzImageInput), findsNothing);
    });

    guardedTestWidgets('a null/empty emission from LayrzImageInput does not commit', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzAvatarSource? changed;
      await pumpThemedApp(
        tester,
        LayrzDynamicAvatarInput(labelText: 'Avatar', onChanged: (c) => changed = c),
      );

      await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Base64'));
      await tester.pumpAndSettle();

      final imageInput = tester.widget<LayrzImageInput>(find.byType(LayrzImageInput));
      imageInput.onChanged?.call(null);
      await tester.pumpAndSettle();

      expect(changed, isNull);
      expect(find.byType(LayrzImageInput), findsOneWidget);
    });
  });

  group('LayrzDynamicAvatarInput — clear', () {
    guardedTestWidgets('the clear affordance fires onChanged with null and closes the surface', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var callCount = 0;
      LayrzAvatarSource? changed = const LayrzAvatarEmoji('😀');
      await pumpThemedApp(
        tester,
        LayrzDynamicAvatarInput(
          labelText: 'Avatar',
          value: const LayrzAvatarEmoji('😀'),
          onChanged: (c) {
            callCount++;
            changed = c;
          },
        ),
      );

      await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove avatar'));
      await tester.pumpAndSettle();

      expect(callCount, 1);
      expect(changed, isNull);
      expect(find.byType(EditableText), findsNothing);
    });
  });

  group('LayrzDynamicAvatarInput — disabled', () {
    guardedTestWidgets('disabled input never opens the surface', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar', disabled: true));

      await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
      await tester.pumpAndSettle();

      expect(find.text('URL'), findsNothing);
    });
  });

  group('LayrzDynamicAvatarInput — didUpdateWidget', () {
    guardedTestWidgets('updating value externally refreshes the closed-field preview', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));
      expect(find.byWidgetPredicate((widget) => widget is LayrzAvatar), findsNothing);

      await pumpThemedApp(
        tester,
        LayrzDynamicAvatarInput(labelText: 'Avatar', value: const LayrzAvatarEmoji('😀')),
      );

      final avatarFinder = find.byWidgetPredicate(
        (widget) => widget is LayrzAvatar && widget.source == const LayrzAvatarEmoji('😀'),
      );
      expect(avatarFinder, findsOneWidget);
    });

    guardedTestWidgets('swapping a supplied controller for null creates and uses an internal one', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar', controller: controller));
      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));

      expect(tester.takeException(), isNull);
      expect(find.byType(LayrzDynamicAvatarInput), findsOneWidget);
    });

    guardedTestWidgets('swapping a supplied focusNode for null creates and uses an internal one', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar', focusNode: focusNode));
      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));

      expect(tester.takeException(), isNull);
      expect(find.byType(LayrzDynamicAvatarInput), findsOneWidget);
    });
  });

  group('LayrzDynamicAvatarInput — errors', () {
    guardedTestWidgets('displays error text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDynamicAvatarInput(labelText: 'Avatar', errors: const ['Required']),
      );

      expect(find.text('Required'), findsOneWidget);
    });

    guardedTestWidgets('hides error text when hideDetails is true', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDynamicAvatarInput(labelText: 'Avatar', errors: const ['Required'], hideDetails: true),
      );

      expect(find.text('Required'), findsNothing);
    });

    guardedTestWidgets('an errored field still renders its content (no readOnly precedence bug)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDynamicAvatarInput(
          labelText: 'Avatar',
          value: const LayrzAvatarEmoji('😀'),
          errors: const ['Required'],
        ),
      );

      expect(find.text('Required'), findsOneWidget);
      final avatarFinder = find.byWidgetPredicate((widget) => widget is LayrzAvatar);
      expect(avatarFinder, findsWidgets);
    });
  });
}
