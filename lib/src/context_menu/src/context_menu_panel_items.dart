import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'context_menu_item.dart';

/// Renders a single [LayrzContextMenuItem] inside a `LayrzContextMenu` panel.
///
/// Dispatches to the correct visual and interaction treatment for each of the
/// three concrete [LayrzContextMenuItem] subtypes via a `switch` over the
/// sealed hierarchy — exhaustive by construction, so a fourth subtype would
/// fail to compile here rather than silently falling through.
///
/// Internal to the `context_menu` module: not exported from its barrel.
class LayrzContextMenuItemWidget extends StatelessWidget {
  /// The item this widget renders.
  final LayrzContextMenuItem item;

  /// Creates a new [LayrzContextMenuItemWidget] for [item].
  const LayrzContextMenuItemWidget({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      LayrzContextMenuEntry entry => _LayrzContextMenuEntryTile(entry: entry),
      LayrzContextMenuLabel label => _LayrzContextMenuLabelTile(label: label),
      LayrzContextMenuDivider() => const _LayrzContextMenuDividerTile(),
    };
  }
}

/// Renders an interactive [LayrzContextMenuEntry] row.
///
/// Hover, press, and focus states vary background, label, and icon color
/// only — never size, padding, or geometry (see D15).
class _LayrzContextMenuEntryTile extends StatefulWidget {
  /// The entry this tile renders.
  final LayrzContextMenuEntry entry;

  /// Creates a new [_LayrzContextMenuEntryTile] for [entry].
  const _LayrzContextMenuEntryTile({required this.entry});

  @override
  State<_LayrzContextMenuEntryTile> createState() => _LayrzContextMenuEntryTileState();
}

class _LayrzContextMenuEntryTileState extends State<_LayrzContextMenuEntryTile> {
  final WidgetStatesController _statesController = WidgetStatesController();

  @override
  void initState() {
    super.initState();
    _statesController.addListener(_onStatesChanged);
  }

  @override
  void dispose() {
    _statesController.removeListener(_onStatesChanged);
    _statesController.dispose();
    super.dispose();
  }

  void _onStatesChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onTap() {
    if (!widget.entry.enabled) return;
    widget.entry.onTap();
    MenuController.maybeOf(context)?.close();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final entry = widget.entry;

    final states = _statesController.value;
    if (!entry.enabled && !states.contains(WidgetState.disabled)) {
      _statesController.update(WidgetState.disabled, true);
    } else if (entry.enabled && states.contains(WidgetState.disabled)) {
      _statesController.update(WidgetState.disabled, false);
    }

    final Color backgroundColor;
    final Color contentColor;
    if (!entry.enabled) {
      backgroundColor = tokens.colors.sf1;
      contentColor = tokens.colors.fg3;
    } else if (states.contains(WidgetState.pressed)) {
      backgroundColor = tokens.colors.sf3;
      contentColor = entry.color ?? tokens.colors.fg1;
    } else if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
      backgroundColor = tokens.colors.sf2;
      contentColor = entry.color ?? tokens.colors.fg1;
    } else {
      backgroundColor = tokens.colors.sf1;
      contentColor = entry.color ?? tokens.colors.fg1;
    }

    return FocusableActionDetector(
      enabled: entry.enabled,
      onShowHoverHighlight: (show) => _statesController.update(WidgetState.hovered, show),
      onShowFocusHighlight: (show) => _statesController.update(WidgetState.focused, show),
      child: MouseRegion(
        cursor: entry.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Listener(
          onPointerDown: (_) {
            if (entry.enabled) _statesController.update(WidgetState.pressed, true);
          },
          onPointerUp: (_) => _statesController.update(WidgetState.pressed, false),
          onPointerCancel: (_) => _statesController.update(WidgetState.pressed, false),
          child: GestureDetector(
            onTap: entry.enabled ? _onTap : null,
            child: Semantics(
              button: true,
              enabled: entry.enabled,
              label: entry.labelText,
              excludeSemantics: true,
              child: AnimatedContainer(
                duration: tokens.motion.dHover,
                curve: tokens.motion.easing,
                constraints: const BoxConstraints(minWidth: 160.0),
                decoration: BoxDecoration(color: backgroundColor),
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spacing.sp3,
                  vertical: tokens.spacing.sp2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (entry.icon != null) ...[
                      Icon(entry.icon, size: 18.0, color: contentColor),
                      SizedBox(width: tokens.spacing.sp2),
                    ],
                    Flexible(
                      child: Text(
                        entry.labelText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tokens.typography.body.copyWith(color: contentColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders a non-interactive [LayrzContextMenuLabel] section heading.
class _LayrzContextMenuLabelTile extends StatelessWidget {
  /// The label this tile renders.
  final LayrzContextMenuLabel label;

  /// Creates a new [_LayrzContextMenuLabelTile] for [label].
  const _LayrzContextMenuLabelTile({required this.label});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      header: true,
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.sp3,
          vertical: tokens.spacing.sp2,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label.labelText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tokens.typography.label.copyWith(color: label.color ?? tokens.colors.fg3),
          ),
        ),
      ),
    );
  }
}

/// Renders a [LayrzContextMenuDivider] separator line.
class _LayrzContextMenuDividerTile extends StatelessWidget {
  /// Creates a new [_LayrzContextMenuDividerTile].
  const _LayrzContextMenuDividerTile();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(height: 1, color: tokens.colors.divider);
  }
}
