/// Opaque token returned by [LayrzShortcutState.register] and consumed by
/// [LayrzShortcutState.deregister].
///
/// A [LayrzShortcutHandle] carries no public state and exposes no members of
/// its own — it exists purely as a caller-held identity so
/// [LayrzShortcutState] can look up the [ShortcutRegistryEntry] (or the lack
/// of one, for an inert duplicate registration) it owns internally without
/// leaking that implementation detail to callers. This mirrors the shape of
/// Flutter's own `ShortcutRegistryEntry`, except a [LayrzShortcutHandle] is
/// deliberately opaque: all of its behaviour lives on
/// [LayrzShortcutState.deregister], not on the handle itself.
///
/// Equality and hashing are the default identity-based implementation
/// (`==` is reference equality, `hashCode` is the default `Object.hashCode`)
/// — two handles are equal only if they are the same instance. This is
/// intentional: a handle is a capability token, not a value type, so there is
/// no meaningful notion of two distinct handles being "equal".
///
/// Callers should keep the handle returned by `register` for as long as the
/// registration should remain active, and pass it to `deregister` (typically
/// from a `dispose()`) to release it. Deregistering is idempotent — calling
/// it more than once, or after the owning widget has already unmounted, is a
/// safe no-op.
final class LayrzShortcutHandle {
  /// Creates a new, uniquely-identified [LayrzShortcutHandle].
  ///
  /// Only [LayrzShortcutState.register] constructs these — application code
  /// never calls this constructor directly, it only receives handles back
  /// from `register` and passes them on to `deregister`.
  const LayrzShortcutHandle();
}
