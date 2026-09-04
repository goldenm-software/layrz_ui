import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// The content widget for the snackbar section.
///
/// Demonstrates [LayrzSnackbar] fired through [LayrzSnackbarMessenger]: one
/// button per severity type, a custom-color/custom-icon toast, a toast with
/// an [LayrzSnackbar.onTap] action affordance, a persistent (`duration:
/// null`) toast, one and two [LayrzSnackbar.actions] demos, and a "fire 6
/// quickly" button that demonstrates the accordion deck's ≤3-visible cap,
/// its hover fan-out, and the "+N / Dismiss all" overflow affordance.
///
/// The messenger host is installed automatically by [LayrzApp] — this
/// section never constructs a [LayrzSnackbarMessenger] itself, it only calls
/// `LayrzSnackbarMessenger.of(context).show(...)`.
class SnackbarSection extends StatelessWidget {
  /// Creates a new [SnackbarSection].
  const SnackbarSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Snackbars',
      description:
          'Material-free transient feedback toasts — five semantic types, a custom treatment, '
          'an onTap action affordance, persistent (duration: null) toasts, below-content '
          'LayrzButton actions, and accordion-deck stacking with overflow',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SeverityTypesDemo(tokens: tokens),
          SizedBox(height: tokens.spacing.sp5),
          _CustomTypeDemo(tokens: tokens),
          SizedBox(height: tokens.spacing.sp5),
          _OnTapDemo(tokens: tokens),
          SizedBox(height: tokens.spacing.sp5),
          _PersistentDemo(tokens: tokens),
          SizedBox(height: tokens.spacing.sp5),
          _ActionsDemo(tokens: tokens),
          SizedBox(height: tokens.spacing.sp5),
          _StackingOverflowDemo(tokens: tokens),
        ],
      ),
    );
  }
}

/// Demonstrates all five non-custom [LayrzSnackbarType] values, each using
/// the flat 10-second default [LayrzSnackbar.duration].
class _SeverityTypesDemo extends StatelessWidget {
  /// Creates a new [_SeverityTypesDemo].
  const _SeverityTypesDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Severity Types', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'Each type resolves its own icon and accent color on the white card. All of these '
          'use the flat 10-second default duration — auto-dismissing with a top progress bar '
          'and a close button.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        Wrap(
          spacing: tokens.spacing.sp3,
          runSpacing: tokens.spacing.sp3,
          children: [
            _SnackbarTriggerButton(
              labelText: 'Success',
              icon: MdiIcons.checkCircleOutline,
              type: .success,
              onTap: () => LayrzSnackbarMessenger.of(context).show(
                const LayrzSnackbar(
                  titleText: 'Saved',
                  descriptionText: 'Your changes were saved successfully.',
                ),
              ),
            ),
            _SnackbarTriggerButton(
              labelText: 'Danger',
              icon: MdiIcons.alertCircleOutline,
              type: .danger,
              onTap: () => LayrzSnackbarMessenger.of(context).show(
                const LayrzSnackbar(
                  titleText: 'Delete failed',
                  descriptionText: 'The record could not be deleted. Please try again.',
                  type: LayrzSnackbarType.danger,
                ),
              ),
            ),
            _SnackbarTriggerButton(
              labelText: 'Warning',
              icon: MdiIcons.alertOutline,
              type: .warning,
              onTap: () => LayrzSnackbarMessenger.of(context).show(
                const LayrzSnackbar(
                  titleText: 'Low battery',
                  descriptionText: 'This device is running low on battery.',
                  type: LayrzSnackbarType.warning,
                ),
              ),
            ),
            _SnackbarTriggerButton(
              labelText: 'Info',
              icon: MdiIcons.informationOutline,
              type: .info,
              onTap: () => LayrzSnackbarMessenger.of(context).show(
                const LayrzSnackbar(
                  titleText: 'New version available',
                  descriptionText: 'A newer version of the app is ready to install.',
                  type: LayrzSnackbarType.info,
                ),
              ),
            ),
            _SnackbarTriggerButton(
              labelText: 'Context',
              icon: MdiIcons.messageTextOutline,
              type: .context,
              onTap: () => LayrzSnackbarMessenger.of(context).show(
                const LayrzSnackbar(
                  titleText: 'Message archived',
                  descriptionText: 'The conversation was moved to the archive.',
                  type: LayrzSnackbarType.context,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates [LayrzSnackbarType.custom] with explicit `icon` and `color`.
class _CustomTypeDemo extends StatelessWidget {
  /// Creates a new [_CustomTypeDemo].
  const _CustomTypeDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Custom Type', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'When type is custom, icon and color are both required and take full control '
          'over the filled surface.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        _SnackbarTriggerButton(
          labelText: 'Custom (purple star)',
          icon: MdiIcons.star,
          type: .custom,
          color: const Color(0xFF9C27B0),
          onTap: () => LayrzSnackbarMessenger.of(context).show(
            LayrzSnackbar(
              titleText: 'Achievement unlocked',
              descriptionText: 'You reached a new milestone.',
              type: LayrzSnackbarType.custom,
              icon: MdiIcons.star,
              color: const Color(0xFF9C27B0),
            ),
          ),
        ),
        SizedBox(height: tokens.spacing.sp3),
        Text('Long content', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'TO DO',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        _SnackbarTriggerButton(
          labelText: 'Long content',
          icon: MdiIcons.star,
          type: .custom,
          color: tokens.colors.primary,
          onTap: () => LayrzSnackbarMessenger.of(context).show(
            LayrzSnackbar(
              titleText: 'This is a long content',
              descriptionText: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
              type: LayrzSnackbarType.custom,
              icon: MdiIcons.home,
              color: tokens.colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Demonstrates [LayrzSnackbar.onTap]: the toast renders a visible action
/// affordance, and tapping it runs the callback and then dismisses.
class _OnTapDemo extends StatefulWidget {
  /// Creates a new [_OnTapDemo].
  const _OnTapDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  State<_OnTapDemo> createState() => _OnTapDemoState();
}

/// State for [_OnTapDemo], tracking how many times the action fired.
class _OnTapDemoState extends State<_OnTapDemo> {
  /// The number of times the snackbar's action affordance was tapped.
  int _actionCount = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('onTap Action', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'When onTap is set, the toast shows an action affordance. Tapping it runs the '
          'callback and dismisses the toast — there is no tap-without-dismiss mode. '
          'Action taps so far: $_actionCount.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        _SnackbarTriggerButton(
          labelText: 'Undo delete',
          icon: MdiIcons.undo,
          type: .context,
          onTap: () => LayrzSnackbarMessenger.of(context).show(
            LayrzSnackbar(
              titleText: 'Item deleted',
              descriptionText: 'Tap to undo this action.',
              type: LayrzSnackbarType.context,
              onTap: () => setState(() => _actionCount++),
            ),
          ),
        ),
      ],
    );
  }
}

/// Demonstrates `duration: null` — the toast becomes **persistent**: no top
/// progress bar, no drain timer, no auto-dismiss, and no close button. It can
/// only be removed programmatically (`dismissAll()`, an [LayrzSnackbar.actions]
/// button's `onTap`, or the whole-card [LayrzSnackbar.onTap] if set).
class _PersistentDemo extends StatelessWidget {
  /// Creates a new [_PersistentDemo].
  const _PersistentDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Persistent (duration: null)', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'duration is the single source of truth for dismissal. Passing null makes the toast '
          'persistent: no progress bar, no drain timer, no auto-dismiss, and no close button. '
          'It only clears via the stack\'s "Dismiss all" overflow action.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        _SnackbarTriggerButton(
          labelText: 'Syncing…',
          icon: MdiIcons.sync,
          type: .info,
          onTap: () => LayrzSnackbarMessenger.of(context).show(
            const LayrzSnackbar(
              titleText: 'Syncing in progress',
              descriptionText: 'This will clear automatically — it cannot be closed manually.',
              type: LayrzSnackbarType.info,
              duration: null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Demonstrates [LayrzSnackbar.actions]: a below-content row of caller-typed
/// [LayrzButton]s, rendered under the title/description and independent of
/// the whole-card [LayrzSnackbar.onTap].
///
/// Shows both a single-action toast ("Retry") and a two-action toast
/// ("Manage rule" tinted to the warning severity, plus a neutral "Dismiss")
/// where the second button calls
/// [LayrzSnackbarMessengerState.dismissAll] to close the stack, since action
/// buttons never auto-dismiss on their own.
class _ActionsDemo extends StatelessWidget {
  /// Creates a new [_ActionsDemo].
  const _ActionsDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'actions renders a row of caller-supplied LayrzButtons below the title/description. '
          'Each button keeps its own onTap and does not auto-dismiss the toast — only the '
          'whole-card onTap does that, so an action that should close the stack calls the '
          'messenger\'s dismissAll() itself.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        Wrap(
          spacing: tokens.spacing.sp3,
          runSpacing: tokens.spacing.sp3,
          children: [
            _SnackbarTriggerButton(
              labelText: 'Upload failed (1 action)',
              icon: MdiIcons.cloudAlert,
              type: .danger,
              onTap: () => LayrzSnackbarMessenger.of(context).show(
                LayrzSnackbar(
                  titleText: 'Upload failed',
                  descriptionText: 'The file could not be uploaded to the server.',
                  type: LayrzSnackbarType.danger,
                  actions: [
                    LayrzButton(
                      labelText: 'Retry',
                      type: LayrzButtonType.danger,
                      style: LayrzButtonStyle.text,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            _SnackbarTriggerButton(
              labelText: 'Rule triggered (2 actions)',
              icon: MdiIcons.shieldAlertOutline,
              type: .warning,
              onTap: () {
                final messenger = LayrzSnackbarMessenger.of(context);
                messenger.show(
                  LayrzSnackbar(
                    titleText: 'Rule triggered',
                    descriptionText: 'A geofence rule fired for this asset.',
                    type: LayrzSnackbarType.warning,
                    actions: [
                      LayrzButton(
                        labelText: 'Manage rule',
                        type: LayrzButtonType.warning,
                        style: LayrzButtonStyle.text,
                        onTap: () {},
                      ),
                      LayrzButton(
                        labelText: 'Dismiss',
                        type: LayrzButtonType.custom,
                        color: tokens.colors.fg3,
                        style: LayrzButtonStyle.text,
                        onTap: messenger.dismissAll,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates the accordion deck's ≤3-visible cap, its hover fan-out, and
/// the "+N / Dismiss all" overflow affordance by firing six toasts in quick
/// succession.
class _StackingOverflowDemo extends StatelessWidget {
  /// Creates a new [_StackingOverflowDemo].
  const _StackingOverflowDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Stacking & Overflow', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'Only the newest $kLayrzSnackbarMaxVisible toasts are shown. At rest they sit in a '
          'compact deck at the top-center of the screen — the newest card fully visible, older '
          'ones peeking a slim sliver behind it. Hover the deck to fan every card out and read '
          'its full content; move away to collapse back. Anything beyond that collapses into a '
          '"+N · Dismiss all" chip above the deck.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        _SnackbarTriggerButton(
          labelText: 'Fire 6 quickly',
          icon: MdiIcons.lightningBolt,
          type: .custom,
          color: context.tokens.colors.primary,
          onTap: () {
            final messenger = LayrzSnackbarMessenger.of(context);
            const types = [
              LayrzSnackbarType.success,
              LayrzSnackbarType.info,
              LayrzSnackbarType.warning,
              LayrzSnackbarType.danger,
              LayrzSnackbarType.context,
              LayrzSnackbarType.success,
            ];
            for (var i = 0; i < types.length; i++) {
              messenger.show(
                LayrzSnackbar(
                  titleText: 'Toast #${i + 1}',
                  descriptionText: 'Fired as part of the "fire 6 quickly" overflow demo.',
                  type: types[i],
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

/// A small [LayrzButton] wrapper shared by every trigger in this section, so
/// each demo only needs to supply its label, icon, and tap handler.
class _SnackbarTriggerButton extends StatelessWidget {
  /// Creates a new [_SnackbarTriggerButton].
  const _SnackbarTriggerButton({
    required this.labelText,
    required this.icon,
    required this.onTap,
    required this.type,
    this.color,
  });

  /// The button's visible label.
  final String labelText;

  /// The leading icon glyph.
  final IconData icon;

  /// Called when the button is tapped.
  final VoidCallback onTap;

  /// type of the button
  final LayrzButtonType type;

  /// Color of the button, only used when [type] is [LayrzButtonType.custom].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return LayrzButton(
      labelText: labelText,
      icon: icon,
      onTap: onTap,
      type: type,
      color: color,
      style: LayrzButtonStyle.filled,
    );
  }
}
