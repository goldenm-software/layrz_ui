# LayrzStepper — API Reference

Source: `lib/src/steppers/src/stepper.dart`
- `LayrzStepper` class
- Companion: `step.dart` — `LayrzStep`
- Companion: `stepper_controller.dart` — `LayrzStepperController`
- Companion: `stepper_state.dart` — `LayrzStepperState` enum
- Companion: `stepper_direction.dart` — `LayrzStepperDirection` enum
- Companion: `step_indicator.dart` — `LayrzStepIndicator` (exported standalone)
- Not exported: `stepper_wide.dart` (`LayrzStepperWideHeader`), `stepper_compact.dart` (`LayrzStepperCompactLayout`) — deliberately private; use only through `LayrzStepper`.

---

## Examples

```dart
// Horizontal (wide) layout
LayrzStepper(
  direction: .horizontal,
  steps: [
    LayrzStep(labelText: 'Shipping', body: ShippingForm()),
    LayrzStep(labelText: 'Payment', body: PaymentForm()),
    LayrzStep(labelText: 'Review', body: ReviewSummary()),
  ],
)

// Vertical (compact accordion) layout, viewport-derived
LayrzStepper(
  direction: context.isCompact ? .vertical : .horizontal,
  steps: steps,
)

// Controller-driven with async validation gate
final controller = LayrzStepperController();
controller.setCanAdvance(() async => await validateCurrentStep());

LayrzStepper(
  controller: controller,
  direction: .horizontal,
  steps: steps,
  onStepChanged: (index) => debugPrint('Now on step $index'),
)

// Step forced into error state
LayrzStep(
  labelText: 'Payment',
  body: PaymentForm(),
  state: paymentFailed ? .error : null,
)

// Step with an identity icon (overridden by state glyph once completed/error)
LayrzStep(
  labelText: 'Billing',
  icon: MdiIcons.cardAccountDetailsOutline,
  body: BillingForm(),
)
```

---

## Constructor: `LayrzStepper`

```dart
const LayrzStepper({
  required this.steps,
  required this.direction,
  this.controller,
  this.onStepChanged,
  this.backButtonLabel,
  this.nextButtonLabel,
  super.key,
}) : assert(steps.length > 0, 'At least one step is required');
```

### Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `steps` | `List<LayrzStep>` | required | At least one required — asserted. No maximum step count. |
| `direction` | `LayrzStepperDirection` | required | No default, no viewport inference. `.horizontal` → `LayrzStepperWideHeader`; `.vertical` → `LayrzStepperCompactLayout`. |
| `controller` | `LayrzStepperController?` | `null` | `null` ⇒ stepper creates/owns/disposes its own. Non-null ⇒ caller-owned disposal; instance must never be swapped on rebuild (debug assert). |
| `onStepChanged` | `void Function(int stepIndex)?` | `null` | Fires with the zero-based index of the new active step whenever it changes. |
| `backButtonLabel` | `String?` | `null` (→ `LayrzUiL10n.steppersPreviousButtonLabel`) | Overrides the "Back" button label. |
| `nextButtonLabel` | `String?` | `null` (→ `LayrzUiL10n.steppersNextButtonLabel`) | Overrides the "Next" button label. |

---

## `LayrzStep`

```dart
const LayrzStep({
  required this.labelText,
  required this.body,
  this.state,
  this.icon,
});
```

| Property | Type | Default | Notes |
|---|---|---|---|
| `labelText` | `String` | required | Display label, shown in both layouts. |
| `body` | `Widget` | required | Rendered only while the step is active. |
| `state` | `LayrzStepperState?` | `null` | Override. `null` ⇒ derived from progression. The active index is always forced to `.active` regardless of this field. |
| `icon` | `IconData?` | `null` | Identity icon shown while `.upcoming`/`.active`. Always overridden by the state glyph once `.completed`/`.error`. |

`@immutable`, has `copyWith`. **Equality caveat**: `==`/`hashCode` depend on `body` (a `Widget`), compared by identity — two structurally identical `const Text('x')` instances are not equal to each other.

---

## `LayrzStepperState` enum

| Value | Meaning |
|---|---|
| `.upcoming` | Not yet reached. Not tappable. |
| `.active` | The current step. Body shown. |
| `.completed` | Successfully completed. Tappable to jump back. |
| `.error` | Failed/needs attention. Tappable to jump back for correction. |

---

## `LayrzStepperDirection` enum

| Value | Renders | Notes |
|---|---|---|
| `.horizontal` | `LayrzStepperWideHeader` | Full-width row, one equal-width flex cell per step, connected by a line. |
| `.vertical` | `LayrzStepperCompactLayout` | Vertical accordion; only the active step's body expands inline. |

Required on `LayrzStepper.direction` — no default, no `context.isCompact` inference (removed deliberately; a caller reproduces it explicitly).

---

## `LayrzStepperController extends ChangeNotifier`

```dart
LayrzStepperController(); // no constructor params
```

| Member | Signature | Notes |
|---|---|---|
| `currentStepIndex` | `int get` | Zero-based active index. |
| `stepCount` | `int get` | Set internally by the stepper via `setStepCount`. |
| `canMoveNext` | `bool get` | `currentStepIndex < stepCount - 1`. |
| `canMovePrevious` | `bool get` | `currentStepIndex > 0`. |
| `next()` | `Future<void>` | Advances one step if `canMoveNext`; awaits the `canAdvance` gate first if set. No-op (no notify) if already denied or on the last step. |
| `previous()` | `void` | Moves back one step, no validation. No-op on the first step. |
| `goTo(int index)` | `void` | Jumps directly, no validation. Out-of-bounds or same-index calls are no-ops. |
| `setCanAdvance(Future<bool> Function()? callback)` | `void` | Sets/clears the async validation gate `next()` checks. |
| `reset()` | `void` | Returns to the first step (index 0, count 0) — called internally when the stepper rebuilds with a different step list. |
| `dispose()` | `void` | Caller-owned if the controller was caller-supplied to `LayrzStepper`; must be called exactly once. |

---

## `LayrzStepIndicator` (exported independently)

```dart
const LayrzStepIndicator({
  required this.index,
  required this.state,
  this.icon,
  super.key,
});
```

| Property | Type | Notes |
|---|---|---|
| `index` | `int` | Zero-based position; renders the 1-based number when `icon` is null. |
| `state` | `LayrzStepperState` | Drives background color and the glyph-override rule. |
| `icon` | `IconData?` | Identity icon; overridden by the state glyph on `.completed`/`.error`. |

### Icon-vs-state-glyph resolution table

| State | Circle content | Background |
|---|---|---|
| `.completed` | Check icon — always, overrides `icon` | `tokens.colors.success` |
| `.error` | Alert icon — always, overrides `icon` | `tokens.colors.danger` |
| `.active` | `icon` if supplied, else 1-based `index` | `tokens.colors.primary` |
| `.upcoming` | `icon` if supplied, else 1-based `index` | `tokens.colors.sf3`, divider-colored border |

`kLayrzStepIndicatorSize = 40.0` (indicator diameter). `kLayrzStepIndicatorGlyphSize = 16.0` (glyph size).

---

## Constants

| Constant | Value | Notes |
|---|---|---|
| `kLayrzStepIndicatorSize` | `40.0` | Circle diameter, shared by both layouts. |
| `kLayrzStepIndicatorGlyphSize` | `16.0` | Glyph size inside the circle. |

---

## Behavior notes

- **Minimum height ~150px**: fixed-height chrome (wide indicator band matching `kLayrzStepIndicatorSize`, label line, spacing gap, Back/Next `LayrzButton` row + its own padding) does not shrink. A bounded box shorter than this overflows (`RenderFlex`) — this is a real layout constraint, not a bug.
- **Wide layout two-band split**: each step's cell stacks a fixed-height indicator band (independent of label length) above the label band — this is a structural fix for a shipped bug where a two-line label used to re-center and misalign the indicator circle.
- **Labels capped at `maxLines: 2` with ellipsis**, no recovery affordance (no tooltip, no long-press) — deliberate, not an oversight.
- **No maximum step count** — an unusually long step list squeezes into narrower cells rather than being capped or scrolled (wide layout never scrolls horizontally); legibility at extreme counts is the caller's responsibility.
- **Compact layout is not a general accordion**: exactly one step is ever open (always the active one, driven by `currentIndex`); tapping a completed step's header navigates rather than opening a second panel. Locked (`.upcoming`) steps can never be opened.
- **Back/Next buttons use `LayrzButton`**, not `LayrzButtonStyle` — the Back button uses `type: LayrzButtonType.info`.
- **Accessibility**: each step's `Semantics` combines a localized "Step N of M" position, the step's own label, and a localized state fragment (`LayrzUiL10nSteppersMixin`). `upcoming`'s fragment includes "locked" so a screen-reader user understands why the step doesn't respond. `ExcludeFocus(excluding: !isOpen)` keeps a collapsed compact-layout step's body out of the tab order — relevant on desktop regardless of window width, since `direction: .vertical` can be chosen deliberately on a wide window.
