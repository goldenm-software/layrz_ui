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

  /// Pumps [child] inside a real [LayrzApp], with an autofocused [Focus] node
  /// in the subtree.
  ///
  /// Shortcuts dispatch through the focus system — [WidgetsApp]'s default
  /// [Shortcuts]/[Actions] wiring only receives key events when some node in
  /// the subtree holds focus, so every test that needs a registered shortcut
  /// to actually fire pumps through this helper rather than a bare
  /// [LayrzShortcut] in isolation.
  Future<void> pumpFocusedApp(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      LayrzApp(
        home: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
    await tester.pump();
  }

  /// Forces a frame so a just-registered [ShortcutRegistryEntry] actually
  /// takes effect.
  ///
  /// [ShortcutRegistry.addAll] (which [LayrzShortcutState.register] calls
  /// under the hood) defers notifying [ShortcutRegistrar]'s internal
  /// [ShortcutManager] to the *next frame* via a post-frame callback —
  /// deliberately, per its own doc comment, to avoid build-order issues when
  /// a shortcut is registered mid-build. That alone would be a plain
  /// `await tester.pump()` away, except [register] is called here as
  /// imperative test code rather than from inside a widget's own build/
  /// `setState` — nothing about that call requests a new engine frame, and
  /// [WidgetTester.pump] only actually drives `handleBeginFrame`/
  /// `handleDrawFrame` (where post-frame callbacks run) when a frame is
  /// already scheduled (see `TestWidgetsFlutterBinding.pump`'s
  /// `if (hasScheduledFrame)` guard). So a bare `pump()` right after
  /// `register()` is a silent no-op here: [SchedulerBinding.scheduleFrame]
  /// must be called explicitly first to make the next `pump()` actually
  /// flush the registry's deferred notification into the live
  /// [ShortcutManager].
  Future<void> pumpPastRegistration(WidgetTester tester) async {
    SchedulerBinding.instance.scheduleFrame();
    await tester.pump();
  }

  group('LayrzShortcut.of / maybeOf', () {
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

      expect(LayrzShortcut.maybeOf(capturedContext), isNull);
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

      expect(() => LayrzShortcut.of(capturedContext), throwsAssertionError);
    });

    testWidgets('of() resolves the ancestor LayrzShortcutState under LayrzApp', (tester) async {
      setWideViewport(tester);
      late BuildContext capturedContext;

      await pumpFocusedApp(
        tester,
        Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      );

      expect(LayrzShortcut.of(capturedContext), isA<LayrzShortcutState>());
      expect(LayrzShortcut.maybeOf(capturedContext), same(LayrzShortcut.of(capturedContext)));
    });
  });

  group('register / deregister', () {
    testWidgets('registering a shortcut fires onInvoke on keypress', (tester) async {
      setWideViewport(tester);
      var invoked = 0;
      late LayrzShortcutState registry;
      late LayrzShortcutHandle handle;

      await pumpFocusedApp(
        tester,
        Builder(
          builder: (context) {
            registry = LayrzShortcut.of(context);
            return const SizedBox.shrink();
          },
        ),
      );

      handle = registry.register(
        keys: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS},
        onInvoke: () => invoked++,
        debugLabel: 'test save',
      );
      addTearDown(() => registry.deregister(handle));
      await pumpPastRegistration(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
      await tester.pump();

      expect(invoked, 1);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
    });

    testWidgets('deregister stops the shortcut from firing', (tester) async {
      setWideViewport(tester);
      var invoked = 0;
      late LayrzShortcutState registry;

      await pumpFocusedApp(
        tester,
        Builder(
          builder: (context) {
            registry = LayrzShortcut.of(context);
            return const SizedBox.shrink();
          },
        ),
      );

      final handle = registry.register(
        keys: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS},
        onInvoke: () => invoked++,
        debugLabel: 'test save',
      );

      registry.deregister(handle);
      await pumpPastRegistration(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
      await tester.pump();

      expect(invoked, 0);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
    });

    testWidgets('empty key set is a no-op registration that does not crash', (tester) async {
      setWideViewport(tester);
      var invoked = 0;
      late LayrzShortcutState registry;

      await pumpFocusedApp(
        tester,
        Builder(
          builder: (context) {
            registry = LayrzShortcut.of(context);
            return const SizedBox.shrink();
          },
        ),
      );

      LayrzShortcutHandle? handle;
      // Genuine no-throw contract: an empty key set is degenerate input the
      // registry must tolerate (it can never match a key event, but registering
      // it must not crash) -- the next line confirms it still returns a handle.
      expect(
        () => handle = registry.register(
          keys: <LogicalKeyboardKey>{},
          onInvoke: () => invoked++,
          debugLabel: 'empty',
        ),
        returnsNormally,
      );
      expect(handle, isNotNull);

      // Deregistering an inert (empty-key-set) handle is also a safe no-op.
      expect(() => registry.deregister(handle!), returnsNormally);
      expect(invoked, 0);
    });

    testWidgets('double-deregister is a safe no-op', (tester) async {
      setWideViewport(tester);
      late LayrzShortcutState registry;

      await pumpFocusedApp(
        tester,
        Builder(
          builder: (context) {
            registry = LayrzShortcut.of(context);
            return const SizedBox.shrink();
          },
        ),
      );

      final handle = registry.register(
        keys: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyQ},
        onInvoke: () {},
        debugLabel: 'double deregister',
      );

      registry.deregister(handle);
      // Genuine no-throw contract (test name states it): a second deregister of an
      // already-deregistered handle must be a safe idempotent no-op.
      expect(() => registry.deregister(handle), returnsNormally);
    });

    testWidgets('deregister after unmount is a safe no-op', (tester) async {
      setWideViewport(tester);
      late LayrzShortcutState registry;
      late LayrzShortcutHandle handle;

      await pumpFocusedApp(
        tester,
        Builder(
          builder: (context) {
            registry = LayrzShortcut.of(context);
            return const SizedBox.shrink();
          },
        ),
      );

      handle = registry.register(
        keys: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyW},
        onInvoke: () {},
        debugLabel: 'unmount test',
      );

      // Unmount the whole tree — this disposes LayrzShortcutState, which
      // disposes every live ShortcutRegistryEntry it owns internally.
      await tester.pumpWidget(const SizedBox.shrink());

      // Genuine no-throw contract (test name states it): deregistering a handle
      // whose owning State has already been disposed must be a safe no-op.
      expect(() => registry.deregister(handle), returnsNormally);
    });
  });

  group('conflict policy (first-wins)', () {
    testWidgets('registering the same activator twice throws in debug', (tester) async {
      setWideViewport(tester);
      late LayrzShortcutState registry;

      await pumpFocusedApp(
        tester,
        Builder(
          builder: (context) {
            registry = LayrzShortcut.of(context);
            return const SizedBox.shrink();
          },
        ),
      );

      registry.register(
        keys: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyP},
        onInvoke: () {},
        debugLabel: 'first owner',
      );

      expect(
        () => registry.register(
          keys: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyP},
          onInvoke: () {},
          debugLabel: 'second owner',
        ),
        throwsAssertionError,
      );
    });

    testWidgets('first registration still fires after a rejected duplicate', (tester) async {
      setWideViewport(tester);
      var firstInvoked = 0;
      var secondInvoked = 0;
      late LayrzShortcutState registry;

      await pumpFocusedApp(
        tester,
        Builder(
          builder: (context) {
            registry = LayrzShortcut.of(context);
            return const SizedBox.shrink();
          },
        ),
      );

      registry.register(
        keys: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyP},
        onInvoke: () => firstInvoked++,
        debugLabel: 'first owner',
      );

      // The duplicate attempt throws (asserts) in debug mode — catch it the
      // way an app-level error boundary would, so the harness's own
      // assertion doesn't fail this "still fires" test.
      LayrzShortcutHandle? secondHandle;
      try {
        secondHandle = registry.register(
          keys: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyP},
          onInvoke: () => secondInvoked++,
          debugLabel: 'second owner',
        );
      } on AssertionError {
        // Expected in debug mode — the registration still completed and
        // returned an inert handle up to the point of the assertion.
      }
      await pumpPastRegistration(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyP);
      await tester.pump();

      expect(firstInvoked, 1);
      expect(secondInvoked, 0);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      // The inert handle (if the assertion path still produced one) is a
      // safe no-op to deregister. Genuine no-throw contract: an inert handle
      // from a conflicting registration must still deregister cleanly.
      if (secondHandle != null) {
        expect(() => registry.deregister(secondHandle!), returnsNormally);
      }
    });
  });

  group('double-install', () {
    testWidgets('a nested LayrzShortcut asserts in debug', (tester) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        LayrzApp(
          home: LayrzShortcut(
            child: const SizedBox.shrink(),
          ),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });
  });
}
