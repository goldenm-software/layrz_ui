import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

/// Renders the error message block below a [LayrzTextInput].
///
/// Displays one line per error in the provided list, using `typography.label`
/// text style and `colors.danger` text color.
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
    final errorStyle = tokens.typography.label.copyWith(
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
