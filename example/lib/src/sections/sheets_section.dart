import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the sheets section for the showroom.
///
/// Demonstrates [LayrzBottomSheet], a modal or persistent bottom sheet
/// draggable across `minSize`/`snapSizes`/`maxSize`, with an optional pinned
/// `actions` row.
///
/// Every showcase here opens on the root navigator automatically -- `show()`
/// always pushes there intrinsically, which matters because this section is
/// rendered inside `ShowroomLayout`'s `ShellRoute` -- a nested `Navigator` --
/// and a sheet opened on the nearest navigator would otherwise be confined to
/// the page body instead of covering the whole shell.
class SheetsSection extends StatefulWidget {
  /// Creates a new [SheetsSection].
  const SheetsSection({super.key});

  @override
  State<SheetsSection> createState() => _SheetsSectionState();
}

class _SheetsSectionState extends State<SheetsSection> {
  /// The value returned by the last basic sheet, or `null` if it has not been
  /// opened yet, or was dismissed without a value.
  String? _lastPickResult;

  /// The current value of the [LayrzSlider] shown inside the "actions + slider"
  /// showcase's sheet content.
  double _sliderValue = 40;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Sheets',
      description: 'Draggable bottom sheets, modal or persistent, with an optional pinned actions row',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetShowcaseCard(
            title: 'Basic modal sheet',
            description:
                'show<T>() returns a value via Navigator.pop(value) -- picking an option '
                'resolves the awaited Future, shown below afterwards.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp2,
              children: [
                LayrzButton(
                  labelText: 'Open Picker Sheet',
                  onTap: () async {
                    final result = await LayrzBottomSheet.show<String>(
                      context,
                      semanticLabel: 'Choose an option. Press Escape to close.',
                      builder: (sheetContext) {
                        final sheetTokens = sheetContext.tokens;
                        return Padding(
                          padding: EdgeInsets.all(sheetTokens.spacing.sp3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            spacing: sheetTokens.spacing.sp2,
                            children: [
                              Text('Choose an option', style: sheetTokens.typography.title),
                              for (final option in const ['Alpha', 'Bravo', 'Charlie'])
                                LayrzButton(
                                  labelText: option,
                                  style: LayrzButtonStyle.outlined,
                                  onTap: () => Navigator.of(sheetContext, rootNavigator: true).pop(option),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                    setState(() {
                      _lastPickResult = result;
                    });
                  },
                ),
                if (_lastPickResult != null)
                  Text(
                    'Last result: $_lastPickResult',
                    style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
                  ),
              ],
            ),
          ),

          _SheetShowcaseCard(
            title: 'Pinned actions + LayrzSlider',
            description:
                'actions is a sibling of the scrollable content, not nested inside it -- scroll '
                'the long list below and watch the action row stay put at the bottom.',
            child: LayrzButton(
              labelText: 'Open Sheet with Actions',
              onTap: () {
                LayrzBottomSheet.show<void>(
                  context,
                  semanticLabel: 'Sheet with pinned actions. Press Escape to close.',
                  builder: (sheetContext) {
                    final sheetTokens = sheetContext.tokens;
                    return Padding(
                      padding: EdgeInsets.all(sheetTokens.spacing.sp3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        spacing: sheetTokens.spacing.sp2,
                        children: [
                          Text('Adjust and confirm', style: sheetTokens.typography.title),
                          Text(
                            'This content is tall enough to scroll -- the actions row below '
                            'stays fixed at the bottom of the sheet the whole time.',
                            style: sheetTokens.typography.body,
                          ),
                          StatefulBuilder(
                            builder: (context, setSheetState) {
                              return LayrzSlider(
                                labelText: 'Volume',
                                value: _sliderValue,
                                onChanged: (value) {
                                  setSheetState(() {
                                    _sliderValue = value;
                                  });
                                  setState(() {
                                    _sliderValue = value;
                                  });
                                },
                              );
                            },
                          ),
                          for (var i = 1; i <= 12; i++) Text('Scrollable line $i', style: sheetTokens.typography.body),
                        ],
                      ),
                    );
                  },
                  actions: [
                    LayrzButton.cancel(
                      labelText: 'Cancel',
                      onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                    ),
                    LayrzButton.save(
                      labelText: 'Confirm',
                      onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                    ),
                  ],
                );
              },
            ),
          ),

          _SheetShowcaseCard(
            title: 'canDismiss: false',
            description:
                'Try tapping the barrier, pressing Escape, dragging the handle past the lowest '
                'snap point, or using the back gesture -- all four are refused. The handle still '
                'drags to resize between snap points; only drag-to-dismiss is disabled. The only '
                'way out is the "Done" action below.',
            child: LayrzButton(
              labelText: 'Open Non-dismissible Sheet',
              onTap: () {
                LayrzBottomSheet.show<void>(
                  context,
                  canDismiss: false,
                  semanticLabel: 'Non-dismissible sheet. Use the Done button to close.',
                  builder: (sheetContext) {
                    final sheetTokens = sheetContext.tokens;
                    return Padding(
                      padding: EdgeInsets.all(sheetTokens.spacing.sp3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        spacing: sheetTokens.spacing.sp2,
                        children: [
                          Text('This sheet refuses to be dismissed', style: sheetTokens.typography.title),
                          Text(
                            'Barrier tap, Escape, drag-past-the-end, and the back gesture are all '
                            'blocked. Dragging the handle to resize between snap points still '
                            'works -- try it. The only way out is the action below.',
                            style: sheetTokens.typography.body,
                          ),
                        ],
                      ),
                    );
                  },
                  actions: [
                    LayrzButton.save(
                      labelText: 'Done',
                      onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                    ),
                  ],
                );
              },
            ),
          ),

          _SheetShowcaseCard(
            title: 'isPersistent: true',
            description:
                'No barrier is painted and the page behind stays interactive -- try tapping this '
                'card\'s own buttons while the sheet is open. Combined here with canDismiss: false, '
                'so Escape and the back gesture are also blocked even though there is no barrier '
                'to tap in the first place.',
            child: LayrzButton(
              labelText: 'Open Persistent Sheet',
              onTap: () {
                LayrzBottomSheet.show<void>(
                  context,
                  isPersistent: true,
                  canDismiss: false,
                  initialSize: 0.3,
                  maxSize: 0.5,
                  builder: (sheetContext) {
                    final sheetTokens = sheetContext.tokens;
                    return Padding(
                      padding: EdgeInsets.all(sheetTokens.spacing.sp3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        spacing: sheetTokens.spacing.sp2,
                        children: [
                          Text('Persistent, non-modal panel', style: sheetTokens.typography.title),
                          Text(
                            'No barrier -- the rest of the page stays interactive while this is '
                            'open. Try the buttons above this card.',
                            style: sheetTokens.typography.body,
                          ),
                        ],
                      ),
                    );
                  },
                  actions: [
                    LayrzButton.save(
                      labelText: 'Close',
                      onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                    ),
                  ],
                );
              },
            ),
          ),

          _SheetShowcaseCard(
            title: 'Custom snapSizes',
            description:
                'snapSizes: [0.3, 0.6, 0.9] gives the drag handle three resting points instead of '
                'the [0.5, 0.95] default -- drag the handle and feel it settle at each one.',
            child: LayrzButton(
              labelText: 'Open Sheet with Snap Points',
              onTap: () {
                LayrzBottomSheet.show<void>(
                  context,
                  semanticLabel: 'Sheet with three snap points. Press Escape to close.',
                  snapSizes: const [0.3, 0.6, 0.9],
                  initialSize: 0.3,
                  minSize: 0.3,
                  maxSize: 0.9,
                  builder: (sheetContext) {
                    final sheetTokens = sheetContext.tokens;
                    return Padding(
                      padding: EdgeInsets.all(sheetTokens.spacing.sp3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        spacing: sheetTokens.spacing.sp2,
                        children: [
                          Text('Three snap points', style: sheetTokens.typography.title),
                          Text(
                            'Drag the handle above -- it settles at 30%, 60%, or 90% of the '
                            'screen height instead of the default two-point [0.5, 0.95] range.',
                            style: sheetTokens.typography.body,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple card wrapper for one sheet showcase within [SheetsSection].
///
/// Mirrors `_DialogShowcaseCard` from `dialogs_section.dart`, since sheet
/// behaviour (barrier dismissal, snap points, dismissibility) is not always
/// self-evident from the button alone.
class _SheetShowcaseCard extends StatelessWidget {
  /// The title of the showcase card.
  final String title;

  /// Explanatory text shown below the title, above [child]. Sheets have more
  /// non-obvious behaviour than most components here, so this is required
  /// rather than optional.
  final String description;

  /// The content displayed inside the card -- typically a button that opens
  /// a sheet.
  final Widget child;

  /// Creates a new [_SheetShowcaseCard].
  const _SheetShowcaseCard({
    required this.title,
    required this.description,
    required this.child,
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
          SizedBox(height: tokens.spacing.sp1),
          Text(
            description,
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
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
