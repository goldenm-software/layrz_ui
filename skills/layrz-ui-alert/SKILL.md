---
name: layrz-ui-alert
description: Use LayrzAlert in a layrz_ui Flutter widget. Apply when rendering an inline status callout — info/success/warning/danger/context/custom severities in a split-panel layout, with .layrz (tonal) or .filledIcon (solid) styles, and optional tap interactivity.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.warning`, `.filledIcon`) — never the fully-qualified form (`LayrzAlertType.warning`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Inline status messaging: form-level validation summaries, page-level banners, dialog body callouts, empty-state hints.
- Choose `type` by **semantic severity:**
  - `.info` — neutral informational hint (default).
  - `.success` — confirmation that an action completed successfully.
  - `.warning` — reversible caution; user can still proceed.
  - `.danger` — blocking or destructive condition; user must act before continuing.
  - `.context` — muted/contextual note; low-emphasis metadata.
  - `.custom` — only when you must override both icon and color.
- Choose `style` by **emphasis:**
  - `.layrz` (default) — tonal accent left panel, safe general-purpose choice.
  - `.filledIcon` — solid accent left panel, higher-emphasis, use for messages requiring immediate attention.
- `LayrzAlert` is a plain `StatefulWidget` — there is no `.show()` or dialog helper. Place it directly inside a `Column`, a dialog body, or any other layout widget.
- **Do not use** for transient action feedback (e.g. "saved" toast) — use a snackbar messenger instead.
- **Do not use** for a compact single-line label — use `LayrzChip` instead.
- Use `LayrzAlertIcon` when you need just the colored icon chip without a title or description.

---

## Minimal usage

```dart
LayrzAlert(
  type: .warning,
  title: 'Confirmation required',
  description: 'This action cannot be undone. Please review before proceeding.',
)
```

---

## Key behaviors

- `title` and `description` are both **required** — there is no variant without them.
- `maxLines` (default 3) clips `description` with an ellipsis; raise it if longer text is expected.
- `.custom` type reads `color`/`icon` when given, else falls back to `tokens.colors.primary` / an info glyph — it does not assert non-null.
- `style` changes only the surface chrome (panel fill, icon contrast); the semantic accent always comes from `type` (or `color` for `.custom`).
- `iconSize` defaults to `kLayrzAlertFilledIconSize` (25.0) regardless of `style` — override explicitly only when layout demands a different size.
- `onTap` is optional. When `null` (default), the alert is fully inert: no cursor change, no hover/press feedback, not focusable, and announces as a plain container to assistive technology. When non-null, the alert lifts on hover/focus, settles on press, and becomes keyboard-activatable (Tab + Enter/Space) — see `references/api.md` for the full state model.
- Layout is always split-panel: a colored icon panel on the left, a neutral `title`/`description` panel on the right.

---

## Common patterns

```dart
// 1. Info banner — default subtle style
LayrzAlert(
  title: 'Tip',
  description: 'You can drag rows to reorder them.',
)

// 2. Filled-icon danger alert with high emphasis
LayrzAlert(
  type: .danger,
  style: .filledIcon,
  title: 'Delete this record?',
  description: 'This action is permanent and cannot be undone.',
)

// 3. Success summary with a longer description
LayrzAlert(
  type: .success,
  title: 'Export complete',
  description: 'Your report was generated and is ready to download from the exports panel.',
  maxLines: 4,
)

// 4. Custom type with a project-specific icon and color
LayrzAlert(
  type: .custom,
  color: const Color(0xFF6A0DAD),
  icon: MdiIcons.shieldCheck,
  title: 'Verified',
  description: 'This device passed the security check.',
)

// 5. Interactive alert — tap to dismiss
LayrzAlert(
  type: .warning,
  title: 'Update available',
  description: 'Tap to install the latest version.',
  onTap: () => setState(() => showBanner = false),
)
```

---

## Usage conventions

- Use plain string literals or `LayrzUiL10n.of(context).<key>` for `title`/`description` — never hardcode application copy that belongs in a localization layer.
- Don't stack multiple alerts of the same severity; collapse them into one with a combined description.
- Keep descriptions short enough to fit in the default 3 lines; set `maxLines` explicitly rather than relying on the default when content is inherently longer.
- Separate `LayrzAlert` from surrounding inputs or cards with `SizedBox(height: 10)`.
- Prefer `LayrzAlert` for content that stays on the page; for a one-shot confirmation after a user action, a snackbar messenger is a better fit.
