# LayrzAlert — API Reference

Source: `lib/src/alerts/src/alert.dart`
- `LayrzAlert` class — line 48
- `LayrzAlertStyle` enum — `lib/src/alerts/src/alert_style.dart`
- `LayrzAlertType` enum — `lib/src/alerts/src/alert_type.dart`
- `LayrzAlertIcon` companion — `lib/src/alerts/src/alert_icon.dart`

---

## Examples

```dart
// Default info alert
LayrzAlert(
  title: 'Information',
  description: 'This is an informational message for the user.',
)

// Success, default .layrz style
LayrzAlert(
  type: .success,
  title: 'Operation successful',
  description: 'Your changes have been saved.',
)

// Warning with custom maxLines
LayrzAlert(
  type: .warning,
  title: 'Warning',
  description: 'This action requires your confirmation. Please review carefully before proceeding.',
  maxLines: 4,
)

// Danger, high-emphasis filledIcon style
LayrzAlert(
  type: .danger,
  style: .filledIcon,
  title: 'Error',
  description: 'An unexpected error occurred. Please try again later.',
)

// Context (muted) type
LayrzAlert(
  type: .context,
  style: .filledIcon,
  title: 'Context-dependent',
  description: "This alert's meaning depends on surrounding application state.",
)

// Custom type — explicit color and icon
LayrzAlert(
  type: .custom,
  color: const Color(0xFF9C27B0),
  icon: MdiIcons.heart,
  title: 'Custom alert',
  description: 'Using a custom color and icon.',
)

// Interactive — dismiss on tap
LayrzAlert(
  type: .success,
  title: 'Update available',
  description: 'A new version is ready. Tap to install.',
  onTap: () => handleUpdateInstall(),
)

// Standalone icon chip (no title/description)
LayrzAlertIcon(
  type: .info,
  size: 40,
  iconSize: 24,
)
```

---

## Constructor

```dart
const LayrzAlert({
  super.key,
  this.type = LayrzAlertType.info,
  required this.title,
  required this.description,
  this.maxLines = 3,
  this.style = LayrzAlertStyle.layrz,
  this.color,
  this.icon,
  this.iconSize,
  this.onTap,
});
```

No asserts — every parameter combination is valid; `.custom` type falls back to sensible defaults (`tokens.colors.primary`, an info glyph) rather than requiring `color`/`icon`.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `type` | `LayrzAlertType` | `.info` | Determines the semantic accent color and default icon. Ignored for color/icon resolution only when `.custom` (then `color`/`icon` are consulted). |
| `title` | `String` | — | **Required.** Bold single-line header text. |
| `description` | `String` | — | **Required.** Body text, clipped to `maxLines`. |
| `maxLines` | `int` | `3` | Max lines for `description` before ellipsis truncation. |
| `style` | `LayrzAlertStyle` | `.layrz` | Visual treatment — see enum table below. Both values render as split-panel. |
| `color` | `Color?` | `null` | Custom accent color, used only when `type == .custom`. Falls back to `tokens.colors.primary` when null. |
| `icon` | `IconData?` | `null` | Custom icon glyph, used only when `type == .custom`. Falls back to an info-box icon when null. |
| `iconSize` | `double?` | `null` | Icon glyph size. When null, resolves to `kLayrzAlertFilledIconSize` (25.0) unconditionally. |
| `onTap` | `VoidCallback?` | `null` | Tap handler. `null` (default) makes the alert fully inert; non-null makes it interactive with hover/press/focus feedback and keyboard activation. |

---

## `LayrzAlertType` enum

| Value | Token color | Default icon | Use case |
|---|---|---|---|
| `.info` | `tokens.colors.info` | information-box outline | Neutral, informational messages (default) |
| `.success` | `tokens.colors.success` | checkbox outline | Confirmation, successful operations |
| `.warning` | `tokens.colors.warning` | alert-box outline | Cautionary, attention-needed messages |
| `.danger` | `tokens.colors.danger` | close-box outline | Critical, destructive, error messages |
| `.context` | `tokens.colors.contextual` | dots-square | Context-dependent, low-emphasis metadata |
| `.custom` | `color` param (fallback `tokens.colors.primary`) | `icon` param (fallback info-box outline) | Any other semantic meaning |

---

## `LayrzAlertStyle` enum

Both values render the same split-panel layout (colored icon panel on the left, neutral surface panel with title/description on the right); they differ only in panel fill and icon contrast.

| Value | Left panel | Icon color | Use case |
|---|---|---|---|
| `.layrz` | Tonal accent (`accent.withOpacityValue(tokens.colors.tonalOpacity)`) | Accent (full strength) | Default; general-purpose, works on any neutral background |
| `.filledIcon` | Solid accent | Contrast color (`accent.contrastColor`) | High-emphasis; message needs immediate attention |

Both styles share: `backgroundColor: tokens.colors.sf1` (right panel), `borderColor: accent`, `borderWidth: tokens.border.base`, `titleColor: tokens.colors.fg1`, `bodyColor: tokens.colors.fg2`.

---

## Companion widgets

### `LayrzAlertIcon`

A standalone circular icon chip — NOT used internally by `LayrzAlert` (which builds its own icon chips), provided as a reusable building block elsewhere.

```dart
const LayrzAlertIcon({
  super.key,
  this.type = LayrzAlertType.info,
  this.size = kLayrzAlertIconWidgetSize,       // 30.0
  this.iconSize = kLayrzAlertIconWidgetIconSize, // 20.0
  this.padding,
  this.color,
  this.icon,
});
```

| Property | Type | Default | Notes |
|---|---|---|---|
| `type` | `LayrzAlertType` | `.info` | Determines icon/color unless `color`/`icon` are given for `.custom`. |
| `size` | `double` | `kLayrzAlertIconWidgetSize` (30.0) | Outer chip container size (width and height). |
| `iconSize` | `double` | `kLayrzAlertIconWidgetIconSize` (20.0) | Glyph size inside the chip. |
| `padding` | `EdgeInsetsGeometry?` | `null` | When null, defaults to `EdgeInsets.all(tokens.spacing.sp1)`. |
| `color` | `Color?` | `null` | Custom color, used only when `type == .custom`. |
| `icon` | `IconData?` | `null` | Custom icon, used only when `type == .custom`. |

The chip background is always the tonal accent (`accent.withOpacityValue(tokens.colors.tonalOpacity)`), regardless of `LayrzAlert`'s `style` — `LayrzAlertIcon` has no `style` parameter of its own.

---

## Behavior notes

- **Interaction state model** (`onTap` non-null): hover or focus lifts the surface by `kLayrzAlertHoverLift` (4.0lp) and raises the shadow to elevation 2; a press without prior hover (touch) gets the same hover treatment; a press *with* prior hover (desktop) settles back down with shadow elevation 1. The lift is a paint-only `Matrix4.translationValues` transform — geometry (size, hit-test region) never changes, so surrounding layout never reflows.
- **Accessibility**: non-interactive alerts are wrapped in `Semantics(container: true, label: '$title. $description')`. Interactive alerts use `Semantics(button: true, enabled: true, label: '$title. $description')` and are Tab-focusable, activatable via Enter/Space.
- **Border painting**: for both styles, the border is painted via `foregroundDecoration` over the clipped split-panel content (not a surrounding `BoxDecoration`), avoiding antialiasing seams at the left/right panel boundary.
- **Translucent fills flattened when interactive**: when `onTap` is non-null, the `.layrz` style's tonal left-panel fill is composited onto `tokens.colors.sf1` via `flattenOn` to stay opaque — otherwise `BoxDecoration`'s shadow would show through a translucent fill as a smudge. Non-interactive alerts keep the true translucent tonal fill.
- **Text scaling**: no fixed heights on title/description — they scale with the system font size (WCAG 1.4.4).
