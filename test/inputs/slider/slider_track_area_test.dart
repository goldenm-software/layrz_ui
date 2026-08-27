import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzSliderTrackArea', () {
    LayrzSliderPainter buildPainter() {
      return const LayrzSliderPainter(
        fraction: 0.5,
        trackThickness: 4.0,
        thumbSize: 16.0,
        thumbCornerRadius: 6.0,
        thumbBorderWidth: 2.0,
        trackColor: Color(0xFFE0E0E0),
        activeTrackColor: Color(0xFF3366FF),
        thumbColor: Color(0xFF3366FF),
        thumbBorderColor: Color(0xFFFFFFFF),
      );
    }

    guardedTestWidgets('sizes itself to hitSlopHeight regardless of the bubble', (tester) async {
      final tokens = LayrzTokens.light();
      final key = GlobalKey();

      await pumpThemed(
        tester,
        SizedBox(
          key: key,
          width: 300,
          child: LayrzSliderTrackArea(
            trackWidth: 300,
            hitSlopHeight: 44,
            paintHeight: 20,
            fraction: 0.5,
            painter: buildPainter(),
            thumbHalfSize: 8,
            bubbleClearance: 28,
            isDragging: false,
            showValueLabel: true,
            formattedValue: '50',
            isDisabled: false,
            tokens: tokens,
          ),
        ),
      );

      final heightAtRest = (key.currentContext!.findRenderObject() as RenderBox).size.height;
      expect(heightAtRest, 44);

      await pumpThemed(
        tester,
        SizedBox(
          key: key,
          width: 300,
          child: LayrzSliderTrackArea(
            trackWidth: 300,
            hitSlopHeight: 44,
            paintHeight: 20,
            fraction: 0.5,
            painter: buildPainter(),
            thumbHalfSize: 8,
            bubbleClearance: 28,
            isDragging: true,
            showValueLabel: true,
            formattedValue: '50',
            isDisabled: false,
            tokens: tokens,
          ),
        ),
      );

      final heightWhileDragging = (key.currentContext!.findRenderObject() as RenderBox).size.height;
      expect(heightWhileDragging, 44);
    });

    guardedTestWidgets('shows the bubble only when isDragging and showValueLabel are both true', (tester) async {
      final tokens = LayrzTokens.light();

      Future<void> pumpWith({required bool isDragging, required bool showValueLabel}) async {
        // A full teardown between pumps, not just a second pumpThemed call:
        // pumpThemed wraps its child in an Overlay, and Overlay.initialEntries
        // is only read once at construction, not on rebuild -- reusing the
        // same Overlay element across pumps would silently keep showing the
        // first pump's child. Resetting to a blank tree first forces a fresh
        // Overlay (and fresh LayrzSliderTrackArea) each time.
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzSliderTrackArea(
              trackWidth: 300,
              hitSlopHeight: 44,
              paintHeight: 20,
              fraction: 0.5,
              painter: buildPainter(),
              thumbHalfSize: 8,
              bubbleClearance: 28,
              isDragging: isDragging,
              showValueLabel: showValueLabel,
              formattedValue: '50',
              isDisabled: false,
              tokens: tokens,
            ),
          ),
        );
      }

      await pumpWith(isDragging: false, showValueLabel: true);
      expect(find.byType(LayrzSliderValueBubble), findsNothing);

      await pumpWith(isDragging: true, showValueLabel: false);
      expect(find.byType(LayrzSliderValueBubble), findsNothing);

      await pumpWith(isDragging: true, showValueLabel: true);
      expect(find.byType(LayrzSliderValueBubble), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
    });

    guardedTestWidgets('the bubble is wrapped in ExcludeSemantics', (tester) async {
      final tokens = LayrzTokens.light();

      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSliderTrackArea(
            trackWidth: 300,
            hitSlopHeight: 44,
            paintHeight: 20,
            fraction: 0.5,
            painter: buildPainter(),
            thumbHalfSize: 8,
            bubbleClearance: 28,
            isDragging: true,
            showValueLabel: true,
            formattedValue: '50',
            isDisabled: false,
            tokens: tokens,
          ),
        ),
      );

      final bubbleFinder = find.byType(LayrzSliderValueBubble);
      final excludeSemanticsAncestor = find.ancestor(
        of: bubbleFinder,
        matching: find.byType(ExcludeSemantics),
      );
      expect(excludeSemanticsAncestor, findsWidgets);
    });
  });
}
