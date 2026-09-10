---
name: layrz-ui-button
description: Use LayrzButton in a layrz_ui Flutter widget. Apply when rendering any tappable action — filled/outlined/text styles, FAB (icon-only) variants, semantic type colors, loading/cooldown busy states via LayrzButtonController, or the six semantic factories (.save/.cancel/.info/.show/.edit/.delete).
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.filled`, `.outlinedFab`, `.success`) — never the fully-qualified form (`LayrzButtonStyle.filled`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any tappable action: CTA buttons, form submit/cancel, confirmation dialogs, detail-page actions, toolbar icon buttons.
- **Prefer the six semantic factories** (`.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete`) for CRUD screens — they wire up the correct icon and `LayrzButtonType` color automatically.
- Use a FAB style (`.filledFab`, `.outlinedFab`, `.textFab`) — or a factory's `isFab: true` — when the button must be icon-only; `labelText` becomes the tooltip/accessible name in that case.
- Use `controller` (a `LayrzButtonController`) for loading or cooldown busy states — especially when several buttons in one form must move in lockstep.
- **Do not use** for static, non-interactive icons — use a plain `Icon`/`IconData` render instead.
- **Do not use** for a responsive row of actions that should collapse to a dropdown on narrow viewports — use `LayrzButtonGroup` instead.
- **Do not use** for generic hover/press chrome around an arbitrary widget — use `LayrzTappable` instead; `LayrzButton` is opinionated about label, icon, and sizing.

---

## Minimal usage

```dart
// Semantic factory — recommended for CRUD save
LayrzButton.save(
  labelText: 'Save',
  onTap: () async {
    await save();
    if (context.mounted) onSaved.call();
  },
)
```

---

## Key behaviors

- `labelText` is the **only** label representation — there is no `label` Widget parameter. FAB variants use it as the tooltip/accessible name.
- `type == LayrzButtonType.custom || color == null` is asserted at construction — passing `color` with any non-`custom` type throws.
- Sizing is **not caller-configurable**: there is no `height`, `width`, `iconSize`, or `fontSize` parameter. Dimensions come from `context.isCompact` — 45px height / 14px font / 22px icon on regular viewports, 50px / 16px / 24px on compact ones. Constrain the button from the parent (e.g. `SizedBox(width: 120)`) if you need a fixed width.
- No style paints a drop shadow in any state, `filled` included — hover/press feedback is colour-only (a lerp toward the content colour), never elevation.
- `controller: LayrzButtonController` drives `isLoading` / cooldown; `null` (default) means the button has no busy state at all and behaves as a plain button.
- Non-FAB buttons show a tooltip **only** when `hintText` is provided; FAB buttons always show one (composed from `labelText`, plus `hintText` on a second line if given).
- `LayrzButton` requires an `Overlay` ancestor (provided by `LayrzApp`) — its tooltip uses `LayrzTooltip` internally and will fail at runtime outside that tree.

---

## Style & type reference

| Style pair | FAB variant | Appearance |
|---|---|---|
| `.filled` | `.filledFab` | Solid accent fill, flat — no shadow, ever |
| `.outlined` | `.outlinedFab` | Transparent + accent border |
| `.text` | `.textFab` | No fill, no border — accent-coloured content only |

| `LayrzButtonType` | Token color | Used by |
|---|---|---|
| `.success` | `tokens.colors.success` | `.save` |
| `.info` | `tokens.colors.info` | `.info`, `.show` |
| `.context` | `tokens.colors.contextual` | manual use only |
| `.danger` | `tokens.colors.danger` | `.cancel`, `.delete` |
| `.warning` | `tokens.colors.warning` | `.edit` |
| `.custom` | explicit `color`, or `tokens.colors.primary` | manual buttons |

---

## Common patterns

```dart
// 1. Manual filled button with a custom color
LayrzButton(
  labelText: 'Export',
  icon: MdiIcons.trayArrowUp,
  type: .custom,
  color: myBrandColor,
  onTap: () async {
    await export();
    if (context.mounted) onExported.call();
  },
)

// 2. Icon-only FAB (label becomes tooltip)
LayrzButton(
  labelText: 'Add item',
  icon: MdiIcons.plus,
  style: .filledFab,
  type: .success,
  onTap: onAdd,
)

// 3. Shared controller — loading state across save + cancel
final controller = LayrzButtonController();

Row(
  children: [
    LayrzButton.cancel(
      labelText: 'Cancel',
      controller: controller,
      onTap: onCancel,
    ),
    const SizedBox(width: 10),
    LayrzButton.save(
      labelText: 'Save',
      controller: controller,
      onTap: () async {
        controller.startLoading();
        try {
          await onSave();
        } finally {
          controller.stopLoading();
        }
      },
    ),
  ],
)

// 4. Cooldown (e.g. resend code)
LayrzButton(
  labelText: 'Resend code',
  icon: MdiIcons.refresh,
  controller: controller,
  onTap: () {
    controller.startCooldown(const Duration(seconds: 30));
    resend();
  },
)

// 5. Semantic factory as FAB on compact layouts
LayrzButton.delete(
  labelText: 'Delete',
  isFab: context.isCompact,
  onTap: onDelete,
)
```

---

## Usage conventions

- Use plain string literals or `LayrzUiL10n.of(context).<key>` for `labelText` — never hardcode application copy that should be localized elsewhere in the app.
- Always guard async callbacks: `if (context.mounted) callback.call();`
- Use the six semantic factories on CRUD detail pages — they encode the project's icon/color conventions and keep buttons consistent across screens.
- Separate stacked buttons with `SizedBox(height: 10)`; separate buttons in a `Row` with `SizedBox(width: 10)`.
- Pass `isFab: context.isCompact` to semantic factories when a form should switch to icon-only buttons on narrow viewports — never derive that from `LayrzPlatform.isMobile`, which is OS-based, not width-based.
- Share one `LayrzButtonController` across a group of related buttons (e.g. save + cancel on the same form) rather than giving each its own — this keeps their busy states in lockstep instead of drifting frame to frame.
