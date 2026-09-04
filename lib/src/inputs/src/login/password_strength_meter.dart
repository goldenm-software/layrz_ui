import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'password_strength.dart';

/// Fixed number of segments the strength bar is divided into.
///
/// One per level `1`–`4`; level `0` renders as zero filled segments. Matches
/// `layrz_theme`'s four requirements/levels exactly — see `password_strength.dart`'s
/// module doc comment for the full rule set this mirrors.
const int _segmentCount = 4;

/// A single password requirement the checklist renders one row for.
///
/// Pairs the requirement's localized description with whether the current password
/// meets it, so [_LayrzPasswordChecklist] can render each row uniformly instead of
/// repeating the same `Row`/`Icon`/`Text` structure four times inline.
@immutable
class _ChecklistItem {
  /// The localized requirement description, e.g. "At least one lowercase letter".
  final String label;

  /// Whether the current password satisfies this requirement.
  final bool met;

  /// Creates a new [_ChecklistItem].
  const _ChecklistItem({required this.label, required this.met});
}

/// A persistent, informational password-strength indicator: a full-width, 4-segment
/// fill bar followed by a checklist of the four character-class requirements.
///
/// **Replaces `layrz_theme`'s tooltip presentation.** `layrz_theme`'s
/// `ThemedPasswordInput` surfaces the same requirements/level rules behind a hover
/// tooltip on a trailing icon — real usage found that undiscoverable (nothing on
/// screen signals there is more information to hover for) and unusable on touch
/// devices (no hover at all). This widget instead renders BOTH elements directly in
/// the layout, always visible whenever the meter itself is shown — no hover, no
/// tooltip, nothing hidden behind an affordance the user has to find first.
///
/// **The scoring rules are `layrz_theme`'s, unchanged.** See
/// [LayrzPasswordRequirements] (`password_strength.dart`) for the exact requirement
/// regexes, the allowed-character whole-string check, and the length→level table.
/// Level 0 legitimately renders in [LayrzColorTokens.danger] — unlike an earlier
/// design of this widget, "never danger-red" is NOT a rule here: a password that
/// fails validity or is very short really is the worst bucket, and hiding that behind
/// a softer color would misrepresent the actual rule `layrz_theme` encodes.
///
/// The meter accepts either a pre-computed [requirements] snapshot or a raw
/// [password] string (in which case it derives the snapshot itself via
/// [LayrzPasswordRequirements.evaluate]). Exactly one of the two must be supplied.
class LayrzPasswordStrengthMeter extends StatelessWidget {
  /// A pre-computed requirements/level snapshot to render.
  ///
  /// Exactly one of [requirements] or [password] must be non-null; supplying both or
  /// neither is a programming error caught by an assertion in
  /// [LayrzPasswordStrengthMeter.new]. Prefer this parameter when the caller already
  /// has a [LayrzPasswordRequirements] (e.g. computed once and reused elsewhere), and
  /// prefer [password] when the caller only has the raw text and wants the meter to
  /// score it.
  final LayrzPasswordRequirements? requirements;

  /// A raw password string to score and render.
  ///
  /// When supplied, the meter derives its [LayrzPasswordRequirements] internally via
  /// [LayrzPasswordRequirements.evaluate] on every build, so passing the live
  /// controller text keeps the meter in sync as the user types. Exactly one of
  /// [requirements] or [password] must be non-null.
  final String? password;

  /// Creates a new [LayrzPasswordStrengthMeter] from a pre-computed [requirements]
  /// snapshot.
  ///
  /// Use this constructor when the caller already has a [LayrzPasswordRequirements]
  /// value (for example, computed once by a parent and shared with other widgets).
  const LayrzPasswordStrengthMeter({super.key, required LayrzPasswordRequirements this.requirements}) : password = null;

  /// Creates a new [LayrzPasswordStrengthMeter] that scores a raw [password] string.
  ///
  /// Use this constructor when the caller only has the raw password text; the meter
  /// calls [LayrzPasswordRequirements.evaluate] internally on every build, so passing
  /// the live controller text keeps the meter in sync as the user types.
  const LayrzPasswordStrengthMeter.fromPassword({super.key, required String this.password}) : requirements = null;

  /// Resolves the effective [LayrzPasswordRequirements] for this build: the
  /// pre-computed [requirements] if supplied, otherwise the result of scoring
  /// [password].
  LayrzPasswordRequirements _resolveRequirements() {
    final fixed = requirements;
    if (fixed != null) {
      return fixed;
    }
    return LayrzPasswordRequirements.evaluate(password!);
  }

  /// Builds the four [_ChecklistItem] rows from [result] and the active [l10n],
  /// in the fixed order: lowercase, uppercase, digit, special character.
  List<_ChecklistItem> _checklistItems(LayrzPasswordRequirements result, LayrzUiL10n l10n) {
    return [
      _ChecklistItem(label: l10n.passwordRequirementsLowercaseLetter, met: result.hasLowercase),
      _ChecklistItem(label: l10n.passwordRequirementsUppercaseLetter, met: result.hasUppercase),
      _ChecklistItem(label: l10n.passwordRequirementsDigit, met: result.hasDigit),
      _ChecklistItem(label: l10n.passwordRequirementsSpecialCharacter, met: result.hasSpecial),
    ];
  }

  @override
  Widget build(BuildContext context) {
    assert(
      (requirements == null) != (password == null),
      'LayrzPasswordStrengthMeter requires exactly one of `requirements` or `password`.',
    );

    final tokens = context.tokens;
    final colors = tokens.colors;
    final l10n = LayrzUiL10n.of(context);
    final result = _resolveRequirements();
    final level = result.level;
    final color = result.colorFor(colors);
    final items = _checklistItems(result, l10n);

    return Semantics(
      container: true,
      label: '${l10n.passwordStrengthLevel}: $level/$_segmentCount',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: _LayrzPasswordStrengthBar(level: level, color: color, tokens: tokens),
          ),
          SizedBox(height: tokens.spacing.sp2),
          _LayrzPasswordChecklist(items: items, tokens: tokens),
        ],
      ),
    );
  }
}

/// The full-width, 4-segment fill bar showing how many of [_segmentCount] segments
/// [level] fills.
///
/// Segments are laid out with [Expanded] rather than a fixed width, so the bar always
/// spans the FULL width of its parent (the field above it) rather than a fixed pixel
/// track — matching the placement brief this widget was built against ("a 4-segment
/// bar spread across the full width of the input").
class _LayrzPasswordStrengthBar extends StatelessWidget {
  /// The 0–4 strength level, from [LayrzPasswordRequirements.level].
  final int level;

  /// The fill color for filled segments, from [LayrzPasswordRequirements.colorFor].
  final Color color;

  /// The active design tokens, for spacing/radius/motion.
  final LayrzTokens tokens;

  /// Creates a new [_LayrzPasswordStrengthBar].
  const _LayrzPasswordStrengthBar({required this.level, required this.color, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_segmentCount, (index) {
        final isFilled = index < level;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == _segmentCount - 1 ? 0 : tokens.spacing.sp1),
            child: AnimatedContainer(
              duration: tokens.motion.dTransition,
              curve: tokens.motion.easing,
              height: 4,
              decoration: BoxDecoration(
                color: isFilled ? color : tokens.colors.fg4,
                borderRadius: tokens.radius.br1,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// The checklist of the four password requirements, one row per requirement, each
/// with a met/unmet icon and its localized description.
///
/// A met requirement shows a filled check in [LayrzColorTokens.success]; an unmet one
/// shows a close mark in [LayrzColorTokens.fg4] (neutral, not [LayrzColorTokens.danger]
/// — an unmet requirement while the user is still typing is normal and expected, not
/// an error condition to alarm about; the strength BAR above already carries the
/// danger-red signal for a genuinely weak/invalid password).
class _LayrzPasswordChecklist extends StatelessWidget {
  /// The four requirement rows to render, in display order.
  final List<_ChecklistItem> items;

  /// The active design tokens, for spacing/typography/color.
  final LayrzTokens tokens;

  /// Creates a new [_LayrzPasswordChecklist].
  const _LayrzPasswordChecklist({required this.items, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final colors = tokens.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: EdgeInsets.only(top: tokens.spacing.sp1),
            child: Semantics(
              label: '${item.label}: ${item.met}',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      item.met ? MdiIcons.checkCircleOutline : MdiIcons.closeCircleOutline,
                      size: 14.0 + tokens.spacing.sp1,
                      color: item.met ? colors.success.shade500 : colors.fg4,
                    ),
                  ),
                  SizedBox(width: tokens.spacing.sp1),
                  ExcludeSemantics(
                    child: Text(
                      item.label,
                      style: tokens.typography.label.copyWith(color: colors.fg3),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
