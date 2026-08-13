# Decision Log

This document records significant architectural, policy, and strategy decisions made during layrz_ui development. Each decision is dated and includes the context, options considered, the choice made, rationale, consequences, and any review triggers.

---

## D1: Component Naming — Layrz* Prefix (Clean Break)

**Date**: 2026-08-13  
**Status**: Decided  
**Category**: Architecture / API Design

### Context

layrz_ui is a ground-up rewrite of layrz_theme, not a port. The old package used the `Themed*` prefix (e.g., `ThemedButton`, `ThemedTextInput`). layrz_ui must choose whether to:
1. Maintain `Themed*` naming for familiarity and ease of migration
2. Use `Layrz*` naming (consistent with the already-shipped LayrzApp, LayrzTheme, LayrzThemeData) as a clean break
3. Use `Layrz*` canonical with deprecated `Themed*` typedef aliases as a migration bridge

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Keep `Themed*` | Drop-in replacement; consuming apps can migrate with a single import swap | Inconsistent with LayrzApp/LayrzTheme naming; duplicates the old design system's naming convention |
| (b) Use `Layrz*` (chosen) | Consistency across the design system; clear break from layrz_theme; aligns with the rewrite's scope | Consuming apps must rename every widget; no drop-in path |
| (c) Dual naming with deprecation | Gradual migration path; backward compatibility window | Maintenance burden of two API surfaces; longer deprecation period needed |

### Decision

**Chose (b): `Layrz*` prefix, clean break.**

### Rationale

- Consistency is the primary design principle of layrz_ui. All foundational types (LayrzApp, LayrzTheme, LayrzThemeData, LayrzPlatform) use the Layrz* prefix.
- The structural change from part-files to a module-barrel system is already a rewrite, not a port. Maintaining `Themed*` naming would create a false impression of drop-in compatibility.
- Clean naming makes it explicit that consuming apps are migrating to a new design system, which sets correct expectations.

### Consequences

- Consuming apps must rename every widget import and instantiation: `ThemedButton` → `LayrzButton`, etc.
- There is no drop-in migration path from layrz_theme. The migration is a rewrite, not a rename.
- Team onboarding and documentation must clearly explain the break.
- No `Themed*` backward-compatibility aliases will be provided.

### Review Trigger

When the first stable release of layrz_ui is shipped and consuming apps begin migration, gather feedback on the naming. If apps report that the rewrite was more painful than expected, consider a `1.x.y` deprecation release that provides `Themed*` aliases pointing to `Layrz*` classes for a transition period. This would not be a breaking change; it would ease migration for late adopters.

---

## D2: layrz_models Material Coupling — Deferred

**Date**: 2026-08-13  
**Status**: Deferred  
**Category**: Dependency Policy

### Context

layrz_models is a peer package (3.24.7, not owned by layrz_ui) that contains API models, ORM helpers, and converters for Layrz entities. It has 19 files with Material imports. layrz_ui may eventually need model-bound components like:
- DynamicCredentialsInput (renders a schema-driven credentials form for InboundProtocol/OutboundProtocol)
- ORM helper widgets (for relationship editing)

The question is whether to decouple layrz_models from Material before building these components, or to accept the coupling temporarily.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Decouple upstream now | Ensures layrz_ui stays design-system-agnostic; unblocks model-bound components immediately | Requires changes to a peer package not owned by layrz_ui; delays layrz_ui development; may require significant refactoring in layrz_models |
| (b) Accept coupling, declare out-of-scope | layrz_ui development is unblocked; model-bound components are deferred to a future package or release | layrz_ui's design-system-agnostic claim is qualified; creates a second package (layrz_ui_models?) for model-bound components |
| (c) Deferred (chosen) | Allows layrz_ui Milestone 1 (foundation) to proceed without external dependencies; revisit when model-bound components are scoped | layrz_models coupling remains unresolved; decision to decouple or split is postponed |

### Decision

**Chose (c): Deferred.**

### Rationale

- layrz_ui Milestone 1 scope is foundation components only (buttons, inputs, layouts, theme). No model-bound components are included.
- Decoupling layrz_models requires coordination with the team maintaining that package and is outside the critical path for Milestone 1.
- Deferring this decision allows Milestone 1 to remain tightly scoped and focused on proving the design-system-agnostic foundation.
- By the time model-bound components are needed, more context will exist about whether layrz_models should be design-system-agnostic or whether a separate layrz_ui_models package is preferred.

### Consequences

- Model-bound components (DynamicCredentialsInput, ORM helpers, etc.) are **out of scope** for Milestone 1 and likely for the 1.0 release.
- Any consuming app that needs such components must either:
  - Wait for a future decision and implementation
  - Implement them themselves on top of layrz_ui
  - Continue using layrz_theme for those specific components
- The "design-system-agnostic" claim is qualified: layrz_ui's core is agnostic; model-bound extensions may be deferred.

### Review Trigger

When model-bound components are first scoped (Milestone 2 or later), re-open this decision with the following context:
- How many consuming apps need model-bound components?
- Has layrz_models evolved? Does it still import Material in the same places?
- Is the solution a) decouple layrz_models, b) create layrz_ui_models, or c) something else?

Revisit date: When model-bound component scoping begins.

---

## D3: google_fonts Dependency — Use TextStyle API Only

**Date**: 2026-08-13  
**Status**: Decided  
**Category**: Dependency Policy

### Context

google_fonts is a widely-used package for importing Google Fonts into Flutter apps. It imports Material in 28 files. However, a detailed audit (see docs/dependencies.md) found that:
- The core font-loading engine (google_fonts_base.dart) has a **dead Material import**
- layrz_theme calls **only** the TextStyle-returning APIs (GoogleFonts.getFont(name), GoogleFonts.ubuntu(), etc.)
- The TextTheme-returning methods (which require Material at runtime) are unreachable in layrz_theme

The decision is whether to:
1. Depend on google_fonts as-is, accepting Material in the transitive compile graph
2. Re-implement a Material-free font loader (300+ lines, using dart:ui FontLoader, http, crypto, path_provider)
3. Upstream a fix to split google_fonts into google_fonts (TextStyle-only) and google_fonts/material (TextTheme)
4. Bundle a fixed font set as package assets (losing runtime font customization)

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Depend as-is (chosen) | google_fonts is robust, widely tested, and maintained; no extra work; users can choose any Google font at runtime | Material sits in the compile graph; decision is fragile if google_fonts later couples more tightly |
| (b) Re-implement | layrz_ui's font loading is under our control; no transitive Material | 300+ lines of code; we own the maintenance; must handle edge cases google_fonts already handles |
| (c) Upstream fix | Elegant long-term solution; benefits the entire Flutter ecosystem; Material can be truly optional | Requires coordination with google_fonts maintainers; may not be accepted; uncertainty on timeline |
| (d) Bundle fonts | Simplest for layrz_ui; eliminates the dependency | Users can no longer customize fonts; severely limits the design system's flexibility; increases package size |

### Decision

**Chose (a): Depend on google_fonts ^8.2.1, using TextStyle-returning APIs only.**

### Rationale

- Material remains in the Flutter SDK until late 2026 (Phase 3 of deprecation), so its presence in the transitive compile graph is zero-cost today.
- google_fonts is the standard solution for Google Fonts in Flutter. Re-implementing it would be a maintenance burden with no Material coupling benefit (the font loading is already decoupled from Material; the Material imports are just dead code).
- Allowing users to customize fonts at runtime via GoogleFonts.getFont(name) is important for layrz_ui's flexibility. Option (d) would remove this.
- layrz_ui's lib/ remains clean (the grep invariant passes) because we never import google_fonts with Material; google_fonts' Material imports are in google_fonts' lib/, not ours.
- Option (c) is elegant but uncertain; it is better to choose a path layrz_ui controls today.

### Consequences

- Material exists in layrz_ui consuming apps' compile graphs via google_fonts → material.dart, but **not** via layrz_ui's lib/.
- If google_fonts later couples Material more tightly (not a risk in 8.2.1 per the changelog), a follow-up decision will be needed.
- When Material is removed from the SDK in late 2026, google_fonts **must** migrate. If it adopts material_ui, layrz_ui will inherit a transitive material_ui dependency, which would violate the grep invariant. This is a recorded risk with a review trigger.

### Review Trigger

**Date to Review**: Q4 2026 or when Material is removed from core (late 2026)

- Monitor google_fonts changelog for deprecation / migration announcements
- When google_fonts migrates off Material, verify whether it:
  - Becomes design-system-free (ideal)
  - Depends on material_ui or cupertino_ui (would affect layrz_ui)
  - Removes TextStyle-returning APIs (would require layrz_ui to re-implement)
- If google_fonts depends on material_ui, open decision D5 to resolve

---

## D4: Milestone 1 Scope — Foundation Only

**Date**: 2026-08-13  
**Status**: Decided  
**Category**: Release Planning

### Context

Milestone 1 establishes the foundation of layrz_ui before any components are built. The scope can be:
1. Foundation only (tokens, theme, extensions, constants; zero components)
2. Foundation + first few components (buttons, basic inputs, maybe layouts)
3. A full vertical slice (foundation + a representative screen showing 5-10 components together)

Options differ in how much of the design system is proven and how much initial token churn affects early components.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Foundation only (chosen) | Tokens are locked in before components are built; changes to kPrimaryColor, spacing, etc. don't require reworking 10+ components; clear separation of concerns | No proof of "can we actually build components?"; consuming apps have nothing to use; longer wait for first useful components |
| (b) Foundation + first components | Proves component viability early; gives consuming apps something to use; earlier feedback on token system | Token churn affects 5-10 components; may require rework if tokens prove inadequate; more work per milestone |
| (c) Vertical slice | Maximum feedback; full proof of end-to-end design system; engaging demo | Large scope; high risk of rework; delays foundation stabilization |

### Decision

**Chose (a): Foundation only.**

### Rationale

- The theme system (LayrzTheme, LayrzThemeData, color tokens, spacing constants, breakpoints) is the bedrock of all components. If tokens are incomplete or poorly designed, every component built on top inherits that debt.
- layrz_ui is a rewrite with a new structure (module + barrel system) and new naming (Layrz* prefix). It is better to stabilize the foundation before building, so that feedback on tokens can be applied without cascading rework to 10+ components.
- Foundation-only also tests the module/barrel structure and export hygiene without component complexity.

### Consequences

- Milestone 1 is "invisible" to consuming apps — no ready-to-use components.
- Milestone 2 begins with a stable, frozen token set, allowing components to be built in parallel with lower risk of rework.
- The first batch of components (Milestone 2) can be prioritized by consuming-app feedback, knowing that tokens won't change.
- Internal documentation and examples can use the foundation to demonstrate theming and extension points without relying on specific components.

### Review Trigger

At the end of Milestone 1 (foundation release), collect feedback:
- Are the token names and values sufficient for a wide range of components?
- Were there token additions needed during Milestone 2 component development that should have been in Milestone 1?
- Did the module/barrel structure prove adequate, or are there organizational lessons?

Use this feedback to inform the token set for the 2.0 roadmap.

---

## D5: Component Naming Prefix — L* Adopted and Reverted

**Date**: 2026-08-13  
**Status**: Decided  
**Category**: Architecture / API Design

### Context

Decision D1 settled on the `Layrz*` prefix for consistency with app-level types like `LayrzApp`, `LayrzTheme`, and `LayrzThemeData`. However, on 2026-08-13, the team discussed whether to use `L*` for all layrz_ui identifiers — components, app-level classes, utilities — for maximum consistency and brevity. An `L*` prefix was briefly adopted and applied to documentation, decisions, and design examples. However, within the same day, the team reconsidered: the source code already uses `Layrz*` consistently, the codebase is stable and tested, and the cost of renaming thousands of lines of code outweighed the marginal benefit of brevity. The `L*` prefix was reverted, restoring `Layrz*` as the settled convention.

### Decision

**Settled on `Layrz*` prefix for ALL layrz_ui identifiers.** No source code rename is required — the code is already correct. D1 is reaffirmed.

The convention is:
- Components: `LayrzButton`, `LayrzTextInput`, `LayrzTable2`, etc.
- App-level classes: `LayrzApp`, `LayrzTheme`, `LayrzThemeData`, `LayrzTextTheme`, `LayrzThemeMode`
- Theme system: `LayrzColorExtensions`, `LayrzContextExtensions`, `LayrzThemeExtension<T>`, `LayrzPreviewTheme`
- Utilities: `LayrzPlatform`, `LayrzFontHandler`, `LayrzTokens`, and all token subclasses
- Suffix convention: `*Input` for all form fields (including pickers), retiring the `*Picker` suffix from layrz_theme

### Rationale

- **Stability**: The source code is already written with `Layrz*` naming and thoroughly tested. Renaming thousands of lines of code introduces risk with no design benefit.
- **Consistency achieved**: D1 already provides the key consistency — all layrz_ui identifiers use the same prefix. The `Layrz*` prefix is descriptive and clear.
- **Reduced friction**: Keeping the existing naming minimizes merge conflicts, avoids rebasing in-flight work, and reduces onboarding confusion during the rename reversal.

### Consequences

- **No source code changes required**: lib/, test/, and example/ remain unchanged. Documentation now aligns with the source code.
- **D1 stands**: D1 is not superseded; it is reaffirmed. The brief `L*` adoption was an exploration, not a lasting change.
- **Documentation fixed**: All documentation files (roadmap, milestone plans, architecture, decisions) are now rewritten to use `Layrz*`, matching the source code exactly. No pending reconciliation work.
- **Input naming confirmed**: The `*Input` suffix convention (retiring `*Picker`) is confirmed and unaffected by this reversal.

### Review Trigger

None. This decision closes the naming question permanently. Future naming discussions should reference both D1 and D5 to understand the settled convention.

---

## D6: Documentation Split — Engineering Docs in Repo, Widget Docs in Wiki

**Date**: 2026-08-13  
**Status**: Decided  
**Category**: Governance / Documentation

### Context

As layrz_ui components grow (M2–M7), the documentation directory would eventually contain 28+ widget documentation files alongside 8 engineering files (architecture, decisions, design tokens, audit, etc.). This risks poor discoverability and makes the repository documentation cluttered. The GitHub wiki is designed for this: flat page structure, fast edit/publish cycle (no PR review), and dedicated hosting.

### Decision

**Documentation is split between repository and wiki:**

- **Repository (`doc/`)** holds engineering documentation: architecture, design decisions, token specifications, dependency audit, Flutter 3.47 inventory, roadmap, and milestone plans. These 8 files are PR-reviewed and versioned with the code.
- **GitHub Wiki** (`wiki/` submodule, tracking [goldenm-software/layrz_ui.wiki.git](git@github.com:goldenm-software/layrz_ui.wiki.git)) holds user-facing documentation: 28 per-component widget pages, the input contract, and the component catalog. Wiki pages are published immediately (no PR review) and live at [github.com/goldenm-software/layrz_ui/wiki](https://github.com/goldenm-software/layrz_ui/wiki).

### Consequences

- **Repository structure**: `doc/` remains singular with 8 files: README.md, roadmap.md, milestone-1.md, architecture.md, design-tokens.md, flutter-347-audit.md, dependencies.md, decisions.md.
- **Wiki is a git submodule**: `wiki/` is a git submodule over SSH pointing to the `master` branch (the wiki's default). Submodule must be initialized with `git clone --recurse-submodules` or `git submodule update --init --recursive`.
- **Wiki is excluded from package**: `wiki/` is listed in `.pubignore`, so the submodule and its contents never ship in the published package on pub.dev.
- **CI requirement**: GitHub Actions workflows that check out the repo must use `submodules: true` in `actions/checkout` to fetch wiki pages.
- **Cross-link fragility**: Wiki pages link to repo docs via absolute GitHub URLs (e.g., `https://github.com/goldenm-software/layrz_ui/blob/main/doc/architecture.md`). If repo files move, wiki links rot. Mitigation: document this risk and establish a no-move policy for doc files, or create a redirect.
- **New widget documentation**: ALL new widget documentation GOES IN THE WIKI. The rule is stated plainly in CLAUDE.md. If you add a widget, create a wiki page; do NOT create a doc/ file.
- **Wiki page structure**: Wiki pages are flat (no subdirectories) with names like `LayrzButton.md`, `LayrzTextInput.md`, etc. The wiki homepage links to all pages.

### Rationale

- **Scalability**: The wiki is built for many pages. The repository docs stay lean and focused on architecture.
- **Ease of editing**: Wiki pages can be edited and published directly from the GitHub UI without a PR cycle. Typos and small updates can be fixed immediately.
- **Version independence**: Widget documentation doesn't need to be versioned with every code release; it's always current for the main branch.
- **Discoverability**: The wiki has better built-in navigation (sidebar, search) than a directory of markdown files.

### Review Trigger

After the first 5 widgets are documented in the wiki (M2), audit:
- Are wiki pages discoverable and well-organized?
- Are cross-links (to repo docs) still valid?
- Should the homepage have a structured guide or just a flat list?
- Is the edit/publish workflow fast enough for contributors?

Revisit date: After M2 component release.

---

## How to Add a Decision

When a significant decision is made during layrz_ui development, follow this format:

1. **Timing**: Add the decision on the date it is finalized.
2. **Header**: Use a unique ID (D5, D6, etc.), a clear title, and the date.
3. **Status**: Mark as `Decided`, `Deferred`, `In Progress`, or `Reconsidered`.
4. **Category**: One of: Architecture, API Design, Dependency Policy, Release Planning, Testing, Tooling, Governance.
5. **Content**:
   - **Context**: The situation that required a decision
   - **Options Considered**: A table or list with pros/cons
   - **Decision**: What was chosen and why
   - **Rationale**: The reasoning (sometimes a separate subsection if long)
   - **Consequences**: What changes as a result
   - **Review Trigger**: When to revisit (optional, but recommended)

6. **Example PR**: Link the PR in which the decision was documented so that decision history is tied to code history.

Keep decisions concise (300-500 words) but complete. Future maintainers should be able to understand the context and rationale without reading external documents.
