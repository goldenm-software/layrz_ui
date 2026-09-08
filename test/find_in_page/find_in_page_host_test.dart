import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

void main() {
  /// Sets a wide desktop viewport so tests don't accidentally exercise the
  /// compact-only default 800×600 test surface (CLAUDE.md testing traps).
  void setWideViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Forces a frame so a just-registered [ShortcutRegistryEntry] actually
  /// takes effect — mirrors `shortcut_registry_test.dart`'s
  /// `pumpPastRegistration` exactly; see that helper's doc for why a bare
  /// `pump()` right after registration is otherwise a silent no-op.
  Future<void> pumpPastRegistration(WidgetTester tester) async {
    SchedulerBinding.instance.scheduleFrame();
    await tester.pump();
  }

  group('LayrzFindInPageHost', () {
    testWidgets('of/maybeOf resolve the ancestor host reachable from home', (tester) async {
      setWideViewport(tester);
      late BuildContext capturedContext;

      await tester.pumpWidget(
        LayrzApp(
          home: Focus(
            autofocus: true,
            child: Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(LayrzFindInPageHost.maybeOf(capturedContext), isNotNull);
      expect(LayrzFindInPageHost.of(capturedContext), isNotNull);
      expect(find.byType(LayrzFindInPageHost), findsOneWidget);
    });

    testWidgets('maybeOf returns null with no ancestor', (tester) async {
      setWideViewport(tester);
      late BuildContext capturedContext;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      );

      expect(LayrzFindInPageHost.maybeOf(capturedContext), isNull);
    });

    testWidgets('of() asserts with no ancestor', (tester) async {
      setWideViewport(tester);
      late BuildContext capturedContext;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      );

      expect(() => LayrzFindInPageHost.of(capturedContext), throwsAssertionError);
    });

    testWidgets('Ctrl+F toggles find open, showing the find bar', (tester) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        LayrzApp(
          home: Focus(
            autofocus: true,
            child: const Text('mango content'),
          ),
        ),
      );
      await tester.pump();
      await pumpPastRegistration(tester);

      expect(find.byType(LayrzFindBar), findsNothing);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      expect(find.byType(LayrzFindBar), findsOneWidget);

      // Pressing Ctrl+F again toggles it closed.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      expect(find.byType(LayrzFindBar), findsNothing);
    });

    testWidgets('gracefully has no shortcut registered without a LayrzShortcut ancestor', (tester) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        LayrzTheme(
          data: LayrzThemeData.light(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => const LayrzFindInPageHost(child: Text('bare content')),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // No LayrzShortcut ancestor exists in this bare tree, so
      // LayrzFindInPageHostState._registerShortcut must degrade gracefully
      // (maybeOf returns null) rather than throwing during its post-frame
      // callback.
      expect(tester.takeException(), isNull);
      expect(find.byType(LayrzFindInPageHost), findsOneWidget);
    });

    testWidgets('controller.open() shows the find bar even without the keyboard shortcut', (tester) async {
      setWideViewport(tester);
      late BuildContext capturedContext;

      await tester.pumpWidget(
        LayrzApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const Text('mango content');
            },
          ),
        ),
      );
      await tester.pump();

      LayrzFindInPageHost.of(capturedContext).controller.open();
      await tester.pump();

      expect(find.byType(LayrzFindBar), findsOneWidget);

      LayrzFindInPageHost.of(capturedContext).controller.close();
      await tester.pump();

      expect(find.byType(LayrzFindBar), findsNothing);
    });

    testWidgets('excludes the find bar itself from its own search results', (tester) async {
      setWideViewport(tester);
      late BuildContext capturedContext;

      await tester.pumpWidget(
        LayrzApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const Text('mango content match');
            },
          ),
        ),
      );
      await tester.pump();

      final host = LayrzFindInPageHost.of(capturedContext);
      host.controller.open();
      await tester.pump();

      // Type "mango" into the actual find-bar query field — self-exclusion
      // must keep the field's own displayed text from matching itself.
      await tester.enterText(find.byType(LayrzTextInput), 'mango');
      await tester.pump();
      host.controller.searchNow();
      // Let the exclude-rect measurement (scheduled post-frame from the find
      // bar overlay's own build) settle before the final walk it informs.
      await tester.pump();
      host.controller.searchNow();
      await tester.pump();

      // Exactly one match: the real page content. The find bar's own query
      // field (which now also displays "mango") must not also match.
      expect(host.controller.matches.length, 1);
      expect(host.controller.matches.single.label, 'mango content match');

      host.controller.close();
      await tester.pump();
    });

    group('find bar positioning', () {
      testWidgets('pins the bar to the top-right corner, compact rather than full-width', (tester) async {
        setWideViewport(tester);
        late BuildContext capturedContext;

        await tester.pumpWidget(
          LayrzApp(
            home: Builder(
              builder: (context) {
                capturedContext = context;
                return const Text('mango content');
              },
            ),
          ),
        );
        await tester.pump();

        final host = LayrzFindInPageHost.of(capturedContext);
        host.controller.open();
        await tester.pump();
        // Let the exclude-rect measurement's post-frame callback settle so
        // the bar's layout is fully committed before measuring it below.
        await tester.pump();

        final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
        final barRect = tester.getRect(find.byType(LayrzFindBar));

        // Compact: nowhere near the full screen width (the old full-width
        // stretch this replaces would have barRect.width ~= screenSize.width).
        expect(barRect.width, lessThan(screenSize.width * 0.6));
        // Pinned top-right: hugs the top and right edges (within the margin
        // token plus a small tolerance for SafeArea insets), and its left
        // edge sits well clear of the screen's left edge — i.e. it is not
        // spanning the full row.
        expect(barRect.right, greaterThan(screenSize.width - 40));
        expect(barRect.top, lessThan(40));
        expect(barRect.left, greaterThan(screenSize.width * 0.3));

        host.controller.close();
        await tester.pump();
      });

      testWidgets('stays top-right and does not overflow on a narrow (compact) viewport', (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        late BuildContext capturedContext;

        await tester.pumpWidget(
          LayrzApp(
            home: Builder(
              builder: (context) {
                capturedContext = context;
                return const Text('mango content');
              },
            ),
          ),
        );
        await tester.pump();

        final host = LayrzFindInPageHost.of(capturedContext);
        host.controller.open();
        await tester.pump();
        await tester.pump();

        // No overflow/layout exception on a narrow viewport.
        expect(tester.takeException(), isNull);

        final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
        final barRect = tester.getRect(find.byType(LayrzFindBar));

        expect(barRect.right, lessThanOrEqualTo(screenSize.width + 1));
        expect(barRect.left, greaterThanOrEqualTo(0));
        expect(barRect.top, lessThan(40));

        host.controller.close();
        await tester.pump();
      });
    });
  });
}
