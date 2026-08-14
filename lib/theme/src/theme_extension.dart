/// Base class for theme extensions in the layrz_ui design system.
///
/// This is the layrz_ui equivalent of Material's `ThemeExtension<T>`. It allows
/// M2+ components (button variants, input label rules, table column styles, etc.)
/// to store theme-scoped data without polluting `LayrzThemeData`'s core fields.
///
/// Extensions are registered when constructing or copying a `LayrzThemeData`,
/// retrieved via `LayrzThemeData.extension<T>()` or `maybeExtension<T>()`,
/// and accessed from the widget tree via `context.themeExtension<T>()`.
///
/// The self-bounded generic `T extends LayrzThemeExtension<T>` is essential — it
/// makes the `type` property a sound map key and enables type-safe lookups.
/// Do not drop or "simplify" this constraint.
///
/// ## Example
///
/// Define a custom extension by subclassing `LayrzThemeExtension`:
///
/// ```dart
/// class ButtonVariantsExtension extends LayrzThemeExtension<ButtonVariantsExtension> {
///   final Color primaryBackground;
///   final Color primaryForeground;
///   final Color secondaryBackground;
///   final Color secondaryForeground;
///
///   const ButtonVariantsExtension({
///     required this.primaryBackground,
///     required this.primaryForeground,
///     required this.secondaryBackground,
///     required this.secondaryForeground,
///   });
///
///   @override
///   ButtonVariantsExtension copyWith({
///     Color? primaryBackground,
///     Color? primaryForeground,
///     Color? secondaryBackground,
///     Color? secondaryForeground,
///   }) {
///     return ButtonVariantsExtension(
///       primaryBackground: primaryBackground ?? this.primaryBackground,
///       primaryForeground: primaryForeground ?? this.primaryForeground,
///       secondaryBackground: secondaryBackground ?? this.secondaryBackground,
///       secondaryForeground: secondaryForeground ?? this.secondaryForeground,
///     );
///   }
///
///   @override
///   ButtonVariantsExtension lerp(
///     covariant ButtonVariantsExtension? other,
///     double t,
///   ) {
///     if (other is! ButtonVariantsExtension) {
///       return this;
///     }
///     return ButtonVariantsExtension(
///       primaryBackground: Color.lerp(primaryBackground, other.primaryBackground, t)!,
///       primaryForeground: Color.lerp(primaryForeground, other.primaryForeground, t)!,
///       secondaryBackground: Color.lerp(secondaryBackground, other.secondaryBackground, t)!,
///       secondaryForeground: Color.lerp(secondaryForeground, other.secondaryForeground, t)!,
///     );
///   }
/// }
/// ```
///
/// Register the extension when creating a theme:
///
/// ```dart
/// final theme = LayrzThemeData.light(
///   extensions: [
///     ButtonVariantsExtension(
///       primaryBackground: const Color(0xFF0066CC),
///       primaryForeground: const Color(0xFFFFFFFF),
///       secondaryBackground: const Color(0xFFF0F0F0),
///       secondaryForeground: const Color(0xFF333333),
///     ),
///   ],
/// );
/// ```
///
/// Retrieve the extension from `LayrzThemeData` or from the widget tree:
///
/// ```dart
/// class MyButton extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final extension = context.themeExtension<ButtonVariantsExtension>();
///     return Container(
///       color: extension.primaryBackground,
///       child: Text(
///         'Press me',
///         style: TextStyle(color: extension.primaryForeground),
///       ),
///     );
///   }
/// }
/// ```
abstract class LayrzThemeExtension<T extends LayrzThemeExtension<T>> {
  /// Creates a theme extension instance.
  const LayrzThemeExtension();

  /// The key this extension is stored under in [LayrzThemeData.extensions].
  ///
  /// Returns the runtime type of this extension (e.g., `ButtonVariantsExtension`).
  /// This is used as the map key when registering and looking up extensions.
  Object get type => T;

  /// Returns a copy of this extension with the given fields replaced.
  ///
  /// Subclasses must implement this to return a new instance of their own type,
  /// replacing only the specified fields and preserving all others.
  LayrzThemeExtension<T> copyWith();

  /// Linearly interpolates between two extensions over a given fraction [t].
  ///
  /// When [t] is 0.0, this extension is returned unmodified. When [t] is 1.0,
  /// the [other] extension is returned. For values in between, both extensions
  /// are interpolated proportionally.
  ///
  /// [other] may be null or of a different type. If [other] is null or not the
  /// same type as this extension, implementations should return unmodified `this`
  /// or perform a best-effort interpolation.
  ///
  /// This method is called by the theme system when animating between two themes.
  /// Most extensions return `this` unmodified if [other] is null or of a different
  /// type, unless a sensible interpolation can be performed.
  LayrzThemeExtension<T> lerp(covariant LayrzThemeExtension<T>? other, double t);
}
