import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_mdi_remap/flutter_mdi_remap.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/pickers/src/icon/icon_input.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzIconInput — construction', () {
    guardedTestWidgets('asserts at least one of labelText/hintText is provided', (tester) async {
      expect(
        () => LayrzIconInput(),
        throwsAssertionError,
      );
    });

    guardedTestWidgets('can be created with only hintText', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzIconInput(hintText: 'Pick an icon'));

      expect(find.byType(LayrzIconInput), findsOneWidget);
    });

    guardedTestWidgets('constructing with a non-null value does not throw', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzIconInput(labelText: 'Marker icon', value: 'mdi-account'));

      expect(tester.takeException(), isNull);
      expect(find.byType(LayrzIconInput), findsOneWidget);
    });
  });

  group('LayrzIconInput — rendering', () {
    guardedTestWidgets('renders the label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzIconInput(labelText: 'Marker icon'));

      expect(findButtonLabel('Marker icon'), findsOneWidget);
    });

    guardedTestWidgets('shows hint text when value is null', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzIconInput(labelText: 'Marker icon', hintText: 'Pick an icon'));

      expect(find.text('Pick an icon'), findsWidgets);
    });

    guardedTestWidgets('displays the picked icon name and glyph when value is non-null', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final target = findMdiRemapIconByName('mdi-account')!;
      await pumpThemedApp(tester, LayrzIconInput(labelText: 'Marker icon', value: target.name));

      expect(find.text(target.name), findsOneWidget);
      expect(find.byIcon(target.data), findsWidgets);
    });

    guardedTestWidgets('renders the shape affordance icon', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzIconInput(labelText: 'Marker icon'));

      expect(find.byIcon(MdiIcons.shapeOutline), findsOneWidget);
    });

    guardedTestWidgets('opens with no Save/Cancel footer -- commit-on-tap, unlike the date/month pickers', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzIconInput(labelText: 'Marker icon'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(findButtonLabel('Save'), findsNothing);
      expect(findButtonLabel('Cancel'), findsNothing);
    });

    guardedTestWidgets('the open surface renders exactly one visible title via LayrzPickerDialogHeader', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzIconInput(labelText: 'Preferred marker'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // With no value set, the anchor field's own labelText renders as
      // hintText (via `LayrzInputChrome`) rather than a floating label, so
      // only the surface's own `LayrzPickerDialogHeader` title contributes a
      // "Preferred marker" Text once the surface is open.
      expect(find.text('Preferred marker'), findsOneWidget);
    });
  });

  group('LayrzIconInput — commit on tap', () {
    guardedTestWidgets('picking an icon fires onChanged with its stable mdi- name and closes the drawer (desktop)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? changed;
      await pumpThemedApp(tester, LayrzIconInput(labelText: 'Marker icon', onChanged: (n) => changed = n));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final target = findMdiRemapIconByName('mdi-account')!;
      await tester.enterText(find.byType(EditableText).first, 'account');
      await tester.pump();

      await tester.tap(find.byIcon(target.data).last);
      await tester.pumpAndSettle();

      expect(changed, target.name);
      expect(changed, startsWith('mdi-'));
      // The drawer is gone -- no more search field on screen.
      expect(find.byType(EditableText), findsNothing);
    });

    guardedTestWidgets('picking an icon fires onChanged and closes the sheet (compact/mobile)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? changed;
      await pumpThemedApp(tester, LayrzIconInput(labelText: 'Marker icon', onChanged: (n) => changed = n));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final target = findMdiRemapIconByName('mdi-account')!;
      await tester.enterText(find.byType(EditableText).first, 'account');
      await tester.pump();

      await tester.tap(find.byIcon(target.data).last);
      await tester.pumpAndSettle();

      expect(changed, target.name);
      expect(find.byType(EditableText), findsNothing);
    });

    guardedTestWidgets('the closed field reflects the pick even without an external value update', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzIconInput(labelText: 'Marker icon'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final target = findMdiRemapIconByName('mdi-account')!;
      await tester.enterText(find.byType(EditableText).first, 'account');
      await tester.pump();
      await tester.tap(find.byIcon(target.data).last);
      await tester.pumpAndSettle();

      expect(find.text(target.name), findsOneWidget);
    });

    guardedTestWidgets('disabled input never opens the surface', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzIconInput(labelText: 'Marker icon', disabled: true));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsNothing);
    });
  });

  group('LayrzIconInput — errors', () {
    guardedTestWidgets('displays error text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzIconInput(labelText: 'Marker icon', errors: const ['Required']),
      );

      expect(find.text('Required'), findsOneWidget);
    });

    guardedTestWidgets('hides error text when hideDetails is true', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzIconInput(labelText: 'Marker icon', errors: const ['Required'], hideDetails: true),
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

      final target = findMdiRemapIconByName('mdi-account')!;
      await pumpThemedApp(
        tester,
        LayrzIconInput(labelText: 'Marker icon', value: target.name, errors: const ['Required']),
      );

      expect(find.text(target.name), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
    });
  });
}
