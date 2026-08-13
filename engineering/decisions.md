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

Use this feedback to inform future development and refinements to the token set.

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
- Components: `LayrzButton`, `LayrzTextInput`, `LayrzTable`, etc.
- App-level classes: `LayrzApp`, `LayrzTheme`, `LayrzThemeData`, `LayrzTextTheme`
- Theme system: `LayrzColorExtensions`, `LayrzContextExtensions`, `LayrzThemeExtension<T>`, `LayrzPreviewTheme`
- Utilities: `LayrzPlatform`, `LayrzTokenizer`, `LayrzFont`, `LayrzFontHandler`, `LayrzTokens`, and all token subclasses
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

- **Repository (`engineering/`)** holds engineering documentation: architecture, design decisions, token specifications, dependency audit, Flutter 3.47 inventory, roadmap, and milestone plans. These 8 files are PR-reviewed and versioned with the code.
- **GitHub Wiki** (`wiki/` submodule, tracking [goldenm-software/layrz_ui.wiki.git](git@github.com:goldenm-software/layrz_ui.wiki.git)) holds user-facing documentation: 28 per-component widget pages, the input contract, and the component catalog. Wiki pages are published immediately (no PR review) and live at [github.com/goldenm-software/layrz_ui/wiki](https://github.com/goldenm-software/layrz_ui/wiki).

### Consequences

- **Repository structure**: `engineering/` holds 8 files: README.md, roadmap.md, milestone-1.md, architecture.md, design-tokens.md, flutter-347-audit.md, dependencies.md, decisions.md.
- **Wiki is a git submodule**: `wiki/` is a git submodule over SSH pointing to the `master` branch (the wiki's default). Submodule must be initialized with `git clone --recurse-submodules` or `git submodule update --init --recursive`.
- **Wiki is excluded from package**: `wiki/` is listed in `.pubignore`, so the submodule and its contents never ship in the published package on pub.dev.
- **CI requirement**: GitHub Actions workflows that check out the repo must use `submodules: true` in `actions/checkout` to fetch wiki pages.
- **Cross-link fragility**: Wiki pages link to repo docs via absolute GitHub URLs (e.g., `https://github.com/goldenm-software/layrz_ui/blob/main/engineering/architecture.md`). If repo files move, wiki links rot. Mitigation: document this risk and establish a no-move policy for engineering files, or create a redirect.
- **New widget documentation**: ALL new widget documentation GOES IN THE WIKI. The rule is stated plainly in CLAUDE.md. If you add a widget, create a wiki page; do NOT create an engineering/ file.
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

## D7: Light Mode First, Dark Mode Dropped for Now

**Date**: 2026-08-13  
**Status**: Decided  
**Category**: Architecture / Feature Scope

### Context

layrz_ui currently has a dual light/dark theme architecture inherited from layrz_theme's design. The immediate scope for Milestone 1 is light mode only. The decision is whether to:
1. Keep the architecture "dark-ready" by defining tokens as semantic roles with only light values populated, leaving dark to be filled in later
2. Drop dark mode entirely, simplify the token system, and accept the cost of a dark-mode retrofit later

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Dark-ready architecture | Framework is in place for dark mode later; tokens are semantic; easier to add dark themes incrementally | Complexity and cognitive load now; all components must assume dual palette; all tests must cover both modes; design decisions are constrained by future-dark assumptions |
| (b) Drop dark entirely (chosen) | Simplicity; focus on quality in light mode; no dual-palette burden on component design; tokens can be concrete rather than semantic | Dark mode retrofit will require revisiting every token and every component; consuming apps accustomed to layrz_theme's dark mode lose that support initially; requires a public review trigger before any stable release |

### Decision

**Chose (b): Light mode only.**

### Rationale

- Milestone 1's goal is to establish a stable foundation. Dual-palette complexity increases the risk of poor token choices early on.
- layrz_ui's stated design principle is simplicity and consistency. A single palette is simpler to reason about and test.
- All component decisions (shadows, hover states, disabled states) can assume a single light context, reducing parameter sprawl.
- Dark mode retrofit is deferred. Adding dark mode later will require revisiting every token and every component that assumed a single palette, but this cost is acceptable compared to the upfront complexity.

### Consequences

- **Dark mode infrastructure removed.** The following symbols have been deleted from the codebase:
  - `LayrzThemeData.dark()` factory
  - `LayrzThemeData.brightness` field
  - `LayrzThemeMode` enum
  - `LayrzApp.darkTheme` and `LayrzApp.themeMode` parameters
  - `context.isDark` extension getter
  - `kDarkBackgroundColor` constant
  - (Related to D12 token work) `LayrzThemeData.errorColor`, renamed to `dangerColor` as part of the new color token system
  
  **Update (2026-08-13)**: Removal is complete.
- `design-tokens.md`'s requirement that every token resolve in both light and dark is **withdrawn**. Tokens are now light-only.
- **CLAUDE.md rule #2** (test both light and dark variants) is **withdrawn** for this cycle; only light-mode tests are required.
- **CLAUDE.md rule #3** (light-and-dark preview pattern) is **withdrawn**; `WidgetPreview` examples need only a light variant.
- `LayrzPreviewTheme` (if introduced) needs only a light-mode variant.
- Dark mode is out of scope for the 1.0 release. Consuming apps can implement their own dark themes using layrz_ui's light tokens as a base, or wait for dark mode support to be added in a future release (no target version set).

### Review Trigger

**Review date**: Before any `1.0.0` stable release.

Revisit this decision if:
- Multiple consuming apps report that lack of dark mode is a blocker
- Flutter's Material Dark 3 guidance evolves in a way that impacts the retrofit plan
- The team formally decides to add dark mode support and sets a target version for its release

---

## D8: LayrzLayout Ships Exactly One Layout Design

**Date**: 2026-08-13  
**Status**: Decided  
**Category**: Architecture / API Design

### Context

`ThemedLayout` in layrz_theme supports multiple desktop and mobile presentation modes:
- **Desktop**: dual bar, sidebar, mini bar
- **Mobile**: appBar, bottomBar

LayrzLayout must choose whether to:
1. Port all presentations as a multi-mode design system
2. Ship a single, opinionated layout design

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Multi-mode (like layrz_theme) | Maximum flexibility; covers all use cases from layrz_theme | Massive scope blocker; every parameter list, navigator item type, and presentation variant must be finalized before any layout ship; five-way decision delays Milestone 2 |
| (b) Single layout design (chosen) | Unblocks Milestone 2 immediately; smaller scope; focused UX; design can evolve later | Consuming apps using dropped presentations cannot upgrade without a layout redesign; two open sub-questions remain (which single design, which navigator items) |

### Decision

**Chose (b): One layout design.**

### Rationale

- Multi-mode layout design is the single largest scope blocker in Milestone 2. Resolving the five-way presentation decision requires product/design input and is not on the critical path for foundation stability.
- A single, focused layout design is easier to iterate and validate. It can be ported and tested faster.
- The layout can grow to support variants in a future release once the base design is proven and deployed.
- Future design variants (sidebar, mini, appBar, bottomBar) can be ported as separate components if needed, rather than built into a monolithic multi-mode system.

### Consequences

- **All five presentations remain in scope only as future work.** ThemedLayout, ThemedLayoutStyle, ThemedMobileLayoutStyle, ThemedDualBar, ThemedSidebar, ThemedMiniBar, ThemedBottomBar, and all related navigator types are **dropped from Milestone 1**.
- **Two sub-questions remain open**: which single layout design is chosen, and which navigator item types (page, action, widget, separator, label) survive in the first version.
- **Consuming apps using multi-mode presentations cannot upgrade to layrz_ui without a layout redesign.** This is a breaking change, but acceptable for a ground-up rewrite.
- LayrzLayout's first release will be smaller in scope but faster to ship and higher in quality.

### Review Trigger

When LayrzLayout's single design is selected and scoped, revisit whether to:
- Restore some presentations (sidebar) as parallel components in a future release
- Keep the single-design philosophy and declare others out of scope
- Provide layout composition patterns for apps that need custom presentations

---

## D9: Responsive Grid Drops the Sizes Enum

**Date**: 2026-08-13  
**Status**: Decided  
**Category**: Architecture / API Design

### Context

layrz_theme's `ResponsiveRow` and `ResponsiveCol` use a `Sizes` enum (col1 through col12) to specify column widths in a 12-column grid. The decision is whether to:
1. Keep the `Sizes` enum for type safety
2. Replace with a plain integer column count

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Keep Sizes enum | Compile-time safety; impossible to pass invalid column counts; autocomplete support | Boilerplate; requires naming 12 values; slightly more verbose call sites (Sizes.col6 vs. 6) |
| (b) Replace with integer (chosen) | Terser call sites (6 instead of Sizes.col6); less boilerplate; idiomatic Dart; matches CSS Grid mental model | Loss of enum's compile-time safety; invalid counts (13, 99) possible at runtime |

### Decision

**Chose (b): Plain integer column count.**

### Rationale

- Responsive layout parameters are low-risk: consumers intuitively know 1–12 are valid. Runtime assertion is sufficient safety.
- Integer column counts match CSS Grid's familiar model (grid-column: span 6) and reduce cognitive friction.
- Removing the enum simplifies the public API surface and reduces boilerplate.
- A debug assertion (`assert(cols > 0 && cols <= 12)`) catches mistakes during development without requiring enum machinery.

### Consequences

- `Sizes` enum (col1–col12) is **dropped**; `SizesExt` extension is **dropped**.
- `ResponsiveCol` now takes `int cols` instead of `Sizes size`. Example: `ResponsiveCol(cols: 6)` instead of `ResponsiveCol(size: Sizes.col6)`.
- All consuming apps using `Sizes.*` must update to integer literals.
- The debug assertion should be clear in documentation: invalid column counts will fail in debug builds.

### Review Trigger

**Before `1.0.0` release**: Verify that the debug assertion catches all practical errors and that call sites read clearly without the enum.

Consider whether `ResponsiveRow.builder` should be carried over. If yes, ensure it integrates cleanly with the integer-based `ResponsiveCol` API.

---

## D10: Reopen D2, Audit layrz_models Material Coupling

**Date**: 2026-08-13  
**Status**: Reopened  
**Category**: Dependency Policy

### Context

Decision D2 (deferred layrz_models integration on 2026-08-13) gates approximately 40 symbols: all localisation (LayrzAppLocalizations), avatars, colorblind support, and dynamic credential inputs. Today, colorblind support was **confirmed in scope** by the product team. ColorblindMode is a layrz_models type, which means D2's deferred status is now a hard blocker for a scoped feature.

The question: does layrz_models' Material coupling (19 Material imports across multiple files) include load-bearing dependencies (e.g., Material enums the types depend on), or are the imports dead code (like google_fonts)?

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Accept the coupling; defer colorblind scope | Avoids audit work; treats layrz_models as a peer with its own design constraints | Blocks confirmed-in-scope feature; splits colorblind support between releases; contradicts product commitment |
| (b) Audit layrz_models now (chosen) | Determines whether coupling is load-bearing or dead; applies D3's (google_fonts) methodology; unblocks colorblind support | Requires coordination with layrz_models maintainers; audit may reveal tight coupling, requiring a decoupling effort; timeline uncertain |

### Decision

**Chose (b): Reopen D2 and audit layrz_models.**

Apply the same audit standard used for google_fonts (D3): trace every Material import to determine whether it is load-bearing (the package's API depends on Material types) or dead (left over from refactoring, e.g., unused constants or legacy code paths). If Material usage is dead (like google_fonts), layrz_models is usable as-is. If Material usage is load-bearing, determine the cost and timeline of a decoupling effort.

### Rationale

- Colorblind support is confirmed as in-scope and high-value. Deferring it again contradicts product intent.
- D3's audit methodology (google_fonts) is proven and applicable. We have a tested framework for this decision.
- layrz_models' Material coupling is the highest-leverage open question by far: 40 symbols hinge on this.
- An audit takes days; a poor decoupling effort takes weeks. Invest in clarity now.

### Consequences

- **Audit has completed.** The audit found that layrz_models' Material coupling is dead code (like google_fonts), not load-bearing. layrz_ui can depend on layrz_models immediately.
- **Pending team ratification**: whether D2 formally closes as "depend on layrz_models as-is" has not yet been confirmed by the team. This decision documents the audit result and unblocks the following symbols pending team approval:
  - ColorblindFilter and six filter functions
  - Avatar-bound components (ThemedDynamicAvatarInput, avatar pickers)
  - Localisation (DateTimeExtension.format, HumanizeDuration, all translations)
  - Dynamic credential inputs
- The audit's favorable finding means no upstream decoupling work is required, and no separate layrz_ui_models package is needed.

### Review Trigger

**Immediate**: Team decision needed on whether to formally close D2 as "depend on layrz_models as-is" based on the audit's favorable finding. Once team confirms, colorblind support, avatar-bound components, localisation, and dynamic credential inputs can proceed.

---

## D11: Component Scope Confirmations

**Date**: 2026-08-13  
**Status**: Decided  
**Category**: Feature Scope / Release Planning

### Context

Many components (LayrzAlert, LayrzChip, LayrzSelect, LayrzButton, LayrzCalendar, etc.) have wiki pages and are listed in the GitHub Project, but have not received formal scope confirmation from the product team. This decision bundles a set of scope confirmations decided during the 2026-08-13 planning session, covering component naming, factories, parameter lists, and carry-over decisions.

### Decision

**Confirmed scoped for Milestone 2 (components):**

**Inputs & Controls:**
- `LayrzSelectItem` (port ThemedSelectItem; no parameter changes expected)
- `LayrzButton`: Six semantic factories (`.primary`, `.secondary`, `.icon`, `.fab`, `.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete`) — **NOT** `.legacyLoading()` (deliberately dropped)
- All other input widgets and controls as listed in wiki pages

**Feedback & Display:**
- `LayrzAlert`, `LayrzAlertIcon`, `LayrzAlertType`, `LayrzAlertStyle` — port ThemedAlert family with styling variants (layrz, filledTonal, filled, outlined, filledIcon)
- `LayrzChip`, `LayrzChipGroup`, `LayrzChipStyle`, `LayrzChipGroupBehavior` — port ThemedChip family with behavior modes (none, single, multi)
- `LayrzTooltip`, `LayrzTooltipPosition` — port ThemedTooltip family with position control

**Scaffolds & Views:**
- `LayrzScaffoldView`, `LayrzScaffoldCell` — port ThemedScaffoldView and cell with no scope changes expected

**Data Display:**
- `LayrzTable<T>` and supporting types — port as preferred table API (supersedes deprecated table)
- `LayrzCalendar`: **Port as LayrzCalendar, but flagged FULL REFACTOR.** (Not a straight port; architecture review required on four view modes: day, week, month, year. Dependency on `package:table_calendar` (Material-built) requires addressing.)
- `LayrzDynamicCredentialsInput` — port but **scheduled late** (depends on D2 audit outcome)

**Responsive Layout:**
- `LayrzRow` (port ResponsiveRow; 12-column grid container)
- `LayrzCol` (port ResponsiveCol; integer-based column count, debug assertion for validity)

**Accessibility:**
- All colorblind support (ColorblindFilter extension, six filter functions) — **port, confirmed in scope, gated on D2 audit**
- See D10 for D2 audit status and timing.

**Utilities & Extensions:**
- All extensions (NumToSizedBox, DateTimeExtension, HumanizeDuration, ORM helpers, page transitions, grid delegates, file utilities, state utils, i18n, styling) — port as-is
- All helper functions (useBlack, validateColor, getPrimaryColor, getAccentColor, getThemeColor, generateSwatch, generateContainerElevation, openInfoDialog, parseFileToBase64, parseFileToByteArray) — port as-is
- Platform-conditional file operations (save_file, pick_file) — port with separate native/web implementations

**Branded Assets:**
- `Layo` widget (SVG asset widget) — **port, name unchanged** (not Layrz-prefixed; it is a brand asset)
- `LayoEmotions` enum (12 emotion variants) — port as-is

### Consequences

- **No symbolic changes required** — this decision clarifies scope, not mechanics.
- `LayrzButton`'s six semantic factories are confirmed. The wiki page for LayrzButton was correct; `.legacyLoading()` is deliberately dropped.
- `LayrzCalendar` requires a **full refactor** (not a 1:1 port), with architecture review on Material dependency (package:table_calendar).
- `LayrzDynamicCredentialsInput` is confirmed in scope but implementation is **scheduled after Milestone 2 initial release**, pending D2 audit.
- Colorblind support is confirmed in scope; availability depends on D2 audit completion.
- All other components proceed with no scope changes or surprises.

### Review Trigger

After the first batch of Milestone 2 components (3-5 components) ship:
- Gather feedback on parameter lists and factory designs
- Validate that the scope confirmations matched product expectations
- Adjust subsequent components' scope if needed

---

## D12: Tokenizer Shape — Immutable Token Storage With a LayrzTokenizer Façade

**Date**: 2026-08-13  
**Status**: Decided  
**Category**: Architecture / API Design

### Context

layrz_theme shipped `LayrzTokenizer.of(context)` built from five `extension` groups (`ColorTokenizer`, `SpacerTokenizer`, `RadiusTokenizer`, `ShadowTokenizer`, `BorderTokenizer`) that read from Material's `Theme.of(context)`. The design-tokens.md specification instead argued for immutable token classes nested on `LayrzThemeData`, making tokens testable without `BuildContext`. layrz_ui needed to choose: immutable tokens only (no façade), port the `LayrzTokenizer` extensions 1:1, or provide both.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Immutable tokens only | Tokens are testable without context; no API redundancy | Call sites must use `context.theme.tokens.colors.primary` (verbose); migration from layrz_theme is harder (API surface changed) |
| (b) Port LayrzTokenizer 1:1 as context-bound extensions | Familiar API; call sites unchanged (`tokenizer.primary`) | Tokens couple to BuildContext; testing requires mocks; no centralized storage |
| (c) **Chosen**: Immutable tokens + thin façade | Tokens testable without context; `LayrzTokenizer.of(context)` preserves layrz_theme call sites; two access paths keep call sites migrating easily | Both access paths must never drift; adds API surface (requires coordination test) |

### Decision

**Chose (c): Immutable token classes as the storage on `LayrzThemeData`, with `LayrzTokenizer.of(context)` as a thin façade over them.**

The tokens are stored in `LayrzThemeData.tokens` (a `LayrzTokens` instance). `LayrzTokenizer` is a stateless wrapper that reads tokens from a theme via `LayrzTheme.of(context)` and exposes them through both group getters (`tokenizer.colors`, `tokenizer.spacingTokens`) and flat shortcuts (`tokenizer.primary`) for API compatibility.

### Rationale

- Immutable tokens become testable and overridable per theme without reaching for `BuildContext`.
- layrz_theme consuming apps can migrate incrementally: the old `LayrzTokenizer.of(context).primary` call pattern still works, easing migration friction.
- Centralizing tokens on `LayrzThemeData` is the source of truth; the façade is transparent (a simple delegation layer).
- The old `error`/`danger` alias pair was resolved by removing `error` entirely and keeping `danger` as the canonical semantic name.
- The old `context` colour getter was renamed `contextual` to avoid collision with the `BuildContext` parameter naming throughout widget code.

### Consequences

- Two access paths exist: `context.theme.tokens.colors.primary` (direct) and `LayrzTokenizer.of(context).primary` (façade). A test asserts they are always equal, preventing drift.
- The `LayrzTokenizer.of()` static method delegates to `LayrzTheme.of()`, so a missing theme raises layrz_ui's existing assertion instead of a layrz_theme-style `Exception("LayrzTokenizer context is null")`.
- All derived tokens (shadow, border, typography) are seeded from base colors and radius at the `LayrzTokens.light()` factory, ensuring consistency.
- Backward-compatibility getters on `LayrzThemeData` (e.g., `primaryColor`, `dangerColor`) delegate to `tokens`, keeping old call sites working.

### Review Trigger

After the first batch of M2 components ship and begin consuming tokens, verify that both access paths are actively earning their keep. If one access path is unused across the first 5 components, consider deprecating it to reduce API surface.

---

## D13: WidgetStateProperty Verified Available Material-Free — Re-Export, Do Not Hand-Roll

**Date**: 2026-08-13  
**Status**: Decided  
**Category**: Architecture / SDK Integration

### Context

Milestone 1 item 6 required verifying whether `WidgetStateProperty`, `WidgetStatesController`, and related state types were Material-only or available material-free from `package:flutter/widgets.dart`. The CLAUDE.md and milestone-1.md files had marked this as an "OPEN QUESTION" blocking M1 item 6. The code had previously anticipated implementing a wrapper around `WidgetStatesController` as an additional layer.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Material-only; hand-roll replacement | Forces layrz_ui to own the abstraction; no Material dependency | Duplicates SDK functionality; error-prone; maintenance burden |
| (b) Material-only; defer item 6 | Unblocks other M1 work | Delays interactive component support; blocks M2 entirely |
| (c) **Chosen**: Re-export from `package:flutter/widgets.dart` | SDK provides a design-system-agnostic implementation; zero maintenance; no hand-rolling | Requires trust in SDK stability; SDK major version change could affect availability |

### Decision

**Chose (c): Verified and re-exported from `package:flutter/widgets.dart`.**

The installed Flutter SDK (3.47.0) at `/home/mochi/develop/flutter` exports `WidgetState`, `WidgetStateProperty`, `WidgetStateMapper`, `WidgetStatePropertyAll`, `WidgetStatesController`, `WidgetStatesConstraint`, `WidgetStateMap`, `WidgetPropertyResolver`, `WidgetStateColor`, `WidgetStateTextStyle`, `WidgetStateBorderSide`, `WidgetStateMouseCursor`, and `WidgetStateOutlinedBorder` from `packages/flutter/lib/widgets.dart` (line 187). None of these types depend on Material.

`lib/state/` is a documented `show` re-export; nothing is hand-rolled. The `WidgetStatesController` *wrapper* anticipated in item 6 is **not** built because the SDK class is already design-system-agnostic and wrapping it would be dead weight.

### Verification Detail

At `/home/mochi/develop/flutter/packages/flutter/lib/widgets.dart`:
```dart
export 'src/widgets/widget_state.dart'
    show
        WidgetState,
        WidgetStateProperty,
        ...
```

The `src/widgets/widget_state.dart` module contains no Material imports. These types are SDK primitives.

### Consequences

- Item 6 shrinks: only one file (`lib/state/state.dart`) with a re-export, plus tests.
- Consumers importing `package:layrz_ui/layrz_ui.dart` automatically have access to all state types without a second import.
- M2 interactive components (buttons, inputs, etc.) can immediately use `WidgetStateProperty<Color>` and `WidgetStateColor` without any local abstraction layer.
- No wrapper class exists; the SDK types are used directly.

### Secondary Finding: PreviewThemeData API

A second verified SDK finding for M1 item 8: `package:flutter/widget_previews.dart` declares `abstract base class PreviewThemeData` (emphasis: `base class`, not interface). Therefore, `LayrzPreviewTheme extends PreviewThemeData` is the correct shape, **not** `implements`. The `@Preview(theme:)` parameter type is `PreviewTheme = PreviewThemeData Function()`, so a `static PreviewThemeData light() => ...` tear-off is valid and correct.

### Review Trigger

When Material is removed from the Flutter SDK (planned for late 2026), re-verify that these state types remain exported from `package:flutter/widgets.dart` without Material dependency.

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
