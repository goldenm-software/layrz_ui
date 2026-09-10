---
name: layrz-ui-stepper
description: Use LayrzStepper in a layrz_ui Flutter widget. Apply when building a multi-step wizard/onboarding/guided form — horizontal wide-header layout or vertical accordion layout via the required direction parameter, step states (upcoming/active/completed/error), and LayrzStepperController navigation.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.horizontal`, `.vertical`, `.error`) — never the fully-qualified form (`LayrzStepperDirection.horizontal`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A full-width step navigator for multi-step flows: wizards, onboarding, guided forms.
- **`direction` is required, with no viewport-derived inference** — the caller always states the axis explicitly. To reproduce the old width-derived behavior: `direction: context.isCompact ? .vertical : .horizontal`.
- Use `.horizontal` for a full-width row of equal-width step cells (desktop-style progress header).
- Use `.vertical` for a vertical accordion where only the active step's body expands inline.
- **Do not use** for a fixed tab strip with no linear progression — use `LayrzTabView` instead.
- **Do not use** in a box shorter than roughly 150 logical pixels — the fixed-height chrome (indicator band, label line, Back/Next row) does not shrink and will overflow.

---

## Minimal usage

```dart
LayrzStepper(
  direction: context.isCompact ? .vertical : .horizontal,
  steps: [
    LayrzStep(labelText: 'Shipping', body: ShippingForm()),
    LayrzStep(labelText: 'Payment', body: PaymentForm()),
    LayrzStep(labelText: 'Review', body: ReviewSummary()),
  ],
)
```

---

## Key behaviors

- **`LayrzStepper` renders no circle/connector/label geometry itself** — it is a thin coordinator delegating to `LayrzStepperWideHeader` (horizontal) or `LayrzStepperCompactLayout` (vertical), both un-exported (compose only via `LayrzStepper`).
- **State is derived automatically unless overridden**: steps before the current index default to `completed`, after default to `upcoming`; the active index is always forced to `active`. Pass `LayrzStep.state` explicitly only to force `.error` after validation fails.
- **The state glyph always wins over `LayrzStep.icon`** on `completed`/`error` — `icon` is the step's *identity* (e.g. a credit-card glyph), the state glyph communicates *status*, and WCAG 1.4.1 requires status to never be color-only. This override cannot be disabled.
- **`completed`, `active`, and `error` steps are all tappable** (jump back for review/correction); only `upcoming` steps are locked.
- **Controller ownership**: pass `controller: null` (default) and `LayrzStepper` creates/disposes its own; pass your own and you own disposal — and the instance must never be swapped on rebuild (debug assert).
- **A single Back/Next `LayrzButton` row** sits below either layout — navigation is always stepper-level, never per-step, even in the vertical accordion.
- **`next()` is gated by an optional async validation callback** (`LayrzStepperController.setCanAdvance`); `previous()` and `goTo()` are never gated.

---

## Common patterns

```dart
// 1. Programmatic navigation + async validation gate
final controller = LayrzStepperController();
controller.setCanAdvance(() async => await validateCurrentStep());

LayrzStepper(
  controller: controller,
  direction: .horizontal,
  steps: steps,
  onStepChanged: (index) => debugPrint('Now on step $index'),
)

// 2. Forcing a step into error state after validation
LayrzStep(
  labelText: 'Payment',
  body: PaymentForm(),
  state: paymentFailed ? .error : null,
)

// 3. Step with an identity icon
LayrzStep(
  labelText: 'Billing',
  icon: MdiIcons.cardAccountDetailsOutline,
  body: BillingForm(),
)

// 4. Custom Back/Next labels
LayrzStepper(
  direction: .horizontal,
  steps: steps,
  backButtonLabel: LayrzUiL10n.of(context).stepperBack,
  nextButtonLabel: LayrzUiL10n.of(context).stepperContinue,
)
```

---

## Usage conventions

- Always pass `direction` explicitly based on `context.isCompact` (or a deliberate fixed choice) — there is no default to fall back on.
- Give `LayrzStepper` at least ~150 logical pixels of height; place it in an `Expanded`/flexible region rather than a fixed small box.
- Keep `LayrzStep.labelText` short — labels are capped at 2 lines with ellipsis and have no recovery affordance (no tooltip, no long-press).
- Use `controller.goTo(index)` to jump back to a completed or error step for review; use `next()`/`previous()` for linear flow.
- Localize `backButtonLabel`/`nextButtonLabel` overrides via `LayrzUiL10n.of(context)` — the built-in defaults are already localized.
