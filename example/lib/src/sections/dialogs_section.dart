import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the dialogs section for the showroom.
///
/// Demonstrates [LayrzDialog] -- a centered, page-relative modal with
/// `title`/`content`/`actions` slots or a `child` escape hatch. The
/// viewport-aware [LayrzResponsiveModal] chooser has its own dedicated
/// showroom entry (`ResponsiveModalSection`, at `/responsive-modal`) rather
/// than being demonstrated here (DESIGN-164) -- see the pointer card below.
///
/// Every showcase here opens on the root navigator automatically — this
/// component always pushes there intrinsically, which matters because this
/// section is rendered inside `ShowroomLayout`'s `ShellRoute` — a nested
/// `Navigator` — and a dialog opened on the nearest navigator would otherwise
/// be confined to the page body instead of covering the whole shell.
class DialogsSection extends StatefulWidget {
  /// Creates a new [DialogsSection].
  const DialogsSection({super.key});

  @override
  State<DialogsSection> createState() => _DialogsSectionState();
}

class _DialogsSectionState extends State<DialogsSection> {
  /// The result returned by the last confirm/cancel dialog, or `null` if it
  /// has not been opened yet, or was dismissed without a value.
  bool? _lastConfirmResult;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Dialogs',
      description: 'Centered modal panels and a viewport-aware dialog/sheet chooser',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DialogShowcaseCard(
            title: 'Title + Content + Actions',
            description:
                'Returns a value via show<bool>() -- confirm returns true, cancel returns false. '
                'With actions present, this dialog is answered only through its own buttons: the '
                'barrier, Escape, the X, and the back gesture are all disabled, so it never resolves '
                'with null.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp2,
              children: [
                LayrzButton(
                  labelText: 'Open Confirm Dialog',
                  onTap: () async {
                    final result = await LayrzDialog.show<bool>(
                      context,
                      title: Text('Delete item?', style: tokens.typography.title),
                      content: Text(
                        'This action cannot be undone.',
                        style: tokens.typography.body,
                      ),
                      actions: [
                        LayrzButton.cancel(
                          labelText: 'Cancel',
                          onTap: () => Navigator.of(context, rootNavigator: true).pop(false),
                        ),
                        LayrzButton.delete(
                          labelText: 'Delete',
                          onTap: () => Navigator.of(context, rootNavigator: true).pop(true),
                        ),
                      ],
                    );
                    setState(() {
                      _lastConfirmResult = result;
                    });
                  },
                ),
                if (_lastConfirmResult != null)
                  Text(
                    'Last result: ${_lastConfirmResult! ? 'confirmed (true)' : 'cancelled (false)'}',
                    style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
                  ),
              ],
            ),
          ),

          _DialogShowcaseCard(
            title: 'Informational (no actions)',
            description:
                'actions is omitted, so canDismiss defaults to true -- '
                'tapping outside the panel or pressing Escape dismisses it.',
            child: LayrzButton.info(
              labelText: 'Open Info Dialog',
              onTap: () {
                LayrzDialog.show<void>(
                  context,
                  title: Text('Did you know?', style: tokens.typography.title),
                  content: Text(
                    'This dialog has no actions, so tapping the barrier or pressing '
                    'Escape dismisses it -- there is no decision to protect.',
                    style: tokens.typography.body,
                  ),
                );
              },
            ),
          ),

          _DialogShowcaseCard(
            title: 'Child escape hatch',
            description:
                'child replaces title/content/actions entirely for freeform layouts '
                'that do not fit the slotted shape.',
            child: LayrzButton(
              labelText: 'Open Custom Dialog',
              onTap: () {
                LayrzDialog.show<void>(
                  context,
                  semanticLabel: 'Custom dialog',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: tokens.spacing.sp2,
                    children: [
                      Text('Freeform content', style: tokens.typography.title),
                      Text(
                        'This body is passed as child, bypassing the title/content/actions '
                        'slots entirely -- useful for a layout none of them fit.',
                        style: tokens.typography.body,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: LayrzButton.save(
                          labelText: 'Close',
                          onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          _DialogShowcaseCard(
            title: 'LayrzResponsiveModal',
            description:
                'The viewport-aware dialog/bottom-sheet chooser now has its own dedicated '
                'showroom entry -- see "Responsive Modal" in the navigation, which covers the '
                'dialog/sheet switch, the pinned actions row, and both LayrzDialogConfig and '
                'LayrzBottomSheetConfig.',
            child: Text(
              'See the "Responsive Modal" section.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple card wrapper for one dialog showcase within [DialogsSection].
///
/// Mirrors `_MenuShowcaseCard` from `menus_section.dart`, adding an optional
/// [description] line since dialog behaviour (barrier dismissal, return
/// values) is not always self-evident from the button alone.
class _DialogShowcaseCard extends StatelessWidget {
  /// The title of the showcase card.
  final String title;

  /// Optional explanatory text shown below the title, above [child].
  final String? description;

  /// The content displayed inside the card -- typically a button that opens
  /// a dialog.
  final Widget child;

  /// Creates a new [_DialogShowcaseCard].
  const _DialogShowcaseCard({
    required this.title,
    required this.child,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: tokens.typography.label),
          if (description != null) ...[
            SizedBox(height: tokens.spacing.sp1),
            Text(
              description!,
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
          ],
          SizedBox(height: tokens.spacing.sp3),
          Container(
            padding: EdgeInsets.all(tokens.spacing.sp3),
            decoration: BoxDecoration(
              color: tokens.colors.sf2,
              borderRadius: tokens.radius.br2,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
