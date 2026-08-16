import 'package:flutter/widgets.dart';
import 'package:layrz_ui/extensions.dart';

/// A reusable shell for each showroom section.
///
/// Renders a consistent heading (from typography tokens), an optional description,
/// and a content area with shadow and surface styling. Every section of the showroom
/// uses this widget to ensure visual uniformity.
class ShowroomSection extends StatelessWidget {
  /// Creates a new [ShowroomSection].
  ///
  /// The [title] is rendered with [TextTheme.headlineSmall], the optional [description]
  /// with [TextTheme.bodyMedium], and the [child] content area is decorated with
  /// elevation-based shadow and surface color.
  const ShowroomSection({required this.title, required this.child, this.description, super.key});

  /// The section title, rendered prominently at the top.
  final String title;

  /// Optional descriptive text displayed below the title.
  final String? description;

  /// The content widget displayed inside the section's surface area.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.sp32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(title, style: tokens.typography.headlineSmall),

          // Description (if provided)
          if (description != null) ...[
            SizedBox(height: tokens.spacing.sp8),
            Text(description!, style: tokens.typography.bodyMedium.copyWith(color: tokens.colors.fg3)),
          ],

          // Content area with elevation shadow
          SizedBox(height: tokens.spacing.sp16),
          Container(decoration: tokens.shadow.elevation(elevation: 1), padding: tokens.spacing.padding, child: child),
        ],
      ),
    );
  }
}
