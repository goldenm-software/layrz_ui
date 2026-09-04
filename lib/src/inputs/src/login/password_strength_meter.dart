import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'password_strength.dart';

/// A segment-count and fill-color pairing used internally to describe how
/// [LayrzPasswordStrengthMeter] paints a given [LayrzPasswordStrength].
///
/// Kept private and immutable: it exists purely to let [LayrzPasswordStrengthMeter]
/// resolve "how many of the track's segments are filled, and in which color" as a
/// single value instead of duplicating a switch statement across the build method.
@immutable
class _MeterVisual {
  /// How many of the track's fixed segments should render as filled.
  ///
  /// Ranges from 0 (nothing filled, [LayrzPasswordStrength.empty]) to
  /// [LayrzPasswordStrengthMeter.segmentCount] (all filled,
  /// [LayrzPasswordStrength.strong]).
  final int filledSegments;

  /// The fill color applied to the filled segments.
  final Color color;

  /// Creates a new [_MeterVisual] pairing a segment count with its fill color.
  const _MeterVisual({required this.filledSegments, required this.color});
}

/// A stateless, informational meter that visualizes a [LayrzPasswordStrength] reading
/// as a row of colored segments with an optional text label.
///
/// **Why "informational" is a hard requirement, not a style preference:** this meter
/// is designed to be shown next to [LayrzPasswordInput] (see `password_input.dart`),
/// including on a *login* field where the user is authenticating with a password they
/// already chose and cannot edit from that screen. On a login field, a weak reading
/// cannot be acted on — there is nothing the user can do about it right there — so
/// painting it in the design system's danger/error color reads as an unactionable
/// alarm about a password the user is not in the process of creating. For that reason
/// this widget **never** uses [LayrzColorTokens.danger] for any strength level,
/// including [LayrzPasswordStrength.weak]. It instead uses the neutral/informational
/// ramp: [LayrzColorTokens.fg4] (empty/track), [LayrzColorTokens.info] (weak/medium)
/// and [LayrzColorTokens.success] (strong) — a gradient of "how far along" rather than
/// "how wrong". See the login-inputs context dossier §12A for the full rationale.
///
/// The meter accepts either a pre-computed [strength] or a raw [password] string (in
/// which case it derives the strength itself via [evaluatePasswordStrength]). Exactly
/// one of the two must be supplied.
class LayrzPasswordStrengthMeter extends StatelessWidget {
  /// The number of discrete segments the track is divided into.
  ///
  /// Fixed at 3, one per non-empty [LayrzPasswordStrength] bucket (weak, medium,
  /// strong). Kept as a named constant rather than a literal so the fill-count mapping
  /// in [_visualFor] stays self-documenting.
  static const int segmentCount = 3;

  /// A pre-computed strength reading to render.
  ///
  /// Exactly one of [strength] or [password] must be non-null; supplying both or
  /// neither is a programming error caught by an assertion in [LayrzPasswordStrengthMeter.new].
  /// Prefer this parameter when the caller already has a [LayrzPasswordStrength] (e.g.
  /// computed once and reused elsewhere), and prefer [password] when the caller only
  /// has the raw text and wants the meter to score it.
  final LayrzPasswordStrength? strength;

  /// A raw password string to score and render.
  ///
  /// When supplied, the meter derives its [LayrzPasswordStrength] internally via
  /// [evaluatePasswordStrength] on every build, so passing the live controller text
  /// keeps the meter in sync as the user types. Exactly one of [strength] or
  /// [password] must be non-null.
  final String? password;

  /// Whether to render the textual strength label below the segment track.
  ///
  /// When true (default), a label resolved from
  /// `LayrzUiL10n.of(context).passwordStrengthLevel` combined with the current
  /// bucket's name is shown below the track. When false, only the segment track is
  /// rendered.
  final bool showLabel;

  /// Creates a new [LayrzPasswordStrengthMeter] from a pre-computed [strength].
  ///
  /// Use this constructor when the caller already has a [LayrzPasswordStrength] value
  /// (for example, computed once by a parent and shared with other widgets). [showLabel]
  /// controls whether the textual label is rendered below the segment track.
  const LayrzPasswordStrengthMeter({super.key, required LayrzPasswordStrength this.strength, this.showLabel = true})
    : password = null;

  /// Creates a new [LayrzPasswordStrengthMeter] that scores a raw [password] string.
  ///
  /// Use this constructor when the caller only has the raw password text; the meter
  /// calls [evaluatePasswordStrength] internally on every build, so passing the live
  /// controller text keeps the meter in sync as the user types. [showLabel] controls
  /// whether the textual label is rendered below the segment track.
  const LayrzPasswordStrengthMeter.fromPassword({super.key, required String this.password, this.showLabel = true})
    : strength = null;

  /// Resolves the effective [LayrzPasswordStrength] for this build: the pre-computed
  /// [strength] if supplied, otherwise the result of scoring [password].
  LayrzPasswordStrength _resolveStrength() {
    final fixedStrength = strength;
    if (fixedStrength != null) {
      return fixedStrength;
    }
    return evaluatePasswordStrength(password!);
  }

  /// Maps a [LayrzPasswordStrength] to how many segments are filled and in which
  /// color, using only the neutral/informational tokens named on the class doc — never
  /// [LayrzColorTokens.danger].
  _MeterVisual _visualFor(LayrzPasswordStrength value, LayrzColorTokens colors) {
    switch (value) {
      case LayrzPasswordStrength.empty:
        return _MeterVisual(filledSegments: 0, color: colors.fg4);
      case LayrzPasswordStrength.weak:
        return _MeterVisual(filledSegments: 1, color: colors.info.shade500);
      case LayrzPasswordStrength.medium:
        return _MeterVisual(filledSegments: 2, color: colors.info.shade700);
      case LayrzPasswordStrength.strong:
        return _MeterVisual(filledSegments: 3, color: colors.success.shade500);
    }
  }

  /// Resolves the textual label for [value] from the active [LayrzUiL10n], e.g.
  /// "Password Length: Strong".
  String _labelFor(LayrzPasswordStrength value, BuildContext context) {
    final l10n = LayrzUiL10n.of(context);
    final level = switch (value) {
      LayrzPasswordStrength.empty => '',
      LayrzPasswordStrength.weak => 'Weak',
      LayrzPasswordStrength.medium => 'Medium',
      LayrzPasswordStrength.strong => 'Strong',
    };
    if (level.isEmpty) {
      return l10n.passwordStrengthLevel;
    }
    return '${l10n.passwordStrengthLevel}: $level';
  }

  @override
  Widget build(BuildContext context) {
    assert(
      (strength == null) != (password == null),
      'LayrzPasswordStrengthMeter requires exactly one of `strength` or `password`.',
    );

    final tokens = context.tokens;
    final colors = tokens.colors;
    final value = _resolveStrength();
    final visual = _visualFor(value, colors);
    final label = _labelFor(value, context);

    return Semantics(
      container: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(segmentCount, (index) {
              final isFilled = index < visual.filledSegments;
              return Padding(
                padding: EdgeInsets.only(right: index == segmentCount - 1 ? 0 : tokens.spacing.sp1),
                child: AnimatedContainer(
                  duration: tokens.motion.dTransition,
                  curve: tokens.motion.easing,
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isFilled ? visual.color : colors.fg4,
                    borderRadius: tokens.radius.br1,
                  ),
                ),
              );
            }),
          ),
          if (showLabel) ...[
            SizedBox(height: tokens.spacing.sp1),
            ExcludeSemantics(
              child: Text(
                label,
                style: tokens.typography.label.copyWith(color: colors.fg3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
