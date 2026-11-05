import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed.dart';

Color? _checkColor(WidgetTester tester) {
  final icon = tester.widget<Icon>(find.byWidgetPredicate((w) => w is Icon && w.icon == MdiIcons.check));
  return icon.color;
}

void main() {
  group('LayrzCheckboxInput check color', () {
    testWidgets('a dark primary in dark mode gets a white check', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(value: true, onChanged: (_) {}),
        theme: LayrzThemeData.dark(primaryColor: const Color(0xFF001E60)),
      );
      await tester.pumpAndSettle();

      expect(_checkColor(tester), const Color(0xFFFFFFFF));
    });

    testWidgets('a light primary in light mode gets a black check', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(value: true, onChanged: (_) {}),
        theme: LayrzThemeData.light(primaryColor: const Color(0xFFFFEB3B)),
      );
      await tester.pumpAndSettle();

      expect(_checkColor(tester), const Color(0xFF000000));
    });

    testWidgets('an error checkbox uses the danger contrast color', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(value: true, errors: const ['required'], onChanged: (_) {}),
        theme: LayrzThemeData.dark(),
      );
      await tester.pumpAndSettle();

      expect(_checkColor(tester), LayrzTokens.dark().colors.danger.contrastColor);
    });
  });
}
