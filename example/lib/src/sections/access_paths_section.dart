import 'package:flutter/widgets.dart';

import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Demonstrates the two token access patterns side by side.
///
/// Shows several values fetched both ways (via [LayrzTokenizer] and via
/// [context.tokens]) and asserts they are equal at runtime. If they ever
/// diverge, the showroom displays a mismatch indicator, proving the access
/// paths remain consistent.
class AccessPathsSection extends StatelessWidget {
  const AccessPathsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tokenizer = LayrzTokenizer.of(context);

    return ShowroomSection(
      title: 'Token Access Paths',
      description: 'Demonstrating D12: two equivalent token access patterns',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Both access paths must return the same values',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg2),
          ),
          SizedBox(height: tokens.spacing.sp3),

          // Primary color
          _AccessPathComparison(
            label: 'primary',
            path1: 'context.tokens.colors.primary',
            value1: tokens.colors.primary.toHex(),
            path2: 'LayrzTokenizer.of(context).primary',
            value2: tokenizer.primary.toHex(),
            match: tokens.colors.primary == tokenizer.primary,
          ),

          SizedBox(height: tokens.spacing.sp3),

          // Spacing base
          _AccessPathComparison(
            label: 'spacing (base)',
            path1: 'context.tokens.spacing.sp2',
            value1: '${tokens.spacing.sp2}',
            path2: 'LayrzTokenizer.of(context).spacing',
            value2: '${tokenizer.spacing}',
            match: tokens.spacing.sp2 == tokenizer.spacing,
          ),

          SizedBox(height: tokens.spacing.sp3),

          // Radius base
          _AccessPathComparison(
            label: 'radius (base)',
            path1: 'context.tokens.radius.r2',
            value1: '${tokens.radius.r2}',
            path2: 'LayrzTokenizer.of(context).radius',
            value2: '${tokenizer.radius}',
            match: tokens.radius.r2 == tokenizer.radius,
          ),

          SizedBox(height: tokens.spacing.sp3),

          // Border width
          _AccessPathComparison(
            label: 'borderWidth',
            path1: 'context.tokens.border.base',
            value1: '${tokens.border.base}',
            path2: 'LayrzTokenizer.of(context).borderWidth',
            value2: '${tokenizer.borderWidth}',
            match: tokens.border.base == tokenizer.borderWidth,
          ),

          SizedBox(height: tokens.spacing.sp3),

          // Success color
          _AccessPathComparison(
            label: 'success',
            path1: 'context.tokens.colors.success',
            value1: tokens.colors.success.toHex(),
            path2: 'LayrzTokenizer.of(context).success',
            value2: tokenizer.success.toHex(),
            match: tokens.colors.success == tokenizer.success,
          ),
        ],
      ),
    );
  }
}

/// A row comparing two access paths for a single token value.
///
/// Displays both paths side by side and renders a visual indicator (✓ or ✗)
/// based on whether the values match at runtime.
class _AccessPathComparison extends StatelessWidget {
  /// Creates a new [_AccessPathComparison].
  const _AccessPathComparison({
    required this.label,
    required this.path1,
    required this.value1,
    required this.path2,
    required this.value2,
    required this.match,
  });

  /// The token name being compared.
  final String label;

  /// The first access path as a code string.
  final String path1;

  /// The value fetched via the first access path.
  final String value1;

  /// The second access path as a code string.
  final String path2;

  /// The value fetched via the second access path.
  final String value2;

  /// Whether the two values match.
  final bool match;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Token name
            Row(
              children: [
                Expanded(child: Text(label, style: tokens.typography.title)),
                // Match indicator
                Container(
                  width: tokens.spacing.sp5,
                  height: tokens.spacing.sp5,
                  decoration: BoxDecoration(
                    color: match ? tokens.colors.success : tokens.colors.danger,
                    borderRadius: BorderRadius.circular(tokens.radius.full),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    match ? '✓' : '✗',
                    style: tokens.typography.label.copyWith(
                      color: tokens.colors.sf2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: tokens.spacing.sp3),

            // Path 1
            _AccessPathRow(path: path1, value: value1, tokens: tokens),

            SizedBox(height: tokens.spacing.sp2),

            // Path 2
            _AccessPathRow(path: path2, value: value2, tokens: tokens),
          ],
        );
      },
    );
  }
}

/// A row displaying a single access path and its value.
class _AccessPathRow extends StatelessWidget {
  /// Creates a new [_AccessPathRow].
  const _AccessPathRow({required this.path, required this.value, required this.tokens});

  /// The access path as a code string.
  final String path;

  /// The value fetched via this path.
  final String value;

  /// The token set.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: tokens.colors.sf3, borderRadius: tokens.radius.br2),
      padding: tokens.spacing.pd2,
      child: Row(
        children: [
          Expanded(
            child: Text(
              path,
              style: tokens.typography.label.copyWith(fontFamily: 'monospace', fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: tokens.spacing.sp3),
          Text(
            '→ $value',
            style: tokens.typography.label.copyWith(
              color: tokens.colors.fg3,
              fontFamily: 'monospace',
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
