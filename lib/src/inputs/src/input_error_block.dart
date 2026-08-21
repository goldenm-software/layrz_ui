import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Renders the error message block and character counter below a [LayrzTextInput].
///
/// When error messages are present, displays them using `typography.label` text style
/// with danger color and bold weight (w700). Errors always render below the field
/// regardless of viewport width. Bold rendering serves as a deliberate visual signal
/// to direct the user's attention to what went wrong.
///
/// When `maxLength` is set, displays a character counter in the format `"5/50"` (current/max)
/// aligned to the right. The counter uses `typography.label` in `fg3` color and remains
/// `fg3` even when errors are present — only the error text turns danger-coloured.
///
/// The detail block (errors + counter row) is hidden when `hideDetails` is true.
class LayrzInputErrorBlock extends StatelessWidget {
  /// The list of error messages to display.
  final List<String> errors;

  /// Whether to hide the error block and character counter.
  final bool hideDetails;

  /// Maximum character length for the input field.
  ///
  /// When non-null, a character counter is displayed.
  final int? maxLength;

  /// The text editing controller for tracking the current character count.
  ///
  /// Required when [maxLength] is non-null.
  final TextEditingController? controller;

  /// Creates a new [LayrzInputErrorBlock] with the given properties.
  const LayrzInputErrorBlock({
    super.key,
    required this.errors,
    required this.hideDetails,
    this.maxLength,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final hasErrors = errors.isNotEmpty;
    final hasCounter = maxLength != null;

    // Hide the entire detail block if hideDetails is true, or if there's nothing to show
    if (hideDetails || (!hasErrors && !hasCounter)) {
      return const SizedBox.shrink();
    }

    final tokens = context.tokens;

    // Render a row with error text (left) and counter (right) when both exist,
    // or just one if only one is present
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: tokens.spacing.sp2),
        if (hasErrors && hasCounter)
          _ErrorAndCounterRow(
            errors: errors,
            tokens: tokens,
            maxLength: maxLength!,
            controller: controller,
          )
        else if (hasErrors)
          Text(
            errors.join(', '),
            style: tokens.typography.label.copyWith(
              fontWeight: FontWeight.w700,
              color: tokens.colors.danger,
            ),
          )
        else if (hasCounter)
          Align(
            alignment: Alignment.centerRight,
            child: _CharacterCounter(
              maxLength: maxLength!,
              controller: controller,
              tokens: tokens,
            ),
          ),
      ],
    );
  }
}

/// Renders a row with error text on the left and character counter on the right.
///
/// This widget handles the case where both errors and a counter need to be displayed
/// simultaneously without overlap.
class _ErrorAndCounterRow extends StatelessWidget {
  final List<String> errors;
  final LayrzTokens tokens;
  final int maxLength;
  final TextEditingController? controller;

  const _ErrorAndCounterRow({
    required this.errors,
    required this.tokens,
    required this.maxLength,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            errors.join(', '),
            style: tokens.typography.label.copyWith(
              fontWeight: FontWeight.w700,
              color: tokens.colors.danger,
            ),
          ),
        ),
        SizedBox(width: tokens.spacing.sp2),
        _CharacterCounter(
          maxLength: maxLength,
          controller: controller,
          tokens: tokens,
        ),
      ],
    );
  }
}

/// Renders a character counter in the format "current/max".
///
/// Uses `typography.label` in `fg3` color. Counts characters from the controller
/// and updates in real-time as the user types.
class _CharacterCounter extends StatelessWidget {
  final int maxLength;
  final TextEditingController? controller;
  final LayrzTokens tokens;

  const _CharacterCounter({
    required this.maxLength,
    this.controller,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final counterStyle = tokens.typography.label.copyWith(
      color: tokens.colors.fg3,
    );

    if (controller == null) {
      return Text(
        '0/$maxLength',
        style: counterStyle,
      );
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller!,
      builder: (context, value, _) => Text(
        '${value.text.length}/$maxLength',
        style: counterStyle,
      ),
    );
  }
}
