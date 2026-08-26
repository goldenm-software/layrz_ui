import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';
import '../common/unit_display.dart';

/// Displays all five spacing token levels as a visual ruler and derived accessor demonstrations.
///
/// Shows each spacing level (sp1 through sp5) as a bar whose width is that token,
/// labelled with name and pixel value. Also demonstrates the derived accessors
/// [pd1-pd5] (padding) and [mg1-mg5] (margin) with visual examples.
class SpacingSection extends StatelessWidget {
  const SpacingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Spacing',
      description:
          'Five semantic spacing levels: sp1 (${tokens.spacing.sp1.toStringAsFixed(0)}px) through sp5 (${tokens.spacing.sp5.toStringAsFixed(0)}px)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spacing ruler
          Text('Spacing Levels', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          _SpacingRuler(tokens: tokens),

          SizedBox(height: tokens.spacing.sp4),

          // Derived accessors: padding and margin
          Text('Padding & Margin Accessors', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          _PaddingAccessors(tokens: tokens),

          SizedBox(height: tokens.spacing.sp4),

          // Margin accessors
          Text('Margin Levels', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          _MarginAccessors(tokens: tokens),
        ],
      ),
    );
  }
}

/// A visual ruler showing all five spacing levels as bars with labels.
class _SpacingRuler extends StatelessWidget {
  /// Creates a new [_SpacingRuler].
  const _SpacingRuler({required this.tokens});

  /// The token set containing spacing tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    final spacingLevels = [
      ('sp1', tokens.spacing.sp1),
      ('sp2', tokens.spacing.sp2),
      ('sp3', tokens.spacing.sp3),
      ('sp4', tokens.spacing.sp4),
      ('sp5', tokens.spacing.sp5),
    ];

    return Column(
      children: spacingLevels
          .map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: tokens.spacing.sp3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Label
                  SizedBox(
                    width: tokens.spacing.sp4,
                    child: Text(item.$1, style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
                  ),

                  // Track (background strip) with bar on top showing true width
                  Expanded(
                    child: LayrzTooltip(
                      contentText: '${item.$1} = ${item.$2.toStringAsFixed(0)}px',
                      child: Container(
                        height: tokens.spacing.sp2,
                        decoration: BoxDecoration(
                          color: tokens.colors.sf2,
                          borderRadius: tokens.radius.br2,
                        ),
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: item.$2,
                          height: tokens.spacing.sp2,
                          key: ValueKey('spacing-bar-${item.$1}'),
                          decoration: BoxDecoration(
                            color: tokens.colors.primary,
                            borderRadius: BorderRadius.circular(
                              // Proportional radius: smaller for tiny bars, larger for bigger bars
                              min(item.$2 / 4, tokens.radius.r2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Value label
                  SizedBox(width: tokens.spacing.sp2),
                  SizedBox(
                    width: tokens.spacing.sp4,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: UnitDisplay(
                        value: item.$2,
                        textStyle: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Demonstrates the [pd1-pd5] padding accessors, each returning [EdgeInsets.all].
class _PaddingAccessors extends StatelessWidget {
  /// Creates a new [_PaddingAccessors].
  const _PaddingAccessors({required this.tokens});

  /// The token set containing spacing tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    final paddingLevels = [
      ('pd1', tokens.spacing.pd1, tokens.spacing.sp1),
      ('pd2', tokens.spacing.pd2, tokens.spacing.sp2),
      ('pd3', tokens.spacing.pd3, tokens.spacing.sp3),
      ('pd4', tokens.spacing.pd4, tokens.spacing.sp4),
      ('pd5', tokens.spacing.pd5, tokens.spacing.sp5),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paddingLevels
          .map(
            (item) => Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$1, style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
                  SizedBox(height: tokens.spacing.sp2),
                  LayrzTooltip(
                    contentText: '${item.$1} = ${item.$3.toStringAsFixed(0)}px on all sides',
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: tokens.colors.divider, width: tokens.border.stroke2),
                        borderRadius: tokens.radius.br2,
                      ),
                      padding: item.$2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: tokens.colors.primary,
                          borderRadius: tokens.radius.br2,
                        ),
                        height: 40,
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.spacing.sp2),
                  UnitDisplay(
                    value: item.$3,
                    textStyle: tokens.typography.label.copyWith(color: tokens.colors.fg3, fontSize: 11),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Demonstrates the [mg1-mg5] margin accessors, each returning [EdgeInsets.all].
class _MarginAccessors extends StatelessWidget {
  /// Creates a new [_MarginAccessors].
  const _MarginAccessors({required this.tokens});

  /// The token set containing spacing tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    final marginLevels = [
      ('mg1', tokens.spacing.mg1, tokens.spacing.sp1),
      ('mg2', tokens.spacing.mg2, tokens.spacing.sp2),
      ('mg3', tokens.spacing.mg3, tokens.spacing.sp3),
      ('mg4', tokens.spacing.mg4, tokens.spacing.sp4),
      ('mg5', tokens.spacing.mg5, tokens.spacing.sp5),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: marginLevels
          .map(
            (item) => Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$1, style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
                  SizedBox(height: tokens.spacing.sp2),
                  LayrzTooltip(
                    contentText: '${item.$1} = ${item.$3.toStringAsFixed(0)}px on all sides',
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: tokens.colors.divider, width: tokens.border.stroke2),
                        borderRadius: tokens.radius.br2,
                      ),
                      margin: item.$2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: tokens.colors.primary,
                          borderRadius: tokens.radius.br2,
                        ),
                        height: 40,
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.spacing.sp2),
                  UnitDisplay(
                    value: item.$3,
                    textStyle: tokens.typography.label.copyWith(color: tokens.colors.fg3, fontSize: 11),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
