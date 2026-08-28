import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the refresh section for the showroom.
///
/// [LayrzRefreshIndicator] is a loading affordance, not a gesture widget: the
/// deliverable is the controller-driven state machine and the ring visual it
/// drives, and the pull-to-refresh drag is an optional, touch-only second
/// entry point into the same controller. This page demonstrates the
/// programmatic [LayrzRefreshController.refresh] path **first and most
/// prominently** — a "Refresh" button any pointer device can use — with the
/// drag gesture shown second, since a desktop user with a mouse or trackpad
/// cannot produce the drag at all.
///
/// The list below also demonstrates the indicator's floating layout (it never
/// pushes list content down) and its built-in fallback refresh button, which
/// appears automatically on this desktop showroom build since no touch drag
/// is available here -- see [LayrzRefreshFallbackButtonMode.auto].
class RefreshSection extends StatefulWidget {
  /// Creates a new [RefreshSection].
  const RefreshSection({super.key});

  @override
  State<RefreshSection> createState() => _RefreshSectionState();
}

class _RefreshSectionState extends State<RefreshSection> {
  /// Drives the demo's [LayrzRefreshIndicator] so the "Refresh" button below
  /// can trigger the exact same loading affordance the drag gesture does.
  late final LayrzRefreshController _controller;

  /// How many times a refresh has completed, shown in the list to make a
  /// completed refresh visibly change something.
  int _refreshCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = LayrzRefreshController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _simulateNetworkRefresh() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _refreshCount++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Refresh',
      description:
          'A loading affordance for a refresh cycle: controller-driven state machine, ring visual, and a '
          'programmatic refresh() as the primary trigger. The pull-to-refresh drag below is an optional, '
          'touch-only second way into the same controller, and the floating button in its top-right corner '
          'is a third, pointer-only way in -- shown automatically whenever no mouse or stylus has been '
          'detected.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Programmatic trigger (primary API)', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Any pointer device can trigger the exact same loading affordance a drag would -- no finger '
            'required. Refreshed $_refreshCount time${_refreshCount == 1 ? '' : 's'}.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzButton(
            labelText: 'Refresh',
            icon: MdiIcons.refresh,
            onTap: () => _controller.refresh(_simulateNetworkRefresh),
          ),
          SizedBox(height: tokens.spacing.sp5),
          Text('Drag-to-refresh (optional, touch-only)', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Drag down from the top of the list below. On a desktop with a mouse or trackpad this gesture '
            'cannot be produced -- use the button above, or the floating fallback button the indicator adds '
            'to the list itself, instead. The indicator floats over the list either way: it never resizes '
            'or pushes the items down.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          SizedBox(
            height: 320,
            child: LayrzRefreshIndicator(
              controller: _controller,
              onRefresh: _simulateNetworkRefresh,
              child: ListView.builder(
                itemCount: 20,
                itemBuilder: (context, index) {
                  return Container(
                    height: 48,
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp3),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: tokens.colors.divider)),
                    ),
                    child: Text('Item ${index + 1}', style: tokens.typography.body),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
