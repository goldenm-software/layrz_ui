/// How [LayrzRefreshIndicator]'s built-in fallback refresh button decides
/// whether to show itself.
///
/// **Why this exists**: [LayrzRefreshGestureDetector]'s pull gesture needs a
/// finger — a session with only a mouse or trackpad has no way to produce an
/// [OverscrollNotification] with real [DragUpdateDetails] at all. Rather than
/// leaving pointer-only sessions with no refresh affordance unless an
/// application developer remembers to add one manually, the indicator can
/// float its own button over the list.
///
/// **What [auto] reads**: [LayrzPlatform.isTouchOS] — `true` when the
/// underlying OS is Android or iOS, on web or native, `false` otherwise. The
/// button shows exactly when [LayrzPlatform.isTouchOS] is `false`. This is a
/// static, one-shot check with no subscription: unlike a live
/// capability signal, it never changes after the app starts, so there is no
/// listener to install or tear down.
///
/// A capability-based approach (reading whether a mouse or stylus pointer has
/// actually been observed connected, live) was considered and built first,
/// but rejected as unnecessary complexity for what this affordance needs —
/// see Kenny's call on DESIGN-95: an OS check is simpler and the two
/// mismatches it accepts are both harmless in the additive direction the
/// button leans.
///
/// **This is an OS check, not a capability check — accepted tradeoff, not an
/// oversight.** Per this package's own [LayrzPlatform]/[BuildContext.isCompact]
/// distinction, an OS read never substitutes for an input- or
/// viewport-capability read; [LayrzRefreshFallbackButtonMode.auto] uses one
/// anyway because the mismatches it produces are both acceptable:
///
/// - A **touchscreen laptop** (touch-capable, but running a non-touch OS)
///   gets the button even though its drag gesture also works — redundant,
///   not wrong.
/// - A **desktop OS with no mouse attached** still gets the button, since
///   [isTouchOS] cannot see that no pointer exists — again redundant, never
///   harmful, since the button is purely additive.
///
/// Both are one-directional: the button can appear where it is not strictly
/// needed, but it is never hidden from a session that actually needs it,
/// which is the failure mode that would matter. **Mobile web still gets
/// pull-only, correctly**: Android and iOS browsers report
/// [TargetPlatform.android]/[TargetPlatform.iOS] from [defaultTargetPlatform],
/// so [LayrzPlatform.isTouchOS] reads `true` there exactly as it does on
/// native — this was the original, explicit correction on this feature
/// ("remember that web can be also android and iOS") and it still holds
/// under the simpler check.
enum LayrzRefreshFallbackButtonMode {
  /// Show the button exactly when [LayrzPlatform.isTouchOS] is `false` — the
  /// default, and the entire point of this feature: no application code has
  /// to remember to wire up its own fallback.
  auto,

  /// Always show the fallback button, regardless of [LayrzPlatform.isTouchOS].
  /// Use this to force the affordance on for a surface the caller knows is
  /// pointer-driven even on a touch OS.
  enabled,

  /// Never show the fallback button, regardless of [LayrzPlatform.isTouchOS].
  /// Use this when a caller supplies their own refresh affordance elsewhere
  /// and the built-in one would be redundant.
  disabled,
}
