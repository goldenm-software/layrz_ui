/// The set of container shapes [AvatarLayo] can clip itself to.
///
/// Every value clips the same square frame (see [AvatarLayo]'s own doc
/// comment for why the avatar is always 1:1) to a different silhouette. The
/// shape is applied to the background fill, the fixed navy border, and the
/// clip boundary alike, so the oversized, cropped [Layo] portrait inside
/// never bleeds past whichever outline is chosen.
enum LayoAvatarShape {
  /// A full circle — the corner radius is always exactly half the avatar's
  /// side length, regardless of size.
  ///
  /// This is [AvatarLayo]'s default shape, matching the reference mailer
  /// avatar (Layo inside a colored circle with a border).
  circle,

  /// A rounded-corner square, with a moderate corner radius proportional to
  /// the avatar's size — softer than a sharp square, but visibly boxier
  /// than [circle].
  roundedBox,
}
