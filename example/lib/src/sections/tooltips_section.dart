import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Displays all [LayrzTooltip] positions, text variants, and interactive pass-through behavior.
///
/// Demonstrates the four cardinal positions with overflow flip behavior, rich text styling,
/// and the headline feature: tooltip surfaces that do not block interaction with widgets
/// behind them.
Widget buildTooltipsSection() {
  return Builder(
    builder: (context) {
      return const _TooltipsSectionContent();
    },
  );
}

/// The content widget for the tooltips section.
///
/// Shows multiple demo subsections illustrating tooltip positioning, text variants,
/// overflow flip behavior, and pass-through interactivity.
class _TooltipsSectionContent extends StatelessWidget {
  /// Creates a new [_TooltipsSectionContent].
  const _TooltipsSectionContent();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Tooltips',
      description: 'Material-free tooltip component with four cardinal positions, rich text support, and pass-through interactivity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. All four positions with clear layout
          _PositionsDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp32),

          // 2. Plain text vs. rich text
          _TextVariantsDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp32),

          // 3. Edge flip behavior
          _EdgeFlipDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp32),

          // 4. Pass-through interactivity
          _PassThroughDemo(tokens: tokens),
        ],
      ),
    );
  }
}

/// Demonstrates all four [LayrzTooltipPosition] values with clearly labelled anchors.
///
/// Shows top, bottom, left, and right placements, each with sufficient surrounding space
/// to demonstrate the positioning and overlap behavior.
class _PositionsDemo extends StatelessWidget {
  /// Creates a new [_PositionsDemo].
  const _PositionsDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('All Four Positions', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'Hover or long-press each anchor to see the tooltip appear in its position.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp16),
        // Grid layout with 4 anchors: top-left, top-right, bottom-left, bottom-right
        Row(
          spacing: tokens.spacing.sp32,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Top
            Column(
              spacing: tokens.spacing.sp12,
              children: [
                Text('Top', style: tokens.typography.label),
                _AnchorBox(
                  label: 'T',
                  tokens: tokens,
                  tooltip: LayrzTooltip(
                    contentText: 'Tooltip above the anchor',
                    position: LayrzTooltipPosition.top,
                    child: SizedBox(
                      width: 60,
                      height: 40,
                      child: _AnchorContent(label: 'T', tokens: tokens),
                    ),
                  ),
                ),
              ],
            ),
            // Bottom
            Column(
              spacing: tokens.spacing.sp12,
              children: [
                Text('Bottom', style: tokens.typography.label),
                _AnchorBox(
                  label: 'B',
                  tokens: tokens,
                  tooltip: LayrzTooltip(
                    contentText: 'Tooltip below the anchor',
                    position: LayrzTooltipPosition.bottom,
                    child: SizedBox(
                      width: 60,
                      height: 40,
                      child: _AnchorContent(label: 'B', tokens: tokens),
                    ),
                  ),
                ),
              ],
            ),
            // Left
            Column(
              spacing: tokens.spacing.sp12,
              children: [
                Text('Left', style: tokens.typography.label),
                _AnchorBox(
                  label: 'L',
                  tokens: tokens,
                  tooltip: LayrzTooltip(
                    contentText: 'Tooltip to the left',
                    position: LayrzTooltipPosition.left,
                    child: SizedBox(
                      width: 60,
                      height: 40,
                      child: _AnchorContent(label: 'L', tokens: tokens),
                    ),
                  ),
                ),
              ],
            ),
            // Right
            Column(
              spacing: tokens.spacing.sp12,
              children: [
                Text('Right', style: tokens.typography.label),
                _AnchorBox(
                  label: 'R',
                  tokens: tokens,
                  tooltip: LayrzTooltip(
                    contentText: 'Tooltip to the right',
                    position: LayrzTooltipPosition.right,
                    child: SizedBox(
                      width: 60,
                      height: 40,
                      child: _AnchorContent(label: 'R', tokens: tokens),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates [LayrzTooltip] with plain text and rich text content.
///
/// Shows a side-by-side comparison of a plain text tooltip and a rich text tooltip
/// with mixed styling (bold, colored spans).
class _TextVariantsDemo extends StatelessWidget {
  /// Creates a new [_TextVariantsDemo].
  const _TextVariantsDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Text Variants', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'Left: plain text. Right: rich text with bold and colored spans.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp16),
        Row(
          spacing: tokens.spacing.sp32,
          children: [
            // Plain text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp8,
              children: [
                Text('contentText', style: tokens.typography.label),
                _AnchorBox(
                  label: 'Plain',
                  tokens: tokens,
                  tooltip: LayrzTooltip(
                    contentText: 'This is a plain text tooltip',
                    child: SizedBox(
                      width: 80,
                      height: 40,
                      child: _AnchorContent(label: 'Plain', tokens: tokens),
                    ),
                  ),
                ),
              ],
            ),
            // Rich text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp8,
              children: [
                Text('contentRichText', style: tokens.typography.label),
                _AnchorBox(
                  label: 'Rich',
                  tokens: tokens,
                  tooltip: LayrzTooltip(
                    contentRichText: TextSpan(
                      children: [
                        const TextSpan(text: 'This is '),
                        TextSpan(
                          text: 'bold',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'colored',
                          style: TextStyle(color: tokens.colors.success[500]),
                        ),
                        const TextSpan(text: ' text'),
                      ],
                    ),
                    child: SizedBox(
                      width: 80,
                      height: 40,
                      child: _AnchorContent(label: 'Rich', tokens: tokens),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates tooltip overflow flip behavior with anchors positioned near viewport edges.
///
/// Shows anchors at the edges of their container so the overflow flip behavior can
/// be observed when the tooltip would overflow on the preferred side.
class _EdgeFlipDemo extends StatelessWidget {
  /// Creates a new [_EdgeFlipDemo].
  const _EdgeFlipDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Edge Flip Behavior', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'Anchors at the viewport edges flip the tooltip to the opposite side when overflow is detected.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp16),
        // Constrain horizontally to force edge positioning
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: tokens.colors.divider, width: 1),
            borderRadius: BorderRadius.circular(tokens.radius.r8),
          ),
          padding: EdgeInsets.all(tokens.spacing.sp24),
          constraints: const BoxConstraints(maxWidth: 600),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left edge: prefer left, should flip right
              _AnchorBox(
                label: 'Left Edge (flips right)',
                tokens: tokens,
                tooltip: LayrzTooltip(
                  contentText: 'Should flip to the right',
                  position: LayrzTooltipPosition.left,
                  child: SizedBox(
                    width: 60,
                    height: 40,
                    child: _AnchorContent(label: 'L', tokens: tokens),
                  ),
                ),
              ),
              // Right edge: prefer right, should flip left
              _AnchorBox(
                label: 'Right Edge (flips left)',
                tokens: tokens,
                tooltip: LayrzTooltip(
                  contentText: 'Should flip to the left',
                  position: LayrzTooltipPosition.right,
                  child: SizedBox(
                    width: 60,
                    height: 40,
                    child: _AnchorContent(label: 'R', tokens: tokens),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Demonstrates the pass-through interactivity guarantee.
///
/// The tooltip surface is shown with `ignorePointer: true`, so widgets behind it
/// remain interactive. This demo shows a row of tappable targets with a tooltip anchor
/// positioned above; when the tooltip is shown with `position: bottom`, it renders
/// downward over the targets. Taps on the targets behind the tooltip still register,
/// demonstrating the pass-through behavior with a live counter.
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
        Text('Pass-Through Interactivity', style: widget.tokens.typography.title),
        SizedBox(height: widget.tokens.spacing.sp12),
        Text(
          'The tooltip surface does not block pointer events. Hover or long-press the anchor '
          'at the top to show the tooltip, then tap the targets beneath it. Taps pass through '
          'the tooltip to the targets and increment the counter.',
          style: widget.tokens.typography.body.copyWith(color: widget.tokens.colors.fg3),
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
                style: widget.tokens.typography.label.copyWith(
                  color: widget.tokens.colors.success[500],
                ),
              ),
              SizedBox(height: widget.tokens.spacing.sp8),
              // Stack: anchor at top, targets positioned to overlap with tooltip surface
              SizedBox(
                height: 50,
                child: Row(
                  spacing: widget.tokens.spacing.sp8,
                  children: List.generate(
                    5,
                    (index) => Expanded(
                      child: LayrzTooltip(
                        contentText: 'Taps pass through to targets below',
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _tapCount++;
                            });
                          },
                          child: Container(
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
                              style: widget.tokens.typography.label.copyWith(
                                color: widget.tokens.colors.fg2,
                              ),
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
    );
  }
}

/// A styled anchor box with a border and background.
///
/// Used as the base container for tooltip anchors in the demo.
class _AnchorBox extends StatelessWidget {
  /// Creates a new [_AnchorBox].
  const _AnchorBox({
    required this.label,
    required this.tokens,
    required this.tooltip,
  });

  /// The label displayed in the box (for documentation purposes only).
  final String label;

  /// The design system tokens.
  final LayrzTokens tokens;

  /// The wrapped tooltip widget.
  final Widget tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.colors.divider, width: 1),
        borderRadius: BorderRadius.circular(tokens.radius.r8),
        color: tokens.colors.surface2,
      ),
      padding: EdgeInsets.all(tokens.spacing.sp8),
      child: tooltip,
    );
  }
}

/// The content displayed inside an anchor (simple centered text).
class _AnchorContent extends StatelessWidget {
  /// Creates a new [_AnchorContent].
  const _AnchorContent({required this.label, required this.tokens});

  /// The label text.
  final String label;

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: tokens.typography.label.copyWith(color: tokens.colors.fg2),
        textAlign: TextAlign.center,
      ),
    );
  }
}
