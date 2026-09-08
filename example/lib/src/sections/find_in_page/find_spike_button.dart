import 'package:flutter/widgets.dart';

import 'package:layrz_ui/layrz_ui.dart';

/// A minimal, token-styled tappable button used only by `LayrzFindSpike`'s
/// own top bar (see `find_spike.dart`) — deliberately not `LayrzButton`,
/// since the spike is meant to stay self-contained and cheap to iterate on
/// without pulling in the full button component's surface area. Built from
/// bare `widgets.dart` primitives ([GestureDetector] + [DecoratedBox]) rather
/// than `Material`/`InkWell`, matching the rest of the package's
/// Material-free constraint.
class SpikeButton extends StatelessWidget {
  /// The button's visible text.
  final String label;

  /// Called when the button is tapped.
  final VoidCallback onTap;

  /// Creates a [SpikeButton].
  const SpikeButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.colors.primary.shade500,
            borderRadius: tokens.radius.br2,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2, vertical: tokens.spacing.sp1),
            child: Text(
              label,
              style: tokens.typography.body.copyWith(color: tokens.colors.sf1),
            ),
          ),
        ),
      ),
    );
  }
}
