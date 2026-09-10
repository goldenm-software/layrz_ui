import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/code/src/code_copy_button.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCodeCopyButton', () {
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    testWidgets('renders without error', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzCodeCopyButton(text: 'print("hi")'));

      expect(find.byType(LayrzCodeCopyButton), findsOneWidget);
    });

    testWidgets('tapping copies text to the clipboard and flips to the copied glyph', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final copied = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );

      await pumpThemed(tester, const LayrzCodeCopyButton(text: 'GET_SENSOR("ignition")'));

      await tester.tap(find.byType(LayrzCodeCopyButton));
      await tester.pump();

      expect(copied, contains('GET_SENSOR("ignition")'));

      // Icon widget swapped internally; a further pump keeps the copied
      // state alive (it only reverts after the 1.5s timer).
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LayrzCodeCopyButton), findsOneWidget);

      // Let the revert timer fire so no pending timers leak into other tests.
      await tester.pump(const Duration(milliseconds: 1100));
    });

    testWidgets('reverts the copied affordance after the transient window elapses', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );

      await pumpThemed(tester, const LayrzCodeCopyButton(text: 'x = 1'));

      final handleBefore = tester.widget<Icon>(find.byType(Icon));
      expect(handleBefore.icon, isNotNull);

      await tester.tap(find.byType(LayrzCodeCopyButton));
      await tester.pump();

      final iconWhileCopied = tester.widget<Icon>(find.byType(Icon));
      expect(iconWhileCopied.icon, isNot(equals(handleBefore.icon)));

      await tester.pump(const Duration(milliseconds: 1600));

      final iconAfterRevert = tester.widget<Icon>(find.byType(Icon));
      expect(iconAfterRevert.icon, equals(handleBefore.icon));
    });

    testWidgets('renders the icon in opaque white by default', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzCodeCopyButton(text: 'a'));

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, equals(const Color(0xFFFFFFFF)));
    });

    testWidgets('honours an explicit color override', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const override = Color(0xFF112233);
      await pumpThemed(tester, const LayrzCodeCopyButton(text: 'a', color: override));

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, equals(override));
    });

    testWidgets('uses tooltipText as the semantics label when provided', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          const LayrzCodeCopyButton(text: 'a', tooltipText: 'Copy snippet'),
        );

        final semanticsNode = tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzCodeCopyButton),
                matching: find.byType(Semantics),
              )
              .first,
        );

        // LayrzButton's Semantics node merges its children with
        // excludeSemantics: true, so the underlying tap gesture does not
        // surface as an explicit SemanticsAction.tap on this node — assert
        // the button flag and label here, and verify tappability
        // functionally in the dedicated clipboard test above.
        expect(
          semanticsNode,
          matchesSemantics(
            label: 'Copy snippet',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('exposes full button semantics with the default label', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzCodeCopyButton(text: 'a'));

        // LayrzButton renders a single, merged Semantics node (button +
        // label + tooltip) — it is the first Semantics descendant of the
        // widget, found here rather than duplicated by this widget.
        final semanticsNode = tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzCodeCopyButton),
                matching: find.byType(Semantics),
              )
              .first,
        );

        expect(
          semanticsNode,
          matchesSemantics(
            label: 'Copy',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
