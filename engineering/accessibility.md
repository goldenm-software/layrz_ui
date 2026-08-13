# Accessibility

This document specifies the accessibility conformance target for layrz_ui, enumerates what is committed now and what is deferred, explains the SDK primitives available for implementation, and catalogs the testing patterns and CI gates that enforce compliance.

---

## Conformance Target

**WCAG 2.1 Level AA is the minimum bar.** AAA is considered ideal but not required.

---

## Committed Criteria — In Scope Now

The following five WCAG 2.1 criteria are committed and must be satisfied by every shipped component.

### 4.1.2 Name, Role, Value (Level A)

**Requirement**: Every interactive control must expose a semantically correct name, role, and current state to assistive technology.

**Layrz commitment**: Every button, toggle (checkbox/switch/radio), input field, select, menu, dialog, and other control declares its role (via `Semantics(role: ...)` or semantic nodes), exposes its current state (e.g., `isEnabled`, `isChecked`), and carries a label or programmatic name.

**Implementation**: Use the Flutter SDK's `Semantics` widget (not Material-gated) and ensure every component builds a semantically annotated subtree.

---

### 2.1.1 Keyboard (Level A)

**Requirement**: All functionality must be operable without a pointer device.

**Layrz commitment**: All interactive components accept keyboard activation (Enter, Space where appropriate), support tab navigation, and respond to arrow keys in groups (radio buttons, menus, lists).

**Implementation**: Wire keyboard actions via `Shortcuts`, `Actions`, and `FocusNode`; verify all interactive components respond to `LogicalKeyboardKey.enter` and similar across platforms.

---

### 1.4.1 Use of Colour (Level A)

**Requirement**: Colour must never be the only means of conveying information.

**Layrz commitment**: Status indicators (success, error, warning, info) must use text, icons, or other non-color cues in addition to colour. Disabled states must use visual markers beyond colour alone (opacity, strikethrough, or icon changes).

**Implementation**: Design components so that removing all colour still preserves meaning. Document per component.

---

### 2.4.7 Focus Visible (Level AA)

**Requirement**: A visible focus indicator must be shown at all times when keyboard navigation is active.

**Layrz commitment**: All focusable elements display a visible focus ring. The ring is not painted by the SDK; layrz_ui owns focus ring design and implementation as a system-wide concern.

**Implementation**: Use `FocusableActionDetector` (SDK, not Material-gated) and paint focus rings in a dedicated token (see `design-tokens.md`). Focus ring visibility is verified via golden tests (see Testing section below).

---

### 1.4.4 Resize Text (Level AA)

**Requirement**: Content must remain usable when text is resized to 200 percent without loss of function.

**Layrz commitment**: Containers that hold text do not have fixed heights that clip or overflow at 2x text scale. Components use `TextScaler` to adapt layout dynamically.

**Implementation**: Avoid fixed-height containers for text-bearing elements. Verify via tests with `TextScaler.linear(2.0)` (see Testing section below).

---

## Deferred Criteria — Single Rationale, Three Linked Decisions

The following criteria are **out of scope** for the 1.0 release. They share a single architectural constraint: all three require an **alternative colour palette**.

### 1.4.3 Contrast (Minimum) and 1.4.11 Non-text Contrast (both Level AA)

**Requirement**: Text contrast must meet 4.5:1 for normal text, 3:1 for large text; UI components must have 3:1 contrast against adjacent colors.

### Dark Mode

**Requirement**: A complete alternative theme with appropriate luminance for dark backgrounds.

### High Contrast Mode

**Requirement**: A palette variant with elevated contrast for users with low vision.

### The Shared Constraint

All three require restructuring the token layer to support multiple palette variants. The current token system (see `design-tokens.md`) resolves to single concrete light values with no seams for variation. This is a by-design choice: the palette was created to support the light theme cleanly, without constraint from contrast requirements.

**When contrast compliance is eventually taken on**, the palette itself may need to change — not merely gain additional values, but restructure semantically. This is a heavier retrofit than dark mode alone, and it lands on the same token infrastructure. All three constraints therefore land together as a single architectural review.

**Known limitation**: Colours are not validated for contrast compliance in the current palette. If a consuming app's brand primary or secondary color does not meet WCAG AA thresholds, compliance is blocked until the palette restructuring is complete.

**Review trigger**: Before any public release of layrz_ui to a production userbase, convene the team to decide:

1. Will the 1.0 release target compliance with contrast + dark mode + high contrast mode (postponing 1.0), or
2. Will 1.0 ship with these deferred and a clear upgrade path in 2.0?
3. If (2), does the colour palette need to be redesigned now to avoid breaking token changes later?

**Cross-reference**: See decision D7 in `decisions.md` for the dark mode deferral.

---

## SDK Primitives Owned by layrz_ui

The Flutter SDK provides semantic and keyboard primitives that are **not Material-gated**. These are available to every Flutter app, including Material-free ones:

### Semantic Annotation

- `Semantics` widget — manually label a widget with role, state, and text
- `MergeSemantics` — combine semantics from multiple children into one node
- `ExcludeSemantics` — hide a subtree from semantics (e.g., decorative widgets)
- `SemanticsService.announce(message)` — read out a message to screen readers (used for transient feedback and live regions)

### Keyboard and Focus

- `FocusNode` — manage focus state programmatically
- `Focus` widget — attach a FocusNode to a subtree
- `FocusScope` widget — manage focus within a bounded region
- `FocusTraversalPolicy` — customize tab order and arrow-key navigation
- `FocusableActionDetector` — bind keyboard actions and expose `onShowFocusHighlight` callback (used by Material buttons to paint focus rings)
- `Actions` and `Shortcuts` — map keyboard events to named actions

### Text Scaling

- `MediaQueryData.textScaler` — get the current text scale factor (deprecated `textScaleFactor` field delegates to this)
- `TextScaler.linear(scale)` — construct a linear scaling factor for testing

All these are in `dart:ui`, `foundation`, `rendering`, or `widgets` packages — no Material imports required.

---

## What Material Was Supplying — Now Owned by layrz_ui

Material components provided behaviours on top of these primitives. layrz_ui must now implement those behaviours directly:

### Semantic Roles and State Traits

Material annotated every button as `isButton`, every checkbox as `isCheckbox` with `isChecked` state, and so on. **Layrz must do this explicitly.** A bare `GestureDetector` announces no role; every interactive component must declare itself via `Semantics` or semantic node flags.

### Focus Ring Painting

The SDK provides the `FocusableActionDetector` callback (`onShowFocusHighlight`), but **the ring itself is painted by the component**. There is no built-in focus ring primitive outside Material. This makes focus indication a **token-level, system-wide design concern**, not a per-component afterthought. The focus ring's colour, width, border radius, and animation are tokens (see `design-tokens.md`).

### Keyboard Bindings

Material defined defaults: Space and Enter activate buttons; arrows move within radio groups and menus; Escape dismisses dialogs. **Layrz must define all bindings.** Use `Shortcuts` to register global or per-widget mappings. Note: `RawRadio` and `RawMenuAnchor` (Flutter SDK, not Material) may already carry some bindings — verify before duplicating.

### Touch Target Minimums

Nothing in the SDK enforces minimum tap targets. Material components shipped 48x48 logical pixels on Android, 44x44 on iOS. **Layrz must enforce these sizes.**  
*Note*: The predecessor package layrz_theme shipped `ThemedMapButton` at a fixed 40 logical pixels, failing both platform thresholds. This is a regression to avoid.

### Text Scaling Adaptation

Fixed-height containers break when text is scaled to 200 percent. Material components adapt their layout dynamically. **Layrz components must not use fixed-height constraints on text-bearing elements.** Test every component at `TextScaler.linear(2.0)`.

---

## Testing — API Details (Flutter 3.47.0)

All APIs below are verified against the local Flutter SDK. Use them exactly as shown.

### Guideline Matchers

Located in `package:flutter_test/lib/src/accessibility.dart`. All are `const AccessibilityGuideline` instances:

- **`androidTapTargetGuideline`** (line 785, type `MinimumTapTargetGuideline`) — 48x48 logical pixels minimum
- **`iOSTapTargetGuideline`** (line 800, type `MinimumTapTargetGuideline`) — 44x44 logical pixels minimum
- **`textContrastGuideline`** (line 818, type `MinimumTextContrastGuideline`) — WCAG AA: 4.5:1 normal text, 3:1 large text
- **`labeledTapTargetGuideline`** (line 825, type `LabeledTapTargetGuideline`) — requires every tap target to carry a label or tooltip

Additional classes:

- **`MinimumTextContrastGuidelineAAA`** (accessibility.dart:525) — AAA thresholds: 7:1 normal, 4.5:1 large. **No const instance** is provided; must be instantiated `MinimumTextContrastGuidelineAAA()` if used.
- **`CustomMinimumContrastGuideline`** — allows defining custom contrast rules over a subset of elements (advanced).

### Using Matchers in Tests

`meetsGuideline(AccessibilityGuideline)` returns an `AsyncMatcher` (matchers.dart:1300). **Must be used with `expectLater`, not `expect`.**

```dart
// Correct usage
await expectLater(
  find.byType(LayrzButton),
  meetsGuideline(androidTapTargetGuideline),
);
```

### Semantics Inspection

**`WidgetTester.ensureSemantics()`** (controller.dart:2369) returns a `SemanticsHandle`. **It is REQUIRED** before any semantics can be inspected.

```dart
// Correct — always dispose the handle
void main() {
  testWidgets('Button announces role', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(LayrzApp(home: LayrzButton(...)));
      final semantics = tester.getSemantics(find.byType(LayrzButton));
      expect(semantics.isButton, true);
    } finally {
      handle.dispose();
    }
  });
}
```

Without `ensureSemantics()`, the semantics tree is not built and all matchers see nothing.

**`WidgetTester.getSemantics(finder)`** (controller.dart:2364) returns a `SemanticsNode` synchronously. Use after calling `ensureSemantics()`.

### Semantic Matchers

**Important correction** (breaking change after Flutter v3.40.0-1.0.pre): `containsSemantics` is **deprecated**. Use `isSemantics` instead.

- **`isSemantics`** (matchers.dart:1068) — matches only the properties you specify (all parameters are nullable). Safe for new code.
  ```dart
  expect(
    find.byType(LayrzButton),
    isSemantics(
      isButton: true,
      isFocusable: true,
      hasEnabledState: true,
      isEnabled: true,
    ),
  );
  ```

- **`matchesSemantics`** (matchers.dart:665) — defaults all unspecified flags to `false`, asserting their absence. This is a real trap: if you forget to specify a flag, the matcher asserts it must not be set.
  ```dart
  // TRAP: this asserts hasTapAction: false, hasLongPressAction: false, etc.
  expect(find.byType(LayrzButton), matchesSemantics(isButton: true));
  ```

### Semantic Role and State Flags

Available in `SemanticsNode` and `isSemantics` matcher:

**Roles**: `isButton`, `isSlider`, `isKeyboardKey`, `isLink`, `isTextField`, `isReadOnly`, `isImage`, `isHeader`.

**States**: `isFocused`, `isFocusable`, `isEnabled`, `hasEnabledState`, `isChecked`, `hasCheckedState`, `isCheckStateMixed`, `isSelected`, `hasSelectedState`, `isObscured`, `isMultiline`, `isExpanded`, `hasExpandedState`, `isRequired`, `hasRequiredState`, `isToggled`, `hasToggledState`, `isHidden`.

**Traits**: `namesRoute`, `scopesRoute`, `isLiveRegion`, `isInMutuallyExclusiveGroup`, `hasImplicitScrolling`.

**Actions**: `hasTapAction`, `hasLongPressAction`, `hasFocusAction`, `hasScrollLeftAction`, `hasScrollRightAction`, `hasScrollUpAction`, `hasScrollDownAction`, `hasIncreaseAction`, `hasDecreaseAction`, `hasDismissAction`, `hasSetTextAction`, `hasSetSelectionAction`, `hasCopyAction`, `hasCutAction`, `hasPasteAction`, and cursor-movement actions.

**Text parameters**: `label`, `hint`, `value`, `tooltip`, and their `attributedText` variants.

### Text Scaling in Tests

Use `MediaQueryData.textScaler` with `TextScaler.linear(2.0)`:

```dart
testWidgets('Button layout adapts at 2x text scale', (tester) async {
  await tester.binding.window.physicalSizeTestValue = Size(800, 600);
  addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
      child: LayrzApp(home: LayrzButton(label: 'Save')),
    ),
  );

  expect(tester.takeException(), isNull);
});
```

**Note**: The `@Preview` annotation (used for widget previews) still exposes a field named `textScaleFactor`. The field is deprecated (after v3.12.0-2.0.pre) but not yet removed, creating an inconsistency in the API surface. Do not fix the `@Preview` side; this is a Flutter SDK issue.

### Golden Files

`matchesGoldenFile(Object key, {int? version})` returns an `AsyncMatcher` (matchers.dart:588), used with `expectLater`. Focus ring visibility cannot be tested programmatically and requires golden comparison.

```dart
testWidgets('Button focus ring matches golden', (tester) async {
  await tester.pumpWidget(LayrzApp(home: LayrzButton(...)));
  await expectLater(
    find.byType(LayrzButton),
    matchesGoldenFile('goldens/button_focus.png'),
  );
});
```

### Material Safety

**Verified finding**: The `accessibility.dart` module in `flutter_test` imports only `dart:async`, `dart:ui`, `foundation`, `rendering`, `widgets`, and local files. **No Material imports.** The `matchers.dart` module does import `package:flutter/material.dart`, but uses it only in the unrelated `isInCard` / `isNotInCard` matchers; accessibility matchers use no Material symbols. The `flutter_test` pubspec pulls no Material into the dependency graph. **These APIs are safe for Material-free packages.**

---

## What CI Can and Cannot Catch — Honest Assessment

### Cheaply Automated (CI Gates These)

- **Tap target size** (`androidTapTargetGuideline`, `iOSTapTargetGuideline`) — binary pass/fail on physical dimensions
- **Labeled tap targets** (`labeledTapTargetGuideline`) — programmatic check for label presence
- **Role and state assertions** (via `isSemantics` matcher) — binary check that a semantic node carries expected flags

These cover WCAG 4.1.2 (Name, Role, Value) properly and are suitable for CI gates.

### Automatable with Effort (Tested, Not Gated)

- **Keyboard activation** — write tests that send key events (`tester.sendKeyEvent(LogicalKeyboardKey.enter)`) and assert the expected action fired (Semantics action present, callback invoked). Automatable but test-heavy.
- **Text scaling** — pump a widget under `MediaQuery(textScaler: TextScaler.linear(2.0))` and assert `tester.takeException()` is null (no overflow). Automatable but requires discipline.

### NOT Automatable (Human Review or Golden Tests)

- **Focus ring visibility** — inherently visual; requires golden tests or manual inspection. CI can run golden comparisons but cannot verify a ring *looks right*.
- **Colour not sole conveyor** — requires human review to ensure icons, text, or other semantic cues accompany colours. No matcher can detect a missing icon.
- **Keyboard bindings completeness** — testing can verify specific keys work; only human review catches missing bindings across all interactive components.
- **Contrast compliance** — deferred (see Deferred Criteria section); when in scope, requires human review or contrast measurement tools.

### Green Build ≠ Conformant

**A passing CI build does NOT mean the component is accessible.** The automated portion covers roughly half of the committed set. The other half requires testing discipline and human judgment.

---

## CI Configuration

### Gates (Milestone 1 Item 9)

When the CI pipeline is established (see `milestone-1.md`, item 9), gate on:

- `androidTapTargetGuideline` — must pass
- `iOSTapTargetGuideline` — must pass
- `labeledTapTargetGuideline` — must pass

### Do NOT Gate

- `textContrastGuideline` — **explicitly do not enable** because contrast is deferred (see Deferred Criteria section). If a team member tries to add it without revisiting the palette decision, the code review should catch it and link back to this document.

### Note

CI does not yet exist. These gates will be implemented as part of Milestone 1 work item 9.

---

## Per-Component Requirements

Every component type has accessibility requirements. The table below specifies the semantic role, expected state flags, keyboard bindings, and any announcement requirements.

| Component Kind | Semantic Role | State Flags | Keyboard Bindings | Announcement / Notes |
|---|---|---|---|---|
| **Button** | `isButton` | `isEnabled` / `hasEnabledState` | Enter, Space | Must have label or tooltip; optional live region announce on action |
| **Checkbox** | `isButton` (alternative: `isCheckbox` if SDK supports) | `isChecked`, `hasCheckedState`, `isEnabled`, `hasEnabledState` | Space to toggle | Must have label |
| **Switch** | `isButton` | `isToggled`, `hasToggledState`, `isEnabled`, `hasEnabledState` | Space to toggle | Must have label |
| **Radio Button** | `isButton`, `isInMutuallyExclusiveGroup` | `isSelected`, `hasSelectedState`, `isEnabled`, `hasEnabledState` | Space to select; arrow keys to navigate group | Must have label |
| **Text Input** | `isTextField` | `isEnabled`, `hasEnabledState`, `isObscured` (if password), `isReadOnly` (if read-only) | Standard text input; Escape to clear (optional) | Must have label or placeholder; error state with live region |
| **Select / Dropdown** | `isButton` (closed state) | `isEnabled`, `hasEnabledState` | Enter / Space to open; arrow keys to navigate options | Must have label; announce selected value on change |
| **Menu / Popup Menu** | `namesRoute: true`, `scopesRoute: true` | `isEnabled` per menu item | Escape to close; arrow keys to navigate; Enter to select | Must label menu items |
| **Dialog / Modal** | `namesRoute: true`, `scopesRoute: true` | — | Escape to dismiss (if allowed) | Must have title (label); announce on open; focus trap |
| **Overlay / Tooltip** | — | `isLiveRegion` (if transient feedback) | Escape to dismiss (optional) | Use `SemanticsService.announce()` for non-obvious tooltips |
| **Table** | — | — | Arrow keys to navigate cells (optional) | Column headers must have semantic role (e.g., `isHeader`) |
| **Snackbar / Toast** | `isLiveRegion: true` | — | Escape to dismiss (optional) | Must use `SemanticsService.announce()` or live region flag |

**Notes**:
- Every component with a visible label must expose that label via `Semantics(label: ...)` or semantic text parameters.
- Disabled components must have `isEnabled: false` and `hasEnabledState: true` even if no enabled state is designed (for consistency).
- Focus ring is mandatory for all focusable components (painted via token, not primitive).
- Transient feedback (snackbars, toasts) must use `isLiveRegion` or `SemanticsService.announce()` so screen readers read them automatically.

---

## Open Questions

The following questions remain open. The team must decide them before shipping layrz_ui 1.0:

### 1. CI Target Size Gating

Is tap target size gated in CI? Note that:
- `androidTapTargetGuideline` and `iOSTapTargetGuideline` are AAA-level in WCAG 2.1 (not AA).
- Android and iOS platform guidelines are stricter than WCAG (48x48 and 44x44 respectively).
- The team has not yet settled whether to enforce AAA-level accessibility as a condition of shipping.

**Decision needed**: Gate both guidelines in CI (AAA enforcement), or test them without gating (best effort)?

### 2. Raw SDK Keyboard Bindings

Does `RawRadio` or `RawMenuAnchor` (Flutter SDK widgets) already provide keyboard bindings for their respective components, or must layrz_ui add them?

**Research needed**: Examine `raw_radio.dart:44` and `raw_menu_anchor.dart:221` to verify existing bindings before duplicating.

### 3. Focus Ring Design

What is the visual design of the focus ring? Specifically:

- Colour (token name and light-theme value)?
- Width in logical pixels?
- Border radius (sharp, rounded, or proportional to component)?
- Animation (fade-in, grow, or static)?

**Design input needed**: Frontend design team to provide focus ring token specifications.

### 4. Reduced-Motion Support

Does reduced-motion preference (`MediaQuery.disableAnimations`) affect motion tokens such as `kHoverDuration` or `kPageTransitionDuration` (see `design-tokens.md`)?

**Decision needed**: Should components respect `disableAnimations` by zeroing durations, or use a `reducedMotionDuration` token?

### 5. Localization and Accessibility Strings

Does the localisation contract (see `localization.md`) include accessibility-specific strings such as:
- Semantic labels for icon-only components
- Screen reader announcements (e.g., "Loading..." for progress indicators)
- Error message content for input validation

**Cross-reference**: Check `localization.md` to see whether the i18n strategy accounts for accessibility.

---

## Progress Tracking

Accessibility implementation progress is tracked in the GitHub Project, not in this file. See the project board for milestone and issue status.

---

## Cross-References

- `decisions.md` — D7 covers dark mode deferral; D2 covers layrz_models Material coupling
- `design-tokens.md` — Token system specification; focus ring token design
- `milestone-1.md` — Foundation work (items 1–10) establishes CI and semantic infrastructure
- `flutter-347-audit.md` — SDK primitive inventory
- `localization.md` — i18n strategy and accessibility string contracts
- `migration-gap.md` — layrz_theme → layrz_ui feature parity
