/// The named set of page transitions this design system ships.
///
/// Each value corresponds one-to-one with a static builder on
/// [LayrzPageTransitions] (`LayrzTransitionType.fade` maps to
/// `LayrzPageTransitions.fade`, and so on), so a caller who wants to select a
/// transition by value — e.g. from a single app-wide setting — can switch on
/// this enum once and resolve the matching builder, rather than branching on
/// the builder functions themselves. [LayrzPageTransitions] remains the
/// primary API for direct use; this enum exists for callers who need a
/// serializable/comparable handle on "which transition", such as a future
/// per-route configuration surface.
enum LayrzTransitionType {
  /// The outgoing page fades out while the incoming page fades in.
  ///
  /// Maps to [LayrzPageTransitions.fade]. This is the default transition
  /// this design system uses when no other transition is specified.
  fade,

  /// The incoming page slides in from the right edge; the outgoing page
  /// stays in place beneath it.
  ///
  /// Maps to [LayrzPageTransitions.slide].
  slide,

  /// The incoming page scales up from a slightly reduced size while fading
  /// in.
  ///
  /// Maps to [LayrzPageTransitions.scale].
  scale,

  /// The incoming page rotates into place while fading in.
  ///
  /// Maps to [LayrzPageTransitions.rotation].
  rotation,

  /// No transition at all — the incoming page appears instantly.
  ///
  /// Maps to [LayrzPageTransitions.none]. Useful for callers who want instant
  /// navigation, and this is also what every transition collapses to when
  /// [MediaQuery.disableAnimationsOf] reports that the user has requested
  /// reduced motion.
  none,
}
