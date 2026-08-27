import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzSlider widget', () {
    guardedTestWidgets('renders with a value label showing the current value by default', (tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(value: 50, min: 0, max: 100, onChanged: (_) {}),
        ),
      );

      expect(find.text('50'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    guardedTestWidgets('renders the label text when provided', (tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(labelText: 'Volume', value: 20, onChanged: (_) {}),
        ),
      );

      expect(find.text('Volume'), findsOneWidget);
    });

    guardedTestWidgets('hides the value label when showValueLabel is false', (tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(value: 50, onChanged: (_) {}, showValueLabel: false),
        ),
      );

      expect(find.text('50'), findsNothing);
    });

    guardedTestWidgets('applies a custom valueFormatter', (tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(
            value: 50,
            onChanged: (_) {},
            valueFormatter: (v) => '\$${v.toInt()}',
          ),
        ),
      );

      expect(find.text('\$50'), findsOneWidget);
    });

    guardedTestWidgets('tapping the track updates the value via onChanged', (tester) async {
      double? updated;
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(
            value: 0,
            min: 0,
            max: 100,
            onChanged: (v) => updated = v,
          ),
        ),
      );

      final trackFinder = find.byType(CustomPaint).last;
      await tester.tapAt(tester.getCenter(trackFinder));
      await tester.pump();

      expect(updated, isNotNull);
      // Tapping the center of a full-width track should land near the midpoint.
      expect(updated!, closeTo(50, 15));
    });

    guardedTestWidgets('dragging horizontally updates the value live, not only on release', (tester) async {
      final values = <double>[];
      double value = 0;
      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 300,
              child: LayrzSlider(
                value: value,
                min: 0,
                max: 100,
                onChanged: (v) {
                  values.add(v);
                  setState(() => value = v);
                },
              ),
            );
          },
        ),
      );

      final trackFinder = find.byType(CustomPaint).last;
      final start = tester.getTopLeft(trackFinder) + const Offset(10, 10);
      final gesture = await tester.startGesture(start);
      await tester.pump();

      // The first move only resolves the gesture arena's pan slop and does
      // not yet reach onHorizontalDragUpdate -- a real device shows the same
      // small dead zone before a drag "takes". A second move of the same
      // size clears that threshold.
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      final midDragCount = values.length;

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      await gesture.up();
      await tester.pump();

      // Live feedback means onChanged already fired during the drag itself,
      // strictly before release -- not just once at the end.
      expect(midDragCount, greaterThan(0));
      expect(values.length, greaterThan(midDragCount));
    });

    guardedTestWidgets('does not call onChanged when disabled', (tester) async {
      bool called = false;
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(
            value: 50,
            onChanged: (_) => called = true,
            disabled: true,
          ),
        ),
      );

      final trackFinder = find.byType(CustomPaint).last;
      await tester.tapAt(tester.getCenter(trackFinder));
      await tester.pump();

      expect(called, isFalse);
    });

    guardedTestWidgets('is disabled when onChanged is null', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        const SizedBox(
          width: 300,
          child: LayrzSlider(value: 50),
        ),
      );

      final semanticsFinder = find
          .descendant(
            of: find.byType(LayrzSlider),
            matching: find.byType(Semantics),
          )
          .first;
      expect(
        tester.getSemantics(semanticsFinder),
        matchesSemantics(
          hasEnabledState: true,
          isEnabled: false,
          isSlider: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );

      handle.dispose();
    });

    guardedTestWidgets('displays error styling details via LayrzInputFooterSlot', (tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(
            value: 50,
            onChanged: (_) {},
            errors: const ['Value is too low'],
          ),
        ),
      );

      expect(find.text('Value is too low'), findsOneWidget);
    });

    guardedTestWidgets('hides error details when hideDetails is true', (tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(
            value: 50,
            onChanged: (_) {},
            errors: const ['Value is too low'],
            hideDetails: true,
          ),
        ),
      );

      expect(find.text('Value is too low'), findsNothing);
    });

    guardedTestWidgets('renders at value == min without overflow', (tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(value: 0, min: 0, max: 100, onChanged: (_) {}),
        ),
      );
      expect(find.text('0'), findsOneWidget);
    });

    guardedTestWidgets('renders at value == max without overflow', (tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(value: 100, min: 0, max: 100, onChanged: (_) {}),
        ),
      );
      expect(find.text('100'), findsOneWidget);
    });

    guardedTestWidgets('renders without overflow when min == max (degenerate range)', (tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(value: 10, min: 10, max: 10, onChanged: (_) {}),
        ),
      );
      expect(find.text('10'), findsOneWidget);
    });

    guardedTestWidgets('creates and disposes its own focus node when none is supplied', (tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(value: 50, onChanged: (_) {}),
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      // No assertion errors on dispose is the pass condition.
    });

    guardedTestWidgets('uses a caller-supplied focus node without disposing it', (tester) async {
      final focusNode = FocusNode();
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(value: 50, onChanged: (_) {}, focusNode: focusNode),
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());

      // If the widget had wrongly disposed the caller's node, using it here throws.
      expect(() => focusNode.dispose(), returnsNormally);
    });

    guardedTestWidgets('swaps focus node when a new one is supplied via didUpdateWidget', (tester) async {
      final nodeA = FocusNode();
      final nodeB = FocusNode();
      addTearDown(nodeA.dispose);
      addTearDown(nodeB.dispose);

      late StateSetter setSliderState;
      FocusNode active = nodeA;

      // A single stable Overlay/OverlayEntry hosting a StatefulBuilder: only
      // the `focusNode` passed to LayrzSlider changes between pumps, which is
      // what actually exercises LayrzSlider.didUpdateWidget. Recreating the
      // whole Overlay/OverlayEntry per pump (as calling pumpThemed twice would)
      // constructs a fresh OverlayEntry object each time, which does not update
      // the same element and so never reaches didUpdateWidget with the new
      // node at all -- it silently mounts a second, disconnected tree instead.
      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            setSliderState = setState;
            return SizedBox(
              width: 300,
              child: LayrzSlider(
                value: 50,
                onChanged: (_) {},
                focusNode: active,
              ),
            );
          },
        ),
      );

      nodeA.requestFocus();
      await tester.pump();
      expect(nodeA.hasFocus, isTrue);

      // Swap the focus node LayrzSlider is given -- didUpdateWidget must pick
      // up nodeB and re-attach the internal Focus widget to it.
      setSliderState(() => active = nodeB);
      await tester.pump();

      nodeB.requestFocus();
      await tester.pump();
      expect(nodeB.hasFocus, isTrue);

      // nodeA must still be a live, undisposed node the caller owns -- it is
      // disposed by addTearDown above, which would itself throw if the
      // widget had wrongly disposed it already.
    });

    guardedTestWidgets('applies quantisation from divisions during a drag', (tester) async {
      final values = <double>[];
      double value = 0;
      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 300,
              child: LayrzSlider(
                value: value,
                min: 0,
                max: 100,
                divisions: 4,
                onChanged: (v) {
                  values.add(v);
                  setState(() => value = v);
                },
              ),
            );
          },
        ),
      );

      final trackFinder = find.byType(CustomPaint).last;
      final start = tester.getTopLeft(trackFinder) + const Offset(10, 10);
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(140, 0));
      await gesture.up();
      await tester.pump();

      // Every emitted value must land on one of the 4-division steps: 0/25/50/75/100.
      for (final v in values) {
        expect(const [0.0, 25.0, 50.0, 75.0, 100.0], contains(v));
      }
    });

    guardedTestWidgets('losing focus clears the focused state and the pointer-focus flag', (tester) async {
      final sliderFocus = FocusNode();
      final otherFocus = FocusNode();
      addTearDown(sliderFocus.dispose);
      addTearDown(otherFocus.dispose);

      await pumpThemed(
        tester,
        Column(
          children: [
            SizedBox(
              width: 300,
              child: LayrzSlider(value: 50, onChanged: (_) {}, focusNode: sliderFocus),
            ),
            Focus(focusNode: otherFocus, child: const SizedBox(width: 10, height: 10)),
          ],
        ),
      );

      sliderFocus.requestFocus();
      await tester.pump();
      expect(sliderFocus.hasFocus, isTrue);

      // Move focus elsewhere -- the slider's onFocusChange(false) branch fires.
      otherFocus.requestFocus();
      await tester.pump();

      expect(sliderFocus.hasFocus, isFalse);
    });

    guardedTestWidgets('hovering the track adds and removes the hovered interaction state', (tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(value: 50, onChanged: (_) {}),
        ),
      );

      final trackFinder = find.byType(CustomPaint).last;
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(trackFinder));
      await tester.pump();

      await gesture.moveTo(const Offset(-100, -100));
      await tester.pump();

      // No assertion errors and a clean re-render is the pass condition here;
      // the actual colour change is covered by slider_style_test.dart's
      // resolveLayrzSliderColors precedence tests.
    });

    guardedTestWidgets('an internally-created focus node is disposed when a caller node arrives later', (
      tester,
    ) async {
      final callerNode = FocusNode();
      addTearDown(callerNode.dispose);

      late StateSetter setSliderState;
      FocusNode? active;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            setSliderState = setState;
            return SizedBox(
              width: 300,
              child: LayrzSlider(value: 50, onChanged: (_) {}, focusNode: active),
            );
          },
        ),
      );

      // The widget created and owns an internal FocusNode here (focusNode: null).
      setSliderState(() => active = callerNode);
      await tester.pump();

      // If the widget failed to dispose its internal node on this transition,
      // this would leak silently; there is nothing further to assert beyond
      // the pump completing without the disposed-node-still-listening error
      // Flutter raises when a disposed FocusNode is used incorrectly.
      callerNode.requestFocus();
      await tester.pump();
      expect(callerNode.hasFocus, isTrue);
    });
  });
}
