import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the skeleton section for the showroom.
///
/// Demonstrates [LayrzSkeleton] composing a tree of shape primitives
/// ([LayrzSkeletonCircle], [LayrzSkeletonLine], [LayrzSkeletonBox]) under one
/// shared shimmer sweep: a realistic profile-card placeholder (avatar + two
/// lines + an image box) and a short list of row skeletons, showing that
/// every primitive in a single [LayrzSkeleton.child] shimmers in phase.
class SkeletonSection extends StatelessWidget {
  /// Creates a new [SkeletonSection].
  const SkeletonSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Skeleton',
      description:
          'A loading placeholder built from caller-composed shape primitives, driven by '
          'one shared shimmer sweep so nothing drifts out of phase.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile card placeholder', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'One LayrzSkeleton wrapping an avatar circle, two text lines, and an image box '
            '-- all shimmering together.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzSkeleton(
            child: Container(
              padding: EdgeInsets.all(tokens.spacing.sp3),
              decoration: BoxDecoration(
                border: Border.all(color: tokens.colors.divider),
                borderRadius: tokens.radius.br2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const LayrzSkeletonCircle(diameter: 48),
                      SizedBox(width: tokens.spacing.sp3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayrzSkeletonLine(width: 140, matchTextStyle: tokens.typography.title),
                            SizedBox(height: tokens.spacing.sp2),
                            const LayrzSkeletonLine(width: 90),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.spacing.sp3),
                  const LayrzSkeletonBox(width: double.infinity, height: 120, borderRadius: 8),
                ],
              ),
            ),
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('Row list placeholder', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'A short list of rows, each a small circle plus a line -- the loading shape of '
            'a list of contacts or notifications.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzSkeleton(
            child: Column(
              children: List.generate(4, (index) {
                final width = 220.0 - (index * 24);
                return Padding(
                  padding: EdgeInsets.only(bottom: index == 3 ? 0 : tokens.spacing.sp3),
                  child: Row(
                    children: [
                      const LayrzSkeletonCircle(diameter: 32),
                      SizedBox(width: tokens.spacing.sp2),
                      LayrzSkeletonLine(width: width),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
