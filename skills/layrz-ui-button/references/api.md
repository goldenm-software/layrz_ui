# LayrzButton — API Reference

Source: `lib/src/buttons/src/button.dart`
- `LayrzButton` class — line 28
- `lib/src/buttons/src/button_style.dart` — `LayrzButtonStyle` enum — line 6
- `lib/src/buttons/src/button_type.dart` — `LayrzButtonType` enum — line 5
- `lib/src/buttons/src/button_style_spec.dart` — `LayrzButtonStyleSpec` class — line 30
- `lib/src/buttons/src/button_controller.dart` — `LayrzButtonController` class — line 36

---

## Examples

```dart
// Default filled with text + icon
LayrzButton(
  labelText: 'Export',
  icon: MdiIcons.trayArrowUp,
  onTap: () => doExport(),
)

// Outlined and text styles (lower emphasis)
LayrzButton(labelText: 'More info', style: .outlined, onTap: () => showInfo()),
LayrzButton(labelText: 'Skip', style: .text, onTap: () => skip()),

// FAB — icon only, label becomes tooltip
LayrzButton(
  labelText: 'Add',
  icon: MdiIcons.plus,
  style: .filledFab,
  onTap: () => add(),
)

// Custom accent color (type must be .custom)
LayrzButton(
  labelText: 'Confirm',
  type: .custom,
  color: const Color(0xFF6A0DAD),
  onTap: () => confirm(),
)

// Semantic type without a custom factory
LayrzButton(
  labelText: 'Continue',
  type: .success,
  onTap: () => proceed(),
)

// Controller-driven loading state
final controller = LayrzButtonController();

LayrzButton(
  labelText: 'Submit',
  controller: controller,
  onTap: () async {
    controller.startLoading();
    try {
      await submit();
    } finally {
      controller.stopLoading();
    }
  },
)

// Controller-driven cooldown
LayrzButton(
  labelText: 'Resend code',
  controller: controller,
  onTap: () {
    controller.startCooldown(const Duration(seconds: 30));
    resend();
  },
)

// Disabled (via isDisabled, independent of onTap)
LayrzButton(labelText: 'Submit', isDisabled: true, onTap: () => submit()),

// Tooltip on a non-Fab button (hintText opts it in)
LayrzButton(
  labelText: 'Copy',
  icon: MdiIcons.contentCopy,
  style: .outlined,
  hintText: 'Copy to clipboard',
  onTap: () => copy(),
)

// Semantic factory — save
LayrzButton.save(
  labelText: 'Save',
  onTap: () => save(),
)

// Semantic factory — delete, as FAB
LayrzButton.delete(
  labelText: 'Delete',
  isFab: true,
  onTap: () => delete(),
)
```

---

## Constructor

```dart
const LayrzButton({
  super.key,
  required this.labelText,
  this.icon,
  this.onTap,
  this.isDisabled = false,
  this.controller,
  this.type = LayrzButtonType.custom,
  this.color,
  this.style = LayrzButtonStyle.filled,
  this.hintText,
  this.tooltipPosition = LayrzPreferredSide.bottom,
}) : assert(
       type == LayrzButtonType.custom || color == null,
       'color is only applied when type is LayrzButtonType.custom.',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `labelText` | `String` | **required** | The only label representation — no `label` Widget parameter exists. FAB variants use this as the tooltip/accessible name. |
| `icon` | `IconData?` | `null` | Icon shown before the label (non-Fab) or as the sole content (Fab). Sourced from `flutter_material_design_icons` (`MdiIcons.*`). |
| `onTap` | `VoidCallback?` | `null` | Tap handler. `null` disables the button (alongside `isDisabled`). |
| `isDisabled` | `bool` | `false` | Disables the button regardless of `onTap` or `controller` state. |
| `controller` | `LayrzButtonController?` | `null` | Drives loading/cooldown busy states. Multiple buttons may share one instance. Disposal is caller-owned. |
| `type` | `LayrzButtonType` | `.custom` | Selects the accent color token. See enum table below. |
| `color` | `Color?` | `null` | Accent override. Only honoured when `type == .custom`; passing it with any other `type` triggers an assertion. |
| `style` | `LayrzButtonStyle` | `.filled` | Visual variant. See enum table below. |
| `hintText` | `String?` | `null` | Non-Fab: supplying this is what enables the tooltip. Fab: appended to `labelText` on a second tooltip line. |
| `tooltipPosition` | `LayrzPreferredSide` | `.bottom` | Preferred side the tooltip renders on. |

No `width`, `height`, `iconSize`, or `fontSize` parameters exist — sizing is fixed by `context.isCompact` (see Behavior notes).

---

## Factory constructors

All six semantic factories share the same parameter shape:

```dart
factory LayrzButton.<name>({
  required String labelText,
  required VoidCallback onTap,
  bool isFab = false,
  LayrzButtonStyle style = LayrzButtonStyle.filled,
  bool isDisabled = false,
  LayrzButtonController? controller,
  String? hintText,
  LayrzPreferredSide tooltipPosition = LayrzPreferredSide.bottom,
  Key? key,
});
```

- `style` must be a **non-Fab** value — asserted (`!style.isFab`). Pass the regular style and use `isFab: true` to switch to icon mode; the factory maps it via `style.asFab` internally.
- `isFab: true` renders the icon-only square variant; `labelText` becomes its tooltip.
- When `isDisabled: true`, the factory nulls out `onTap` itself (in addition to setting `isDisabled`).

| Factory | Icon (`MdiIcons`) | `LayrzButtonType` | Semantic meaning |
|---|---|---|---|
| `.save` | `contentSaveOutline` | `.success` | Positive action confirming intent |
| `.cancel` | `closeCircleOutline` | `.danger` | Secondary action reverting state |
| `.info` | `informationOutline` | `.info` | Informational action |
| `.show` | `eyeOutline` | `.info` | Display or reveal action |
| `.edit` | `pencilOutline` | `.warning` | Modification action |
| `.delete` | `trashCanOutline` | `.danger` | Destructive action requiring intent |

All six default `style` to `.filled`.

---

## `LayrzButtonStyle` enum

| Value | FAB counterpart | `isFab` | `hasBorder` | Appearance |
|---|---|---|---|---|
| `.filled` | `.filledFab` | `false` / `true` | `false` | Solid accent fill, no border, no shadow — hover/press is a colour lerp toward content colour. |
| `.outlined` | `.outlinedFab` | `false` / `true` | `true` | Transparent background, accent border, no shadow. |
| `.text` | `.textFab` | `false` / `true` | `false` | No fill, no border, no shadow at rest — accent-coloured content, tonal wash on hover/press. |

Members: `style.isFab` (bool), `style.hasBorder` (bool, true only for `outlined`/`outlinedFab`), `style.asFab` (returns the Fab counterpart; identity for an already-Fab style).

---

## `LayrzButtonType` enum

| Value | Token color | Notes |
|---|---|---|
| `.success` | `tokens.colors.success` | Applied by `.save`. |
| `.info` | `tokens.colors.info` | Applied by `.info`, `.show`. |
| `.context` | `tokens.colors.contextual` | For context-dependent actions; no factory applies it automatically. |
| `.danger` | `tokens.colors.danger` | Applied by `.cancel`, `.delete`. |
| `.warning` | `tokens.colors.warning` | Applied by `.edit`. |
| `.custom` | `color` param, or `tokens.colors.primary` if `color` is null | The only type that honours the `color` parameter. |

---

## `LayrzButtonController` — API

Extends `ChangeNotifier`. Owns busy-state (loading/cooldown) timing; buttons are pure observers.

### State getters

| Getter | Type | Notes |
|---|---|---|
| `isLoading` | `bool` | Whether a loading indicator is active. |
| `cooldownTotal` | `Duration?` | Total duration of the active cooldown, or `null`. |
| `cooldownRemaining` | `Duration` | Clamped ≥ `Duration.zero`. |
| `cooldownProgress` | `double` | Clamped `[0.0, 1.0]`, `1.0` = fully elapsed. |
| `isBusy` | `bool` | `true` if loading, cooldown active, or the anti-flash floor is holding. |

### Methods

```dart
void startLoading();                    // no-op if already loading
void stopLoading();                     // starts the anti-flash floor
void startCooldown(Duration duration);  // no-op if duration <= 0; idempotent for same duration
void clearCooldown();                   // early exit, skips the anti-flash floor
void reset();                           // clears loading + cooldown + floor immediately
```

- `startCooldown` restarts the countdown only if `duration` differs from the currently running one.
- Cooldown auto-clears and notifies listeners when the duration elapses — the button never clears the controller itself.
- Disposal is caller-owned; a disposed controller does not throw if a still-mounted button is attached to it (though the app should stop using it).

---

## Static members

| Member | Signature | Notes |
|---|---|---|
| `kLayrzButtonHeight` | top-level `const double` (45) | Regular (non-compact) button height. |
| `kLayrzButtonCompactHeight` | top-level `const double` (50) | Height on `context.isCompact` viewports. |
| `kLayrzButtonFontSize` | top-level `const double` (14) | Regular font size. |
| `kLayrzButtonCompactFontSize` | top-level `const double` (16) | Font size on compact viewports. |
| `kLayrzButtonIconSize` | top-level `const double` (22) | Regular icon size. |
| `kLayrzButtonCompactIconSize` | top-level `const double` (24) | Icon size on compact viewports. |
| `kLayrzButtonMinBusyDuration` | top-level `const Duration` (100ms) | Anti-flash floor duration used by `LayrzButtonController`. |

These are top-level constants (from `lib/src/constants/`), not static members of `LayrzButton` — there is no caller-facing way to override sizing per instance.

---

## Companion widgets

The `buttons` barrel (`lib/src/buttons/buttons.dart`) also exports:

- **`LayrzButtonGroup`** — renders a row of `LayrzButton`s on wide viewports and collapses to a single dropdown trigger on narrow ones. Use this instead of a manual `Wrap`/`Row` of `LayrzButton`s for a list of related actions.
- **`LayrzButtonStyleSpec`** — the immutable paint spec (`backgroundColor`, `borderColor`, `borderWidth`, `contentColor`, `shadows`) resolved per style/state; internal to rendering, not typically constructed by callers.
- **`LayrzButtonController`** — see above.

---

## Behavior notes

- **Fill ladder:** each style occupies a different rung of the same transparent → tonal → solid ladder as interaction increases (default → hovered/focused → pressed). `filled` starts solid and only darkens; `outlined` starts transparent-with-border and reaches solid-with-border at pressed; `text` starts fully transparent and reaches a tonal wash at pressed. No style ever paints a `boxShadow`.
- **Disabled resolution:** `_effectivelyDisabled` is `onTap == null || isDisabled || (controller?.isBusy ?? false)` — any one of these three suppresses taps, sets the cursor to `SystemMouseCursors.basic`, and applies the disabled paint (`fg3` at 40% alpha for solid backgrounds, transparent kept transparent for outlined/text).
- **Pressed-state minimum window:** a tap's pressed visual holds for at least `kLayrzButtonMinPressedDuration` even if the pointer releases sooner, so a fast tap is still visibly acknowledged.
- **Sizing responds live to viewport:** height/font/icon size are recomputed from `context.isCompact` on every build — resizing a window across the compact breakpoint changes them without any explicit parameter.
- **Width is measured, not fixed:** for non-Fab buttons, width is computed from the actual `labelText` + `icon` content via `TextPainter`, then clamped to the incoming `BoxConstraints`. Fab buttons are always exactly square at the resolved height.
- **Tooltip source:** tooltips render via `LayrzTooltip` (not a bare `RawTooltip`), and require an `Overlay` ancestor — provided automatically inside `LayrzApp`.
- **Loading/cooldown indicator:** a thin bar (`kLayrzButtonIndicatorHeight`) overlays the bottom of the button whenever `controller.isLoading` or a cooldown is active; it is indeterminate while loading and shows `cooldownProgress` as a determinate fill during cooldown.
