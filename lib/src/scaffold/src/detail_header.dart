import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

/// Private detail header widget.
class DetailHeader extends StatelessWidget {
  /// Optional title for the detail header.
  final String? title;

  /// Optional subtitle for the detail header.
  final String? subtitle;

  /// List of action widgets to display in the header.
  final List<Widget> actions;

  /// Optional callback for the back button.
  /// When null, no back button is displayed.
  final VoidCallback? onBack;

  /// Creates a new [DetailHeader].
  const DetailHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      decoration: BoxDecoration(
        color: t.colors.surface,
        border: Border(
          bottom: BorderSide(color: t.colors.divider, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: kLayrzScaffoldDetailHeaderVerticalPadding,
        horizontal: kLayrzScaffoldDetailHeaderHorizontalPadding,
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  LayrzIcons.solarOutlineArrowLeft,
                  size: 20,
                  color: t.colors.fg1,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: kLayrzScaffoldDetailHeaderTitleFontSize,
                      fontWeight: FontWeight.w700,
                      color: t.colors.fg1,
                    ),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: kLayrzScaffoldDetailHeaderSubtitleFontSize,
                      color: t.colors.fg3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: kLayrzScaffoldDetailHeaderGap),
            Wrap(
              spacing: 8,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}
