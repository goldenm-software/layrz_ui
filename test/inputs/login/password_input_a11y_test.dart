import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/login/password_input.dart';

import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzPasswordInput - Accessibility', () {
    testWidgets('password field label is exposed to screen readers exactly once at a wide viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzPasswordInput(labelText: 'Password', controller: TextEditingController()),
        );

        expect(find.bySemanticsLabel('Password'), findsOneWidget);

        expect(
          tester.getSemantics(
            find
                .descendant(
                  of: find.byType(LayrzPasswordInput),
                  matching: find.byType(Semantics),
                )
                .first,
          ),
          matchesSemantics(
            label: 'Password',
            hasEnabledState: true,
            isEnabled: true,
            isTextField: true,
            isObscured: true,
            isFocusable: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('password field label is exposed to screen readers exactly once at a compact viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzPasswordInput(labelText: 'Password', controller: TextEditingController()),
        );

        expect(find.bySemanticsLabel('Password'), findsOneWidget);

        expect(
          tester.getSemantics(
            find
                .descendant(
                  of: find.byType(LayrzPasswordInput),
                  matching: find.byType(Semantics),
                )
                .first,
          ),
          matchesSemantics(
            label: 'Password',
            hasEnabledState: true,
            isEnabled: true,
            isTextField: true,
            isObscured: true,
            isFocusable: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the eye toggle is a named, enabled button announcing "Show password" while obscured', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzPasswordInput());

        final toggleNode = tester.getSemantics(find.bySemanticsLabel('Show password'));

        expect(
          toggleNode,
          matchesSemantics(
            label: 'Show password',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the eye toggle relabels to "Hide password" and stays a named, enabled button after reveal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzPasswordInput());

        await tester.tap(find.bySemanticsLabel('Show password'));
        await tester.pumpAndSettle();

        final toggleNode = tester.getSemantics(find.bySemanticsLabel('Hide password'));

        expect(
          toggleNode,
          matchesSemantics(
            label: 'Hide password',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the eye toggle is announced as disabled (no tap action) when the field is disabled', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzPasswordInput(disabled: true));

        final toggleNode = tester.getSemantics(find.bySemanticsLabel('Show password'));

        expect(
          toggleNode,
          matchesSemantics(
            label: 'Show password',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('revealing the password fires a "Password shown" live-region announcement', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzPasswordInput());

        await tester.tap(find.bySemanticsLabel('Show password'));
        await tester.pumpAndSettle();

        final announcementNode = tester.getSemantics(find.bySemanticsLabel('Password shown'));

        expect(
          announcementNode,
          matchesSemantics(label: 'Password shown', isLiveRegion: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('re-hiding the password fires a "Password hidden" live-region announcement', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzPasswordInput());

        await tester.tap(find.bySemanticsLabel('Show password'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Hide password'));
        await tester.pumpAndSettle();

        final announcementNode = tester.getSemantics(find.bySemanticsLabel('Password hidden'));

        expect(
          announcementNode,
          matchesSemantics(label: 'Password hidden', isLiveRegion: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('disabled password field is semantically marked as disabled', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzPasswordInput(
            labelText: 'Disabled password',
            disabled: true,
            controller: TextEditingController(),
          ),
        );

        expect(
          tester.getSemantics(
            find
                .descendant(
                  of: find.byType(LayrzPasswordInput),
                  matching: find.byType(Semantics),
                )
                .first,
          ),
          matchesSemantics(
            label: 'Disabled password',
            hasEnabledState: true,
            isEnabled: false,
            isTextField: true,
            isObscured: true,
            isReadOnly: true,
            isFocusable: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('password field exposes the default l10n label when none is supplied', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzPasswordInput());

        expect(find.bySemanticsLabel('Password'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the strength meter, when shown, is exposed as a labelled container to screen readers', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        final controller = TextEditingController(text: 'Str0ng!Password12');
        await pumpThemed(
          tester,
          LayrzPasswordInput(controller: controller, showStrengthMeter: true),
        );

        expect(find.bySemanticsLabel(RegExp(r'Password Length: \d/4')), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });
}
