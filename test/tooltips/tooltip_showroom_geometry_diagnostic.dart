import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/extensions.dart';
import 'package:layrz_ui/tooltips.dart';

import '../helpers/pump_themed.dart';

/// DIAGNOSTIC TEST — Measure the actual geometry of the _PassThroughDemo.
///
/// This test measures whether the tooltip surface overlaps the target buttons,
/// and whether the anchor overlaps any targets. This determines if the demo
/// can actually demonstrate pass-through behavior.

void main() {
  testWidgets(
    'DIAGNOSTIC: Measure tooltip and target geometry in _PassThroughDemo layout',
    (tester) async {
      // Recreate the _PassThroughDemo layout exactly
      final demoWidget = Builder(
        builder: (context) {
          final tokens = context.tokens;
          int tapCount = 0;

          return StatefulBuilder(
            builder: (context, setState) {
              return Container(
                color: tokens.colors.background,
                padding: EdgeInsets.all(tokens.spacing.sp16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pass-Through Test', style: tokens.typography.titleMedium),
                    SizedBox(height: tokens.spacing.sp16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: tokens.colors.divider, width: 1),
                        borderRadius: BorderRadius.circular(tokens.radius.r8),
                      ),
                      padding: EdgeInsets.all(tokens.spacing.sp16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: tokens.spacing.sp12,
                        children: [
                          Text(
                            'Tap count: $tapCount',
                            style: tokens.typography.labelLarge,
                          ),
                          SizedBox(height: tokens.spacing.sp8),
                          // THE STACK: exact layout from _PassThroughDemo
                          Stack(
                            children: [
                              // Background: row of tappable target buttons
                              Row(
                                spacing: tokens.spacing.sp8,
                                children: List.generate(
                                  5,
                                  (index) => Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          tapCount++;
                                        });
                                      },
                                      child: Container(
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: tokens.colors.surface2,
                                          border: Border.all(
                                            color: tokens.colors.divider,
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(tokens.radius.r8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Target ${index + 1}',
                                          key: Key('target_${index + 1}'),
                                          style: tokens.typography.labelSmall,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Foreground: tooltip anchor (positioned centrally)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: LayrzTooltip(
                                    contentText: 'Taps pass through to targets below',
                                    position: LayrzTooltipPosition.bottom,
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: tokens.colors.primary[500],
                                        borderRadius: BorderRadius.circular(tokens.radius.r8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Anchor',
                                        key: const Key('anchor'),
                                        style: tokens.typography.labelSmall,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

      await pumpThemed(tester, demoWidget);

      // Step 1: Trigger the tooltip with mouse hover
      final anchorCenter = tester.getCenter(find.byKey(const Key('anchor')));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);

      await mouse.moveTo(anchorCenter);
      await tester.pumpAndSettle();

      // Verify tooltip is showing
      expect(find.text('Taps pass through to targets below'), findsOneWidget);

      // Step 2: Measure the tooltip surface rect
      final tooltipRect = tester.getRect(find.text('Taps pass through to targets below'));
      debugPrint('=== TOOLTIP GEOMETRY ===');
      debugPrint('Tooltip rect: $tooltipRect');
      debugPrint('  left: ${tooltipRect.left}');
      debugPrint('  top: ${tooltipRect.top}');
      debugPrint('  right: ${tooltipRect.right}');
      debugPrint('  bottom: ${tooltipRect.bottom}');
      debugPrint('  width: ${tooltipRect.width}');
      debugPrint('  height: ${tooltipRect.height}');

      // Step 3: Measure the 5 target rects
      debugPrint('=== TARGET GEOMETRY ===');
      final targetRects = <int, Rect>{};
      for (int i = 1; i <= 5; i++) {
        final targetRect = tester.getRect(find.byKey(Key('target_$i')));
        targetRects[i] = targetRect;
        debugPrint('Target $i rect: $targetRect');
        debugPrint('  left: ${targetRect.left}');
        debugPrint('  top: ${targetRect.top}');
        debugPrint('  right: ${targetRect.right}');
        debugPrint('  bottom: ${targetRect.bottom}');
      }

      // Step 4: Check overlaps between tooltip and targets
      debugPrint('=== TOOLTIP-TARGET OVERLAPS ===');
      final overlaps = <int>{};
      for (int i = 1; i <= 5; i++) {
        final doesOverlap = tooltipRect.overlaps(targetRects[i]!);
        debugPrint('Tooltip overlaps Target $i? $doesOverlap');
        if (doesOverlap) {
          overlaps.add(i);
        }
      }

      if (overlaps.isEmpty) {
        debugPrint('WARNING: Tooltip does NOT overlap any targets!');
        debugPrint('This means the demo cannot demonstrate pass-through behavior.');
      } else {
        debugPrint('Tooltip overlaps targets: $overlaps');
      }

      // Step 5: Measure the anchor rect
      final anchorRect = tester.getRect(find.byKey(const Key('anchor')));
      debugPrint('=== ANCHOR GEOMETRY ===');
      debugPrint('Anchor rect: $anchorRect');
      debugPrint('  left: ${anchorRect.left}');
      debugPrint('  top: ${anchorRect.top}');
      debugPrint('  right: ${anchorRect.right}');
      debugPrint('  bottom: ${anchorRect.bottom}');
      debugPrint('  width: ${anchorRect.width}');
      debugPrint('  height: ${anchorRect.height}');

      // Step 6: Check which targets the anchor overlaps
      debugPrint('=== ANCHOR-TARGET OVERLAPS ===');
      final anchorOverlaps = <int>{};
      for (int i = 1; i <= 5; i++) {
        final doesOverlap = anchorRect.overlaps(targetRects[i]!);
        debugPrint('Anchor overlaps Target $i? $doesOverlap');
        if (doesOverlap) {
          anchorOverlaps.add(i);
        }
      }

      if (anchorOverlaps.isNotEmpty) {
        debugPrint('ISSUE: Anchor covers targets: $anchorOverlaps');
        debugPrint('This makes those targets unclickable because the Listener(behavior: opaque)');
        debugPrint('in RawTooltip blocks hits to the target beneath the anchor.');
      }

      // Final summary
      debugPrint('=== SUMMARY ===');
      debugPrint('Tooltip overlaps any target? ${overlaps.isNotEmpty}');
      debugPrint('Anchor overlaps any target? ${anchorOverlaps.isNotEmpty}');
      debugPrint('Number of targets unreachable due to anchor: ${anchorOverlaps.length}');
    },
  );
}
