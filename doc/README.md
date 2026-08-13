# layrz_ui Documentation

This directory contains the design system documentation for `layrz_ui`, a Material-free, Cupertino-free Flutter design system built exclusively on `package:flutter/widgets.dart` and `dart:ui`.


## Project Invariant

Every change must maintain this invariant — no Material or Cupertino imports are ever allowed anywhere under `lib/`:

```bash
grep -r "package:flutter/material\|package:flutter/cupertino" lib/
```

This output must always be empty.

## Progress Tracking

Progress on milestones and individual components is tracked in the repository's **GitHub Project** (`goldenm-software/layrz_ui`). This documentation describes the plan and architecture; for real-time status, see the Project board.

## Documentation Guide

| Document | Answers | Read when |
|----------|---------|-----------|
| [**roadmap.md**](roadmap.md) | What are the overall milestones? Why this sequence? What gets unblocked when? | You want to understand the full arc from M1 (foundation) through M7 (deferred features). Includes scale context and rewrite rationale. |
| [**milestone-1.md**](milestone-1.md) | What exactly ships in M1? What are the 12 work items? Which files change and why? How is success measured? | You are implementing M1, need acceptance criteria, or want to understand which work items block others. Primary deliverable. |
| [**design-tokens.md**](design-tokens.md) | How are semantic colors, typography, spacing, shadows, borders and motion defined? What is the token API? | You are adding token support, extending the tokenizer, or designing a new component that depends on tokens. |
| [**flutter-347-audit.md**](flutter-347-audit.md) | Which raw widgets does Flutter 3.47 offer that we can build on? (RawTooltip, RawRadio, ToggleableStateMixin, etc.) | You are designing a new component and need to know what primitives are available without Material/Cupertino. |
| [**architecture.md**](architecture.md) | How is the codebase organized? How do modules relate? What are the patterns for state, routing, and theming? | You need to add a new module or understand the design system architecture. |
| [**dependencies.md**](dependencies.md) | What does layrz_ui depend on? Which packages are Material-coupled and when must they migrate? | You are evaluating a new dependency, or want to understand the Material decoupling strategy. |
| [**decisions.md**](decisions.md) | What major decisions have been made? Why? What are the consequences and risks recorded? | You are considering a design change and want to understand prior context. |

## Widget Documentation

For widget-specific documentation, see the **[GitHub wiki](https://github.com/goldenm-software/layrz_ui/wiki)**:
- Per-component widget pages (28 pages)
- Input contract specification
- Component catalog

The wiki is hosted as a git submodule. Widget documentation is kept separate from repository engineering documentation.

## Key Links

- **Repository**: https://github.com/goldenm-software/layrz_ui
- **Related package**: [`layrz_theme`](https://github.com/goldenm-software/layrz_theme) (the predecessor design system, still in use; layrz_ui is a clean break, not a drop-in replacement)
- **Project environment**: Flutter 3.47.0 stable, Dart 3.13.0, SDK constraint `>=3.13.0 <4.0.0`

## Running the Example

```bash
make run-linux    # Linux desktop
make run-android  # Android
make run-ios      # iOS
make run-windows  # Windows desktop
make run-macos    # macOS desktop
```

## Running Tests

```bash
flutter test                  # All tests
flutter test --coverage       # With coverage report
```

## CLAUDE.md

The project's [CLAUDE.md](../CLAUDE.md) file contains critical rules for this codebase:

1. **Document every argument at 100%** — all public fields, parameters, and method arguments must have `///` dartdoc comments.
2. **Full test coverage** — every new widget, extension, helper, or utility ships with tests.
3. **Use `@Preview` for visual widgets** — add Flutter 3.47 preview annotations with `LayrzPreviewTheme` (planned for M1).
4. **One concern per file** — split large files, never pile unrelated things together.

---

**Last updated**: 2026-08-13
