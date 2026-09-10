import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

/// The new-tab (+) affordance pinned to the right edge of a
/// [LayrzWorkspaceTabs] bar.
///
/// Rendered only when the strip's `onNewTab` callback is non-null; the
/// parent strip is responsible for that null check and for pinning this
/// widget outside the scrollable tab region.
class LayrzWorkspaceNewTabButton extends StatelessWidget {
  /// Called when the user taps this affordance.
  final VoidCallback onTap;

  /// Creates a new [LayrzWorkspaceNewTabButton].
  const LayrzWorkspaceNewTabButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      container: true,
      button: true,
      label: 'New tab',
      child: LayrzTappable(
        onTap: onTap,
        borderRadius: tokens.radius.br1,
        color: const Color(0x00000000),
        hoverColor: tokens.colors.sf3,
        pressedColor: tokens.colors.sf4,
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.sp2),
          child: Icon(MdiIcons.plus, size: 18.0, color: tokens.colors.fg2),
        ),
      ),
    );
  }
}
