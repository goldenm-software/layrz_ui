import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/login/web/login_web_field.dart';

import '../../../helpers/pump_themed.dart';

void main() {
  group('LayrzLoginWebField', () {
    testWidgets('throws UnsupportedError when built', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tokens = LayrzThemeData.light().tokens;

      await pumpThemed(
        tester,
        LayrzLoginWebField(
          kind: LayrzLoginFieldKind.username,
          value: '',
          tokens: tokens,
        ),
      );

      expect(tester.takeException(), isA<UnsupportedError>());
    });

    testWidgets('throws for the password kind too', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tokens = LayrzThemeData.light().tokens;

      await pumpThemed(
        tester,
        LayrzLoginWebField(
          kind: LayrzLoginFieldKind.password,
          value: 'secret',
          labelText: 'Password',
          errors: const ['Required'],
          autofillHints: const ['password'],
          formId: 'login-form',
          disabled: false,
          dense: true,
          tokens: tokens,
        ),
      );

      expect(tester.takeException(), isA<UnsupportedError>());
    });

    testWidgets('throws regardless of viewport (compact)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tokens = LayrzThemeData.light().tokens;

      await pumpThemed(
        tester,
        LayrzLoginWebField(
          kind: LayrzLoginFieldKind.username,
          value: '',
          tokens: tokens,
        ),
      );

      expect(tester.takeException(), isA<UnsupportedError>());
    });
  });
}
