import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

/// Renders the error message block below a [LayrzTextInput].
///
/// Displays joined error messages using `typography.label` text style with danger color
/// and bold weight. Bold rendering serves as a deliberate visual signal to direct the user's
/// attention to what went wrong.
class LayrzInputErrorBlock extends StatelessWidget {
  /// The list of error messages to display.
  final List<String> errors;

  /// Whether to hide the error block.
  final bool hideDetails;

  /// Creates a new [LayrzInputErrorBlock] with the given properties.
  const LayrzInputErrorBlock({
    super.key,
    required this.errors,
    required this.hideDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (hideDetails || errors.isEmpty) {
      return const SizedBox.shrink();
    }

    final tokens = context.tokens;
    // Bold error text is a deliberate signal: tells the user "this is what went wrong"
    final errorStyle = tokens.typography.label.copyWith(
      fontWeight: FontWeight.w700,
      color: tokens.colors.danger,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: tokens.spacing.sp6),
        Text(
          errors.join(', '),
          style: errorStyle,
        ),
      ],
    );
  }
}
