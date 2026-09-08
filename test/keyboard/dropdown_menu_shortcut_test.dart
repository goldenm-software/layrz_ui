import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';
import '../helpers/pump_themed_app.dart';

void main() {
  /// Sets a wide desktop viewport so tests don't accidentally exercise the
  /// compact-only default 800×600 test surface (CLAUDE.md testing traps).
  void setWideViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Forces a frame so a shortcut [LayrzDropdownMenu] just registered (from
  /// `didChangeDependencies`, during the widget's own mount) actually takes
  /// effect on the *next* simulated keypress.
  ///
  /// See the identically-named helper's doc comment in
  /// `shortcut_registry_test.dart` for the full explanation: registering
  /// against Flutter's [ShortcutRegistry] defers propagating into the live
  /// [ShortcutManager] to a post-frame callback, and nothing about a widget
  /// mounting during [WidgetTester.pumpWidget] schedules a further frame on
  /// its own — [SchedulerBinding.scheduleFrame] must be called explicitly so
  /// the next `pump()` actually flushes it.
  Future<void> pumpPastRegistration(WidgetTester tester) async {
    SchedulerBinding.instance.scheduleFrame();
    await tester.pump();
  }

  group('LayrzDropdownMenu shortcut auto-binding', () {
    testWidgets('Ctrl+S fires onTap without opening the menu', (tester) async {
      setWideViewport(tester);
      var invoked = 0;

      await pumpThemedApp(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Save',
              shortcut: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS},
              onTap: () => invoked++,
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Actions',
            onTap: controller.open,
          ),
        ),
      );
      await pumpPastRegistration(tester);

      // The menu is closed, and its entry is not in the tree.
      expect(find.text('Save'), findsNothing);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
      await tester.pump();

      expect(invoked, 1);
      // Still closed — the shortcut invoked onTap directly, it did not open
      // the menu panel first.
      expect(find.text('Save'), findsNothing);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
    });

    testWidgets('a disabled entry does not bind its shortcut', (tester) async {
      setWideViewport(tester);
      var invoked = 0;

      await pumpThemedApp(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Save',
              enabled: false,
              shortcut: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS},
              onTap: () => invoked++,
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Actions',
            onTap: controller.open,
          ),
        ),
      );
      await pumpPastRegistration(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
      await tester.pump();

      expect(invoked, 0);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
    });

    testWidgets('unmounting the menu deregisters its shortcut', (tester) async {
      setWideViewport(tester);
      var invoked = 0;

      await pumpThemedApp(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Save',
              shortcut: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS},
              onTap: () => invoked++,
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Actions',
            onTap: controller.open,
          ),
        ),
      );
      await pumpPastRegistration(tester);

      // Replace the whole tree, unmounting the menu (and, with it, its
      // LayrzShortcutState registrations via dispose()).
      await tester.pumpWidget(
        LayrzApp(
          debugShowCheckedModeBanner: false,
          home: const SizedBox.shrink(),
        ),
      );
      await pumpPastRegistration(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
      await tester.pump();

      expect(invoked, 0);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
    });

    testWidgets('didUpdateWidget re-syncs bindings when items change', (tester) async {
      setWideViewport(tester);
      var saveInvoked = 0;
      var openInvoked = 0;

      Widget buildMenu(List<LayrzDropdownItem> items) {
        return LayrzDropdownMenu(
          items: items,
          builder: (context, controller) => LayrzButton(
            labelText: 'Actions',
            onTap: controller.open,
          ),
        );
      }

      await pumpThemedApp(
        tester,
        buildMenu([
          LayrzDropdownEntry(
            labelText: 'Save',
            shortcut: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS},
            onTap: () => saveInvoked++,
          ),
        ]),
      );
      await pumpPastRegistration(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
      await tester.pump();
      expect(saveInvoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      // Swap to a new items list binding a different shortcut (Ctrl+O).
      await pumpThemedApp(
        tester,
        buildMenu([
          LayrzDropdownEntry(
            labelText: 'Open',
            shortcut: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyO},
            onTap: () => openInvoked++,
          ),
        ]),
      );
      await pumpPastRegistration(tester);

      // The old Ctrl+S binding no longer fires.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
      await tester.pump();
      expect(saveInvoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      // The new Ctrl+O binding fires.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyO);
      await tester.pump();
      expect(openInvoked, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyO);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
    });

    testWidgets('the formatted shortcut hint still renders when the menu is open', (tester) async {
      setWideViewport(tester);

      // The default test target platform is Android, where LayrzPlatform.isMobile
      // is true and the entry hides its shortcut hint entirely (no reserved space).
      // Override to a desktop platform so the hint actually renders, matching how
      // formatLayrzShortcut/LayrzPlatform.isMobile behave on a real desktop build.
      // Reset before the test body ends (not via addTearDown) — the test harness's
      // own invariant check runs before addTearDown callbacks fire and fails if a
      // foundation debug variable is still overridden at that point.
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      await pumpThemedApp(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Save',
              shortcut: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS},
              onTap: () {},
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Actions',
            onTap: controller.open,
          ),
        ),
      );
      await pumpPastRegistration(tester);

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
      expect(
        find.text(formatLayrzShortcut({LogicalKeyboardKey.control, LogicalKeyboardKey.keyS})),
        findsOneWidget,
      );

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('works without crashing when there is no LayrzShortcut ancestor', (tester) async {
      setWideViewport(tester);
      var invoked = 0;

      // See the desktop-platform-override note in the previous test — the
      // hint is hidden entirely on the default (mobile) test platform. Reset
      // before the test body ends, not via addTearDown (see that same note).
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      // pumpThemed wraps in Localizations + LayrzTheme + Overlay only — no
      // LayrzApp/LayrzShortcut ancestor. LayrzDropdownMenu must degrade
      // gracefully: the shortcut stays purely a display hint (never binds a
      // key), exactly as it behaved before this feature existed.
      await pumpThemed(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Save',
              shortcut: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS},
              onTap: () => invoked++,
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Actions',
            onTap: controller.open,
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
      expect(
        find.text(formatLayrzShortcut({LogicalKeyboardKey.control, LogicalKeyboardKey.keyS})),
        findsOneWidget,
      );
      expect(invoked, 0);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
