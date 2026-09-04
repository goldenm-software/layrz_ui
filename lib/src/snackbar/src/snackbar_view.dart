import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import 'snackbar.dart';
import 'snackbar_style_spec.dart';

/// Renders a single [LayrzSnackbar] card in the white-card treatment
/// (DESIGN-60 rework — supersedes the first build's filled/full-color
/// "Turn-2" treatment).
///
/// [LayrzSnackbarView] is pure presentation: it paints exactly one card from a
/// [snackbar], its resolved [style], and a host-supplied [progress] value
/// (0.0–1.0) driving the top-edge progress bar. It owns **no timer, no
/// [AnimationController], and no overlay** — the messenger is the sole owner
/// of timing and animation, and drives [progress] frame-by-frame (or
/// value-by-value) as the toast's remaining duration elapses.
///
/// Anatomy (top to bottom): when [snackbar] is auto-dismissing
/// (`LayrzSnackbar.isAutoDismiss`), a thin progress bar flush at the top edge
/// of the card; then a row of `[semantic icon] [title + description column]
/// [close LayrzButton — aside slot, auto-dismiss only]`; then — only when
/// [LayrzSnackbar.actions] is non-empty — a wrapping row of the caller's
/// [LayrzButton]s below the content. The aside slot is reserved for the close
/// affordance only; actions never render there. A **persistent** snackbar
/// (`LayrzSnackbar.isPersistent`) renders neither the progress bar nor the
/// close button — just the icon/title/description content and, if present,
/// the actions row (DESIGN-60, duration-driven dismissal — final).
///
/// The widget never dismisses itself: [onClose] is a plain [VoidCallback]
/// supplied by the host, which is responsible for actually removing the toast
/// from its stack. Each [LayrzSnackbar.actions] button carries its own
/// `onTap` and is rendered as-is — tapping one runs that button's callback
/// only, never [onCardTap] and never an implicit dismiss.
class LayrzSnackbarView extends StatefulWidget {
  /// The snackbar payload to render — supplies [LayrzSnackbar.titleText],
  /// [LayrzSnackbar.descriptionText], [LayrzSnackbar.actions], and
  /// [LayrzSnackbar.isAutoDismiss] (which gates whether the progress bar and
  /// close affordance are shown).
  final LayrzSnackbar snackbar;

  /// The resolved paint properties for this card, computed by
  /// `LayrzSnackbarStyleSpec.resolve` from [snackbar]'s type/color and the
  /// live theme tokens.
  final LayrzSnackbarStyleSpec style;

  /// The remaining-duration fraction driving the top-edge progress bar, from
  /// `1.0` (just shown, full width) to `0.0` (about to auto-dismiss, zero
  /// width).
  ///
  /// Only meaningful when [snackbar] is auto-dismissing
  /// (`LayrzSnackbar.isAutoDismiss`) — the progress bar is not rendered at
  /// all for a persistent [snackbar], so this value is ignored in that case.
  /// Supplied by the host on every animation tick; this widget performs no
  /// clamping — callers are expected to pass values already within `0.0`–`1.0`.
  final double progress;

  /// Called when the user activates the close (✕) affordance.
  ///
  /// Only reachable when [snackbar] is auto-dismissing
  /// (`LayrzSnackbar.isAutoDismiss`), since the close affordance itself is
  /// not rendered for a persistent snackbar. This widget does not dismiss
  /// itself — the host is expected to remove the toast in response.
  final VoidCallback? onClose;

  /// Called when the user taps the card body (outside the close button and
  /// any [LayrzSnackbar.actions] button).
  ///
  /// When non-null, the whole card becomes tappable. The host is expected to
  /// run [snackbar]'s own `onTap` and then dismiss the toast in response to
  /// this callback — this widget performs neither itself. Tapping a close or
  /// action button never also fires this callback.
  final VoidCallback? onCardTap;

  /// Creates a [LayrzSnackbarView].
  const LayrzSnackbarView({
    super.key,
    required this.snackbar,
    required this.style,
    required this.progress,
    this.onClose,
    this.onCardTap,
  });

  @override
  State<LayrzSnackbarView> createState() => _LayrzSnackbarViewState();
}

class _LayrzSnackbarViewState extends State<LayrzSnackbarView> {
  /// The size of the leading semantic icon.
  static const double _iconSize = 22;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final snackbar = widget.snackbar;
    final style = widget.style;

    final icon = snackbar.type.icon ?? snackbar.icon;

    final content = Padding(
      padding: EdgeInsets.fromLTRB(tokens.spacing.sp3, tokens.spacing.sp3, tokens.spacing.sp2, tokens.spacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: _iconSize, color: style.iconColor),
                SizedBox(width: tokens.spacing.sp2),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snackbar.titleText,
                      style: tokens.typography.body.copyWith(
                        fontWeight: tokens.typography.title.fontWeight,
                        fontVariations: tokens.typography.title.fontVariations,
                        color: style.titleColor,
                      ),
                    ),
                    SizedBox(height: tokens.spacing.sp1 / 2),
                    Text(
                      snackbar.descriptionText,
                      style: tokens.typography.body.copyWith(
                        color: style.descriptionColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (snackbar.isAutoDismiss) ...[
                SizedBox(width: tokens.spacing.sp2),
                LayrzButton(
                  labelText: l10n.snackbarDismissLabel,
                  icon: MdiIcons.close,
                  style: LayrzButtonStyle.textFab,
                  onTap: widget.onClose,
                ),
              ],
            ],
          ),
          if (snackbar.actions.isNotEmpty) ...[
            SizedBox(height: tokens.spacing.sp2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: tokens.spacing.sp2,
              children: snackbar.actions,
            ),
          ],
        ],
      ),
    );

    final card = Container(
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: style.surfaceColor,
        border: Border.all(color: style.borderColor, width: 1),
        borderRadius: tokens.radius.br2,
        boxShadow: style.shadow,
      ),
      child: ClipRRect(
        borderRadius: tokens.radius.br2,
        // A persistent snackbar (isAutoDismiss == false) has no timer to
        // show progress for, so it skips the progress-bar Stack entirely —
        // just the content, per DESIGN-60's duration-driven dismissal.
        child: snackbar.isAutoDismiss
            ? Stack(
                children: [
                  content,
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: _buildProgressBar(style),
                  ),
                ],
              )
            : content,
      ),
    );

    final announcement = '${l10n.snackbarAnnouncementPrefix}. ${snackbar.titleText}. ${snackbar.descriptionText}';

    final semanticCard = Semantics(
      liveRegion: true,
      label: announcement,
      container: true,
      explicitChildNodes: true,
      button: widget.onCardTap != null,
      enabled: widget.onCardTap != null ? true : null,
      onTap: widget.onCardTap,
      child: card,
    );

    if (widget.onCardTap == null) {
      return semanticCard;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onCardTap,
        child: semanticCard,
      ),
    );
  }

  /// Builds the top-edge progress bar, whose width is
  /// [LayrzSnackbarView.progress] as a fraction of the card's full width.
  ///
  /// Driven purely by the host-supplied [LayrzSnackbarView.progress] — this
  /// widget owns no timer and performs no animation of its own.
  Widget _buildProgressBar(LayrzSnackbarStyleSpec style) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widget.progress.clamp(0.0, 1.0),
        child: Container(
          height: 3,
          color: style.progressColor,
        ),
      ),
    );
  }
}
