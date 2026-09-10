# LayrzSelectionToolbar — API Reference

Source: `lib/src/selection/src/selection_toolbar.dart`
- `LayrzSelectionToolbar` class (`StatelessWidget`)

---

## Examples

```dart
// Direct integration (advanced — normally rendered by LayrzTextSelectionControls)
LayrzSelectionToolbar(
  actions: {
    LayrzSelectableAction.copy,
    LayrzSelectableAction.paste,
  },
  anchorAbove: Offset(selection.dx, selection.dy),
  anchorBelow: Offset(selection.dx, selection.dy + 50),
  tokens: context.tokens,
  onActionPressed: (type) {
    if (type == 'copy') {
      _copySelectedText();
    } else if (type == 'paste') {
      _pasteText();
    }
  },
)
```

The typical path — via `LayrzTextSelectionControls.instance`'s `EditableText.contextMenuBuilder` integration:

```dart
EditableText(
  selectionControls: LayrzTextSelectionControls.instance,
  // contextMenuBuilder is supplied internally by the controls class
)
```

---

## Constructor

```dart
const LayrzSelectionToolbar({
  super.key,
  required this.actions,
  required this.anchorAbove,
  this.anchorBelow,
  required this.tokens,
  required this.onActionPressed,
});
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `actions` | `Set<LayrzSelectableAction>` | **required** | Action buttons to display. Internally sorted by `type` for consistent ordering, independent of the `Set`'s own iteration order. |
| `anchorAbove` | `Offset` | **required** | Position where the toolbar should appear above the selection (typically the selection's top-left). |
| `anchorBelow` | `Offset?` | `null` | Position to use if there isn't enough space above. `null` means the toolbar flips below and may extend off-screen. |
| `tokens` | `LayrzTokens` | **required** | Design tokens driving colors/spacing/radius/typography — typically `context.tokens`. |
| `onActionPressed` | `Function(String actionType)` | **required** | Fired when a button is pressed, with the action's `type` (`'copy'`, `'cut'`, `'paste'`, `'selectAll'`, or a custom action's own `type`, always `'custom'`). |

---

## Surface treatment

| Aspect | Value |
|---|---|
| Background fill | `tokens.colors.fg1` (dark foreground) |
| Content color | `tokens.colors.sf1` (light surface text) |
| Text style | `tokens.typography.label` (12px, w400) |
| Border radius | `tokens.radius.r2` (8px) |
| Elevation | `elevation2` shadow |

Matches `LayrzTooltip`'s own dark-overlay convention — page surfaces are light with dark text, overlay surfaces are dark with light text. This is deliberate, not to be "corrected" to a light fill.

---

## Sizing and positioning

- **Content-sized**: the toolbar fits its action buttons rather than expanding to fill the overlay width.
- **Horizontal scroll**: enabled only when content exceeds available width — rare, given typical 3–5 button toolbars.
- **Automatic positioning**: via `CustomSingleChildLayout` with `TextSelectionToolbarLayoutDelegate` — positions above the selection by default, flips below when there's insufficient space above.

---

## Action button styling

- Padding: `sp1` (4px) horizontal, consistent spacing between buttons.
- Text color inherits `sf1` from the container.
- Hover: subtle background color change.
- Press: opacity/shadow feedback (D15 — geometry never changes on interaction state).

---

## Behavior notes

- **Not usually constructed directly.** `LayrzTextSelectionControls.instance` builds and positions this widget via `EditableText.contextMenuBuilder` — see the `layrz-ui-text-selection-controls` skill.
- **Context-driven theming.** Every visual property is resolved from the `tokens` parameter at construction time, so a theme change is reflected without recreating anything, as long as the caller re-passes fresh `tokens`.
- **Localization.** Action labels come from `LayrzSelectableAction.label`, a function of `LayrzUiL10n` — resolved here via `LayrzUiL10n.of(context)` and passed to each action's `label` function.
- **Accessibility.** Buttons render as ordinary semantic actions — screen readers announce their labels and states.
