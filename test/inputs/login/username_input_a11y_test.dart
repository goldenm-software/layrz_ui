import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/login/username_input.dart';

import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzUsernameInput - Accessibility', () {
    testWidgets('username field label is exposed to screen readers exactly once at a wide viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzUsernameInput(labelText: 'Username', controller: TextEditingController()),
        );

        expect(find.bySemanticsLabel('Username'), findsOneWidget);

        expect(
          tester.getSemantics(
            find
                .descendant(
                  of: find.byType(LayrzUsernameInput),
                  matching: find.byType(Semantics),
                )
                .first,
          ),
          matchesSemantics(
            label: 'Username',
            hasEnabledState: true,
            isEnabled: true,
            isTextField: true,
            isFocusable: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('username field label is exposed to screen readers exactly once at a compact viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzUsernameInput(labelText: 'Username', controller: TextEditingController()),
        );

        expect(find.bySemanticsLabel('Username'), findsOneWidget);

        expect(
          tester.getSemantics(
            find
                .descendant(
                  of: find.byType(LayrzUsernameInput),
                  matching: find.byType(Semantics),
                )
                .first,
          ),
          matchesSemantics(
            label: 'Username',
            hasEnabledState: true,
            isEnabled: true,
            isTextField: true,
            isFocusable: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('disabled username field is semantically marked as disabled', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzUsernameInput(
            labelText: 'Disabled username',
            disabled: true,
            controller: TextEditingController(),
          ),
        );

        expect(
          tester.getSemantics(
            find
                .descendant(
                  of: find.byType(LayrzUsernameInput),
                  matching: find.byType(Semantics),
                )
                .first,
          ),
          matchesSemantics(
            label: 'Disabled username',
            hasEnabledState: true,
            isEnabled: false,
            isTextField: true,
            isReadOnly: true,
            isFocusable: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('username field exposes the default l10n label when none is supplied', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzUsernameInput());

        expect(find.bySemanticsLabel('Username'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });
}
