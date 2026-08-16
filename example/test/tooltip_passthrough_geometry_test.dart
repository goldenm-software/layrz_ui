import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/app.dart';
import 'package:layrz_ui/constants.dart';
import 'package:layrz_ui/theme.dart';
import 'package:layrz_ui/tooltips.dart';
import 'package:layrz_ui/tokens.dart';

void main() {
  group('Tooltip PassThrough Geometry', () {
    testWidgets('tooltip overlaps targets and anchor does not', (WidgetTester tester) async {
      // Build the app with the PassThroughDemo
      final themeData = LayrzThemeData.light();

      await tester.pumpWidget(
        LayrzApp(
          title: kAppTitle,
          theme: themeData,
          home: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Center(
                  child: _PassThroughDemo(tokens: themeData.tokens),
                ),
              ),
            ],
          ),
        ),
      );

      // Initial pump to render
      await tester.pumpAndSettle();

      // Find the anchor (the "Pass Through" button)
      final anchorFinder = find.byKey(const ValueKey('pass-through-anchor'));
      expect(anchorFinder, findsOneWidget, reason: 'Anchor should be present');

      // Long-press the anchor to show the tooltip
      await tester.longPress(anchorFinder);
      await tester.pumpAndSettle();

      // Verify tooltip is visible
      final tooltipTextFinder = find.text('Taps pass through to targets below');
      expect(tooltipTextFinder, findsOneWidget, reason: 'Tooltip should be visible after long-press');

      // Get the anchor rect
      final anchorRect = tester.getRect(anchorFinder);

      // Get the tooltip surface rect
      // The tooltip is rendered in a FadeTransition by LayrzTooltip's RawTooltip.
      // FadeTransition -> ConstrainedBox/Container (constrainedSurface) -> Container (surface) -> Text
      final tooltipContainerFinder = find.ancestor(
        of: tooltipTextFinder,
        matching: find.byType(Container),
      ).first;

      // The tooltip container is the inner Container (surface) that wraps the text
      final tooltipRect = tester.getRect(tooltipContainerFinder);

      // Get the target rects
      final targetRects = <int, Rect>{};
      for (int i = 0; i < 5; i++) {
        final targetFinder = find.byKey(ValueKey('pass-through-target-$i'));
        expect(targetFinder, findsOneWidget, reason: 'Target $i should exist');
        targetRects[i] = tester.getRect(targetFinder);
      }

      // Print all measured rects
      debugPrint('=== MEASURED RECTS ===');
      debugPrint('Anchor: $anchorRect');
      debugPrint('Tooltip Surface: $tooltipRect');
      for (int i = 0; i < 5; i++) {
        debugPrint('Target $i: ${targetRects[i]}');
      }
      debugPrint('======================');

      // Check overlap: tooltip should overlap at least 2 targets
      int overlapCount = 0;
      for (int i = 0; i < 5; i++) {
        if (tooltipRect.overlaps(targetRects[i]!)) {
          overlapCount++;
          debugPrint('Tooltip overlaps Target $i');
        }
      }

      expect(
        overlapCount,
        greaterThanOrEqualTo(2),
        reason: 'Tooltip should overlap at least 2 targets, but overlapped $overlapCount',
      );

      // Check that anchor does not overlap any target
      bool anchorOverlapsTarget = false;
      for (int i = 0; i < 5; i++) {
        if (anchorRect.overlaps(targetRects[i]!)) {
          anchorOverlapsTarget = true;
          debugPrint('ERROR: Anchor overlaps Target $i');
        }
      }

      expect(anchorOverlapsTarget, false, reason: 'Anchor should not overlap any target');
    });
  });
}

/// A copy of [_PassThroughDemo] with ValueKeys added for testing.
class _PassThroughDemo extends StatefulWidget {
  /// Creates a new [_PassThroughDemo].
  const _PassThroughDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  State<_PassThroughDemo> createState() => _PassThroughDemoState();
}

class _PassThroughDemoState extends State<_PassThroughDemo> {
  int _tapCount = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pass-Through Interactivity', style: widget.tokens.typography.titleMedium),
        SizedBox(height: widget.tokens.spacing.sp12),
        Text(
          'The tooltip surface does not block pointer events. Hover or long-press the anchor '
          'at the top to show the tooltip, then tap the targets beneath it. Taps pass through '
          'the tooltip to the targets and increment the counter.',
          style: widget.tokens.typography.bodySmall.copyWith(color: widget.tokens.colors.fg3),
        ),
        SizedBox(height: widget.tokens.spacing.sp16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: widget.tokens.colors.divider, width: 1),
            borderRadius: BorderRadius.circular(widget.tokens.radius.r8),
          ),
          padding: EdgeInsets.all(widget.tokens.spacing.sp16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: widget.tokens.spacing.sp12,
            children: [
              Text(
                'Tap count: $_tapCount',
                style: widget.tokens.typography.labelLarge.copyWith(
                  color: widget.tokens.colors.success[500],
                ),
              ),
              SizedBox(height: widget.tokens.spacing.sp8),
              // Stack: anchor at top, targets positioned to overlap with tooltip surface
              SizedBox(
                height: 120,
                child: Stack(
                  children: [
                    // Anchor: pinned to TOP, centered horizontally
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: LayrzTooltip(
                          contentText: 'Taps pass through to targets below',
                          position: LayrzTooltipPosition.bottom,
                          child: Container(
                            key: const ValueKey('pass-through-anchor'),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: widget.tokens.colors.primary[500],
                              borderRadius: BorderRadius.circular(widget.tokens.radius.r8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Pass\nThrough',
                              style: widget.tokens.typography.labelSmall.copyWith(
                                color: widget.tokens.colors.background,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Targets: positioned to overlap with tooltip surface
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 70,
                      height: 48,
                      child: Row(
                        spacing: widget.tokens.spacing.sp8,
                        children: List.generate(
                          5,
                          (index) => Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _tapCount++;
                                });
                              },
                              child: Container(
                                key: ValueKey('pass-through-target-$index'),
                                decoration: BoxDecoration(
                                  color: widget.tokens.colors.surface2,
                                  border: Border.all(
                                    color: widget.tokens.colors.divider,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(widget.tokens.radius.r8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Target ${index + 1}',
                                  style: widget.tokens.typography.labelSmall.copyWith(
                                    color: widget.tokens.colors.fg2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
