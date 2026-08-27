import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the dialogs section for the showroom.
///
/// Demonstrates [LayrzDialog] (a centered, page-relative modal with
/// `title`/`content`/`actions` slots or a `child` escape hatch) and
/// [LayrzResponsiveModal] (which resolves once, at `show()` time, to either a
/// [LayrzDialog] or a `LayrzBottomSheet` depending on viewport width).
///
/// Every showcase here opens on the root navigator automatically — both
/// components always push there intrinsically, which matters because this
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

  /// The [LayrzModalPresentation] the last [LayrzResponsiveModal] resolved to,
  /// captured so the demo can show what was actually chosen at open time.
  String? _lastModalPresentation;

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
                'Returns a value via show<bool>() -- confirm returns true, cancel returns false, '
                'and dismissing via the barrier or Escape returns null.',
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
                'actions is omitted, so barrierDismissible defaults to true -- '
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
                'Chooses a LayrzDialog at/above a 960px viewport width, or a bottom sheet '
                'below it -- decided once, at the moment show() is called.',
            child: _ResponsiveModalShowcase(
              lastPresentation: _lastModalPresentation,
              onPresentationResolved: (label) {
                setState(() {
                  _lastModalPresentation = label;
                });
              },
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

/// Showcase for [LayrzResponsiveModal], teaching its one deliberate non-goal:
/// the chosen surface (dialog vs. bottom sheet) is decided once at `show()`
/// time and never re-evaluated, so resizing the window mid-route does not
/// swap the presentation of an already-open modal.
class _ResponsiveModalShowcase extends StatelessWidget {
  /// The [LayrzModalPresentation] label the most recent `show()` call
  /// resolved to, or `null` if the modal has not been opened yet.
  final String? lastPresentation;

  /// Called with a human-readable presentation label every time a modal is
  /// opened, so the parent can display which surface was actually chosen.
  final ValueChanged<String> onPresentationResolved;

  /// Creates a new [_ResponsiveModalShowcase].
  const _ResponsiveModalShowcase({
    required this.lastPresentation,
    required this.onPresentationResolved,
  });

  /// Opens the responsive modal, optionally forcing [isCompact] to override
  /// the viewport-based choice, and records which presentation was used.
  void _open(BuildContext context, {bool? isCompact}) async {
    final willBeCompact = isCompact ?? context.isCompact;
    final presentationLabel = willBeCompact ? 'bottom sheet (compact)' : 'dialog (wide)';

    await LayrzResponsiveModal.show<void>(
      context,
      isCompact: isCompact,
      semanticLabel: 'Responsive modal',
      builder: (sheetContext) {
        final tokens = sheetContext.tokens;
        return Padding(
          padding: EdgeInsets.all(tokens.spacing.sp3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: tokens.spacing.sp2,
            children: [
              Text('Presented as: $presentationLabel', style: tokens.typography.title),
              Text(
                'This surface was chosen once, when show() was called, from the viewport '
                'width at that moment. Resizing the window while this is open will not '
                'swap it to the other surface -- that is a deliberate non-goal, not a bug. '
                'Close this and resize before opening again to see a different choice.',
                style: tokens.typography.body,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: LayrzButton.save(
                  labelText: 'Close',
                  onTap: () => Navigator.of(sheetContext, rootNavigator: true).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );

    onPresentationResolved(presentationLabel);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.sizeOf(context).width;
        final wouldBeCompact = context.isCompact;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp2,
          children: [
            Text(
              'Live viewport width: ${width.round()}px -- next show() call would choose: '
              '${wouldBeCompact ? 'bottom sheet (< 960px)' : 'dialog (>= 960px)'}',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            Text(
              'Resize this window and reopen the modal below to see the choice change. '
              'An already-open modal never swaps surfaces mid-route.',
              style: tokens.typography.label.copyWith(color: tokens.colors.fg4),
            ),
            if (lastPresentation != null)
              Text(
                'Last opened as: $lastPresentation',
                style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: tokens.spacing.sp2,
              children: [
                LayrzButton(
                  labelText: 'Open (auto)',
                  onTap: () => _open(context),
                ),
                LayrzButton(
                  labelText: 'Force sheet',
                  style: LayrzButtonStyle.outlined,
                  onTap: () => _open(context, isCompact: true),
                ),
                LayrzButton(
                  labelText: 'Force dialog',
                  style: LayrzButtonStyle.outlined,
                  onTap: () => _open(context, isCompact: false),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
