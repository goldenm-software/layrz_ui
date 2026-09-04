import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';

import 'snackbar_type.dart';

/// An immutable transient feedback payload for the `LayrzSnackbarMessenger`.
///
/// [LayrzSnackbar] carries everything needed to render one white-card toast —
/// mandatory title/description text, a severity [type] (icon + accent color,
/// resolved from tokens), an optional [duration] override, an optional [onTap]
/// whole-card action, and optional below-content [actions] buttons. It is pure
/// data: it holds no [BuildContext], no animation state, and no overlay
/// knowledge. The messenger (`LayrzSnackbarMessenger`, U4) is responsible for
/// showing, queueing, animating, and dismissing it.
///
/// Construct one and pass it to `LayrzSnackbarMessenger.of(context).show(...)`:
/// ```dart
/// LayrzSnackbarMessenger.of(context).show(
///   const LayrzSnackbar(
///     titleText: 'Saved',
///     descriptionText: 'Your changes were saved successfully.',
///     type: LayrzSnackbarType.success,
///   ),
/// );
/// ```
///
/// **Custom type contract:** when [type] is [LayrzSnackbarType.custom], [icon]
/// and [color] are both **required** (a debug assertion enforces this). For
/// every other [type], [icon] and [color] must both be **null** — the type
/// itself determines the icon and accent color (DESIGN-60 §16.1). This
/// two-way assertion exists so a caller can never silently pass a `color` that
/// a non-custom type would ignore.
///
/// **Duration-driven dismissal (DESIGN-60, final):** [duration] is the single
/// source of truth for whether this toast auto-dismisses. There is no
/// `isDismissible` field — see [isPersistent] and [isAutoDismiss].
@immutable
class LayrzSnackbar {
  /// The title text of the snackbar.
  ///
  /// Required. Displayed as the bold first line of the card (design spec:
  /// 13px/500 weight). The messenger's live-region announcement reads this
  /// together with [descriptionText].
  final String titleText;

  /// The description text of the snackbar.
  ///
  /// Required. Displayed as the second line of the card (design spec: 12px,
  /// line-height 1.4, at 78% opacity over the filled surface). The
  /// messenger's live-region announcement reads this together with [titleText].
  final String descriptionText;

  /// The semantic type of the snackbar.
  ///
  /// Determines the default icon and filled surface color via
  /// [LayrzSnackbarType.icon] and [LayrzSnackbarType.filledSurface]. Defaults to
  /// [LayrzSnackbarType.success]. When [type] is [LayrzSnackbarType.custom],
  /// [icon] and [color] control appearance instead; otherwise they must be null.
  final LayrzSnackbarType type;

  /// The custom icon glyph, valid **only** when [type] is [LayrzSnackbarType.custom].
  ///
  /// Must be non-null when [type] is custom (debug-asserted) and must be null
  /// for every other [type] (also debug-asserted) — non-custom types derive
  /// their icon from [LayrzSnackbarType.icon].
  final IconData? icon;

  /// The custom fill color, valid **only** when [type] is [LayrzSnackbarType.custom].
  ///
  /// Must be non-null when [type] is custom (debug-asserted) and must be null
  /// for every other [type] (also debug-asserted) — non-custom types derive
  /// their filled surface from [LayrzSnackbarType.filledSurface].
  final Color? color;

  /// The duration this snackbar remains visible before auto-dismissing.
  ///
  /// This is the **single source of truth** for dismissal behaviour
  /// (DESIGN-60, duration-driven dismissal — final): there is no separate
  /// `isDismissible` field.
  ///
  /// - **Non-null (default: `Duration(seconds: 10)`, flat across all
  ///   [type]s):** the toast auto-dismisses. The messenger shows the draining
  ///   progress bar, runs the drain timer, auto-dismisses on timeout, and
  ///   shows a manual close (✕) button. See [isAutoDismiss].
  /// - **Explicit `null`:** the toast is **persistent** — no progress bar, no
  ///   drain timer, no auto-dismiss, and no close button. It can only be
  ///   removed programmatically (`dismissAll()`, an action button's `onTap`,
  ///   or the whole-card [onTap] if set). See [isPersistent].
  ///
  /// Pass `null` explicitly to opt into persistence; there is no flag
  /// separate from this value.
  final Duration? duration;

  /// Called when the user taps the snackbar body.
  ///
  /// When non-null, the messenger renders a visible whole-card tappable
  /// affordance (DESIGN-60 §16.3 / the "onTap visual cue" requirement) and, on
  /// tap, runs this callback **and then dismisses** the snackbar — there is no
  /// tap-without-dismiss mode. When null, the snackbar body is not tappable
  /// (only the close affordance, when [isAutoDismiss], or an [actions] button
  /// can dismiss it).
  ///
  /// This is distinct from [actions]: a whole-card [onTap] always dismisses
  /// after running, while an individual action button's own `onTap` does not
  /// dismiss automatically.
  final VoidCallback? onTap;

  /// The action buttons rendered **below** the title/description content.
  ///
  /// Typed as `List<LayrzButton>` (not a generic `Widget` list) so only
  /// [LayrzButton]s are accepted — a compile-time enforcement of "strictly
  /// LayrzButton" (DESIGN-60 rework). Defaults to an empty list, which renders
  /// no action row at all. Multiple buttons are supported (the messenger/view
  /// lays them out as a row that wraps on compact viewports) — e.g. a semantic
  /// action ("Manage rule") alongside a neutral one ("Dismiss").
  ///
  /// Each button is self-styled: the caller picks its `type`/`style`/`color`.
  /// Tapping an action button runs **that button's own `onTap`** — it does
  /// **not** automatically dismiss the snackbar. If a caller wants an action tap
  /// to also dismiss, its `onTap` must call the messenger's dismiss itself. This
  /// is distinct from the whole-card [onTap] (below), which always dismisses
  /// after running.
  final List<LayrzButton> actions;

  /// Creates a [LayrzSnackbar].
  ///
  /// Debug-asserts, in both directions, that [icon] and [color] are supplied
  /// exactly when [type] is [LayrzSnackbarType.custom]:
  /// - `type == custom` ⇒ [icon] and [color] must both be non-null.
  /// - `type != custom` ⇒ [icon] and [color] must both be null.
  const LayrzSnackbar({
    required this.titleText,
    required this.descriptionText,
    this.type = LayrzSnackbarType.success,
    this.icon,
    this.color,
    this.duration = const Duration(seconds: 10),
    this.onTap,
    this.actions = const [],
  }) : assert(
         (type == LayrzSnackbarType.custom && icon != null && color != null) ||
             (type != LayrzSnackbarType.custom && icon == null && color == null),
         'LayrzSnackbar: when type is LayrzSnackbarType.custom, both icon and color '
         'must be supplied; for every other type, both icon and color must be null.',
       );

  /// Whether this snackbar is persistent — i.e. never auto-dismisses.
  ///
  /// `true` exactly when [duration] is `null`. A persistent snackbar shows no
  /// draining progress bar, no timer, and no close (✕) button; it can only be
  /// removed programmatically (`dismissAll()`, an [actions] button's `onTap`,
  /// or the whole-card [onTap] if set).
  bool get isPersistent => duration == null;

  /// Whether this snackbar auto-dismisses after [duration] elapses.
  ///
  /// `true` exactly when [duration] is non-null — the logical complement of
  /// [isPersistent]. When `true`, the messenger shows the draining progress
  /// bar, runs the drain timer, auto-dismisses on timeout, and shows a manual
  /// close (✕) button.
  bool get isAutoDismiss => duration != null;

  /// Private sentinel used in [copyWith] to distinguish "field not passed"
  /// from "explicitly set to null", since `null` is meaningful for [duration]
  /// (it selects persistence, not "keep the current value").
  static const Object _unset = Object();

  /// Returns a copy of this snackbar with the given fields replaced.
  ///
  /// Because `null` is a meaningful value for [duration] (it means
  /// "persistent", not "unspecified"), [duration] uses a private sentinel
  /// default rather than being copied via `??`. Omitting [duration] keeps the
  /// current value; passing `null` explicitly clears it to persistent:
  ///
  /// ```dart
  /// // Keep the current duration:
  /// final copy = snackbar.copyWith(titleText: 'New title');
  ///
  /// // Explicitly clear it to persistent:
  /// final persistent = snackbar.copyWith(duration: null);
  /// assert(persistent.isPersistent);
  /// ```
  ///
  /// Note: because [icon] and [color] are only valid together with a matching
  /// [type], changing [type] via `copyWith` without also updating [icon]/[color]
  /// can produce a combination that fails the constructor's debug assertion if
  /// passed back into a new [LayrzSnackbar]. `copyWith` itself does not
  /// re-validate — construct a fresh [LayrzSnackbar] directly if type and
  /// icon/color must change together.
  LayrzSnackbar copyWith({
    String? titleText,
    String? descriptionText,
    LayrzSnackbarType? type,
    IconData? icon,
    Color? color,
    Object? duration = _unset,
    VoidCallback? onTap,
    List<LayrzButton>? actions,
  }) {
    return LayrzSnackbar(
      titleText: titleText ?? this.titleText,
      descriptionText: descriptionText ?? this.descriptionText,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      duration: identical(duration, _unset) ? this.duration : duration as Duration?,
      onTap: onTap ?? this.onTap,
      actions: actions ?? this.actions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzSnackbar &&
          runtimeType == other.runtimeType &&
          titleText == other.titleText &&
          descriptionText == other.descriptionText &&
          type == other.type &&
          icon == other.icon &&
          color == other.color &&
          duration == other.duration &&
          onTap == other.onTap &&
          _actionsEqual(actions, other.actions);

  @override
  int get hashCode => Object.hash(
    titleText,
    descriptionText,
    type,
    icon,
    color,
    duration,
    onTap,
    Object.hashAll(actions),
  );

  /// Element-wise equality for the [actions] list, since [List] does not override `==`.
  static bool _actionsEqual(List<LayrzButton> a, List<LayrzButton> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
