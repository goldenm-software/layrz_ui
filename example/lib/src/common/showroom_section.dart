import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// A reusable shell for each showroom section.
///
/// Renders a consistent heading (from typography tokens), an optional description,
/// and a content area with shadow and surface styling. Every section of the showroom
/// uses this widget to ensure visual uniformity.
class ShowroomSection extends StatelessWidget {
  /// Creates a new [ShowroomSection].
  ///
  /// The [title] is rendered with [TextTheme.headline], the optional [description]
  /// with [TextTheme.body], and the [child] content area is displayed inside
  /// a [LayrzCard] for consistent elevation and surface styling.
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.all(context.tokens.spacing.sp16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Title
            Text(title, style: tokens.typography.headline),

            // Description (if provided)
            if (description != null) ...[
              SizedBox(height: tokens.spacing.sp8),
              Text(
                description!,
                style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
                maxLines: 3,
              ),
            ],

            // Content area with LayrzCard for elevation and surface styling
            SizedBox(height: tokens.spacing.sp16),
            LayrzCard(
              elevation: 1,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
