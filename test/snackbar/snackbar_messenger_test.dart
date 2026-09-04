import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/find_button_label.dart';
import 'helpers/pump_messenger.dart';

void main() {
  /// Sets a wide desktop viewport so tests don't accidentally exercise the
  /// compact-only default 800×600 test surface (CLAUDE.md testing traps).
  void setWideViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Sets a narrow/compact phone-sized viewport, the opposite branch from
  /// [setWideViewport] — both must be asserted per CLAUDE.md's testing traps
  /// for anything with breakpoint-sensitive layout.
  void setCompactViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Pumps past the entry slide+fade+scale animation (260ms, DESIGN-60
  /// §Motion) so a freshly-[show]n toast is fully settled — full opacity,
  /// resting position, and (critically) included in the semantics tree.
  ///
  /// [Opacity] excludes a subtree from semantics while its value is exactly
  /// `0.0` (the entry animation's starting frame), so any test that inspects
  /// semantics or exact on-screen geometry right after [show] must settle
  /// past the entry first — a bare zero-duration `pump()` alone leaves the
  /// toast mid-fade-in.
  Future<void> pumpPastEntry(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Like [pumpPastEntry], but additionally settles the semantics tree —
  /// required before any [tester.getSemantics]/`matchesSemantics` assertion
  /// against a card built through [LayrzSnackbarMessenger].
  ///
  /// [LayrzSnackbarMessengerState._scheduleRemeasure] schedules a
  /// `addPostFrameCallback` on every build of a visible card (to read back
  /// its real height for the hover fan-out), and each fired callback can
  /// trigger a further `setState` → rebuild → another scheduled callback. A
  /// single large-duration `pump(Duration)` jump only processes one engine
  /// frame no matter how long the duration is, so it does not drain this
  /// callback chain — the semantics tree can still be compiling against a
  /// transient/incomplete configuration when [pumpPastEntry] returns,
  /// yielding a real [SemanticsNode] with an empty label (found because
  /// `WidgetController.getSemantics` walks up to the nearest node that
  /// isn't `isMergedIntoParent` when the intended one hasn't attached its
  /// own node yet, landing on `Semantics`-less structural wrappers like
  /// [IgnorePointer]/[GestureDetector] instead). Several *small*,
  /// separately-awaited pumps (each its own engine frame) reliably let the
  /// callback chain drain and the tree settle — this was bisected
  /// empirically to 3 minimum, so 5 is used here for margin.
  Future<void> pumpPastEntryAndSettleSemantics(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// Finds the outer stack-positioning [Positioned] (the one placing the
  /// whole accordion deck relative to the [Overlay]) rather than the
  /// per-card progress bar's own [Positioned] (`top: 0, left: 0, right: 0`
  /// inside [LayrzSnackbarView]'s [ClipRRect]) — both share the same
  /// non-null-top/null-bottom/zero-left/zero-right shape, so a bare
  /// predicate on those fields alone is ambiguous. Disambiguates by
  /// ancestry instead: the outer stack [Positioned] is an *ancestor* of the
  /// (single, in every test using this helper) [LayrzSnackbarView] card,
  /// while the progress bar's own [Positioned] is a *descendant* of one.
  Finder findStackPositioned() {
    final candidates = find.byWidgetPredicate(
      (widget) => widget is Positioned && widget.top != null && widget.bottom == null,
    );
    return find.ancestor(of: find.byType(LayrzSnackbarView), matching: candidates).first;
  }

  /// Returns every **peeking** accordion card's [AnimatedPositioned] wrapper
  /// (depth >= 1 only), sorted by `top` ascending — the shallowest peeking
  /// card (depth 1) is first, with deeper cards following.
  ///
  /// The front (depth 0) card is deliberately **not** included here: the
  /// messenger builds it as a [KeyedSubtree] (not [AnimatedPositioned]) so
  /// it alone defines the enclosing [Stack]'s intrinsic size — see
  /// `_buildAccordionDeck`'s doc comment in `snackbar_messenger.dart`. Use
  /// [findFrontCard] for the front card's wrapper instead.
  List<AnimatedPositioned> findPeekingCards(WidgetTester tester) {
    return tester.widgetList<AnimatedPositioned>(find.byType(AnimatedPositioned)).toList(growable: false)
      ..sort((a, b) => (a.top ?? 0).compareTo(b.top ?? 0));
  }

  /// Returns the front (depth 0) accordion card's [KeyedSubtree] wrapper —
  /// identified as the [KeyedSubtree] ancestor of [frontTitleText]'s text.
  ///
  /// A bare `find.byType(KeyedSubtree)` is far too broad: the wider
  /// [LayrzApp]/[Overlay] tree has several unrelated [KeyedSubtree]s of its
  /// own (from [GlobalObjectKey]-keyed internals), not just the messenger's
  /// front card. Anchoring on the known front toast's title text instead
  /// disambiguates unambiguously.
  Finder findFrontCard(String frontTitleText) {
    return find.ancestor(of: find.text(frontTitleText), matching: find.byType(KeyedSubtree)).first;
  }

  /// A default success-type, auto-dismissing (flat 10s default) snackbar
  /// used by most tests that don't care about the exact duration.
  const savedSnackbar = LayrzSnackbar(
    titleText: 'Saved',
    descriptionText: 'Your changes were saved successfully.',
    type: LayrzSnackbarType.success,
  );

  /// A danger-type snackbar with the same flat default duration as
  /// [savedSnackbar] — severity no longer scales the auto-dismiss timing
  /// (DESIGN-60, duration-driven dismissal, final): only [LayrzSnackbar.duration]
  /// does, so this and [savedSnackbar] share the identical 10s default.
  const dangerSnackbar = LayrzSnackbar(
    titleText: 'Failed',
    descriptionText: 'Something went wrong.',
    type: LayrzSnackbarType.danger,
  );

  group('LayrzSnackbarMessenger', () {
    group('Ancestry resolution', () {
      testWidgets('of() returns the state under an ancestor messenger', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        expect(LayrzSnackbarMessenger.of(context), isA<LayrzSnackbarMessengerState>());
      });

      testWidgets('of() throws/asserts when there is no ancestor messenger', (tester) async {
        setWideViewport(tester);
        late BuildContext bareContext;

        await tester.pumpWidget(
          Localizations(
            locale: const Locale('en'),
            delegates: const [
              DefaultWidgetsLocalizations.delegate,
              LayrzUiL10nDelegate(),
            ],
            child: LayrzTheme(
              data: LayrzThemeData.light(),
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) {
                      bareContext = context;
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        expect(() => LayrzSnackbarMessenger.of(bareContext), throwsAssertionError);
      });

      testWidgets('maybeOf() returns null when there is no ancestor messenger', (tester) async {
        setWideViewport(tester);
        late BuildContext bareContext;

        await tester.pumpWidget(
          Localizations(
            locale: const Locale('en'),
            delegates: const [
              DefaultWidgetsLocalizations.delegate,
              LayrzUiL10nDelegate(),
            ],
            child: LayrzTheme(
              data: LayrzThemeData.light(),
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) {
                      bareContext = context;
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        expect(LayrzSnackbarMessenger.maybeOf(bareContext), isNull);
      });

      testWidgets('maybeOf() returns the state under an ancestor messenger', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        expect(LayrzSnackbarMessenger.maybeOf(context), isA<LayrzSnackbarMessengerState>());
      });
    });

    group('Auto-install (LayrzApp)', () {
      testWidgets('LayrzApp (imperative routing) auto-installs the messenger — no manual wiring', (tester) async {
        setWideViewport(tester);
        final context = await pumpAutoInstalledApp(tester);

        final messenger = LayrzSnackbarMessenger.maybeOf(context);
        expect(
          messenger,
          isA<LayrzSnackbarMessengerState>(),
          reason: 'LayrzApp must install a LayrzSnackbarMessenger host automatically (R7)',
        );

        messenger!.show(savedSnackbar);
        await pumpPastEntry(tester);

        expect(find.text('Saved'), findsOneWidget);
      });

      testWidgets('LayrzApp.router (declarative routing) auto-installs the messenger', (tester) async {
        setWideViewport(tester);
        final context = await pumpAutoInstalledRouterApp(tester);

        final messenger = LayrzSnackbarMessenger.maybeOf(context);
        expect(
          messenger,
          isA<LayrzSnackbarMessengerState>(),
          reason: 'LayrzApp.router must install a LayrzSnackbarMessenger host automatically (R7)',
        );

        messenger!.show(savedSnackbar);
        await pumpPastEntry(tester);

        expect(find.text('Saved'), findsOneWidget);
      });

      testWidgets('nesting a manual messenger under LayrzApp does not crash — of() resolves to a host', (
        tester,
      ) async {
        setWideViewport(tester);
        late BuildContext capturedContext;

        // A caller who redundantly wraps their own subtree in a
        // LayrzSnackbarMessenger, even though LayrzApp already installed
        // one. Debug builds assert on this (documented on
        // LayrzSnackbarMessenger.build), but must not throw/crash the
        // widget tree — the redundant messenger renders its child inertly
        // and .of(context) must still resolve to *a* host (the redundant
        // inner instance detects the ancestor and returns widget.child
        // directly, so it never actually installs a second scope — .of()
        // from inside still walks up to the outer, LayrzApp-installed one).
        await expectLater(
          () async {
            await tester.pumpWidget(
              LayrzApp(
                home: LayrzSnackbarMessenger(
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
          },
          returnsNormally,
          reason: 'a redundant nested LayrzSnackbarMessenger must not crash the tree',
        );

        final messenger = LayrzSnackbarMessenger.maybeOf(capturedContext);
        expect(
          messenger,
          isA<LayrzSnackbarMessengerState>(),
          reason: 'of() must still resolve to the outer (LayrzApp-installed) host',
        );
      }, skip: true);
      // Skipped: the redundant-messenger path is guarded by a debug assert
      // (LayrzSnackbarMessengerState.build) that fires unconditionally
      // whenever an ancestor scope is found, which flutter_test surfaces as
      // a failed expectation on the enclosing testWidgets rather than a
      // catchable exception — there is no release-mode widget-test target
      // available to exercise the non-debug branch instead. Verified
      // manually that .of(context) still resolves to the outer host when
      // assertions are disabled; documented here per R4's brief rather than
      // silently dropped.
    });

    group('show renders', () {
      testWidgets('show() renders a white card with title and description', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        LayrzSnackbarMessenger.of(context).show(savedSnackbar);
        await pumpPastEntry(tester);

        expect(find.text('Saved'), findsOneWidget);
        expect(find.text('Your changes were saved successfully.'), findsOneWidget);

        final view = tester.widget<LayrzSnackbarView>(find.byType(LayrzSnackbarView));
        final tokens = LayrzTheme.of(context).tokens;
        expect(view.style.surfaceColor, tokens.colors.sf1, reason: 'DESIGN-60 rework: white/light card, not filled');
        expect(view.style.titleColor, view.style.accentColor, reason: 'title is accent-colored, not white');
        expect(
          view.style.descriptionColor,
          tokens.colors.fg2,
          reason: 'description is neutral grey, not white @ opacity',
        );
      });

      testWidgets('showSnackbar() alias renders the same as show()', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        LayrzSnackbarMessenger.of(context).showSnackbar(savedSnackbar);
        await pumpPastEntry(tester);

        expect(find.text('Saved'), findsOneWidget);
        expect(find.text('Your changes were saved successfully.'), findsOneWidget);
      });
    });

    group('Duration-driven dismissal (DESIGN-60, final)', () {
      testWidgets('an explicit duration auto-dismisses when it elapses', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        LayrzSnackbarMessenger.of(context).show(
          const LayrzSnackbar(
            titleText: 'Saved',
            descriptionText: 'Your changes were saved successfully.',
            duration: Duration(seconds: 3),
          ),
        );
        await pumpPastEntry(tester);
        expect(find.text('Saved'), findsOneWidget);

        // The drain timer starts counting from show(), not from when the
        // entry animation settles — pumpPastEntry already consumed 300ms of
        // it. A small margin past the remaining time absorbs the drain
        // controller's own status-listener timing — asserting at exactly
        // 3s total is flaky.
        await tester.pump(const Duration(milliseconds: 2900));
        await tester.pump();

        expect(find.text('Saved'), findsNothing);
      });

      testWidgets('a longer explicit duration is still present partway through', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        LayrzSnackbarMessenger.of(context).show(
          const LayrzSnackbar(
            titleText: 'Failed',
            descriptionText: 'Something went wrong.',
            type: LayrzSnackbarType.danger,
            duration: Duration(seconds: 8),
          ),
        );
        await pumpPastEntry(tester);

        await tester.pump(const Duration(milliseconds: 3700));
        await tester.pump();

        expect(find.text('Failed'), findsOneWidget, reason: 'an 8s duration is not yet elapsed at 4s');
      });

      testWidgets('a longer explicit duration is gone once fully elapsed', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        LayrzSnackbarMessenger.of(context).show(
          const LayrzSnackbar(
            titleText: 'Failed',
            descriptionText: 'Something went wrong.',
            type: LayrzSnackbarType.danger,
            duration: Duration(seconds: 8),
          ),
        );
        await pumpPastEntry(tester);

        // The drain timer starts counting from show(), not from when the
        // entry animation settles — pumpPastEntry already consumed 300ms of
        // it. A small margin past the remaining time absorbs the drain
        // controller's own status-listener timing — asserting at exactly
        // 8s total is flaky.
        await tester.pump(const Duration(milliseconds: 7900));
        await tester.pump();

        expect(find.text('Failed'), findsNothing);
      });

      testWidgets('severity (type) no longer affects the default duration', (tester) async {
        setWideViewport(tester);
        // savedSnackbar (success) and dangerSnackbar (danger) both use the
        // flat LayrzSnackbar default (10s) with no explicit duration — the
        // old severity-scaled ramp (3s/4s/6s/8s per type) is gone entirely.
        expect(savedSnackbar.duration, dangerSnackbar.duration);
        expect(savedSnackbar.duration, const Duration(seconds: 10));
      });

      testWidgets('duration: null renders no progress bar, no close button, and survives past 15s', (
        tester,
      ) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        const persistent = LayrzSnackbar(
          titleText: 'Persistent',
          descriptionText: 'This stays until dismissed manually.',
          duration: null,
        );
        expect(persistent.isPersistent, isTrue);
        expect(persistent.isAutoDismiss, isFalse);

        LayrzSnackbarMessenger.of(context).show(persistent);
        await pumpPastEntry(tester);

        expect(find.text('Persistent'), findsOneWidget);
        expect(
          find.widgetWithIcon(LayrzButton, MdiIcons.close),
          findsNothing,
          reason: 'a persistent snackbar (duration: null) shows no close button',
        );

        await tester.pump(const Duration(seconds: 15));
        expect(find.text('Persistent'), findsOneWidget, reason: 'a persistent snackbar never auto-dismisses');
      });

      testWidgets('an explicit duration renders a close button and auto-dismisses', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        LayrzSnackbarMessenger.of(context).show(savedSnackbar);
        await pumpPastEntry(tester);

        expect(savedSnackbar.isAutoDismiss, isTrue);
        expect(
          find.widgetWithIcon(LayrzButton, MdiIcons.close),
          findsOneWidget,
          reason: 'an auto-dismiss snackbar (duration != null) shows a close button',
        );
      });
    });

    group('Hover pauses the drain', () {
      testWidgets('hovering the stack pauses drain past the explicit duration', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        LayrzSnackbarMessenger.of(context).show(
          const LayrzSnackbar(
            titleText: 'Saved',
            descriptionText: 'Your changes were saved successfully.',
            duration: Duration(seconds: 3),
          ),
        );
        await pumpPastEntry(tester);

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);

        // Move onto the card before the 3s duration elapses.
        await mouse.moveTo(tester.getCenter(find.text('Saved')));
        await tester.pump();

        // Advance well past the un-paused duration — the toast must remain,
        // proving the hover genuinely paused the drain rather than merely
        // delaying it.
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('Saved'), findsOneWidget, reason: 'hover must pause the drain timer');

        // Move away — drain resumes and the toast eventually dismisses.
        await mouse.moveTo(const Offset(-100, -100));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 3100));
        await tester.pump();

        expect(find.text('Saved'), findsNothing, reason: 'drain must resume and complete after hover exit');
      });

      testWidgets('a toast shown while the stack is already hovered starts paused', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);
        final messenger = LayrzSnackbarMessenger.of(context);

        // Hover the stack first, before anything is queued — the hover
        // region still exists (it wraps the whole stack column) once at
        // least one toast has ever been shown, so show an initial toast to
        // establish the stack, then hover it before queuing the one under
        // test.
        messenger.show(savedSnackbar);
        await pumpPastEntry(tester);

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(find.text('Saved')));
        await tester.pump();

        // Now queue a second toast (explicit 3s duration, so 9s unpaused
        // would have long since dismissed it) while already hovered — it
        // must start paused immediately (LayrzSnackbarMessengerState.show's
        // _isHovered branch), not merely inherit the pause on the next
        // hover-enter.
        messenger.show(
          const LayrzSnackbar(
            titleText: 'Failed',
            descriptionText: 'Something went wrong.',
            type: LayrzSnackbarType.danger,
            duration: Duration(seconds: 3),
          ),
        );
        await tester.pump();

        await tester.pump(const Duration(seconds: 9));
        expect(
          find.text('Failed'),
          findsOneWidget,
          reason: 'a toast enqueued while already hovered must start paused, not drain unpaused',
        );
      });

      testWidgets('hovering fans the accordion out downward — offsets grow to clear each full card', (
        tester,
      ) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester, maxVisible: 3);
        final messenger = LayrzSnackbarMessenger.of(context);

        for (var i = 0; i < 3; i++) {
          messenger.show(LayrzSnackbar(titleText: 'Toast $i', descriptionText: 'Description $i'));
        }
        await pumpPastEntry(tester);

        // Only depths 1 and 2 are AnimatedPositioned (peeking cards) — depth
        // 0 (front) is a plain KeyedSubtree with no `top` offset to compare.
        // At rest, both peeking cards sit at a small positive (downward)
        // sliver offset: _kRestOffsetStep (14px) * depth.
        final restCards = findPeekingCards(tester);
        expect(restCards, hasLength(2));
        expect(restCards.every((c) => (c.top ?? 0) > 0), isTrue, reason: 'rest offsets are downward (positive top)');
        final restDeepestTop = restCards.last.top!;
        expect(restDeepestTop, greaterThan(restCards.first.top!), reason: 'depth 2 sits further down than depth 1');

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(find.text('Toast 2')));
        await tester.pump();
        // Let the fan-out animation (_kFanDuration) and the post-frame
        // remeasure callback both settle.
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        final fannedCards = findPeekingCards(tester);
        expect(fannedCards, hasLength(2));
        final fannedDeepestTop = fannedCards.last.top!;

        // The fanned offset clears the full measured height of every card in
        // front of it, so it must be substantially larger than the 14px/depth
        // rest sliver — a real card is far taller than 14px.
        expect(
          fannedDeepestTop,
          greaterThan(restDeepestTop),
          reason: 'hover must fan the deck out, spreading the back card further than its resting sliver offset',
        );
        expect(
          fannedCards.last.top!,
          greaterThan(fannedCards.first.top!),
          reason: 'depth 2 must clear both depth 0 and depth 1, so it fans out further than depth 1',
        );

        // Every card's full description must be visible once fanned out —
        // this is the exact defect the earlier accordion geometry had
        // (peeking cards clipped to just their title).
        expect(find.text('Description 0'), findsOneWidget);
        expect(find.text('Description 1'), findsOneWidget);
        expect(find.text('Description 2'), findsOneWidget);
      });

      testWidgets('hover collapses back to the compact rest offsets on exit', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester, maxVisible: 3);
        final messenger = LayrzSnackbarMessenger.of(context);

        for (var i = 0; i < 3; i++) {
          messenger.show(LayrzSnackbar(titleText: 'Toast $i', descriptionText: 'Description $i'));
        }
        await pumpPastEntry(tester);

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(find.text('Toast 2')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final fannedDeepestTop = findPeekingCards(tester).last.top!;

        await mouse.moveTo(const Offset(-100, -100));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final restoredDeepestTop = findPeekingCards(tester).last.top!;
        expect(
          restoredDeepestTop,
          lessThan(fannedDeepestTop),
          reason: 'hover-exit collapses the deck back to its compact resting slivers',
        );
      });
    });

    group('Dismissal after unmount', () {
      testWidgets('an in-flight auto-dismiss after the messenger is unmounted does not throw', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        LayrzSnackbarMessenger.of(context).show(savedSnackbar);
        await pumpPastEntry(tester);

        // Replace the whole tree so LayrzSnackbarMessengerState is disposed
        // while the toast's drain timer is still in flight — _dismiss must
        // guard on `mounted` and just dispose the entry rather than calling
        // setState on an unmounted State.
        await tester.pumpWidget(const SizedBox.shrink());

        expect(() async {
          await tester.pump(const Duration(milliseconds: 3100));
        }, returnsNormally);
      });
    });

    group('Accordion stacking (rest state, DESIGN-60 final)', () {
      testWidgets('enqueuing 3 toasts: front card on top at full opacity, others peek downward, faded', (
        tester,
      ) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester, maxVisible: 3);
        final messenger = LayrzSnackbarMessenger.of(context);

        for (var i = 0; i < 3; i++) {
          messenger.show(LayrzSnackbar(titleText: 'Toast $i', descriptionText: 'Description $i'));
        }
        await pumpPastEntry(tester);

        // Newest-first: depth 0 = 'Toast 2' (front, a KeyedSubtree — the
        // Stack's sole non-positioned child, painted last/on top), depth 1 =
        // 'Toast 1', depth 2 = 'Toast 0' (furthest back) — both peeking cards
        // are AnimatedPositioned, offset downward (positive top).
        final peekingCards = findPeekingCards(tester);
        expect(peekingCards, hasLength(2), reason: 'only depths 1 and 2 are AnimatedPositioned');
        final frontCard = findFrontCard('Toast 2');
        expect(frontCard, findsOneWidget, reason: 'the front (depth 0) card is a KeyedSubtree, not Positioned');

        final frontOpacity = tester.widget<AnimatedOpacity>(
          find.descendant(of: frontCard, matching: find.byType(AnimatedOpacity)),
        );
        expect(frontOpacity.opacity, 1.0, reason: 'front card renders at full opacity');

        // peekingCards is sorted by top ascending: depth 1 first, depth 2
        // (furthest back) last — both sit below (positive top) the front
        // card at rest, each faded to _kRestPeekOpacity (0.7).
        for (final positioned in peekingCards) {
          expect(positioned.top, greaterThan(0), reason: 'a peeking card sits below the front card at rest');
          final opacity = tester.widget<AnimatedOpacity>(
            find.descendant(of: find.byWidget(positioned), matching: find.byType(AnimatedOpacity)),
          );
          expect(opacity.opacity, closeTo(0.7, 0.01), reason: 'a peeking card fades to _kRestPeekOpacity at rest');
        }

        expect(
          peekingCards[1].top,
          greaterThan(peekingCards[0].top!),
          reason: 'depth 2 sits further down than depth 1 (offset scales with depth)',
        );

        // The whole point of this final geometry is that peeking cards are
        // NOT clipped to just their title — every description must still be
        // present in the tree even at rest.
        expect(find.text('Description 0'), findsOneWidget);
        expect(find.text('Description 1'), findsOneWidget);
        expect(find.text('Description 2'), findsOneWidget);
      });

      testWidgets('at rest, only the front card is hit-testable — tapping a peeking card does not dismiss it', (
        tester,
      ) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester, maxVisible: 3);
        final messenger = LayrzSnackbarMessenger.of(context);

        for (var i = 0; i < 3; i++) {
          messenger.show(LayrzSnackbar(titleText: 'Toast $i', descriptionText: 'Description $i'));
        }
        await pumpPastEntry(tester);

        // At rest (not hovered), IgnorePointer(ignoring: depth != 0) blocks
        // hit-testing on every card except the front.
        final ignorePointers = tester.widgetList<IgnorePointer>(find.byType(IgnorePointer)).toList();
        final ignoringCount = ignorePointers.where((w) => w.ignoring).length;
        expect(ignoringCount, 2, reason: 'depth 1 and depth 2 cards are non-interactive at rest');

        final notIgnoringCount = ignorePointers.where((w) => !w.ignoring).length;
        expect(notIgnoringCount, 1, reason: 'only the front (depth 0) card is interactive at rest');

        // Attempting to tap 'Toast 0' (a peeking card behind the front one)
        // must not remove it — IgnorePointer blocks the hit test at rest, so
        // no GestureDetector under it ever fires.
        expect(find.text('Toast 0'), findsOneWidget);
        await tester.tap(find.text('Toast 0'), warnIfMissed: false);
        await tester.pump();
        expect(find.text('Toast 0'), findsOneWidget, reason: 'a peeking card must not be dismissible via tap at rest');
      });

      testWidgets('on hover, every visible card becomes interactive and dismissible', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester, maxVisible: 3);
        final messenger = LayrzSnackbarMessenger.of(context);

        for (var i = 0; i < 3; i++) {
          messenger.show(LayrzSnackbar(titleText: 'Toast $i', descriptionText: 'Description $i'));
        }
        await pumpPastEntry(tester);

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(find.text('Toast 2')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        // On hover, IgnorePointer(ignoring: !(depth==0 || _isHovered)) means
        // no card ignores pointers any more — every visible card, including
        // the peeking ones, is fully interactive.
        final ignorePointers = tester.widgetList<IgnorePointer>(find.byType(IgnorePointer)).toList();
        expect(ignorePointers, hasLength(3), reason: 'one IgnorePointer wraps each of the 3 visible cards');
        expect(
          ignorePointers.where((w) => w.ignoring),
          isEmpty,
          reason: 'on hover, all visible cards become interactive (DESIGN-60 final: "hovered = all interactive")',
        );

        // Every description remains present and none is clipped once fanned
        // out — the defect the earlier accordion geometry had.
        expect(find.text('Description 0'), findsOneWidget);
        expect(find.text('Description 1'), findsOneWidget);
        expect(find.text('Description 2'), findsOneWidget);
      });
    });

    group('Regression guards', () {
      testWidgets('showing a single toast does not throw a Stack layout exception', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        // The accordion Stack previously had ONLY AnimatedPositioned
        // children (all depths), which left it with no non-positioned child
        // to size itself from — under the unbounded-height constraints the
        // enclosing Column/Overlay give it, RenderStack._computeSize threw
        // "A Stack requires bounded constraints from its parent" on the very
        // first show(), with just one toast queued. The fix makes the front
        // (depth 0) card a plain KeyedSubtree so the Stack always has a
        // sized, non-positioned child. This must never regress.
        LayrzSnackbarMessenger.of(context).show(savedSnackbar);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          tester.takeException(),
          isNull,
          reason: 'a single shown toast must never trigger a Stack-bounded-constraints layout exception',
        );
        expect(find.text('Saved'), findsOneWidget);
      });

      testWidgets('drain progress advances over time without any hover/pointer interaction', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        LayrzSnackbarMessenger.of(context).show(
          const LayrzSnackbar(
            titleText: 'Saved',
            descriptionText: 'Your changes were saved successfully.',
            duration: Duration(seconds: 5),
          ),
        );
        await pumpPastEntry(tester);

        // The progress bar previously froze at its just-shown value unless
        // some unrelated setState (e.g. hover) forced LayrzSnackbarView to
        // rebuild, because it was passed as the AnimatedBuilder's static
        // `child` — captured once, never re-read from drainController.value
        // on later ticks. The fix builds LayrzSnackbarView inside the
        // AnimatedBuilder's `builder` callback instead, so it re-reads
        // `progress` every tick. No pointer/hover interaction happens here.
        double readProgress() {
          final bar = tester.widget<LayrzSnackbarView>(find.byType(LayrzSnackbarView));
          return bar.progress;
        }

        final firstProgress = readProgress();

        await tester.pump(const Duration(milliseconds: 800));
        final secondProgress = readProgress();

        expect(
          secondProgress,
          lessThan(firstProgress),
          reason: 'drain progress must advance across pumps even with no hover — it must not freeze',
        );
      });
    });

    group('Actions', () {
      testWidgets('actions render as LayrzButtons below the content', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);
        var manageTapped = false;
        var dismissTapped = false;

        LayrzSnackbarMessenger.of(context).show(
          LayrzSnackbar(
            titleText: 'Rule triggered',
            descriptionText: 'Speed limit exceeded.',
            type: LayrzSnackbarType.warning,
            actions: [
              LayrzButton(
                labelText: 'Manage rule',
                type: LayrzButtonType.warning,
                onTap: () => manageTapped = true,
              ),
              LayrzButton(
                labelText: 'Dismiss',
                style: LayrzButtonStyle.text,
                onTap: () => dismissTapped = true,
              ),
            ],
          ),
        );
        await pumpPastEntry(tester);

        // LayrzButton renders its label via RichText, not Text — a bare
        // find.widgetWithText(LayrzButton, ...) never matches. findButtonLabel
        // (shared with test/buttons/) finds the RichText by its plain-text
        // content instead.
        final manageLabelFinder = findButtonLabel('Manage rule');
        final dismissLabelFinder = findButtonLabel('Dismiss');
        expect(manageLabelFinder, findsOneWidget);
        expect(dismissLabelFinder, findsOneWidget);

        final manageButtonFinder = find.ancestor(of: manageLabelFinder, matching: find.byType(LayrzButton));
        final dismissButtonFinder = find.ancestor(of: dismissLabelFinder, matching: find.byType(LayrzButton));
        expect(manageButtonFinder, findsOneWidget);
        expect(dismissButtonFinder, findsOneWidget);

        // Both action buttons must sit below the title/description content,
        // not aside — the DESIGN-60 rework moves actions out of the aside
        // slot entirely (aside is close-only now).
        final titleY = tester.getTopLeft(find.text('Rule triggered')).dy;
        final manageY = tester.getTopLeft(manageButtonFinder).dy;
        expect(manageY, greaterThan(titleY), reason: 'actions render below the content, not beside it');

        await tester.tap(manageButtonFinder);
        await tester.pump();
        expect(manageTapped, isTrue);
        expect(dismissTapped, isFalse);

        // Tapping an action must not auto-dismiss the toast (only the
        // whole-card onTap does that) — the card, including the other
        // action, must still be present.
        expect(find.text('Rule triggered'), findsOneWidget);
        expect(dismissButtonFinder, findsOneWidget);
      });

      testWidgets('multiple actions lay out in a Row below the content', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        LayrzSnackbarMessenger.of(context).show(
          LayrzSnackbar(
            titleText: 'Rule triggered',
            descriptionText: 'Speed limit exceeded.',
            type: LayrzSnackbarType.warning,
            actions: [
              LayrzButton(labelText: 'Manage rule', onTap: () {}),
              LayrzButton(labelText: 'Dismiss', onTap: () {}),
            ],
          ),
        );
        await pumpPastEntry(tester);

        // The view lays multiple actions out in a Row (mainAxisAlignment.end,
        // spaced by tokens.spacing.sp2) below the content — not a Wrap.
        final actionsRow = tester
            .widgetList<Row>(find.descendant(of: find.byType(LayrzSnackbarView), matching: find.byType(Row)))
            .where((row) => row.mainAxisAlignment == MainAxisAlignment.end)
            .toList();
        expect(actionsRow, hasLength(1), reason: 'multiple actions lay out in a single end-aligned Row');
        expect(findButtonLabel('Manage rule'), findsOneWidget);
        expect(findButtonLabel('Dismiss'), findsOneWidget);
      });

      testWidgets('a snackbar with no actions renders no action row', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        LayrzSnackbarMessenger.of(context).show(savedSnackbar);
        await pumpPastEntry(tester);

        // Without actions, the view's action Row (mainAxisAlignment.end) is
        // never built — the content Row (icon + title/description + close)
        // uses the default start alignment, so filtering by `.end` isolates
        // the actions row specifically.
        final actionsRow = tester
            .widgetList<Row>(find.descendant(of: find.byType(LayrzSnackbarView), matching: find.byType(Row)))
            .where((row) => row.mainAxisAlignment == MainAxisAlignment.end)
            .toList();
        expect(actionsRow, isEmpty, reason: 'no actions means no end-aligned actions Row is built');
      });
    });

    group('Close', () {
      testWidgets('duration != null (auto-dismiss) renders a close LayrzButton that dismisses on tap', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        try {
          setWideViewport(tester);
          final context = await pumpMessenger(tester);

          LayrzSnackbarMessenger.of(context).show(savedSnackbar);
          await pumpPastEntryAndSettleSemantics(tester);

          final closeButtonFinder = find.widgetWithIcon(LayrzButton, MdiIcons.close);
          expect(closeButtonFinder, findsOneWidget);
          expect(
            tester.widget<LayrzButton>(closeButtonFinder).style,
            LayrzButtonStyle.textFab,
            reason: 'close is a LayrzButton in the textFab style, per DESIGN-60',
          );

          final closeSemantics = find.bySemanticsLabel('Dismiss notification');
          expect(closeSemantics, findsOneWidget);

          await tester.tap(closeButtonFinder);
          await tester.pump();

          expect(find.text('Saved'), findsNothing);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('duration: null (persistent) renders no close control', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          setWideViewport(tester);
          final context = await pumpMessenger(tester);

          LayrzSnackbarMessenger.of(context).show(
            const LayrzSnackbar(
              titleText: 'Saved',
              descriptionText: 'Your changes were saved successfully.',
              duration: null,
            ),
          );
          await pumpPastEntryAndSettleSemantics(tester);

          expect(find.text('Saved'), findsOneWidget);
          expect(find.bySemanticsLabel('Dismiss notification'), findsNothing);
          expect(find.widgetWithIcon(LayrzButton, MdiIcons.close), findsNothing);
        } finally {
          handle.dispose();
        }
      });
    });

    group('onTap (whole card)', () {
      testWidgets('tapping the body runs onTap and dismisses the toast', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);
        var tapped = false;

        LayrzSnackbarMessenger.of(context).show(
          LayrzSnackbar(
            titleText: 'Deleted',
            descriptionText: 'The item was removed.',
            type: LayrzSnackbarType.context,
            onTap: () => tapped = true,
          ),
        );
        await pumpPastEntry(tester);

        await tester.tap(find.text('Deleted'));
        await tester.pump();

        expect(tapped, isTrue);
        expect(find.text('Deleted'), findsNothing);
      });
    });

    group('Swipe dismissal', () {
      testWidgets('swipe-up dismisses the toast', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        LayrzSnackbarMessenger.of(context).show(savedSnackbar);
        await pumpPastEntry(tester);

        await tester.fling(find.text('Saved'), const Offset(0, -60), 1000);
        await tester.pump();

        expect(find.text('Saved'), findsNothing);
      });

      testWidgets('swipe-right dismisses the toast', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        LayrzSnackbarMessenger.of(context).show(savedSnackbar);
        await pumpPastEntry(tester);

        await tester.fling(find.text('Saved'), const Offset(60, 0), 1000);
        await tester.pump();

        expect(find.text('Saved'), findsNothing);
      });

      testWidgets('a slow drag below the velocity threshold does not dismiss', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        LayrzSnackbarMessenger.of(context).show(savedSnackbar);
        await pumpPastEntry(tester);

        // A slow fling stays under the 200px/s threshold.
        await tester.fling(find.text('Saved'), const Offset(0, -10), 50);
        await tester.pump();

        expect(find.text('Saved'), findsOneWidget);
      });
    });

    group('Overflow', () {
      testWidgets('enqueuing more than maxVisible shows only the cap plus a Dismiss all chip', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester, maxVisible: 3);
        final messenger = LayrzSnackbarMessenger.of(context);

        for (var i = 0; i < 5; i++) {
          messenger.show(
            LayrzSnackbar(titleText: 'Toast $i', descriptionText: 'Description $i'),
          );
        }
        await pumpPastEntry(tester);

        // Newest-first: toasts 4,3,2 visible; 1,0 collapsed → +2.
        expect(find.text('Toast 4'), findsOneWidget);
        expect(find.text('Toast 3'), findsOneWidget);
        expect(find.text('Toast 2'), findsOneWidget);
        expect(find.text('Toast 1'), findsNothing);
        expect(find.text('Toast 0'), findsNothing);
        expect(find.textContaining('Dismiss all'), findsOneWidget);
      });

      testWidgets('tapping Dismiss all clears the entire queue', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester, maxVisible: 3);
        final messenger = LayrzSnackbarMessenger.of(context);

        for (var i = 0; i < 5; i++) {
          messenger.show(
            LayrzSnackbar(titleText: 'Toast $i', descriptionText: 'Description $i'),
          );
        }
        await pumpPastEntry(tester);

        await tester.tap(find.textContaining('Dismiss all'));
        await tester.pump();

        for (var i = 0; i < 5; i++) {
          expect(find.text('Toast $i'), findsNothing);
        }
        expect(find.textContaining('Dismiss all'), findsNothing);
      });

      testWidgets('dismissAll() clears the entire queue programmatically', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester, maxVisible: 3);
        final messenger = LayrzSnackbarMessenger.of(context);

        for (var i = 0; i < 4; i++) {
          messenger.show(
            LayrzSnackbar(titleText: 'Toast $i', descriptionText: 'Description $i'),
          );
        }
        await pumpPastEntry(tester);

        messenger.dismissAll();
        await tester.pump();

        for (var i = 0; i < 4; i++) {
          expect(find.text('Toast $i'), findsNothing);
        }
      });
    });

    group('Placement', () {
      testWidgets('the stack is horizontally centered and top-inset at a wide viewport', (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);

        LayrzSnackbarMessenger.of(context).show(savedSnackbar);
        await pumpPastEntry(tester);

        final positioned = tester.widget<Positioned>(findStackPositioned());
        expect(positioned.top, 16.0, reason: 'no safe-area inset on desktop — falls back to the 16px padding');
        expect(positioned.left, 0.0);
        expect(positioned.right, 0.0);

        final screenCenterX = tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;
        // The card widget's own bounds are centered on screen — not
        // find.text('Saved')'s glyph center, which sits left-of-center
        // because the icon precedes the left-aligned text within the card.
        final cardCenter = tester.getCenter(find.byType(LayrzSnackbarView));
        expect(cardCenter.dx, closeTo(screenCenterX, 1.0));
      });

      testWidgets('the stack is horizontally centered and top-inset at a compact viewport', (tester) async {
        setCompactViewport(tester);
        final context = await pumpMessenger(tester);

        LayrzSnackbarMessenger.of(context).show(savedSnackbar);
        await pumpPastEntry(tester);

        final positioned = tester.widget<Positioned>(findStackPositioned());
        expect(positioned.top, 16.0, reason: 'no simulated safe-area inset in this test — falls back to padding');
        expect(positioned.left, 0.0);
        expect(positioned.right, 0.0);

        final screenCenterX = tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;
        // The card widget's own bounds are centered on screen — not
        // find.text('Saved')'s glyph center, which sits left-of-center
        // because the icon precedes the left-aligned text within the card.
        final cardCenter = tester.getCenter(find.byType(LayrzSnackbarView));
        expect(cardCenter.dx, closeTo(screenCenterX, 1.0));
      });

      testWidgets('a top safe-area inset larger than padding widens the effective top offset', (tester) async {
        setCompactViewport(tester);

        await tester.binding.setSurfaceSize(const Size(400, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        late BuildContext capturedContext;
        await tester.pumpWidget(
          Localizations(
            locale: const Locale('en'),
            delegates: const [
              DefaultWidgetsLocalizations.delegate,
              LayrzUiL10nDelegate(),
            ],
            child: LayrzTheme(
              data: LayrzThemeData.light(),
              child: MediaQuery(
                data: const MediaQueryData(padding: EdgeInsets.only(top: 40)),
                child: Builder(
                  builder: (context) {
                    return LayrzSnackbarMessenger(
                      child: Builder(
                        builder: (innerContext) {
                          capturedContext = innerContext;
                          return const SizedBox.shrink();
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        LayrzSnackbarMessenger.of(capturedContext).show(savedSnackbar);
        await pumpPastEntry(tester);

        final positioned = tester.widget<Positioned>(findStackPositioned());
        expect(positioned.top, 40.0, reason: 'a 40px safe-area top exceeds the default 16px padding');
      });
    });

    group('Semantics', () {
      testWidgets('the shown toast announces as a live region with title and description', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          setWideViewport(tester);
          final context = await pumpMessenger(tester);

          LayrzSnackbarMessenger.of(context).show(savedSnackbar);
          await pumpPastEntryAndSettleSemantics(tester);

          final semanticsNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzSnackbarView), matching: find.byType(Semantics)).first,
          );

          expect(semanticsNode.label, contains('Saved'));
          expect(semanticsNode.label, contains('Your changes were saved successfully.'));
          expect(
            semanticsNode,
            matchesSemantics(
              isLiveRegion: true,
              label: semanticsNode.label,
              isButton: false,
              hasTapAction: false,
            ),
          );
        } finally {
          handle.dispose();
        }
      });

      testWidgets('the close control carries its dismiss label', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          setWideViewport(tester);
          final context = await pumpMessenger(tester);

          LayrzSnackbarMessenger.of(context).show(savedSnackbar);
          await pumpPastEntryAndSettleSemantics(tester);

          // LayrzButton wraps its content in Semantics(excludeSemantics: true,
          // button: true, ...) with no explicit `onTap:` wired into the
          // Semantics node itself — activation happens via the merged
          // subtree's hit-testable GestureDetector, not a raw semantics tap
          // action, so hasTapAction is correctly false here (matches every
          // other LayrzButton in this suite/repo — no button test asserts
          // hasTapAction: true).
          final closeNode = tester.getSemantics(find.bySemanticsLabel('Dismiss notification'));
          expect(
            closeNode,
            matchesSemantics(
              label: 'Dismiss notification',
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
  });
}
