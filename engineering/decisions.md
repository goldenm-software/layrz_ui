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

**Update (2026-08-13)**

A forensic audit of `google_fonts 8.2.1` has clarified D3's original reasoning. The claim that "Material is just dead code" was imprecise and matters because it is exactly the claim someone will lean on when deciding whether to fork.

**Verified findings:**
- **28 of 35 lib/ files** import `package:flutter/material.dart`
- **The 329-line font-loading engine** (`google_fonts_base.dart`) imports Material but references **zero Material symbols** — genuinely dead code in the engine
- **The 27 generated catalogue files** (`lib/src/google_fonts_parts/part_*.dart`) are **real libraries** (203,538 lines total), not `part of` files despite their naming
- Material is **load-bearing in the catalogue only** — it supplies `TextTheme` and `ThemeData` for the **1,893 `static TextTheme()` methods**, but layrz_ui calls only the 1,893 TextStyle-returning twins, leaving the Material-coupled half entirely unreachable
- `TextStyle` itself does not require Material — it comes from `dart:ui`/`painting`, which those files already import

D3's **conclusion stands**: Material's presence is harmless to layrz_ui. The coupling is confined to unreachable API surface, and `LayrzFontHandler` makes the coupling reversible.

**Forking is disqualified:** pub.dev refuses to publish any package with a git or path dependency. Since M1 item 12 plans a version bump and publication to pub.dev is anticipated, forking would trade the transitive Material import for the inability to publish layrz_ui.

**Ranked alternatives should coupling removal become necessary:**
1. **Upstream split** (ideal): petition google_fonts to emit `TextStyle()` methods into google_fonts, and `TextTheme()` methods into google_fonts/material. Mechanical change; benefits every Material-free design system.
2. **Do nothing** (current): Material remains transitive but zero-cost at runtime. `LayrzFontHandler` is an interface; replacing google_fonts later touches one file and zero components.
3. **Write a replacement loader** (medium): Material-free loader using only `dart:ui FontLoader`, `http`, `crypto`, `path_provider` — approximately 100–200 lines behind the interface. Loses runtime font discovery, retains custom font flexibility.
4. **Fork** (worst): takes on maintenance, forfeits pub.dev publication, duplicates upstream burden indefinitely.

**Why no action now:** The coupling's cost is latent — zero runtime impact (Dart AOT tree-shakes unreachable `*TextTheme()` methods), and the interface makes deferral cheap. Material remains in the SDK until late 2026. Revisit when Material leaves core or google_fonts announces its migration plan.

### Review Trigger

**Date to Review**: Q4 2026 or when Material is removed from core (late 2026)

Watch for two specific signals in the google_fonts changelog:

1. **API split**: Does google_fonts separate its `TextTheme()` methods (Material-bound) from `TextStyle()` methods (design-system-free)? A split is option (c) from D3 — elegant and solves the coupling long-term.
2. **material_ui adoption**: When Material leaves the Flutter SDK, does google_fonts depend on `material_ui` for backward compatibility? If yes, layrz_ui inherits a transitive `material_ui` dependency, violating the grep invariant in consuming apps and escalating this to a follow-up decision (D5-style).

If neither signal appears by Q4 2026, the decision stands unchanged and review is deferred another year.

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

**Update (2026-08-13) — D7 Reaffirmed: Single-Mode Scope Locked**

A consuming product's dark-mode UI raised the concrete question whether D7 should be reopened. The team has answered definitively: **D7 stands unchanged.** layrz_ui targets a single mode — light mode only. Dark mode and high contrast mode are both out of scope.

Two points from that discussion strengthen the original decision:

1. **High contrast mode is also explicitly deferred**, on the same architectural terms as dark mode. The system targets a single palette in normal contrast; supporting dark mode and high contrast mode requires a dedicated team conversation, not scheduled for the current release cycle.

2. **The review trigger has changed.** Reopening D7 requires a **dedicated team conversation about multi-mode support** — not merely the 1.0.0 release date, not a single consuming product's feature request, and not SDK guidance shifts. The question has been raised and answered: the scope is light mode only, with full knowledge of the retrofit cost.

**Cost accepted knowingly:** Retrofitting dark or high contrast mode later will require revisiting every token and every component that assumed a single palette. This cost, already noted in the original rationale, is the correct trade-off for current simplicity.

Path forward: Consuming products needing additional modes should implement their own theme layer on top of layrz_ui's light foundation, or await the team's deliberate decision to undertake multi-mode support as a future initiative.

### Review Trigger

**Locked pending explicit team decision.** Reopening this decision requires the team to formally commit to a multi-mode support project. This decision is not automatically revisited at the 1.0.0 milestone, on individual consuming products' feature requests, or based on framework guidance shifts.

If a dedicated multi-mode initiative is formally undertaken, see the **Update (2026-08-13)** section above for the known retrofit costs.

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

**Update (2026-08-19) — D8 Questions Resolved in D37**

D8's two parked sub-questions ("which single design" and "which navigator items") have been answered and documented in D37:
- **Desktop presentation**: Sidebar (labelled, 178px, not mini or dual)
- **Mobile presentation**: Drawer (off-canvas on a top bar, not bottom bar)
- **Navigator item types**: LayrzNavigatorPage and LayrzNavigatorLabel only (Action, Widget, Separator dropped)

D37 also clarifies container-driven breakpoints (not viewport-driven) and LayrzApp's default scrollbar behaviour. See D37 for the full DESIGN-61/62 rulings and specification.

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

**Update (2026-08-16) — ResponsiveRow.builder Review Resolved**

The review trigger about `ResponsiveRow.builder` has been resolved: it was **deliberately not ported** from layrz_theme to layrz_ui. The rationale: a factory that builds children from an `itemCount` and `itemBuilder` callback duplicates the responsibility of `List.generate`, which is simpler and more idiomatic Dart. Callers use `LayrzRow(children: List.generate(...))` instead, achieving the same result with less custom machinery. This decision is documented in the Grid.md wiki page and in the Milestone 2 work item for LayrzRow/LayrzCol.

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
- `LayrzAlert`, `LayrzAlertIcon`, `LayrzAlertType`, `LayrzAlertStyle` — port ThemedAlert family with styling variants (layrz, filledIcon; D27 trim from 5 to 2)
- `LayrzChip`, `LayrzChipGroup`, `LayrzChipStyle`, `LayrzChipGroupBehavior` — port ThemedChip family with behavior modes (none, single, multi)
- `LayrzTooltip`, `LayrzTooltipPosition` — port ThemedTooltip family with position control

**Scaffolds & Views:**
- `LayrzScaffoldView`, `LayrzScaffoldCell` — port ThemedScaffoldView and cell with no scope changes expected

**Update (2026-08-13)**

This line is superseded. The scaffold family is not a 1:1 port of layrz_theme's two components. Instead, `ThemedScaffoldView` and `ThemedScaffoldCell` are retired entirely, and layrz_ui ships a single public component called `LayrzScaffoldShell` — an adaptive list-detail shell that internally swaps between side-pane (desktop) and bottom-sheet (mobile) presentations based on breakpoint. The view and cell concepts are folded into this single adaptive component and do not appear as separate public APIs. The full contract of `LayrzScaffoldShell` — including the programmatic-selection mechanism for deep-linking support — is not yet decided. This component answers D8's parked question about "which single layout design" the system will adopt.

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
- All helper functions (useBlack, validateColor, getPrimaryColor, getThemeColor, generateSwatch, generateContainerElevation, openInfoDialog, parseFileToBase64, parseFileToByteArray) — port as-is (note: `getAccentColor` dropped per D14)
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

## D14: Accent Colour Removed From the Design System

**Date**: 2026-08-13  
**Status**: Decided  
**Category**: Architecture / Feature Scope

### Context

layrz_ui inherited a two-colour brand model from layrz_theme — `kPrimaryColor` (#001E60 navy) and `kAccentColor` (#FF8200 orange) — surfaced as a semantic `accent` token alongside `primary`. In practice a second undifferentiated brand colour competed with the semantic status tokens (`info`, `success`, `warning`, `danger`) for the same design jobs. An "accent" colour has no defined semantic meaning, so every component author would have had to decide independently when an accent state applied versus a warning or primary state. This invites inconsistent use across the system. The decision point arose before any component consumed the accent token, making this the cheapest moment to remove it.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Keep `accent` as a semantic token | Provides a second brand colour for emphasis; familiar from layrz_theme | Undefined semantics invite inconsistent use; semantic status colours already cover emphasis with actual meaning; removes design clarity |
| (b) Keep `kAccentColor` constant, drop the token | Leaves the brand colour available to apps that need it | Invites someone to wire it back into components; creates a second colour path inconsistent with token-driven design |
| (c) **Chosen** — Remove entirely, constant included | Forces clarity: apps needing the brand orange define it themselves; tokens stay semantically clear; no unused public constant | Breaking change with no alias; apps using the accent colour must migrate manually |

### Decision

**Chose (c): Remove `accent` entirely — both the `LayrzColorTokens.accent` field and the `kAccentColor` constant.**

### Rationale

- An undefined token is worse than a missing one, because it invites inconsistent use that is expensive to unwind later once components depend on it.
- The semantic status colours (`danger`, `success`, `warning`, `info`) already provide a complete vocabulary for emphasis with actual meaning. A second undifferentiated colour adds no semantic value.
- Removing an unused public constant prevents it from being wired back in later. Leaving `kAccentColor` would create a "second brand colour" path that contradicts the token system's design principle (all design values come from tokens, never hardcoded).
- Milestone 1 is foundation-only (D4), so no component depends on the accent token. Removing it now costs nothing; removing it later (after 5+ components depend on it) would be expensive.

### Consequences

- **Breaking change.** This is consistent with D1's clean-break stance on naming and is expected for a ground-up rewrite.
- `LayrzColorTokens.light()` loses its `accent` parameter.
- `LayrzTokens.light()` loses its `accent` parameter.
- `LayrzThemeData.light()` loses its `accent` parameter.
- `LayrzTokenizer.accent` getter is removed.
- `LayrzColorTokens` now has 17 fields (primary, background, surface, surface2, surface3, fg1, fg2, fg3, fg4, danger, success, warning, info, contextual, divider, overlay, tonalOpacity) instead of 18.
- Apps migrating from layrz_theme that used the brand orange must define `kAccentColor` in their own code if needed.
- The showroom's brand category now displays only the primary colour.

### Review Trigger

If M2+ component design repeatedly reaches for a second brand colour, revisit this decision. If reintroduced, it must come with a defined semantic role (not "accent" which is meaningless) and include updated token documentation and component guidelines.

---

## D15: Interaction States Never Change Geometry

**Date**: 2026-08-13  
**Status**: Decided  
**Category**: Architecture / API Design

### Context

Interaction states (hover, press, focus, disabled) can be expressed through appearance changes or geometry changes. The showroom's hover demo animated a button's border width from 1px to 2px; because `BoxDecoration.border` insets its child by the stroke width, the element grew by one pixel per side and its content shifted under the pointer, causing perceived flicker. The user identified this as a systemic problem to prevent across all components, not a one-off bug fix. Without a documented rule, every component author in Milestones 2–7 would face the same design decision independently, inviting repeated mistakes.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Allow geometry changes per component | Maximum flexibility; some components might genuinely need visual growth | Invites flicker and reflow; accessibility irritant; inconsistent system behaviour; expensive to fix once components are built |
| (b) Standardize the geometry change amount | Consistent visual language; predictable reflow | Still causes flicker; reflow overhead per component; doesn't resolve the core accessibility problem |
| (c) **Chosen** — Prohibit geometry changes entirely | No flicker; no sibling reflow; accessibility best practice; consistent interaction behaviour across all components | Interaction feedback limited to colour and shadow; some designs may feel less tactile initially |

### Decision

**Chose (c): Interaction states must change appearance only, never geometry.**

Hover, press, focus, and disabled states may vary **colour, border colour, shadow and elevation, opacity, and cursor**. They must **not** change size, border *width*, padding, margin, or apply a scale transform.

### Rationale

- **Hit target stability**: When an element resizes under the pointer, its own hit target moves. At the boundary where the element grows, the original target position drifts out from under the cursor, the element shrinks back, and the cursor re-enters — a flicker loop familiar to users with motor impairments trying to acquire small targets.
- **Reflow cost**: Growing an element reflows all siblings in tight layouts (grids, flex containers). This is computationally expensive and visually jarring.
- **Accessibility precedent**: WCAG and mobile accessibility guidelines identify resizing elements on interaction as a documented friction point for users with fine motor control limitations.
- **Sufficiency**: `boxShadow` and colour changes deliver the same affordance (visual emphasis) without layout side effects. A heavier shadow gives tactile feedback; a colour shift signals state change. Both are non-destructive.
- **User preference**: The user stated this directly as a standing design principle, which is sufficient rationale on its own.

### Consequences

- Component authors animate **colour** (primary → pressed variant), **shadow/elevation** (static to elevated), and **opacity** (100% → 80% disabled) within the static layout bounds.
- Where a thicker border is desired in an interaction state, the stroke must exist at constant width in every state with varying colour. Example: `border: Border.all(width: 2, color: _isHovered ? hoverColor : transparentColor)` instead of toggling the width.
- `LayrzBorderTokens` supplies `stroke1`/`stroke2`/`stroke3` for *static* design-time weight choices (a button always at 2px, a field always at 1px), not for transitions between states.
- The showroom's hover demo gains a regression test asserting the rendered size is unchanged while hovered.

### Review Trigger

If a component design genuinely needs a geometry change to be usable — an expanding search bar that grows to full width, a growing text field — that is a deliberate **layout behaviour** (expanding to fill space, revealing content) rather than an interaction state. Such cases should be argued on their own terms in the component's decision, not treated as an exception to this rule. The distinction is intent: state changes provide feedback within fixed bounds; layout changes intentionally restructure the view.

**Update (2026-08-16) — Paint-Time Transforms Permitted; Hover Detection Safety Required**

D15's prohibition on geometry changes was originally absolute: nothing layout-affecting in any interaction state. However, **paint-time transforms** (Transform, AnimatedSlide, AnimatedContainer.transform) move pixels without touching the render box's layout, so no reflow occurs and no sibling shifts. This permits a controlled exception: interaction states MAY apply paint-only translations if and only if the hover detection sits outside the moved element.

**The distinction — layout-affecting vs. paint-only:**
- **Layout-affecting** (forbidden): changes to size, padding, margin, border width, or the `RenderBox.size` rect. Causes reflow and sibling shifting. Example: widening a border from 1px to 2px.
- **Paint-only** (permitted): `Transform.translate()`, `AnimatedSlide`, or `transform:` property on `AnimatedContainer`. Moves pixels without changing the widget's rect. The hit target stays fixed in layout space while the visual moves. Example: lifting a card on hover via `Transform.translate(offset: Offset(0, -elevation))`.

**Critical safety constraint — Hover detection outside the transform:**

A widget that applies a paint-time transform on hover can move out from under the pointer. If the hover detector (MouseRegion, FocusableActionDetector) is inside the transform, the hit region moves with the visual, and this sequence occurs:
1. User hovers the element → element lifts via transform
2. Element visual moves up, taking its hit target with it
3. Original pointer position is no longer over the hit target → hover exits
4. Element drops back down → hover re-enters → lifts again → loop

This is a documented precedent in this milestone: **LayrzTooltip** surfaced on top of its anchor widget, causing the anchor to lose hover as the tooltip appeared, which triggered the tooltip to hide, which re-triggered the anchor's hover, indefinitely.

**The rule:** The `MouseRegion` or `FocusableActionDetector` detecting the hover state must NOT be inside the `Transform`. The detector wraps the transform, so the hit region stays fixed in layout space while the child's pixels move.

```dart
// CORRECT: detector outside transform
MouseRegion(
  onEnter: (_) => setState(() => _hovered = true),
  onExit: (_) => setState(() => _hovered = false),
  child: Transform.translate(
    offset: _hovered ? Offset(0, -4) : Offset.zero,
    child: MyCard(),
  ),
)

// WRONG: detector inside transform (hover oscillates)
Transform.translate(
  offset: _hovered ? Offset(0, -4) : Offset.zero,
  child: MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: MyCard(),
  ),
)
```

**Testing requirements:** Components using paint-time transforms on interaction states must include:
1. A layout-neutrality test asserting the widget's `RenderBox.size` and rect are identical in all interaction states (hovered, pressed, focused, normal, disabled). Example: `expect(findRenderBox(find.byType(MyCard)).size, equals(Offset(200, 100)))` before and after hover.
2. An oscillation-safety test that hovers at the edge of the moving element and asserts no oscillation occurs (the hover state stabilizes within one frame and remains stable for 100ms+).

### Consequences

- **LayrzAlert (interactive mode)** is the first component to use paint-time transforms, lifting on hover with shadow elevation step-up.
- **LayrzCard** deliberately retains shadow-only hover for now (no lift). Whether shadow-only components should adopt paint-time lift is an open design question, not an oversight or blocker.
- **Existing components remain fully compliant** — nothing changes for components already shipped or in progress.

### Review Trigger

After LayrzAlert's interactive mode ships and accumulates user feedback, revisit whether the lift affordance should become standard for all hoverable components (cards, buttons, etc.) or remain opt-in per-component design.

---

## D16: Project Items Stay Drafts, Converted to Issues On Demand

**Date**: 2026-08-13  
**Status**: Decided  
**Category**: Governance / Process

### Context

The GitHub Project for layrz_ui currently holds 47 items — all as draft items (not real Issues). This is a deliberate design: drafts exist only in the project and have no issue numbers, labels, or PR linkage. The question is whether to maintain this draft-only approach or convert items to Issues in bulk. A bulk conversion would create dozens of open Issues before anyone begins work on them, most of which would sit untouched for months (M2–M5 components especially). The 12 Milestone 1 items already shipped have no corresponding Issues and would manufacture trail-less completions if converted now.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Convert all 47 items now | Immediate issue numbers; PRs can reference them all | 35 open Issues before work starts; no PR linkage yet; manufactured trail (shipped M1 items would be opened and closed without a PR); noisy repository |
| (b) Convert the 35 M2–M5 items now | Ready for future work | Same noise; premature issue creation; 3+ months of idle Issues before M2 begins |
| (c) **Chosen** — Convert on demand, one at a time | Linkage exactly where it earns its keep (active branch + PR); drafts remain lightweight planning artifacts; only active work gets an Issue | Drafts cannot be referenced (no issue number) until converted; board must be moved by hand for non-converted items; contributor discipline needed to remember the conversion step |
| (d) Never convert; pure planning board | Cleanest repo (no idle Issues); Project is the single source of truth | No GitHub Issue trail; PRs cannot auto-close items; board updates require manual intervention for all items |

### Decision

**Chose (c): Items stay as drafts by default. Convert to Issues individually when work begins.**

When a contributor picks up `LayrzButton` for Milestone 2:
1. Convert the `LayrzButton` draft to an Issue (GitHub Project UI button: "Convert to issue")
2. Create a branch: `feat/buttons/layrz-button`
3. Reference the Issue in the PR (`Closes #N` in the PR body)
4. Merging the PR auto-closes the Issue and updates the Project board

### Rationale

- **Just-in-time linkage**: Issues are created only when someone is actively working on that component, with an immediate branch and PR context. No idle Issues.
- **Lightweight backlog**: Drafts have no noise — no labels, no milestone (built-in field, can't be used on drafts), no linked PRs until converted. The Project remains the planning artifact.
- **Shipped work has no manufactured trail**: The 12 Milestone 1 items already completed don't spawn ghost Issues. Future M2 items remain untracked until work actually begins.
- **Repo stays clean**: Only active components have Issues. Prevents the pattern of opening 50 Issues in August for work planned in December.
- **Process is documented**: CLAUDE.md makes the conversion step explicit, reducing the chance a contributor forgets.

### Consequences

- Draft items cannot be referenced by commit or PR until converted (GitHub doesn't issue numbers for drafts).
- The board must be moved by hand for items that are not converted to Issues (if a contributor completes a component without creating an Issue, the draft must be moved manually).
- Contributors must remember the conversion step when starting work — it is not automatic. Mitigation: documented in CLAUDE.md.
- Only items being actively developed have Issues. M3–M5 components will have no Issues until work begins, which is the intended state.

**Update (2026-08-13)**

D16's "no bulk-convert" rule was refined after the decision date. The GitHub Project's all-draft state did not communicate that Milestone 1's work was complete, which the user identified as a legibility problem for the board. The refinement distinguishes two distinct cases:

1. **Work not yet started** stays as a draft and converts individually on demand, as originally decided.
2. **Work already shipped** is converted to an Issue and closed immediately, making board state reflect reality.

Specifically:
- The 12 completed M1 Foundation items (LayrzApp, LayrzTheme, LayrzThemeData, LayrzTokens, LayrzTokenizer, LayrzTextTheme, LayrzFontHandler, WidgetState re-export (lib/state), LayrzPlatform, Extensions (Color, BuildContext), Constants (colors, grid, durations, app), Example showroom) were converted from drafts to Issues **#2–#13** and closed with state reason `completed`.
- Each issue body gained a **"Delivered by"** section listing commits from `git log` that implemented it, providing a genuine audit trail rather than empty closed tickets.
- The remaining 35 items stay as drafts: the 5 open M1 items and all 30 M2–M5 component items.
- Numbering begins at #2 because **PR #1** existed prior (merged 2026-05-25, "docs: add README, LICENSE, CONTRIBUTING and finalize roadmap").

**The refined rule**: Bulk conversion of *upcoming* work remains prohibited. Conversion to Issues in bulk is only applied to work already delivered, to communicate completion and create an audit trail. Upcoming work converts on demand, individual items only, as the decision originally stated.

**Weakness and mitigation**: Issues #2–#13 were never open during the work (no PR closed them), so the commit references in each body are what make them a real record rather than decoration. This is acceptable: the "Delivered by" trail carries the genuine evidence. In future work cycles, contributors should open Issues when work begins so PRs can close them naturally.

**Update (2026-08-16) — GitHub Project Retired; D16 Superseded**

On 2026-08-16, the GitHub Project (number 9) was retired as an internal planning tool. The decision to keep items as drafts and convert on demand is now moot — the project no longer exists.

**New arrangement:**
- `engineering/milestone-N.md` Status tables are the sole authoritative progress record.
- GitHub Issues remain enabled only as the inbound bug channel (declared in `pubspec.yaml:6` as `issue_tracker`), not for internal planning.
- Notion mirrors the milestone documents with a read-only public link.

**Impact on D16**: The draft-to-issue workflow described in D16 is no longer valid. The `/start-todo-process` and `/complete-todo-process` skills (which relied on the GitHub Project workflow) are retired or rewritten to work with the milestone documents directly.

Existing issue references in commit history (#2–#13, and any references to upcoming work) remain valid because closed issues persist on GitHub. External bug reports will continue to use the GitHub Issues interface as documented in `pubspec.yaml`.

### Review Trigger

None. D16 documented a process (draft-to-issue conversion) that is no longer applicable. The GitHub Project is retired.

---

## D17: CI Enforces Six Gates — Superseded by Shared Action Integration

**Date**: 2026-08-14  
**Status**: Superseded  
**Category**: Tooling / Release Planning

### Context

CLAUDE.md rule #2 promised three CI gates: tests pass, mirror-file structure check, and coverage ratchet. Milestone 1 item 9 originally specified four checks (analyze, test, format, Material guard) but did not mention the mirror check or ratchet, creating a contradiction between the rule and the item scope. The decision resolved this in favour of the stronger set, making the promise real rather than aspirational.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Follow item 9 only (4 checks) | Simpler CI; lower burden on contributors | Breaks the promise in CLAUDE.md rule #2; no automatic test/code structure pairing; coverage can degrade silently |
| (b) **Chosen** — Implement all six gates | Fulfills CLAUDE.md rule #2 promise; test/code parity enforced automatically; coverage ratchet prevents regression | More complex CI setup; requires maintaining `tool/check_test_mirror.sh` and `tool/coverage_baseline` |

### Decision (Original)

**Chose (b): Implement all six gates.**

The intended CI gates were:

1. `flutter analyze` — catches linting violations
2. `flutter test --coverage` — runs tests and generates coverage reports
3. `dart format --set-exit-if-changed` — enforces code formatting
4. `grep` Material/Cupertino guard — enforces the no-Material invariant
5. `grep` GoogleFonts TextTheme guard — prevents Material-coupled font methods
6. `tool/check_test_mirror.sh` — verifies test-to-code parity
7. `tool/check_coverage.sh` — ratchet against `tool/coverage_baseline`

### Rationale (Original)

- **Consistency with documentation**: CLAUDE.md rule #2 is the project's testing and code quality standard. It explicitly mentions three gates; implementing them makes the documentation accurate.
- **Prevent test decay**: Without the mirror check, a contributor could add code to `lib/` without adding tests, and CI would not catch it. The manual code review process would catch it eventually, but automatic checking is lower friction.
- **Coverage ratchet over fixed percentage**: A fixed percentage (e.g., "90% coverage required") requires backfilling existing code to meet the threshold. A ratchet works from the current baseline (96–97%) and prevents new code from lowering it. Untested code naturally penalizes the system by raising the bar for all future work.
- **Mirrors the test best practice**: Many projects enforce mirror directory structures. layrz_ui's mirror rule (every `lib/` file has a `test/` counterpart) is simple and verifiable by script.

### Consequences (Original)

- Contributors must maintain test/code parity; `tool/check_test_mirror.sh` would fail if a new file lacks tests.
- The coverage ratchet would be committed to `tool/coverage_baseline` and updated when coverage improves.
- The six gates would ensure M1 code quality is locked in before M2 components are added.

---

### Update (2026-08-14) — CI Restructured; D17 Superseded

On 2026-08-14, the CI pipeline was restructured. The original D17 design has been superseded by a new approach using shared org-wide GitHub Actions and a simpler local-enforced convention.

**What changed:**

1. **Shared action replaces repo-specific scripts**: The six local gates were replaced with the shared `goldenm-software/layrz-actions/check-dart@v1` action, which runs:
   - `flutter pub get`
   - `flutter analyze`
   - `flutter test --machine --coverage`
   - Coverage reporting (90% floor, not a ratchet)
   - Material/Cupertino guard (inline `grep`)
   - GoogleFonts TextTheme guard (inline `grep`)

2. **Deleted tool scripts**: The following scripts have been removed:
   - `tool/check_test_mirror.sh` — test-mirror structure check
   - `tool/check_coverage.sh` — coverage ratchet enforcement
   - `tool/coverage_baseline` — committed baseline file

3. **Mirror structure becomes code-review convention**: The test-mirror pattern (every `lib/<module>/src/*.dart` has a corresponding `test/<module>/*_test.dart`) is **now enforced by code review**, not CI. The convention remains a hard requirement, but structural enforcement is no longer automatic.

4. **Coverage enforcement changes to a floor**: Instead of a ratchet that works from the baseline (97.21%) and never decreases, coverage now has a **90% floor** enforced by the shared action. The current coverage is 97.21%, so approximately 7 percentage points of drift are permitted before the floor is breached.

5. **dart format is local-only**: Code formatting with `dart format` is **not** a CI gate. It is a local-development concern. Contributors run `dart format -w lib/ test/` before committing.

6. **Workflow files**: Two workflows exist in `.github/workflows/`:
   - `checks.yaml` (named "CI") — lint, test, and code quality checks on every push and pull request
   - `publish.yaml` (named "Publish to pub.dev") — release and deployment workflow triggered by version tags

**Rationale for the change:**

- **Shared actions reduce maintenance burden**: Repo-specific scripts required ongoing maintenance and were duplicated across multiple projects. A shared org-wide action provides a single source of truth and reduces complexity.
- **Local format enforcement**: Formatting is better enforced locally before commit, not in CI. Developers who integrate `dart format` into their editor or pre-commit hook catch formatting issues before pushing, avoiding wasted CI runs.
- **Simpler coverage model**: A 90% floor is simpler to understand and measure than a ratchet. It provides a reasonable quality bar without requiring constant baseline updates.
- **Mirror structure by discipline**: Code review is sufficient for catching test-mirror violations. Removing the automatic check simplifies CI and forces contributors to develop the habit of maintaining structure, which is more reliable long-term than script enforcement.

**Consequences of the change:**

- **Simpler CI**: Two workflows instead of one; fewer inline checks; faster feedback cycles.
- **Cleaner repo**: No tool scripts or baseline files to maintain; less boilerplate in the repo.
- **Developer discipline**: The mirror structure requirement is now a **convention enforced by review**, not a CI gate. This relies on contributors understanding and following the pattern.
- **Coverage floor instead of ratchet**: If coverage drops below 90%, the build fails. Unlike a ratchet, it permits some drift as long as the floor is not breached. At 97.21%, there is substantial headroom.

### Review Trigger

None. D17's original decision (implement six gates) was made in good faith with the information available at that time. The restructuring on 2026-08-14 supersedes that decision based on org-wide tooling improvements and a simpler maintenance model. Future changes to CI should be decided independently on their own merits.

---

## D18: lib/preview.dart is a Deliberate Top-Level Entrypoint

**Date**: 2026-08-14  
**Status**: Decided  
**Category**: Architecture / API Design

### Context

The standard layrz_ui module structure requires every module to live under `lib/<module>/` with a barrel `<module>.dart` at the root. Milestone 1 item 8 introduces `LayrzPreviewTheme`, which lives in `lib/preview/` with a barrel `lib/preview/preview.dart`. However, CLAUDE.md rule #3 and the shipped code also expose `lib/preview.dart` at the top level, following the pattern `import 'package:layrz_ui/preview.dart';` rather than the standard `import 'package:layrz_ui/preview/preview.dart';`. This violates the module structure rule, so the decision documents the deliberate exception and the rationale.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Follow standard pattern | Consistent with rule #4; only `lib/layrz_ui.dart` re-exports | Forces consumers to use `package:layrz_ui/preview/preview.dart` (verbose); `import 'package:layrz_ui/preview.dart'` does not work |
| (b) **Chosen** — Create top-level `lib/preview.dart` | `import 'package:layrz_ui/preview.dart'` works as documented in CLAUDE.md rule #3; matches the documented consumer code pattern | Violates the one-barrel-per-module rule; adds an exception to rule #4; creates a second public entrypoint |

### Decision

**Chose (b): Create a top-level `lib/preview.dart` barrel that re-exports `LayrzPreviewTheme` from `lib/preview/src/preview_theme.dart`.**

This is a **scoped exception to rule #4** (one concern per file, barrels at module root). Only `lib/preview.dart` is permitted as a top-level barrel. All other modules follow the standard pattern.

### Rationale

- **Consumer clarity**: Widget preview examples in CLAUDE.md rule #3 show `import 'package:layrz_ui/preview.dart';` with `@Preview(theme: LayrzPreviewTheme.light)`. This import pattern is intuitive and matches the mental model of "previews are a first-class layrz_ui feature."
- **Opt-in scope**: Making previews require a separate import (vs. always importing from the root barrel) signals to consumers that preview support is opt-in. Projects using layrz_ui in production don't need `package:flutter/widget_previews.dart`; they can ignore this module entirely. The separate import means no token cost for non-preview use cases.
- **Prevents scope creep**: The root barrel `lib/layrz_ui.dart` stays focused on core functionality. Preview infrastructure is orthogonal and intentionally separated.

### Consequences

- **Exception documented**: D18 permanently records that `lib/preview.dart` is an allowed exception to rule #4. Future architects reviewing the codebase will understand the decision.
- **Consumer code matches docs**: All code examples in CLAUDE.md rule #3 work exactly as written.
- **No other top-level barrels**: No other modules may follow this pattern. If future modules need similar treatment, they must argue for an exception explicitly (following D18's precedent).
- **Module structure remains standard otherwise**: All M2–M7 components and utility modules follow the standard pattern.

**Update (2026-08-16) — D18 Superseded by D19**

When D19 (per-domain library entrypoints) was implemented, the package structure changed such that every module now has a top-level entrypoint (`lib/<module>.dart`). The preview exception that D18 documented — a top-level barrel outside the standard module structure — is no longer an exception; it is the standard. D18's documented rationale and the `lib/preview.dart` file remain unchanged, but the "exception" framing is now historical. See D19 for the current module structure.

### Review Trigger

**None — D18's decision is permanent. See D19 for current module structure.**

---

## D19: Per-Domain Library Entrypoints — Superseded

**Date**: 2026-08-15 (deferred)  
**Status**: Superseded  
**Category**: Architecture / API Design

**Superseded by**: D26 (2026-08-16) — reversed to single root barrel

### Context

layrz_ui's current structure exports every module through a single root barrel (`lib/layrz_ui.dart`), requiring consumers to write:

```dart
import 'package:layrz_ui/layrz_ui.dart';
// Then use LayrzButton, LayrzTextInput, LayrzLayout, etc.
```

The proposed restructure follows the Flutter SDK's model, where each domain is its own importable library:

```dart
import 'package:layrz_ui/buttons.dart';
import 'package:layrz_ui/inputs.dart';
import 'package:layrz_ui/layout.dart';
```

This design has stated benefits around explicit dependency intent, no accidental coupling, and smaller analysis surfaces per library. However, the restructure moves every file in the package and rewrites every import path, making it a large diff that would block #21 (LayrzButton) from review if folded into that PR. The user's decision: defer this structural work until LayrzButton is complete and merged.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Proceed with current single-barrel structure | No refactoring needed; simpler file layout; all imports stay as-is | Requires every consumer to import the full barrel; accidental coupling between unrelated domains possible; no explicit dependency intent per call site |
| (b) Restructure now, as part of #21 | Achieves the cleaner import structure immediately; ships with the first component | Balloons the #21 diff to ~5,000+ lines; makes both the component and the restructure impossible to review independently; blocks #21 indefinitely |
| (c) **Chosen** — Defer until #21 ships, then restructure in its own PR | Component and package structure are reviewed separately; each change can be reverted independently; clearer git history; lower review friction | Consumes the remainder of M2 / early M3 as dedicated restructuring work; consumes a full PR + CI cycle; requires updating all downstream imports |

### Decision

**Chose (c): Defer the per-domain library restructure until LayrzButton (#21) has landed.**

Rationale: Folding a 4,800-line component diff and a 2,000+ line package restructure into a single PR makes both impossible to review rigorously and impossible to revert independently if issues surface. The restructure earns its own issue, branch, and PR once #21 is complete. This keeps the review focused and the git history clear.

### Rationale — Clarification on Initial Intent

The user's initial framing was "to optimize what is loading" (implying tree-shaking efficiency). This reasoning **does not apply to Dart.** In Dart, the compiler tree-shakes unreachable code regardless of how it was imported — a single fat barrel costs nothing at runtime or in output size. That intuition is valid in JavaScript bundlers; it is false in Dart's AOT and JIT models.

The reasons the restructure is **still worth doing** are different and real:

- **Explicit dependency intent at each call site**: A consumer writing `import 'package:layrz_ui/buttons.dart';` makes it clear which domains they depend on, improving readability and discoverability.
- **No accidental coupling**: Removing the root barrel prevents a team from accidentally importing LayrzButton to use LayrzTextInput, coupling unrelated concerns.
- **Smaller analysis surface per library**: Fewer files per import means faster analyzer and IDE responsiveness.
- **Familiarity**: It is exactly how the Flutter SDK is structured, easing mental model transfer for consumers.

### Consequences

- **Deferred work**: A new GitHub Project item will be created (separate from M2 components) to track the restructuring as its own 1–2 week effort.
- **Timing**: Restructure begins after #21 merges and before M2 components enter code review. Estimated to land in early M2 or mid-M2.
- **File/import updates**: Every `import` in `lib/`, `test/`, `example/`, and the wiki will change. CLAUDE.md's "Project structure" section will be rewritten. The `engineering/architecture.md` file will document the new layout.
- **Root barrel fate**: Two unresolved sub-decisions:
  - **Physical layout**: Either `lib/src/<module>/` entrypoints at the top of `lib/` (Flutter SDK exact), or the minimal-movement `lib/<module>.dart` + `lib/<module>/src/`. Both yield the same consumer import `package:layrz_ui/buttons.dart`, but the file layout differs.
  - **Fate of `lib/layrz_ui.dart`**: Delete it entirely (Flutter SDK has no `flutter.dart` that exports everything), or keep it as a convenience barrel re-exporting each entrypoint for callers who want the old pattern. This is a **forward-compatibility decision** that could ease early adoption.
- **Automation burden**: The `/complete-todo-process` skill and related automation will need no changes; only the import paths in newly-generated files will differ.

**Update (2026-08-16) — D19 Implemented**

The per-domain library restructure has been completed ahead of LayrzButton's merge. The implementation chose the second physical layout option from the original decision:

- **Entrypoint location**: `lib/<module>.dart` (not `lib/src/<module>.dart`)
- **Implementation location**: `lib/src/<module>/` (implementation files under src/)
- **Consumer imports**: `import 'package:layrz_ui/buttons.dart';` (matching Flutter SDK convention)
- **Root barrel fate**: The `lib/layrz_ui.dart` barrel was deleted entirely. There is deliberately no way to import all modules at once. Consumers must write per-domain imports.

**Rationale for the choice**: Absolute imports survive refactors (D20's precondition). The root barrel deletion eliminates a footgun (accidentally importing unrelated modules). Per-domain imports force explicit dependency intent, improving code clarity.

**Consequences of the change**: Every consuming app's import statements break when migrating to this version. The breaking change is explicit and unavoidable; this is acceptable for a ground-up rewrite (consistent with D1's stance on clean breaks).

### Review Trigger

None. D19 is now complete. The per-domain library structure is the new standard for layrz_ui.

---

## D20: Cross-Module Imports Use `package:layrz_ui/` Form, Never Relative Paths

**Date**: 2026-08-15  
**Status**: Decided  
**Category**: Architecture / API Design

### Context

Within layrz_ui, files often need to import types and constants from other modules. For example, a button component in `lib/buttons/src/button.dart` may need to import color tokens from `lib/tokens/tokens.dart`. The choice is how to form this import:

- **Relative path**: `import '../../tokens/tokens.dart';` (leaves the module, climbs directory tree)
- **Absolute package path**: `import 'package:layrz_ui/tokens/tokens.dart';` (explicit module boundary cross)

This convention applies to cross-module imports in `lib/`, `test/`, and `example/lib/` alike. Same-module relative imports within `src/` subdirectories (e.g., `import 'button_style.dart';` in the same directory) are unaffected.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Relative paths (climbing `../`) | Shorter syntax; familiar from any file system navigation | Breaks silently when files move; hides module boundaries; harder to trace; difficult to refactor as a unit |
| (b) **Chosen** — Absolute `package:layrz_ui/` form | Survives refactors; explicit module boundaries; improves discoverability; matches Dart/Flutter ecosystem convention | Slightly more verbose; requires knowing the package name |

### Decision

**Chose (b): All cross-module imports within layrz_ui use the `package:layrz_ui/...` form.**

Any import containing `../` (leaving the current module) must be rewritten to use `package:layrz_ui/`. This applies to:
- Imports in `lib/<module>/src/` reaching into other modules
- Imports in `test/` reaching into `lib/`
- Imports in `example/lib/` reaching into the package

Same-module relative imports are fine:
```dart
// In lib/buttons/src/layrz_button.dart
import 'button_style.dart';  // OK — same module, same directory
```

Cross-module imports must use the absolute form:
```dart
// In lib/src/buttons/src/layrz_button.dart
import 'package:layrz_ui/src/tokens/tokens.dart';  // OK — absolute cross-module
import 'package:layrz_ui/src/constants/constants.dart';  // OK — absolute cross-module

// NOT:
import '../../tokens/tokens.dart';  // WRONG — relative, leaves module
```

Consumers in `test/` and `example/lib/` import the root barrel:
```dart
import 'package:layrz_ui/layrz_ui.dart';  // Consumers use root barrel
```

### Verification

A one-line check to find violations in `lib/`:
```bash
grep -rn "import '\.\./" lib/
```
This must return empty. If any results appear, rewrite those imports to use `package:` form.

**Note**: `test/` is deliberately excluded from this grep. Test files legitimately import test-local helpers with relative paths (e.g., `import '../helpers/pump_themed.dart';`) because the package URI space covers only `lib/`, making `package:layrz_ui/...` imports impossible for test infrastructure. This exemption applies to relative imports within `test/` that reference other `test/` files only; imports from `test/` into `lib/` must still use the `package:` form.

### Rationale

- **Refactor resilience**: When the per-domain library restructure (D19) moves every file in the package (`lib/buttons/src/` → `lib/src/buttons/`, or similar), relative imports will all break and require rewriting. Absolute `package:` imports survive the restructure with no changes — the package name stays the same regardless of internal layout.
- **Module boundary visibility**: A `package:layrz_ui/` import is an obvious signal that you are crossing a module boundary. A relative path `../../` hides the fact that you are leaving your domain. Explicit boundaries make it easier to understand dependencies at a glance and easier to spot over-coupling.
- **Discoverability**: In a large codebase, seeing `import 'package:layrz_ui/tokens/tokens.dart';` makes it clear which modules exist and what is exported. Relative paths obscure this.
- **Ecosystem alignment**: The Flutter SDK, Dart packages, and the wider Dart community all use absolute `package:` imports for cross-package and cross-library dependencies. Using the same convention reduces cognitive friction.
- **D19 enabler**: The deferred per-domain library restructure (D19) explicitly lists absolute imports as the precondition for cheap refactoring. This decision makes that refactor viable at low cost.

### Consequences

- New code and refactored code must use `package:layrz_ui/` form for all cross-module imports.
- Existing code using relative paths (`../../`) should be rewritten as code is touched. No bulk rewrite is needed unless D19's restructure is triggered (at which point all imports will be rewritten anyway).
- Code review must verify that no relative `../` imports are introduced.

**Update (2026-08-15) — Verification Corrected; Test-Local Relative Imports Exempted**

The original Verification section contained an impossible requirement: `grep -rn "import '\.\./" lib/ test/ example/lib/` as a unified check. This fails on `test/` because test files legitimately and necessarily use relative paths to import test-local helpers (`import '../helpers/pump_themed.dart';`). The package URI space (`package:layrz_ui/...`) covers only `lib/`, so test infrastructure cannot use absolute imports for test-only files.

The corrected Verification now:
- Checks only `lib/` with `grep -rn "import '\.\./" lib/` (which must be empty)
- Documents the exemption explicitly: relative imports **within `test/`** for test-local files are required and correct
- Clarifies that imports **from `test/` into `lib/`** must still use `package:layrz_ui/...` form

This amendment does not change the decision itself, only clarifies its scope. The rule applies to cross-module imports within `lib/`, and to imports from `test/` and `example/lib/` into the package — not to test-local relative imports, which have no alternative.

### Review Trigger

**Before per-domain library restructure (D19)**: Verify that no cross-module relative imports remain in `lib/`, `test/`, or `example/lib/`. This check ensures the restructure's refactoring tools can work with consistent import paths.

If code review finds a cross-module relative import, ask the author to rewrite it to `package:layrz_ui/` form before approval. This is a non-negotiable code quality gate.

---

## D21: Grid Breakpoints Are Viewport-Driven, Not Container-Driven

**Date**: 2026-08-16  
**Status**: Decided  
**Category**: Architecture / API Design

### Context

During the Milestone 2 grid implementation, a design choice emerged about how breakpoint bands are resolved. Two options existed:

1. **Container-driven** — A grid's column spans would be determined by the grid's own measured width, allowing different grids on the same screen to select different breakpoints based on their local box width.
2. **Viewport-driven** — All grids on the screen would select breakpoints based on the overall viewport width, following standard CSS Grid and Bootstrap semantics.

The first option offered more flexibility for grids in narrow containers (sidebars, cards, etc.). The second option simplified mental model and aligned with industry convention. During implementation, an escape hatch (`useScreenWidth` parameter) was added to `LayrzCol` to allow switching between modes, creating a design inconsistency: the same column span "md: 4" would mean different pixel widths depending on a hidden parameter, making "md" have multiple meanings across an application.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Container-driven breakpoints | Maximum flexibility per grid; grids in narrow containers can use narrow-screen spans | "md" means different things in different contexts; inconsistent layout behavior; escape hatch (`useScreenWidth`) complicates the mental model |
| (b) **Chosen** — Viewport-driven breakpoints only | Single source of truth; "md" always means the same thing; aligns with CSS Grid / Bootstrap; simpler mental model | Less flexible for grids in very narrow containers; narrow sidebars must divide a small width by wide-screen spans, resulting in very thin columns |
| (c) Dual-mode with deprecation | Gradual migration path | Maintenance burden of two code paths; delayed resolution of the inconsistency |

### Decision

**Chose (b): Grid breakpoints are always viewport-driven. The `useScreenWidth` escape hatch is removed.**

Breakpoints are resolved exclusively from `MediaQuery.sizeOf(context).width` (the viewport width), not from the grid's measured box width. This is the standard CSS Grid and Bootstrap behaviour.

### Rationale

- **Consistency**: "md" always means the same breakpoint band (960–1263 logical pixels) regardless of where the grid appears. This is critical for team coordination and reduces mental overhead.
- **Industry alignment**: CSS Grid, Bootstrap, Tailwind, and other responsive systems all use viewport-driven breakpoints. Following this convention makes layrz_ui familiar to developers trained on those systems.
- **Implementation simplicity**: Removing the `useScreenWidth` parameter eliminates branching logic in `LayrzCol.spanAt()` and `LayrzRow`, making the code simpler and faster.
- **Accepted consequence**: The trade-off is that grids in narrow containers (e.g., a 400px sidebar on a 1920px screen) will select the xl band and divide 400px by wide-screen spans, resulting in very narrow columns. This is the correct behaviour per CSS Grid semantics and is expected by developers trained on responsive design.

### Consequences

- **`useScreenWidth` parameter removed** from `LayrzCol` and `LayrzRow` — it no longer exists, and code attempting to use it will fail at compile time.
- **Pixel widths still respect the row's measured box** — the row's own width (not viewport width) is used for pixel arithmetic when sizing columns. This prevents overflow in narrow containers and is standard responsive grid behaviour.
- **Design guidance updated** — grid documentation must emphasize that breakpoints come from viewport width and that narrow containers will select wide-screen spans, producing thin columns by design.

### Worked Example (Consequence Illustration)

A grid in a 400px sidebar on a 1920px display:

```dart
SizedBox(
  width: 400,
  child: LayrzRow(
    children: [
      LayrzCol(xs: 12, md: 6, lg: 4, child: ...),  // Span 4 at lg band
      LayrzCol(xs: 12, md: 6, lg: 8, child: ...),  // Span 8 at lg band
    ],
  ),
)
```

**Result**:
- Viewport width = 1920 → **xl band** selected (because 1920 ≥ 1904)
- Neither column sets `xl`, so both cascade to `lg`
- Row's measured width = 400px
- Column 1 resolves to span 4; pixel width = 400 × 4/12 ≈ **133px**
- Column 2 resolves to span 8; pixel width = 400 × 8/12 ≈ **267px**

The grid selects **xl band** (the right choice for a 1920px viewport) but divides **400px** by those wide-screen spans (the right consequence for a narrow container). This is correct per CSS Grid semantics.

### Review Trigger

**Revisit if**: A consuming application reports that grids in narrow containers are unusable because columns are too thin. At that point, re-evaluate whether the design guidance was clear enough, or whether an alternative approach (e.g., a **container-relative** mode for grids within Cards, with explicit opt-in) is needed. Current decision assumes developers will adapt their span definitions for narrow containers (e.g., using larger `lg` spans if they know the grid lives in a sidebar).

---

## D22: Breakpoints Live on the Theme, Not as Constants

**Date**: 2026-08-16  
**Status**: Decided  
**Category**: Architecture / API Design

### Context

Milestone 1 established `kExtraSmallGrid`, `kSmallGrid`, `kMediumGrid`, and `kLargeGrid` constants (valued 600, 960, 1264, 1904) exported from `package:layrz_ui/constants.dart`. When Milestone 2's grid components were implemented, the question arose: should these constants remain, or should breakpoint thresholds become themeable tokens?

Options:
1. **Keep as constants** — Simple, predictable; all apps use the same breakpoints by default.
2. **Move to theme as tokens** — Apps can customize breakpoints; every consumer automatically follows the custom thresholds.
3. **Both constants and tokens** — Backward compatibility and customization, but two sources of truth.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Keep as constants only | Simple; no theme complexity; familiar pattern from layrz_theme | Inflexible; apps cannot customize breakpoints without forking layrz_ui; changes to breakpoints require a new release |
| (b) **Chosen** — Move to theme tokens; delete constants | Apps can customize via theme; design-system-agnostic; follows token pattern; single source of truth | Breaking change (constants deleted); requires apps to update imports; slightly more verbose access (`context.tokens.breakpoints` instead of constant reference) |
| (c) Both constants and tokens | Maximum compatibility | Two sources of truth; confusion about which to use; maintenance burden if they diverge |

### Decision

**Chose (b): Breakpoints are `LayrzBreakpointTokens` on the theme. The constants `kExtraSmallGrid`, `kSmallGrid`, `kMediumGrid`, `kLargeGrid` are deleted.**

Breakpoint thresholds now live in `LayrzBreakpointTokens` (a field on `LayrzTokens` on `LayrzThemeData`). Default values match the former constants (xs: 600, sm: 960, md: 1264, lg: 1904), but apps can override them when creating a custom theme:

```dart
final customTheme = LayrzThemeData.light().copyWith(
  tokens: tokens.copyWith(
    breakpoints: LayrzBreakpointTokens(
      xs: 500,    // Custom mobile threshold
      sm: 900,    // Custom tablet threshold
      md: 1200,   // Custom desktop threshold
      lg: 1800,   // Custom large-desktop threshold
    ),
  ),
);

LayrzApp(theme: customTheme, ...)
```

All grid consumers (`LayrzRow`, `LayrzCol`, responsive layouts) automatically follow the custom thresholds from the theme.

### Rationale

- **Design-system principle**: Design systems are customizable. Hardcoded constants violate this principle; tokens on the theme are the right pattern.
- **No API fragmentation**: Without customizable breakpoints, apps would need to fork layrz_ui to change responsive behaviour. With tokens, no fork is needed.
- **Consistency with other tokens**: Spacing, colors, typography, shadow, and radius are all themeable; breakpoints should be too. This completes the token story.
- **Backward compatibility through override**: Apps previously using `kExtraSmallGrid` in their own code can continue to define the constant locally; layrz_ui no longer exports it, but that is a clean breaking change (aligned with D1's stance on clean breaks).

### Consequences

- **`kExtraSmallGrid`, `kSmallGrid`, `kMediumGrid`, `kLargeGrid` are deleted** from `lib/src/constants/grid.dart` and no longer exported from `package:layrz_ui/constants.dart`.
- **`lib/src/tokens/breakpoints.dart` is new** — defines `LayrzBreakpoint` enum and `LayrzBreakpointTokens` class.
- **`LayrzTokens.breakpoints`** (a field of type `LayrzBreakpointTokens`) is the source of truth for all breakpoint thresholds.
- **`context.tokens.breakpoints.bandAt(width)`** is the method to resolve a viewport width to its breakpoint band.
- **`context.breakpoint` getter** returns the current breakpoint band based on viewport width and the theme's breakpoint tokens.
- **Grid documentation updated** to reference `LayrzBreakpointTokens` instead of deleted constants; examples show how to customize via theme.

### Migration Path for Apps

Apps previously using `kExtraSmallGrid` and friends must migrate:

**Before** (using constants):
```dart
if (width < kExtraSmallGrid) {
  // xs band
} else if (width < kSmallGrid) {
  // sm band
}
```

**After** (using tokens):
```dart
final band = context.tokens.breakpoints.bandAt(width);
if (band == LayrzBreakpoint.xs) {
  // xs band
} else if (band == LayrzBreakpoint.sm) {
  // sm band
}
```

Or use the convenience getter:
```dart
if (context.breakpoint == LayrzBreakpoint.xs) {
  // xs band layout
}
```

### Review Trigger

**Revisit if**: Multiple apps define their own breakpoint constants after this change, suggesting that the token customization path is too cumbersome or not discoverable. At that point, evaluate whether to provide a simpler customization API or add documentation with best practices for team-wide breakpoint overrides.

---

## D23: Typography Scale Collapse — Five Styles Instead of Fifteen

**Date**: 2026-08-16  
**Status**: Decided  
**Category**: Architecture / Feature Scope

### Context

`LayrzTextTheme` inherited a fifteen-style typography scale from Material 3's `TextTheme`: five families (display, headline, title, body, label) × three sizes each (large, medium, small). This required developers to choose between three near-identical sizes on every text call, inviting inconsistent choices across components. The original rationale was familiarity with Material's taxonomy to ease migration from layrz_theme. However, layrz_ui is explicitly Material-free (D7 removed dark mode, D14 removed the undefined accent colour). The typography naming was the last thing tying it to Material's structure even though the weights diverged (commit `d4f8063` set display w800, headline w700, title w500, body w300, label w100, departing from Material's uniform weights).

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Keep all fifteen styles | Familiar from layrz_theme; granular control over every text size | Forces three-way choice per call site; inconsistent use across components; Material-only taxonomy; scale has already diverged in weight, so naming was the last Material tie |
| (b) **Chosen** — Collapse to five, taking the Medium of each family | One clear choice per text role; scales with the metric (headline = 28px, body = 14px); components only use `displayMedium`, `headlineMedium`, etc., never the Large/Small variants | Apps migrating from layrz_theme need real edits (`bodyMedium` → `body`); the break is cheap now with only two components (LayrzApp and LayrzCard) consuming the scale, and would be expensive after M3–M6 |
| (c) Provide both (keep fifteen, add five shortcuts) | Backward compatibility; shortcuts for common case | Two APIs maintain parallel; drift risk if shortcuts diverge from canonical sizes; no real unification |

### Decision

**Chose (b): Collapse `LayrzTextTheme` to five styles — `display`, `headline`, `title`, `body`, `label` — taking exactly the Medium size of each family.**

The fifteen old names are **removed outright** — no deprecated aliases, since the package is 0.0.x and this is an explicit clean break, consistent with D1.

### Mapped Values

| New Name | Replaces | Size | Weight | Usage |
|----------|----------|------|--------|-------|
| `display` | `displayMedium` | 45px | 800 | Hero text, splash screens |
| `headline` | `headlineMedium` | 28px | 700 | Section headings |
| `title` | `titleMedium` | 16px | 500 | Card titles, dialog headers |
| `body` | `bodyMedium` | 14px | 300 | Paragraph text, default root |
| `label` | `labelMedium` | 12px | 100 | Button labels, form labels, badges |

### Rationale

- **Design clarity**: One text style per role removes the decision paralysis of choosing between three sizes. `headline` unambiguously means 28px/w700, not "which headline size did I use elsewhere?"
- **Align with diverged weights**: Commit `d4f8063` already set weights that depart from Material (label w100 is not Material's w500). The naming was the last Material tie. Removing it completes the decoupling.
- **Material-free branding**: layrz_ui is not Material. Dropping Material's taxonomy (even the name shape) reinforces this identity.
- **Lower migration cost now than later**: Only LayrzApp and LayrzCard consume the scale as of 2026-08-16. M2–M7 components have not shipped. Removing fifteen names before 5+ components depend on them costs a search-replace; removing it after costs careful component-by-component rework.
- **Variant access pattern**: Apps needing a `headline` variant use `copyWith(fontSize:)`, which reads as a deliberate deviation rather than one of three blessed options.

### Consequences

- **`LayrzTextTheme` fields change** — the class loses twelve fields. Consumers must rename: `displayLarge`, `displaySmall`, `headlineLarge`, `headlineSmall`, `titleLarge`, `titleSmall`, `bodyLarge`, `bodySmall`, `labelLarge`, `labelSmall` are all removed. Only `display`, `headline`, `title`, `body`, `label` remain. The old `displayMedium`, `headlineMedium`, etc. are renamed to their base form.
- **Migration for layrz_theme consumers** — any app currently using the old names must update. This is a deliberate breaking change (D1's stance applies).
- **Design docs updated** — `engineering/design-tokens.md` and `wiki/Design-Tokens.md` must reflect the five-style scale with sizes and weights.
- **No deprecated aliases** — apps will see compile-time errors immediately, forcing explicit migration. No gradual deprecation path.
- **Weight clarity** — the document of weights (w800 → display, w700 → headline, w500 → title, w300 → body, w100 → label) reinforces the semantic scale.

### Review Trigger

If a component design genuinely needs a second size in one family — e.g., a "large headline" (32px) in addition to the standard 28px — that is a signal to revisit whether five is too few. At that point, add a new style (e.g., `headlineCompact` or `headlineExpanded`) with a new weight, document it clearly, and accept that the scale is growing to meet a real need. Current decision assumes five covers the range.

---

## D24: Font Sourcing Strategy — Google Fonts vs. CDN vs. Bundled

**Date**: 2026-08-16  
**Status**: Deferred  
**Category**: Dependency Policy / Architecture

### Context

layrz_ui currently sources fonts through `LayrzGoogleFontsHandler`, which uses `google_fonts: ^8.2.1` to download font files at runtime, verify them by hash, cache them to the device filesystem, and register them via `FontLoader`. This approach is intentional, not a temporary placeholder.

On 2026-08-16, a weight-rendering bug was fixed: `LayrzFontHandler.resolveFamily()` requested fonts with no weight specified, so all text resolved to the family `OpenSans_regular` (a single w400 face), causing all weights to paint as regular weight. The fix added `LayrzFontHandler.resolveFamilyForWeight(font, weight)` with a default implementation delegating to `resolveFamily`, preserving backward compatibility.

This resolution revealed the mechanic: `google_fonts` registers one Flutter font family **per variant** (`OpenSans_400`, `OpenSans_700`, …), so weight is selected by choosing the family name, not by the `fontWeight` property. google_fonts 8.x supplies **13 discrete Open Sans variant files** (w300, w400, w500, w600, w700, w800; no w100) and exposes no variable font.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) google_fonts (chosen for now) | Flexible runtime selection; any Google font by name; familiar pattern | Runtime network latency and caching complexity; new dependency on `path_provider` if caching is needed; conditional `path_provider` coupling complicates testing |
| (b) **Bundled fonts (enum + static assets)** | Explicit per-face weight mapping; compile-time safety; no network, no fallback flash; WASM showroom avoids cold-start fetches | ~490 KB of font assets in published package (paid by every consumer); loss of "any Google font" flexibility; per-face licensing review required; O(N) maintenance burden if faces are added later |
| (c) **Layrz CDN (runtime, custom)** | Same caching pattern as google_fonts but pointed at Layrz-controlled infrastructure | The seam for URI substitution exists (`LayrzFontSource.uri`); two implementation gaps: (1) `LayrzFont` holds a single `uri`, but one file per weight is needed; (2) caching injection point exists but adds new responsibility to the app (or revisits the no-dependency stance) |

### Decision

**Chose (a): Stay with google_fonts for now.**

The current approach is stable, tested, and works. The weight-rendering fix (adding `resolveFamilyForWeight`) closes the gap and establishes the **seam** for future font sourcing.

### Rationale

- **Minimum viable** — google_fonts works, avoids 490 KB of bundled assets, and keeps layrz_ui a thin layer atop Flutter primitives.
- **Deferred complexity** — Both (b) and (c) introduce maintenance and distribution trade-offs; neither is blocking M1–M7 component delivery.
- **Seams in place** — `LayrzFontSource.uri` + injected `fetcher` (used by `LayrzGoogleFontsHandler`) and the new `resolveFamilyForWeight` method provide the hooks needed to swap implementations later without API churn.
- **Proven pattern** — google_fonts' download-verify-cache approach is production-tested by millions of apps; re-implementing it (option c) or abandoning it (option b) has hidden costs.

### Consequences

**No change to current API.** `LayrzFontHandler` and consuming apps remain unchanged. Google Fonts remains a dependency.

**Two futures are now documented**:

1. **Future: Serve fonts from Layrz CDN** — Implement a `LayrzCdnFontsHandler` following the same pattern. Implementation gaps to close:
   - `LayrzFont` currently holds a single `uri`. For CDN hosting, one file per weight is needed. Solution: either add a weight→URI map field, or adopt a convention (e.g., `{uri}/{font-family}_w{weight}.ttf`) and compose URIs in `resolveFamilyForWeight`.
   - Caching. google_fonts uses `path_provider` for device filesystem caching. layrz_ui deliberately ships no `path_provider` dependency. Future solution: either inject a caching callback (parallel to `fetcher`), or revisit the no-dependency stance and add `path_provider` as a normal dependency.

2. **Future: Bundled fonts with enum-based safety** — Implement a `LayrzBundledFontsHandler` with a `LayrzFontFamily` enum declaring curated faces, their available weights, and which asset file backs each. Benefits: compile-time or assert-time error on missing weights (prevents the silent nearest-match failure that hid today's bug); no network; no showroom cold-start fetch penalty. Trade-offs: ~490 KB of assets in the published package (borne by all consumers whether used or not); loss of runtime flexibility; per-face licensing review (Open Sans is OFL, reauditing required if faces change). **Recommended strategy if pursued**: ship as a bundled **default** handler, keep `LayrzGoogleFontsHandler` as opt-in, and do not replace the `LayrzFontHandler` abstraction — it exists precisely to keep font sourcing pluggable.

### Review Trigger

**Revisit if**:
- A consuming app reports runtime font availability issues (missing weight, network latency on cold start, or conflicting licenses).
- The WASM showroom (web build) reports measurable performance degradation from font fetches on cold start, and bundled fonts are measured to improve the metric.
- A team decision is made to self-host fonts on Layrz infrastructure; at that point, implement the CDN handler and close the weight→URI seam.

---

## D25: GitHub Project Retired — Engineering Documentation as Single Source of Truth

**Date**: 2026-08-16  
**Status**: Decided  
**Category**: Governance / Process

### Context

The GitHub Project for layrz_ui held 47 items as draft items, requiring manual board management. Progress was tracked in **two places**: the GitHub Project (with a status field and four metadata columns) and the engineering documentation (`engineering/milestone-N.md` Status tables). Keeping both in sync required discipline in every commit message, and the synchronization was a source of friction:

1. **Board automation was unreliable.** The GitHub API does not expose which values automations write, so after merging a PR, the status field had to be verified by hand and corrected if it did not move as expected.
2. **Duplication invited drift.** The milestone documents held the real specification (work items, acceptance criteria, completion logic); the Project repeated that as metadata. Two sources of truth is no source.
3. **Previous corruption.** A concurrent draft-to-issue conversion run duplicated an item three times and attached bodies to wrong components, requiring manual cleanup.
4. **Coordination burden.** Every commit touching status required moving both the Project field and the milestone table row, doubling the editorial effort.

The question: does the GitHub Project earn its keep as an internal planning tool, or is it a redundant duplicate that adds friction?

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Keep the Project; improve automation | Board is visual; Kanban view is familiar; custom fields provide structure | Automation is unreliable by design (API limitation); drift remains unless discipline is perfect; previous corruption history suggests humans will make mistakes |
| (b) Keep the Project as a mirror, decouple updates | Visualization remains; drift is acceptable as long as the milestone docs are authoritative | Adds a new failure mode (viewers look at stale board); introduces two "truths" explicitly; Notion could do this cheaper |
| (c) **Chosen** — Retire the Project entirely; use milestone documents as the single source of truth | Eliminates duplication and synchronization burden; all status lives in one place with one update ceremony; Notion can mirror it for viewers who prefer that interface | Loses the Kanban board visualization; requires team to get comfortable with markdown-based progress tracking; contributors must reference the milestone docs instead of looking at a GUI |

### Decision

**Chose (c): Retire GitHub Project 9 entirely.**

`engineering/milestone-N.md` becomes the authoritative progress record. Each Status table records work items and their current state. When work completes, the milestone table is updated in the commit message.

GitHub Issues remain enabled and publicly declared in `pubspec.yaml:6` as the inbound bug channel (`issue_tracker`), but Issues are no longer created for internal planning.

Notion can mirror the milestone documents with a public read-only link for viewers who find markdown less accessible than a database interface.

### Rationale

- **Single source of truth**: The milestone documents already held the canonical specification. Retiring the Project makes that explicit and eliminates duplication.
- **Eliminates unreliable automation**: No more waiting for board automations to fire (or not fire). Status moves when documented, period.
- **Reduces coordination burden**: Developers move on to shipping code instead of managing two trackers. Every commit has one update point, not two.
- **Markdown is simpler**: Status tables are plain text, reviewable in diffs, mergeable without conflicts, and versionable alongside the code. A database (GitHub Project or Notion) adds a separate coordination surface.
- **Proven alternative**: Notion mirrors are read-only, so viewers get fresh data without the team managing dual updates.

### Consequences

- **GitHub Project 9 is deleted or archived.** It no longer appears in the org interface. (Archived items may remain in the UI but are not actively managed.)
- **Skills are retired or rewritten**: The `/start-todo-process` and `/complete-todo-process` skills, which relied on GitHub Project draft-to-issue conversion, are retired. (These may be replaced with scripts that update `engineering/milestone-N.md` Status tables directly, but that is a separate implementation question outside this decision.)
- **Issue references persist**: Issues #2–#13 (closed Milestone 1 items) remain valid and closed. Any future references to issue numbers in commit history (e.g., `Closes #N`) are still valid and will auto-link in GitHub.
- **External bug reports continue**: GitHub Issues remain the declared `issue_tracker` in `pubspec.yaml`, so `pub.dev` and external consumers can report bugs via GitHub Issues as usual. No change to the external interface.
- **CLAUDE.md is rewritten**: The "Progress Tracking" section is condensed to document the new arrangement. The sections on "Project Workflow: Draft-to-Issue Conversion" and "Working an item end to end" are removed, since those workflows no longer exist.
- **Notion becomes optional**: If a team member sets up a Notion mirror of the milestone documents, viewers without GitHub access can see progress. This is convenience, not authoritative.

### Review Trigger

**Revisit if**:
- A consuming app or internal stakeholder reports that markdown-based progress tracking is too opaque for their workflow, and a GUI-based tracker would improve visibility.
- The team reports that updating milestone documents in commits is too friction-heavy compared to dragging cards on a board, and automation tooling emerges to reduce the friction.
- Notion mirrors prove inadequate (stale data, poor sync), suggesting that a dedicated internal board (GitHub Project or Jira) is necessary.

**Revisit date**: Six months after the first M2 release (approximately early 2027), when the team has enough experience with the new workflow to evaluate whether it is sustainable.

---

## D26: Root Barrel Restored — Single lib/layrz_ui.dart for All Consumers

**Date**: 2026-08-16  
**Status**: Accepted  
**Category**: Architecture / API Design

### Context

Decision D19 implemented a per-domain library restructure, creating per-domain entrypoints (`lib/buttons.dart`, `lib/tokens.dart`, etc.) and deleting the root barrel `lib/layrz_ui.dart`. The rationale was that per-domain imports offered four benefits: explicit dependency intent, no accidental coupling, smaller analysis surfaces, and familiarity with Flutter SDK patterns.

A later architectural review surfaced a question about Dart's deferred imports (`import 'package:layrz_ui/buttons.dart' deferred as buttons`), which enable code splitting and lazy loading. Deferred imports work with per-domain libraries, but not with a single root barrel. However, deferred loading is only supported on two of Flutter's six platforms: web (dart2js/wasm) and, with significant setup, Android (via Flutter Deferred Components and Play Feature Delivery). iOS, macOS, Windows, and Linux do not support deferred loading; `loadLibrary()` completes immediately and the code is already in the binary. This meant the per-domain split was optimizing for a benefit that 67% of Flutter platforms cannot realize.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Keep per-domain entrypoints (D19's choice) | Deferred imports possible on web and Android; explicit dependency intent; no accidental coupling; smaller analysis surface; Flutter SDK familiarity | Benefits only 2 of 6 platforms; per-domain structure adds complexity with no runtime gain on most platforms; breaking import change required for adoption |
| (b) **Chosen** — Revert to single root barrel | Simpler consumer experience; one import path for all code; no platform-conditional benefits; breaking change costs nothing now (package is 0.0.x, no established consumers); addresses "which library to import?" confusion | Loses explicit dependency intent within single files; removes smaller-analysis-surface benefit; defers deferred loading to future (if ever needed) |
| (c) Keep both barrel and entrypoints | Maximum flexibility; backward compatibility if per-domain entrypoints are later adopted | Two sources of truth; confusion about which to use; maintenance burden if they diverge |

### Decision

**Chose (b): Restore the single root barrel at `lib/layrz_ui.dart`; delete all per-domain entrypoints.**

All 14 modules (alerts, app, buttons, cards, constants, extensions, fonts, grid, platform, state, theme, tokenizer, tokens, tooltips) are exported from the root barrel. This is the sole blessed consumer import:

```dart
import 'package:layrz_ui/layrz_ui.dart';

// Use LayrzButton, LayrzTextInput, LayrzTokens, etc. directly
```

### Rationale

- **Platform parity**: layrz_ui targets all six Flutter platforms equally. Optimizing the import structure for benefits that only two platforms can use is not a sound trade-off.
- **Simplicity for consumers**: One import path (`import 'package:layrz_ui/layrz_ui.dart';`) is simpler than deciding between 14 domain-specific paths. No accidental coupling occurs if all modules are equally visible; the risk of coupling exists regardless of import style.
- **Cost is negligible now**: The package is 0.0.x with zero established consumers. No apps depend on the per-domain import style. The breaking change is free to execute now; executing it after 3–5 components ship would be much more costly.
- **Deferred imports are deferred**: If a future initiative decides to invest in code splitting (requiring platform-conditional build logic, feature detection, and performance measurement), the importer can switch back to per-domain entrypoints or use a custom import strategy. The decision is not being made under time pressure.
- **Architecture stays sound**: Per-domain structure remains inside `lib/src/` (lib/src/buttons/buttons.dart as the per-module barrel), preserving the module-boundary clarity for maintainers. Only the consumer-facing surface changes.

### Counter-Arguments Recorded

D19's four stated benefits survive the deferral question and remain architecturally sound:
- **Explicit dependency intent**: Per-domain imports make it clear which modules an app uses. The root barrel removes this. Mitigation: code review can note imports; linters can flag unused modules.
- **No accidental coupling**: Coupling risk is real in large systems. Per-domain imports prevent it. The root barrel accepts this risk as a trade-off for simplicity.
- **Smaller analysis surface**: Importing one module instead of 14 improves analyzer and IDE responsiveness. The root barrel makes the analysis surface larger. This is accepted.
- **Flutter SDK familiarity**: The SDK structures imports per domain (`import 'package:flutter/widgets.dart'`, etc.). Following this convention eases mental model transfer. Reverting breaks that familiarity.

An additive option (keep both the root barrel and per-domain entrypoints, exporting the same symbols from each) was proposed and rejected. Maintaining two parallel APIs is a source of truth problem and adds no benefit — if per-domain imports are available, callers will use them inconsistently, creating the same coupling and clarity risks the split was meant to prevent.

### Consequences

- **Consumer imports change**: Every app consuming layrz_ui must update from per-domain imports to the root barrel. Example: `import 'package:layrz_ui/buttons.dart';` becomes `import 'package:layrz_ui/layrz_ui.dart';` This is a breaking change, acceptable for a 0.0.x package.
- **Per-domain entrypoints deleted**: `lib/buttons.dart`, `lib/tokens.dart`, etc. no longer exist. Import paths that reached them will fail at compile time.
- **lib/layrz_ui.dart is created**: The root barrel at `lib/layrz_ui.dart` exports all 14 modules in a single statement. This is the public API surface.
- **Internal structure unchanged**: `lib/src/<module>/<module>.dart` (per-module barrels) and `lib/src/<module>/src/` (implementations) remain; only the consumer-facing entry point changes.
- **Documentation updates required**: CLAUDE.md, architecture.md, and wiki examples all reference the old per-domain imports and must be rewritten.
- **D20 imports adjust**: Cross-module imports inside `lib/` use `package:layrz_ui/src/<module>/<module>.dart` form to reach other modules' barrels (unchanged in principle, paths updated in documentation).

### Review Trigger

**None.** This decision reverses D19 based on a clear platform-coverage analysis and zero-cost timing. No review trigger is needed; the reversal has been validated and is final.

---

## D27: Component Enum Trims — LayrzButtonStyle and LayrzAlertStyle

**Date**: 2026-08-17  
**Status**: Accepted  
**Category**: Feature Scope / Architecture

### Context

Two design votes (DESIGN-20 and DESIGN-22) trimmed unused style enums in core components. `LayrzButtonStyle` shipped with twelve style variants; analysis of consuming patterns showed that four styles were never used in practice or conflicted with the fill ladder principle. `LayrzAlertStyle` shipped with five styles; two were single-panel layouts that fragmented the visual language. The votes removed the unused variants to sharpen the design system's focus.

### Decision

**DESIGN-20: `LayrzButtonStyle` trimmed from 12 to 6 values.**

Removed: `filled`, `filledFab`, `filledTonal`, `filledTonalFab`, `text`, `fab`  
Remaining: `elevated`, `elevatedFab`, `outlined`, `outlinedFab`, `outlinedTonal`, `outlinedTonalFab`

The semantic button factories (`.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete`) changed signature: the `isElevated: bool` parameter is **removed** and replaced by an exposed `style: LayrzButtonStyle` parameter. All six factories default to `LayrzButtonStyle.elevated` (a deliberate uniformity, replacing the previous per-factory variation where `isElevated: false` kept `.cancel()` and `.delete()` quiet via the `filled` style). The `isFab: bool` parameter remains, and factories automatically map the given style to its Fab twin via a new `asFab` enum extension getter. Examples:
- `LayrzButton.save(labelText: 'Save', onTap: _save)` → elevated style by default
- `LayrzButton.delete(labelText: 'Delete', onTap: _delete, style: LayrzButtonStyle.outlined)` → pass style explicitly for quiet appearance when desired
- `LayrzButton.save(labelText: 'Save', onTap: _save, isFab: true)` → factory maps to `.elevatedFab` automatically

**DESIGN-22: `LayrzAlertStyle` trimmed from 5 to 2 values.**

Removed: `filledTonal`, `filled`, `outlined`  
Remaining: `layrz`, `filledIcon`

Consequence: all alerts now render in split-panel layout (the two survivors were the only split-panel options). The single-panel render path (`filledTonal`, `filled`, `outlined`) is deleted.

**Design Rule (Not Enforced in Code):**

Button labels should be concise; do not rely on `TextOverflow.ellipsis` / `maxLines: 1` to truncate long text. This is guidance for button designers and callers, not a runtime constraint. `LayrzButton` continues to render labels with `TextOverflow.ellipsis` / `maxLines: 1`.

### Rationale

- **Simplification**: Fewer style options reduce decision paralysis for consumers. The removed styles were rarely used and created redundant choices (e.g., `filled`, `filledTonal`, `filledFab`, `filledTonalFab` all occupied similar visual space).
- **Consistency**: Two surviving alert styles both use split-panel layout, unifying the visual language. Single-panel variants fragmented the design.
- **Cost-benefit**: The package is 0.0.x with minimal real-world consumers at the time of the vote (0.0.5 shipped in August 2026). Removing unused variants is low-cost now; keeping them would add long-term maintenance burden.
- **Fill ladder alignment**: The six surviving button styles map cleanly to the fill ladder principle (transparent → tonal → solid), without the complexity of managing six variants with overlapping appearances.

### Consequences

- **Breaking change**. Consuming apps using deleted styles will fail at compile time. Examples:
  - `style: LayrzButtonStyle.filled` → must rewrite to `style: LayrzButtonStyle.elevated` or `style: LayrzButtonStyle.outlined`
  - `style: LayrzAlertStyle.filledTonal` → must rewrite to `style: LayrzAlertStyle.layrz`
- **Enum extensions**:
  - New: `LayrzButtonStyle.asFab` getter maps regular styles to Fab twins
  - Removed: no extensions changed, but the six-style shape is smaller
- **Icon size constants** (LayrzAlert only):
  - Removed: `kLayrzAlertIconBoxSize`, `kLayrzAlertIconSize` (orphaned by single-panel removal)
  - Remaining: `kLayrzAlertFilledIconSize` (the one icon size for split-panel layouts)
- **Factory signatures** (LayrzButton only):
  - Old: `LayrzButton.save(labelText: 'Save', onTap: _save, isElevated: true)`; `.cancel()` and `.delete()` used `isElevated: false` for flat appearance
  - New: `LayrzButton.save(labelText: 'Save', onTap: _save, style: LayrzButtonStyle.elevated)` — all six factories use the same `elevated` default
  - Removed: `isElevated` boolean parameter (eliminated the per-factory variation)
  - Added: `style: LayrzButtonStyle` parameter with uniform `elevated` default across all six factories
  - Consequence: callers pass `style: LayrzButtonStyle.outlined` explicitly when a quiet appearance is desired for `.cancel()` or `.delete()`

### Versioning

Both trims are shipped in **0.0.6** (released 2026-08-17).

### Related Decisions

- **D15** (Interaction States Never Change Geometry) — the six surviving button styles all conform to D15's no-geometry-change rule and the fill ladder principle, making D15 enforcement simpler.
- **D11** (Component Scope Confirmations) — both button and alert were confirmed in M2 with these style enums in place; the votes refined the enum contents without changing the components' scoping or milestones.

### Review Trigger

**None.** Both votes have concluded and shipped. If consuming apps report that the surviving styles are insufficient, revisit whether additional styles (e.g., a quieter outline variant for buttons, a filled-solid variant for alerts) should be added in a future release.

---

## D28: M2 Core Primitives — Chips, Text, and Dropdown Design Finalization

**Date**: 2026-08-17  
**Status**: Decided  
**Category**: Architecture / API Design

### Context

Three M2 components shipped with design details that merit explicit documentation to prevent future confusion or regressions:

1. **Chips are visual-only**, not selection controls. The original layrz_theme `ThemedChip` and `ThemedChipGroup` supported selection modes (none, single, multi); layrz_ui removes selection entirely. This is a deliberate decoupling of visual representation from interaction state.

2. **LayrzText is a `Text` drop-in, not a scope wrapper.** It mirrors `Text`'s API exactly, including all parameters. One deliberate divergence: null `style` resolves to `tokens.typography.body` instead of inheriting from `DefaultTextStyle`. This is important to document because it surprises developers accustomed to `Text`'s inheritance behavior.

3. **LayrzDropdownMenu uses a builder-based trigger**, not a wrapped child. The menu installs no gesture handling; the trigger owns the interaction. This is non-obvious and cost significant debugging.

4. **LayrzDropdownItem is sealed**, ensuring menu items cannot be arbitrary widgets. All menus across the app have a consistent appearance by construction.

5. **LayrzChipStyle trimmed to three values**, dropping layrz_theme's `elevated` style. Continuing D27's trimming precedent.

### Decision

**Record four API design rules for M2 core primitives:**

1. **Chips are static visual labels.** No selection, no interaction states beyond the optional delete affordance. Chips represent data, not choices. Selection control belongs to an input component (M3+), not to chips themselves.

2. **LayrzText is a drop-in for `Text`.** Its API mirrors `Text` exactly. The single divergence (null `style` → `tokens.typography.body`) must be documented prominently in the API docs, CLAUDE.md, and wiki to prevent user confusion. Pass an explicit `style` to override.

3. **LayrzDropdownMenu trigger is a builder.** The menu controller is passed to the builder; the caller wires it to their trigger's own tap handler. This decouples the menu from gesture handling, avoiding gesture-arena conflicts with disabled buttons (which maintain `onTapCancel` even when disabled).

4. **LayrzDropdownItem is sealed.** Three concrete types are allowed: `LayrzDropdownEntry`, `LayrzDropdownDivider`, `LayrzDropdownLabel`. Custom widgets are impossible by design. This ensures visual consistency across all menus.

5. **LayrzChipStyle is three values**, matching the established button fill ladder: `filled` (solid), `outlined` (border only), `filledTonal` (tonal). The `elevated` style is not used by chips and is not included. Continuing D27's style-reduction precedent.

### Rationale

- **Chips as visual-only:** Separating visual representation from selection state is architecturally cleaner. It allows chips to be used purely for labeling (e.g., in lists, tags, badges) without implying selection semantics. Selection controls are inputs and belong in M3+.

- **LayrzText API parity:** Mirroring `Text`'s API exactly makes adoption frictionless. Consuming code can often swap `Text` for `LayrzText` with a single import change. The one exception (null `style` behavior) is documented to prevent bugs.

- **Builder-based trigger:** Passing the controller to a builder function allows the caller to wire interaction logic directly to their trigger widget (e.g., a button). This avoids the gesture-arena problem where a menu that wraps its trigger in a `GestureDetector` would never fire because the button already consumed the pointer event.

- **Sealed dropdown items:** A sealed class hierarchy ensures that all menus across the system use the same rendering logic and styling. No app can accidentally insert a custom widget that breaks the visual consistency.

- **Chip styles from fill ladder:** Aligning chip styles with the button fill ladder reduces cognitive load. Developers learn one ladder pattern and apply it across buttons, alerts, chips, and other components.

### Consequences

- **Chips never support selection modes** in layrz_ui. Apps needing to select from a list of labels must use an input component (e.g., `LayrzMultiSelectInput` in M3+) or implement selection at the app level.

- **`LayrzText` inherits `SelectableRegion` from `SelectableRegion`, not `Text`'s `DefaultTextStyle`** when style is null. This is documented in the widget's doc comment and CLAUDE.md but is easy to miss. Code review must verify correct documentation.

- **LayrzDropdownMenu builder pattern is mandatory.** Callers cannot pass a child and expect the menu to wrap it; they must implement the builder and wire the controller themselves.

- **Dropdown items are sealed.** Any attempt to pass a custom widget into `items:` will fail at compile time with a sealed class error, guiding developers to use the provided types.

- **LayrzChipStyle has no `.elevated` value.** Apps using the enum from layrz_theme's `ThemedChip` with `.elevated` must rewrite to `.filled` or `.outlined`.

### Related Decisions

- **D27** (Component Enum Trims) — D27 trimmed button and alert styles. D28 extends the principle to chips.
- **D15** (Interaction States Never Change Geometry) — Chips, menus, and text selections all comply with D15's no-geometry-change rule for interaction states.

### Shipping Status (Updated 2026-08-17)

**Chips and Text are shipped as of this release.** Both decisions are implemented and tested. LayrzChip and LayrzChipGroup are available in `lib/src/chips/` and exported from the root barrel. LayrzText is available in `lib/src/text/` and exported from the root barrel.

**Dropdown decisions are decided but not yet shipped.** The sealed `LayrzDropdownItem` hierarchy, builder-based trigger pattern, and no-exit-animation design are all finalized and correct. Implementation is in progress on branch `feat/navigation/dropdown-menu`, currently at 28 of 34 tests passing (Escape-to-close and outside-tap-to-close outstanding). The decisions stand unchanged and will guide completion on the follow-up branch. The gesture-arena explanation remains significant: `LayrzButton` retains a non-null `onTapCancel` even when disabled, creating a gesture recognizer that wins the arena — which is precisely why the trigger must wire itself through the controller rather than being wrapped.

### Review Trigger

**None.** These decisions document final API details of shipped (chips, text) and decided-but-not-yet-shipped (dropdown) M2 components. If consuming apps report that chips need selection support, or that the dropdown builder pattern is too verbose, consider an M4+ component that wraps `LayrzDropdownMenu` with selection semantics added, rather than reopening this decision.

---

## D29: `LayrzDropdownEntry.color` is a Plain `Color`, Not a Swatch

**Date**: 2026-08-18  
**Status**: Decided  
**Category**: API Design / Architecture

### Context

`LayrzDropdownEntry.color` was originally typed `LayrzColorSwatch?` because the pressed and hovered interaction states read `accent.shade100` for hover and `accent.shade700` for press. When the interaction states were later redesigned to use neutral opaque tokens (`surface`, `surface2`, `surface3`), those swatch shades were no longer read anywhere in the render tree — but the `LayrzColorSwatch?` type survived the change. It then propagated into DESIGN-31's `LayrzButton` → `LayrzDropdownEntry` type mapping and shipped in 0.0.7, turning what should have been a quiet cleanup into a breaking change.

### Decision

**Change `LayrzDropdownEntry.color` from `LayrzColorSwatch?` to `Color?`.**

### Rationale

**When a requirement changes, audit what became *unnecessary*, not only what *broke*.** The swatch type was justified only by the shade reads; with those reads gone, the swatch type adds no semantic value and only constrains callers. Accepting `Color?` is strictly more general.

### Consequences

- **Source-compatible for most callers**: Since `LayrzColorSwatch extends ColorSwatch<int> extends Color`, passing a token swatch (e.g., `tokens.colors.success`) still compiles because a swatch *is* a `Color`.
- **Visually identical**: Each swatch is constructed with its shade500 as its primary value, so rendering the swatch's color directly is byte-for-byte identical to the previous behavior.
- **Breaking only for code that reads the field**: Any caller code that received `entry.color` and then read `.shade100` or `.shade700` from it will fail at compile time with "the getter 'shade100' isn't defined". This is rare but possible in consuming apps.
- **Lesson for future work**: This decision is a post-mortem on technical debt. The lesson is: when an API's original constraint (the need to read shades) is removed, actively search for references to that constraint elsewhere in the codebase and the dependency graph, and remove them. Do not let the old type survive as legacy baggage.

### Related Decisions

- **D28** (M2 Core Primitives) — documents the `LayrzDropdownEntry` type and its sealed hierarchy.

---

## D30: layrz_ui Depends on layrz_sdk; Pins layrz_icons to 1.x

**Date**: 2026-08-18  
**Status**: Partially superseded by D36 (SDK dependency only; icons 1.x pin remains in force)  
**Category**: Dependency Policy

### Context

`LayrzAvatar` (M2 item 11, shipped in 0.0.8) consumes the `Avatar` model from `layrz_sdk` to render user avatars by semantic type. layrz_sdk 4.4.3 (current stable) requires `layrz_icons: ^1.1.1`. layrz_ui previously required `layrz_icons: ^2.0.0`. These version ranges are disjoint: `pub get` fails because no single version of layrz_icons satisfies both the package constraint and the transitive constraint from layrz_sdk.

### Decision

**Downgrade `layrz_icons` from `^2.0.0` to `^1.1.1` to align with layrz_sdk.**

### Rationale

All 20 `LayrzIcons.*` symbol references in layrz_ui exist identically in both 1.1.1 and 2.0.0:
- Symbol names unchanged
- Symbol values (IconData constants) unchanged
- Behavior identical

Verification: Compared symbol binaries across both versions and confirmed byte-for-byte identity for all used symbols. Both versions import only `package:flutter/widgets.dart` (Material-free). The upgrade from 1.x to 2.x was purely a file reorganization plus an SDK-floor bump; no API changes affected icons themselves.

**The tradeoff was examined and accepted deliberately.** layrz_sdk brings 18 new transitive dependencies, including:
- HTTP client: `dio`
- JSON support: `freezed_annotation`, `json_annotation`
- i18n: `layrz_i18n`
- Logging: `layrz_logging`
- WebSocket: `web_socket_channel`

`flutter_svg` adds the vector graphics chain: `vector_graphics`, `xml`, `petitparser`.

**Why binary size is not the cost**: Dart tree-shakes unreachable code; layrz_ui never calls `dio` or `web_socket_channel`, so none of that code reaches a consumer's compiled application. The cost is a few MB of `pub get` download and CI cache, and nothing at runtime.

**The real cost is version-constraint coupling.** Declared dependencies bind consumers regardless of whether the code is ever imported — which is exactly why `layrz_sdk`'s `layrz_icons ^1.1.1` forced layrz_ui backwards from `^2.0.0` despite layrz_ui never touching layrz_sdk's icon code. Every layrz_ui consumer now inherits dio's and web_socket_channel's version ranges, and release cadences are coupled: a dio major version bump forces layrz_sdk, which forces layrz_ui.

**No native or platform cost was added.** `jni`, `objective_c`, `ffi` and `path_provider` appear in the resolved graph but arrive via `google_fonts` → `path_provider`, and predate this change. `dio` and `web_socket_channel` support all six platform targets, so nothing was narrowed.

**Why the coupling was accepted — the precedent.** This coupling is consistent with the rest of the Layrz stack rather than novel: `layrz_theme`, the package layrz_ui replaces, declares **32 direct dependencies**, including `dio`, `layrz_models`, `flutter_svg`, `permission_handler`, `file_picker`, `flutter_map` and `shared_preferences`. `layrz_models` itself depends on `layrz_sdk`. layrz_ui with `layrz_sdk` and `flutter_svg` has **5 direct dependencies** — an order of magnitude leaner than its predecessor. `layrz_theme` also pins `layrz_icons: ^1.1.0`. The 1.x pin therefore **aligns** layrz_ui with the rest of the stack; layrz_ui's `^2.0.0` was the outlier, not the norm.

**The road not taken.** Dart has **no optional dependencies, features, or extras**. There is no flag that disables layrz_sdk's API half for consumers who only want models. Splitting layrz_sdk's barrel into a separate library entrypoint would **not** help either: pub resolves from pubspec declarations, not imports. Only a genuinely separate package with its own pubspec removes a constraint. The cut would be unusually clean if ever wanted: `dio` and `web_socket_channel` are each imported in exactly **one** file of layrz_sdk (`lib/src/api/api.dart`). `Avatar` reaches into that barrel only for `GqlFragment` and `GqlField`, which are pure data classes of roughly 155 lines with no networking. A models-only package covering the pure modules plus the GraphQL builders would be about **1,250 of layrz_sdk's 3,954 non-generated lines**, depending only on `freezed_annotation`, `collection` and `layrz_icons`. Only `employee` and `token` are genuinely welded to networking, via static methods calling `LayrzConnector`. Incidental finding worth keeping: layrz_sdk declares `json_annotation` but imports it in zero files.

### Consequences

- **Old consuming apps cannot upgrade beyond 0.0.7** if they require `layrz_icons: ^2.0.0` specifically. Most apps likely have looser constraints or none at all, so this is a non-issue in practice.
- **Exit condition explicitly stated**: Raise the `layrz_icons` constraint back to `^2.0.0` once `layrz_sdk` advances to `layrz_icons: ^2.0.0`. This decision is temporary and driven by external dependency management, not by a desire to stay on 1.x long-term.

### Related Decisions

- **D30 is itself a dependency adjustment.** It does not trigger a revision of D2 (layrz_models coupling) or any other decision.

---

## D31: `LayrzAvatar` is a Static Display Component

**Date**: 2026-08-18  
**Status**: Decided  
**Category**: API Design

### Context

`LayrzAvatar` was designed as a static visual component that renders a user avatar by type. The original layrz_theme `ThemedAvatar` was an interactive component with `onTap`, `onLongPress`, and `onSecondaryTap` callbacks, and supported elevation. layrz_ui's design philosophy prohibits Material imports, which blocks using Material's `InkWell` and elevation system. The decision is whether to:
1. Implement interaction and elevation from scratch (using nested gesture handlers and custom shadows)
2. Keep the component static, requiring callers to wrap it if they need interaction

### Decision

**Chose (2): `LayrzAvatar` is static display-only.** No `onTap`, `onLongPress`, `onSecondaryTap`, or elevation parameters. Callers wrap the avatar in a `GestureDetector` or similar if they need interaction.

### Rationale

- **Separation of concerns**: The avatar's job is to render an avatar image or initials. Interaction logic is orthogonal and belongs in the caller's domain.
- **Same stance as `LayrzChip`**: `LayrzChip` is visual-only per decision D28. Consistency across the system suggests that display components should not own interaction logic.
- **Fixed compact1 shadow, not configurable elevation**: Avatars carry `tokens.shadow.compact1` as a fixed drop shadow in all render modes (initials, icon, emoji, URL, base64). This is the small-component shadow ramp used by `LayrzButton`, chosen because a soft low-offset shadow disappears at 40px width; compact shadows provide clear separation even at avatar sizes. This shadow is intentionally not configurable—it is part of the avatar's baseline visual treatment, not a parameter. No elevation parameter exposed.

### Consequences

- **Callers must own interaction logic** — wrap `LayrzAvatar` in their own gesture handling if needed
- **No elevation parameter** — visual hierarchy is achieved via layout and background color choices, not elevation
- **Initials algorithm is deliberately not locale-aware** — no Unicode segmentation for combining characters or non-Latin scripts. This is an accepted limitation. A future `LayrzInitialsGenerator` component could provide locale-aware logic if needed.
- **Fallback to initials is deterministic** — given the same Avatar model, the same initials are always generated. Callers can override via the `avatarImage` parameter to provide a custom image regardless of the model type.

### Related Decisions

- **D28** (M2 Core Primitives) — establishes the pattern of static visual components with no ownership of interaction state
- **D11** (Component Scope Confirmations) — M2 item 11 (LayrzAvatar/LayrzImage) was scoped as display components per this decision

---

## D32: Filled Visual Language and Six-State Matrix for the Input Family

**Date**: 2026-08-18  
**Status**: Decided  
**Category**: Architecture / API Design

### Context

`LayrzTextInput` establishes the visual language for the entire M3+ input family. Since every other input composes `LayrzTextInput` and inherits its chrome (label, prefix/suffix, error display, help affordance, padding), the interaction state matrix must be finalized early and propagated to all downstream inputs.

### Decision

**Adopt a filled style with a six-state interaction matrix as the sole visual language for the input family.**

### Matrix

| State | Fill | Border (1.5px) | Text |
|---|---|---|---|
| Rest | `surface2` | transparent | `fg1`, hint `fg3` |
| Hover | `surface3` | transparent | `fg1` |
| Focus | `surface2` | `colors.primary` | `fg1` |
| Error | `colors.danger.shade50` | `colors.danger` | `fg1` |
| Disabled | `surface2` | transparent | `fg4` |
| Read-only | `surface2` | transparent | `fg1` + lock icon |

### Key Features

- **Focus preserves fill**: Focus only changes the border to primary; the fill stays `surface2` (does not elevate to a lighter shade).
- **Read-only is rest + lock**: Read-only uses the rest state's fill and transparent border, with a lock icon in the suffix signalling non-editability. Text remains full-contrast `fg1`.
- **Disabled darkens text to fg4**: Disabled state uses muted text (`fg4`, darkest of the fg tones) and transparent border to signal permanent non-editability.
- **All borders are solid**: All six states use solid borders. Transparency creates the invisible border effect where needed (rest, hover, disabled, read-only).
- **Single border width**: 1.5px throughout, matching `border.base` token.
- **Six-state precedence**: disabled > read-only > error > pressed > hover/focused > default.
- **Light mode only**: Dark theme is out of scope (D7).

### Rationale

- **Filled style consistency**: All inputs use filled backgrounds (never outlined or tonal-only). This creates immediate visual unity across the input family.
- **Focus-on-rest prevents elevation flicker**: Keeping focus fill identical to rest prevents a "pop-up" visual as the user navigates with Tab. Only the border signals focus.
- **Read-only as visual rest**: Read-only shares fill and transparent border with rest, making it visually calm and clearly not an error state. The lock icon is the only distinction.
- **Disabled uses text contrast only**: Disabled is visually distinct via muted text (`fg4`), reducing contrast. The lock icon (in read-only) and text colour (in disabled) are the primary signals.
- **Solid borders throughout**: All borders are solid with the same width, preserving D15's geometry invariant. Transparency (not dashing) renders invisible borders where needed.

### Consequences

- All M3+ inputs inherit this matrix
- New inputs added later must conform to this matrix
- Focus interactions no longer cause fill changes, reducing visual motion
- All states maintain byte-identical geometry; only colour and transparency vary

### Related Decisions

- **D7** (Light Mode Only) — input family defaults to light; dark mode is out of scope
- **D15** (Interaction States via Geometry Invariants) — all states preserve identical geometry; interaction states vary only colour and transparency

---

## D33: Read-Only as Rest State Plus Lock Icon

**Date**: 2026-08-18  
**Status**: Decided  
**Category**: API Design / Interaction Semantics

### Context

`LayrzTextInput` distinguishes `disabled` (not editable, not tappable) from `readOnly` (not editable, but tappable). The visual treatment for read-only must signal that the field is locked against keyboard input but remains interactive (tappable, for picker access).

### Decision

**Read-only uses the rest state's visual treatment (surface2 background, transparent border, fg1 text) plus a lock icon in the suffix.**

### Rationale

- **Read-only is calm**: Read-only shares the visual treatment with rest (not error, not disabled), making it visually serene and clearly not an error state or a permanently locked field.
- **Lock icon is the only distinction**: The lock icon in the suffix is the sole visual difference between rest and read-only, making it immediately recognizable that the field can be accessed (via tap, for pickers) but not edited (via keyboard).
- **Transparent border (not dashed)**: Read-only uses a transparent border (solid, but invisible) because it is a transient state from the user's perspective: they can tap to open a picker and change the value. All states now use transparent or coloured solid borders; dashing is not used.
- **Full-contrast text (fg1, not fg4)**: Text in read-only mode is full-contrast `fg1`, reinforcing that the field is readable and accessible, not grayed out or locked down.

### Consequences

- Callers can instantly recognize read-only fields by the lock icon in the suffix
- Read-only is visually distinct from disabled (transparent vs. transparent border, fg1 vs. fg4 text — the text colour difference is the primary signal)
- Picker inputs render as read-only and display a lock, signalling to users that the field is interactive but not editable
- All states use solid borders with constant width and radius; only colour and transparency vary

### Related Decisions

- **D32** (Input Family Visual Language) — read-only uses the rest row of the matrix plus a lock icon in the suffix
- **D15** (Interaction States via Geometry Invariants) — all states preserve geometry; only colour and transparency vary

---

## D34: Caller-Owned Errors, Joined into Single Line

**Date**: 2026-08-18  
**Status**: Decided  
**Category**: API Design

### Context

layrz_theme's `ThemedTextInput` included a `validator` callback and a separate `FieldError` component for error display, coupling validation logic with the field.

layrz_ui simplifies: callers provide error messages directly via a `List<String>`, and the field renders them as a single comma-separated line (matching layrz_theme's default `errors.join(", ")` behavior).

### Decision

**Remove the `validator` callback entirely. Callers provide a `List<String> errors` directly. `LayrzTextInput` joins multiple errors with `", "` into a single line and displays them below the field.**

### Rationale

- **Separation of concerns**: Validation is the caller's responsibility. Error display is `LayrzTextInput`'s responsibility.
- **Single-line errors are concise**: Joining with `", "` keeps error text compact and scannable (e.g., `'required, too short, no capitals'`).
- **Simpler for pickers**: Picker-style inputs have no keyboard validation; they set errors only when the dialog closes. Direct `List<String>` errors are ergonomic.
- **Matches Form patterns**: Form validation is centralized, then sets errors on each field. Direct errors are the natural fit.
- **No `FieldError` coupling**: Error rendering is integral to the field; no separate component needed.

### Consequences

- Callers own validation logic. `LayrzTextInput` does not call a validator.
- Multiple errors are joined with `", "` into a single line for display.
- Error styling on the field (danger-coloured border, light danger background) is automatic when `errors.isNotEmpty`.
- Callers hide errors with `hideDetails: true` if they want to display error messages elsewhere.

### Related Decisions

- **D32** (Input Family Visual Language) — the error state row of the matrix applies when `errors.isNotEmpty`

---

## D35: D15 Amendment — Dashed Borders for Modal States (RETRACTED)

**Date**: 2026-08-18  
**Status**: Retracted  
**Category**: Architecture / Visual Consistency

### Context

Decision D15 governs interaction state changes: they must vary only colour, border colour, shadow, opacity, and cursor — never geometry (height, width, padding, border width, radius). This prevents reflow and flicker as users interact.

`LayrzTextInput`'s `disabled` state uses a **dashed border**, while other states use solid borders. Dashing is a paint-style change (how the border is drawn), not a geometry change. But D15 does not explicitly permit paint-style changes.

### Original Decision (Retracted)

**Amend D15 to permit border paint-style changes (solid vs. dashed) for the `disabled` state only. All other states must use solid borders. Transient interaction states (hover, press, focus) must never change paint style.**

### Retraction Rationale

D35 was superseded in August 2026 when the dashed border feature for the disabled state was removed from `LayrzTextInput`. The dashed border never rendered correctly (a CustomPaint was layered beneath a solid Container, so the fill always obscured the dashes). Rather than fix the rendering, the feature was removed entirely. As a consequence, D35 defends nothing: all states now use solid borders consistently, and **D15 stands unamended**.

### Final State (per August 2026)

All six input field states (rest, hover, focus, error, disabled, read-only) use solid borders. Border width (1.5px) and radius (r10) are identical across all states; only colour changes vary (and transparency for invisible borders). D15's geometry invariant is fully satisfied without paint-style modifications.

### Related Decisions

- **D15** (Interaction States via Geometry Invariants) — stands unamended; this decision retracted
- **D32** (Input Family Visual Language) — updated matrix shows solid borders only
- **D33** (Read-Only as Rest Plus Lock Icon) — read-only uses solid transparent border

---

## D36: layrz_ui Has No Layrz Data-Model Dependencies

**Date**: 2026-08-18  
**Status**: Decided  
**Category**: Dependency Policy

### Context

D30 (2026-08-18) recorded a temporary coupling to `layrz_sdk` via `LayrzAvatar`. The Avatar model was imported directly into layrz_ui, forcing a downgrade of `layrz_icons` from `^2.0.0` to `^1.1.1` to resolve layrz_sdk's constraints. This broke the design principle that layrz_ui has **no dependencies on any Layrz data-model package** — it depends only on `google_fonts`, `layrz_icons`, and `flutter_svg`.

### Decision

**Remove `layrz_sdk` as a dependency.** Replace the `Avatar` model with a native sealed hierarchy `LayrzAvatarSource` with four concrete types: `LayrzAvatarUrl`, `LayrzAvatarBase64`, `LayrzAvatarIcon`, and `LayrzAvatarEmoji`. Each type holds its data directly (URL string, base64 string, `IconData`, emoji string), with no SDK imports. Raise `layrz_icons` back to `^2.0.0`, satisfying D30's exit condition.

### Rationale

- **layrz_ui is a design system, not a data-integration layer.** It should never know about domain models, API schemas, or authentication objects. A sealed hierarchy of plain Dart classes perfectly expresses "pick an avatar source" without coupling to layrz_sdk.
- **The sealed hierarchy enforces exhaustiveness.** When a new avatar source type is added (e.g., `LayrzAvatarGradient`), every `switch` statement on `LayrzAvatarSource` becomes a compile error at every uncovered case. This is stronger than optional parameters or string enums.
- **API boundary is cleaner.** Callers holding an SDK `Avatar` model still need avatars; now they convert at the boundary — in a consumer-facing adapter package like `layrz_ui_extensions` — rather than inside layrz_ui's core. The conversion is: `Avatar.type` → match to `LayrzAvatarSource` concrete type, extract fields, construct the sealed type.
- **Restores the design principle.** layrz_ui now has zero dependencies on `layrz_sdk`, `layrz_models`, or any other Layrz data package. It is a pure design system.

### Changes

- New file: `lib/src/images/src/avatar_source.dart` — sealed hierarchy with `@immutable`, `==`/`hashCode`, and `copyWith()` on each variant.
- `LayrzAvatar` parameter: `avatar: Avatar?` → `source: LayrzAvatarSource?`.
- `_buildFromAvatarType()` → exhaustive `switch` on `LayrzAvatarSource` variants.
- `pubspec.yaml`: Remove `layrz_sdk: ^4.4.3`. `layrz_icons` remains at `^1.1.1` (see note below).
- Tests ported to use `LayrzAvatarUrl('...')`, `LayrzAvatarBase64('...')`, etc. instead of SDK `Avatar` objects.

### Consequences

- **Breaking change for consumers passing SDK `Avatar` directly.** Migration is straightforward: callers convert SDK models at the boundary in their own adapter. This is deliberate and improves separation of concerns.
- **`layrz_icons` remains at `^1.1.1` pending layrz_sdk's upgrade.** Although layrz_ui itself no longer depends on layrz_sdk, the `layrz_ui_extensions` package must depend on both layrz_ui and layrz_sdk to provide the `Avatar` → `LayrzAvatarSource` conversion. layrz_sdk 4.4.3 (current stable) pins `layrz_icons: ^1.1.1`, which would make layrz_ui_extensions unresolvable if layrz_ui raised to `^2.0.0`. The icons constraint will be raised back to `^2.0.0` once layrz_sdk advances (decision D30's exit condition owned by layrz_sdk, not layrz_ui).

### Related Decisions

- **Supersedes D30:** That decision is now expired. Mark D30 as superseded in place (do not renumber or delete). D36 records the resolution of the temporary coupling.
- **Related to D2 (layrz_models coupling).** Like that decision, D36 establishes that layrz_ui will **never** import data-model packages. The boundary is at the application layer, not in the design system.

---

## D37: LayrzLayout and LayrzScaffoldShell Scope — Desktop Sidebar, Mobile Drawer, Flat Navigation

**Date**: 2026-08-19  
**Status**: Decided  
**Category**: Architecture / API Design

### Context

Decision D8 (LayrzLayout ships exactly one layout design) deferred the selection of which single design. On 2026-08-19, the product and design team confirmed two components and their exact scope: `LayrzLayout` (application shell) and `LayrzScaffoldShell` (list-detail shell). Both are container-driven (responsive via `LayoutBuilder` + `bandAt`, not viewport-driven). Their scope answers D8's parked questions and resolves the navigator item and interaction model.

### Decisions (DESIGN-61 and DESIGN-62)

#### DESIGN-61: LayrzLayout Scope

| Question | Ruling |
| --- | --- |
| Which desktop presentation survives | **Sidebar (labelled, 178px width).** Mini-bar (icon-only, collapsed) and dual-bar (toolbar + app-bar) are dropped |
| Which mobile presentation | **Drawer.** A collapsible 260px off-canvas drawer on a 56px top bar. No bottom-bar variant |
| Which navigator item types | **LayrzNavigatorPage** (page with icon + label + active flag) and **LayrzNavigatorLabel** (full-bleed band for section grouping) only. `Action`, `Widget`, `Separator` dropped entirely |
| User profile / settings affordances | **In scope.** User block with avatar + name, dropdown from `userMenuItems` (List<LayrzDropdownItem>) |
| Persistent vs transient item distinction | **Dropped entirely.** Single flat list; no two-tier structure |
| Notifications | **In scope.** Labelled "Notifications" footer row + `RawMenuAnchor` dropdown panel, never a route |
| Breadcrumbs and route integration | **Dropped entirely.** No automatic breadcrumb rendering, no route-to-label binding |

#### DESIGN-62: LayrzScaffoldShell Scope

| Question | Ruling |
| --- | --- |
| Generics | **Required.** `onDetailsBuild(T)` needs the item type as a generic parameter |
| List-header controls | **Search only.** No grouping, no sorting controls in the shell; consumer-owned filtering |
| Detail tabs, docked inspector, breadcrumb | **Out of scope.** Detail area is opaque to the shell; consumer owns the header |
| Filtering | **Consumer-owned via `onSearch` callback.** Shell does not filter; consumer receives search text and returns filtered list |
| Mobile bottom sheet | **Deferred.** Narrow fallback is a single-pane layout with a back affordance; no bottom-sheet modal presentation |

#### Secondary Scope

- **Breakpoints are container-driven**, resolved via `LayoutBuilder` constraints + `bandAt()`, not viewport-driven. This differs from `LayrzRow`/`LayrzCol` which remain viewport-driven.
- **LayrzApp installs LayrzScrollBehavior by default** when `scrollBehavior` is null, making scrollbars visible on all vertical scrollables (Material-free via `RawScrollbar`). This is a visible behaviour change for consuming apps that had no scrollbars before. Horizontal scrollables and touch platforms are exempt. Consumers can opt out by passing an explicit `scrollBehavior`.

### Decision

**Implement `LayrzLayout` and `LayrzScaffoldShell` as specified above.** Complete the specifications and amend D8 to record this resolution.

### Rationale

- **Single design reduces decision paralysis.** Trying to support five presentation modes (mini, sidebar, dual, appBar, bottomBar) is a critical-path blocker for Milestone 2. A single, focused design can be shipped and validated fast.
- **Container-driven breakpoints** decouple layout presentation from viewport dimensions, enabling components to adapt to their own constraints rather than global screen size. This is more reusable and testable.
- **Flat navigation is simpler.** Persistent vs. transient distinction added complexity without clear benefit. A single list, with optional visual grouping via `LayrzNavigatorLabel`, serves the same purpose.
- **User chrome via dropdown** is cleaner than dedicated UI. A `RawMenuAnchor` is Material-free and keeps the layout's top bar compact.
- **Notifications as a footer row** keeps them discoverable without competing for screen real estate with the main navigation.
- **Search-only list header** moves filtering responsibility to the consumer, where the domain knowledge lives. The shell's job is display and selection, not data semantics.

### Consequences

- **NavBar variants dropped.** Consuming apps using ThemedLayout's mini-bar, dual-bar, or bottom-bar presentations must migrate to the sidebar (desktop) or drawer (mobile) or implement their own custom layout using LayrzApp + routing.
- **Navigator item types reduced to two.** `ThemedNavigatorAction`, `ThemedNavigatorWidget`, `ThemedNavigatorSeparator` are dropped. Apps needing these must use custom UI or defer to M5+ releases if additional types are added later.
- **No automatic breadcrumbs.** Apps using route-based breadcrumbs must implement their own integration or use the detail area's consumer-owned header.
- **Mobile deep-linking and restoration.** Single-pane mobile layout does not automatically preserve detail-pane state across app suspension. Consumers must own state restoration via a `StateNotifier`, `ChangeNotifier`, or equivalent, or accept transient loss on app backgrounding.
- **Scrollbar visibility change.** Apps get scrollbars on vertical scrollables where they had none; this is intentional and part of M5's accessibility baseline. Consumers can opt out with a custom `scrollBehavior`.

### Review Trigger

After the first consuming app ships using `LayrzLayout` and `LayrzScaffoldShell`:
- Is the single layout design sufficient for the product's UX needs?
- Do any customers request the dropped presentations? If so, prioritize a future M5+ release adding optional variants.
- Is the search-only filtering contract limiting, or do most tables need custom filters anyway?

If feedback indicates a second presentation is essential, revisit in M5.x (post-release patch work).

### Amendment — DESIGN-140 (2026-08-23)

**Lifts the mobile bottom sheet deferral.** The original DESIGN-62 decision deferred the narrow-band presentation on mobile, ruling "Narrow fallback is a single-pane layout with a back affordance; no bottom-sheet modal presentation." This deferral was prudent at the time because `LayrzBottomSheet` did not exist.

`LayrzBottomSheet` now exists at `lib/src/sheets/src/bottom_sheet.dart`, and the mobile experience is refined by DESIGN-140 to use it:

- **Narrow band (sm/xs)** now presents the detail in a `LayrzBottomSheet` layered over the still-visible list (not replaced).
- **Sheet defaults**: 50% initialSize, snaps to 50% and 95%, maxSize 95%, drag handle on. No public parameters customize the sheet — it is a fixed presentation choice.
- **Selection persistence**: Selection survives a breakpoint crossing. Crossing from narrow → wide pops the sheet but keeps `openedKey`, so the detail pane shows the same item. Crossing from wide → narrow auto-opens the sheet for the already-selected item.
- **Dismissal**: Dismissing the sheet (drag-down, barrier tap, Escape, system back) calls `controller.close()`, de-highlighting the list row and returning to list-only view.
- **Navigator requirement**: The narrow band now pushes a route (`LayrzBottomSheet.show`), so the shell requires a `Navigator` ancestor (e.g. inside `LayrzApp`). A debug assert fires if missing; no release crash.

This amendment also softens the consequence stated in D37's Decision section, "Neither component pushes a Navigator route." That was true of `LayrzLayout` and of the wide band of `LayrzScaffoldShell`, but the narrow band now does push one to show the detail sheet. The amendment records this honestly rather than quietly contradicting the original statement.

---

---

## D38: Touch Press Feedback Without Hover Precedent — Lift + Elevation2

**Date**: 2026-08-19  
**Status**: Decided  
**Category**: Interaction Design / Feedback

### Context

Touch devices (phones, tablets) cannot hover, so a two-stage gesture on desktop (hover → press) collapses on touch to a single press event. Earlier design applied `elevation1` (the hover treatment) to press-without-hover on all platforms, but on touch this resulted in imperceptible feedback — the surface remained visually idle throughout the user's interaction, harming tactile feedback.

### Decision

**When a press is not preceded by hover, apply a lift transform (4dp) plus `elevation2` (one level above the hover treatment).** Desktop presses after hover remain unchanged (settle to `elevation1`). Touch, which cannot hover, always gets the lift treatment.

### Rationale

- Touch interaction is inherently gesture-based and brief — feedback must be immediate and obvious.
- Lift is a paint-only transform (not a layout change) and satisfies decision D15's invariant: only color, shadow, elevation, opacity, and cursor change during interaction states.
- `elevation2` on touch (press-no-hover) mirrors the visual weight of desktop hover, providing the missing feedback stage on touch.
- The asymmetry (desktop press settles, touch press lifts) is justified by the physical nature of the input: a mouse press follows hover, while a touch press stands alone.

### Consequences

- Touch buttons now show more dramatic feedback: lift + elevated shadow on press.
- Desktop interaction remains unchanged: hover lifts, press settles.
- All interactive components (buttons, cards, alerts) adopt this pattern consistently.
- Tests asserting the old press-only behavior must be updated to verify lift + `elevation2` when no hover precedes.

### Review Trigger

After the first month of apps using touch buttons, gather user feedback: is the lift + elevation feedback clear, or does it feel excessive? Adjust elevation level or lift distance if needed.

---

## D39: Touch Tooltips — Open on Long-Press, Close on Tap-Away

**Date**: 2026-08-19  
**Status**: Decided  
**Category**: Interaction Design / Accessibility

### Context

An earlier iteration closed tooltips on finger release, requiring the user to press and hold to read, then release to dismiss. This violated the principle of readable UI on touch: a tooltip visible only while holding is difficult to read. Additionally, closing on release conflicted with the `LayrzTooltipTrigger` enum design, which needed to distinguish pointer (hover/press) from tap triggers. A revision was needed.

### Decision

**Tooltips on touch stay open after the finger lifts and dismiss only when the user taps elsewhere.** A separate full-screen barrier `OverlayEntry` inserted below the tooltip captures tap-away events. The `LayrzTooltipTrigger` enum defaults to `.pointer` (hover/press on desktop, long-press on touch) with `.tap` for manual trigger control.

### Rationale

- Open-after-release provides readable text without requiring the user to hold.
- A tap-away barrier is cleaner than mixing release-dismiss with tap-dismiss logic.
- Tap-away is a familiar gesture on mobile: tap anything outside a menu to close it.
- Reusing the barrier mechanism for `.tap`-triggered tooltips avoids code duplication.
- The implementation eliminates ~22 test rewrites that would have been required by the earlier release-based design.

### Consequences

- Tooltips are now persistent surfaces on touch, not transient on-hold overlays.
- Users must tap to dismiss, not just release.
- The barrier entry consumes a small overlay slot and one pointer event per tap-away.
- Tooltip scroll-following (anchor moves during scroll) requires scroll position listeners to call `markNeedsBuild` on the barrier.

### Review Trigger

Monitor apps using tooltips on touch devices: are users naturally discovering the tap-to-close pattern, or do they expect hover/release behavior? Adjust messaging or gesture if needed.

---

## D40: `LayrzTooltipTrigger { pointer, tap }` Enum — Default Pointer

**Date**: 2026-08-19  
**Status**: Decided  
**Category**: API Design

### Context

The `LayrzTooltip` widget needed to distinguish between automatic triggers (hover on desktop, long-press on touch) and manual triggers (explicit tap events). A sealed enum was required to express this choice cleanly.

### Decision

**Introduce `LayrzTooltipTrigger` enum with two values: `.pointer` (default) and `.tap`.** Existing call sites remain unchanged (default to `.pointer`). `.tap` explicitly opts into tap-to-open behavior, reusing the tap-away barrier from D39.

### Rationale

- Enum provides type safety and clarity compared to a boolean `autoTrigger`.
- Default `.pointer` ensures backward compatibility; no API change for existing code.
- `.tap` is explicit, making it clear to readers that manual tap handling is required.
- The same barrier logic (D39) powers both trigger modes, reducing implementation complexity.

### Consequences

- `LayrzTooltip` constructor accepts a `trigger` parameter defaulting to `.pointer`.
- No changes to existing call sites unless `.tap` behavior is desired.
- Tests for trigger modes are isolated to the trigger enum and tooltip integration tests.

---

## D41: Field Errors Below sm Breakpoint — Tooltip Slot

**Date**: 2026-08-19  
**Status**: Decided  
**Category**: Interaction Design / Responsive Layout

### Context

On small screens (below 960px), inline error messages in text input fields consume valuable vertical space and are often invisible below the fold. A mobile-first design needed to move errors out of the inline slot and into a dismissible surface when space is constrained.

### Decision

**Below the sm breakpoint (`LayrzBreakpoint.xs` or `LayrzBreakpoint.sm`, < 960px), field errors open in a left-positioned tap tooltip, one error per line. The counter gains full width in the freed inline slot.** Breakpoint resolution is internal; no public parameter exposes this behavior.

### Rationale

- Mobile screens are narrow; tooltips reclaim vertical real estate.
- Tooltips are discoverable via visual affordance (error state + optional hint).
- Tap-to-read errors match the touch-friendly interaction model (D39).
- Reusing `LayrzTooltipTrigger { pointer, tap }` (D40) with `.tap` mode ensures consistency.
- The left-positioning rule avoids obscuring the input field itself.
- An 800px browser window (common tablet width) and most tablets in portrait receive this treatment, not just mobile-OS devices.

### Consequences

- Text input errors behave differently below 960px: tooltip instead of inline.
- Test suites must verify both presentations (inline above sm, tooltip below sm).
- Error messages are no longer always visible; users must interact to see them.
- The counter field (character count, for example) gains full width below sm.

### Review Trigger

After the first release on mobile and tablet devices, measure error discovery: do users find and read the error tooltips, or do they miss them? Adjust affordance (e.g., color, animation) if needed.

---

## D42: Layout Does Not Inset Body Slot — Surface Edge-to-Edge, Content Per-Edge

**Date**: 2026-08-19  
**Status**: Decided  
**Category**: Architecture / Layout

### Context

`LayrzLayout` and the navigation UI (rail, drawer, top bar) paint surfaces (backgrounds) that should extend edge-to-edge for visual impact. Simultaneously, page content inside the body slot should be inset to avoid the surfaces' edges. A decision was needed on where inset responsibility lies.

### Decision

**Surfaces (rail, drawer, top bar) paint edge-to-edge. Content inset is applied per-edge: the page itself owns its own SafeArea or equivalent inset.** The body slot passes content through unchanged; it does not wrap the child in an inset.

### Rationale

- Edge-to-edge surfaces maximize visual impact and work well with shadow/color transitions.
- Delegating inset to the page allows flexibility: pages can inset globally via SafeArea, or selectively inset specific children.
- The body slot is transparent about the page's layout, not a layout intermediary.
- This pattern is familiar from Bootstrap's `.container` approach: the framework provides a constrained wrapper, and the consumer owns padding.

### Consequences

- Page content inside the body slot must apply its own SafeArea or equivalent inset to avoid collision with surfaces.
- Keyboard `viewInsets` (the on-screen keyboard) are not automatically handled by the layout. Each page owns its input handling and scroll behavior.
- Tests must verify that surfaces paint edge-to-edge and that the body slot is transparent (renders the child directly).

### Review Trigger

After the first app ships using `LayrzLayout`, review padding in the body slot: are pages consistently applying SafeArea, or is manual inset tedious? If tedious, consider a future version that provides optional default inset with an escape hatch.

---

## D43: Top Bar Surface — Background Colour with No Elevation

**Date**: 2026-08-19  
**Status**: Decided  
**Category**: Design / Visual System

### Context

The mobile top bar in `LayrzLayout` (drawer presentation) was initially shadowed to distinguish it from the body. Mobile design review determined that the shadow was unnecessary and visually heavy on small screens.

### Decision

**Top bar uses `tokens.colors.background` with no shadow (elevation 0).** The user avatar, previously in the top bar, is removed and lives only in the drawer's user block. This reduces visual clutter and unifies user identity in a single location.

### Rationale

- A plain background (no shadow) is lighter and less dominant on constrained mobile screens.
- Removing the avatar from the top bar reduces visual noise and focuses attention on page content.
- The user is discoverable in the drawer's user block, which is one swipe away.
- Consistency: rail on desktop also uses a plain background without shadow.

### Consequences

- Top bar is now identical in color to the page background, visually receding.
- User identity is accessible via the drawer user block, not the top bar.
- Accessibility concern: the top bar is less distinct. Ensure the drawer trigger icon is prominent and the affordance is clear.
- Tests asserting the old shadow treatment must be updated to verify `background` color with zero elevation.

### Review Trigger

After the first release, monitor accessibility feedback: do users find the user menu and drawer trigger, or is the collapsed top bar confusing? Adjust affordance or add a visual separator if needed.

---

## D44: Mobile Drawer Presentation — Floating-Page Transition

**Date**: 2026-08-19  
**Status**: Decided  
**Category**: Design / Visual System

### Context

The mobile drawer presentation in `LayrzLayout` was implemented with two competing approaches under review:
1. **Conventional slide-over**: drawer slides in from the left over the page (Material.io pattern), with a semi-transparent scrim behind it to darken the page.
2. **Floating-page reveal**: the page shrinks, translates right, gains rounded corners and elevation, and reveals the drawer as a flat backdrop behind it (card-over-backdrop pattern).

Design review with the product team included reference material from a banking app showcasing the floating-page approach. The question was whether the drawer's visual impact justified the implementation complexity and performance implications.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Conventional slide-over + scrim (rejected) | Familiar Material.io pattern; minimal page change; drawer moves in one direction | Scrim darkens content; drawer reads as modal occlusion, not depth |
| (b) **Floating-page reveal (chosen)** | Reads as depth via layering; page elevation creates visual hierarchy; drawer recedes to backdrop; scrim unnecessary | More complex animation (scale + translate page); larger per-frame cost if animated property affects layout |
| (c) Parallax reveal (rejected) | Visually engaging; page and drawer move together | High complexity; difficult to parallax two unrelated widgets; parallax affordance unclear to users (not a standard mobile pattern) |
| (d) Staggered item entrance (rejected) | Smooth, polished feel; items animate in sequence | Complexity increases linearly with item count; does not improve drawer findability on first open; visual noise on mobile |

### Decision

**Chose (b): Floating-page reveal with scale + translate.**

When the drawer opens, the page (top bar + body content) **scales to 0.88** (anchored `Alignment.centerLeft`) and **translates right by 260 px** (the drawer width). The page gains **rounded corners (r16)** and **elevation4 shadow**. The drawer renders as a **flat, unshaded backdrop** behind the page.

The drawer does **not** have elevation or shadow; the page's shadow creates all the depth. This inverse-shadow rule is critical: it ensures the drawer reads as "behind" (non-interactive visual anchor) while the page reads as "above" (interactive, draggable, closable).

**Full-screen scrim removed.** With the drawer behind the page, a scrim can never be seen, so it is eliminated from the design and from the constants (`kLayrzLayoutDrawerScrimOpacity` was removed).

### Rationale

- **Depth hierarchy**: Scaling + translating the page while revealing the drawer creates a clear visual depth relationship. The page reads as a floating card; the drawer as the surface it floats above.
- **Feedback clarity**: Users immediately understand that the drawer is a separate layer, not an overlaid modal. The page's elevation shadow and rounded corners provide haptic-like feedback.
- **Touch affordance**: The visible page sliver (12% of the original width on the right) remains draggable, providing a clear dismissal affordance. Users can either tap the page or drag it to close the drawer.
- **No scrim needed**: Without a scrim, the visual design is cleaner and simpler. The absence of dimming is intentional: the drawer is not "interrupting" the page, it is an alternative view.

### Constraint: Layout-Affecting Animations Are Performance Killers

**Critical finding from profiling**: Never animate layout-affecting properties in the drawer transition.

When the drawer gesture updates the animation, the page's `Positioned` offset was being mutated, which marked `RenderStack` dirty for **LAYOUT**. This forced the entire subtree to relayout on every frame:

| Metric | Cost |
|--------|------|
| LAYOUT | 795ms per gesture frame |
| PAINT | 205ms per gesture frame |
| Frame drop | Up to 48.8ms frame time (max sustainable: 16.6ms at 60fps) |

**Solution**: Replace the `Positioned` offset mutation with `Positioned.fill` + `Transform.translate` (paint-and-hit-test only). `Transform` does NOT mark parents dirty for layout; it only affects painting and hit testing. New metrics:

| Metric | Cost |
|--------|------|
| LAYOUT | ~1ms per gesture frame (no dirty marks) |
| PAINT | ~50ms per gesture frame |
| Frame drop | ~8.2ms frame time (no jank) |

**Rule for future work**: In animations and gestures, only vary `Transform`, opacity, color, shadow, and border radius. Never mutate `Positioned` offsets, sizes, or `Flex` grow factors on every frame. If you must animate geometry, profile first and confirm the RenderBox's parents do NOT get marked dirty for layout.

This constraint is encoded in the implementation (`Transform.translate` inside `Positioned.fill`) and documented here for future drawer/rail/tab work.

### Consequences

- **Page is uninteractable while drawer is open**: The page is wrapped in `IgnorePointer(ignoring: true)` when the drawer opens, preventing accidental taps from reaching content beneath. This is intentional — the drawer should be closed before interacting with the page.
- **Scrim constant removed**: `kLayrzLayoutDrawerScrimOpacity` no longer exists; code referencing it will fail at compile time, forcing explicit acknowledgment of the design change.
- **Gesture handling is stateful**: The drawer manages two gesture regions (closed-state left edge, open-state page sliver) and switches between them. Tests must verify both paths.
- **Animation curves are tuned**: The transition uses `motion.easingEnter` and `motion.easingExit` from tokens, so the feel can be adjusted per-theme without code changes.
- **Drawer is no longer a scroll container**: The previous draft rendered the drawer as a scrollable surface. The new design renders it as a flat, static backdrop. If navigation items exceed viewport height, the drawer menu itself must become scrollable (not the entire drawer).

### Review Trigger

**Revisit if**:
- User testing reveals that the 12% visible page sliver is not an obvious dismissal affordance; users miss the drag-to-close interaction.
- Animation smoothness during gesture degrades on older devices despite the `Transform` optimization.
- A future design update decides the drawer should have elevation or a different backdrop treatment.
- A consuming app reports that the page's uninteractability while the drawer is open breaks their workflow (e.g., they need background content to remain partially interactive).

---

## D45: Icon Set Migration — Solar (layrz_icons) to Material Design Icons (flutter_material_design_icons)

**Date**: 2026-08-20  
**Status**: Decided  
**Category**: Dependency Policy / Design System

### Context

layrz_ui initially planned to use the Solar icon set via `layrz_icons` (1.1.1 and 2.0.0) as the system-wide icon source. On 2026-08-20, the maintainer directed the design system to migrate to Material Design Icons (`flutter_material_design_icons`). This was a product/design direction, not a decision derived from technical evaluation of alternatives.

### Decision

**Chose: Material Design Icons via `flutter_material_design_icons` (^3.1.0+7447).**

### Rationale

This was directed by the maintainer as a design-language change; no comparative technical evaluation was performed.

However, several properties of the chosen package are worth recording:

- **Material-free package**: `flutter_material_design_icons` is a pure font + constants library importing only `package:flutter/widgets.dart`. It has zero Material coupling, despite its name. This preserves layrz_ui's design-system-agnostic foundation.
- **Const-preserving**: All members are `static const IconData`, so call sites retain `const` semantics — no change to component API const-ness. `layrz_icons` by contrast exposes `static IconData get`, which is not const; only `flutter_material_design_icons` constants are usable in const contexts (e.g., const default parameter values).
- **Icon coverage**: The package provides 7,447 icon constants. This is comparable in scale to the Solar set (which layrz_icons bundles along with Material Design Icons and Font Awesome); it is not a smaller catalogue, despite its name suggesting a Material-specific set. A name-by-name mapping verified that all required icons had MDI equivalents or close substitutes.
- **Semantic factories parity**: All semantic factories (LayrzButton.save, .cancel, .info, .show, .edit, .delete; LayrzDropdownEntry equivalents; LayrzAlert types) use identical icons across all components. Each semantic factory has a deliberate icon mapping (e.g., `.save` → `contentSaveOutline`, `.cancel` → `closeCircleOutline`, `.info` → `informationOutline`, `.show` → `eyeOutline`, `.edit` → `pencilOutline`, `.delete` → `trashCanOutline`). Note: `LayrzAlert`'s info icon is `informationBoxOutline` (boxed), which is intentionally *different* from the `.info` factory icon (`informationOutline`, bare).
- **layrz_icons retention**: `layrz_icons` is **retained** in `pubspec.yaml` exclusively for the planned `LayrzIconInput` widget. This picker widget browses the Solar catalogue, which is its intended use case. The system-wide icon source is MDI only; `layrz_icons` is no longer used in components.

### Consequences

**Immediate**:
- All components using `LayrzIcons.solarOutlineXxx` migrate to `MdiIcons.xxx` (e.g., `MdiIcons.informationBoxOutline`, `MdiIcons.checkCircleOutline`).
- Every wiki widget page, engineering doc, and code example listing icon names must be updated.
- The mapping from Solar → MDI is recorded in a canonical table in the migration commit.

**Visual appearance change**: Where a Solar icon had no exact MDI counterpart, the closest substitute was chosen, so some icons changed appearance beyond a like-for-like swap.

**Dependency graph**:
- `flutter_material_design_icons: ^3.1.0+7447` is added to `pubspec.yaml`.
- `layrz_icons: ^1.1.1` remains (for future LayrzIconInput) and is no longer the system-wide icon source. Note: `layrz_icons` 1.1.1 itself depends on `flutter_material_design_icons: ^3.1.0+7447`, so adding it to layrz_ui's pubspec promotes a transitive dependency to a direct one, adding no new font asset to the bundle. Both packages expose the same font family and code points (7,447 MDI members).

**Future components**: Components that need icons not in MDI must either use a reasonable MDI substitute, add a new icon to a custom icon font, or defer implementation.

### Review Trigger

**Revisit if**:
- A consuming app reports that a critical UI icon is missing from MDI and no reasonable substitute exists, necessitating a custom icon font or package replacement.
- The Material Design Icons package is discontinued or significantly degraded in maintenance, requiring evaluation of alternatives.

---

## D46: Spacing and Radius Token Refactor — Semantic Level Ramps

**Date**: 2026-08-20  
**Status**: Decided  
**Category**: Design System / Token Architecture

### Context

Both spacing and radius tokens had grown ad-hoc collections of pixel-named members (e.g., `sp4`, `sp6`, `sp8`… `sp48` for spacing; `r8`, `r10`, `r12`… `r24` for radius). The shadow token system already exposed five semantic elevation levels (`elevation1`…`elevation5`), providing a unified mental model. On 2026-08-20, the maintainer directed a refactor to align spacing and radius with the pre-existing shadow pattern.

### Decision

**Chose: Replace pixel-named members with five semantic levels using a shared value scale (4, 8, 16, 24, 32).**

Both `LayrzSpacingTokens` and `LayrzRadiusTokens` now expose:
- Five final `double` fields: `sp1`/`r1` (4), `sp2`/`r2` (8), `sp3`/`r3` (16), `sp4`/`r4` (24), `sp5`/`r5` (32)
- Derived getters (not in `copyWith`/`==`/`hashCode`): `pdN`/`mgN` returning `EdgeInsets.all(spN)` for spacing clarity; `brN` returning `BorderRadius.circular(rN)` for radius clarity
- For radius only: `full` = 999 (pill shape, retained), `innerRadius()` and `innerRadiusValue()` (nested container math)

### Rationale

- **Unification**: One value scale (4, 8, 16, 24, 32) across spacing, radius, and shadow (elevation) eliminates memorization and makes design system choices faster.
- **Semantic clarity**: Named levels (sp1–5) replace pixel names, aligning intent with the shadow pattern already in use.
- **API simplification**: Fewer members (5 vs. 15+ in spacing; 5 + 1 vs. 8 + 1 in radius) reduce cognitive load and discovery burden.
- **Accessibility**: Derived getters (`pdN`, `mgN`, `brN`) make call sites read as intent-driven rather than shape-driven, improving code clarity without additional tokens.

### Consequences

**Breaking API change**: All consuming code must migrate from pixel-named members to level-based ones.

**Silent failure hazard**: `sp4` existed in both schemes with *different* values (4.0 → 24.0). Stale code using the old `sp4` would compile and render six times the intended spacing. The mitigation adopted was **complete removal with no deprecation aliases or `@deprecated` annotations**, forcing every stale call site to fail at compile time rather than silently. This is a one-time safety trade-off (clean break) over ongoing technical debt (dual API surface).

**Safe migration order** (applied to this codebase):
1. Rewrite all old `sp4` references to `sp1` *first*, verify zero `sp4` remains.
2. *Then* introduce the new `sp4` definition.
3. Generalize: whenever a rename reuses an existing identifier with a new value, delete before re-adding.

**Call-site migration (spacing)**:

| Old | New | Justification |
|-----|-----|---|
| `sp4` (4.0) | `sp1` | Exact; level 1 is 4 |
| `sp6` (6.0) | `sp2` | Round up to 8 |
| `sp8` (8.0) | `sp2` | Exact; level 2 is 8 |
| `sp10` (10.0) | `sp2` | Nearest (8) |
| `sp12` (12.0) | `sp3` | Round up to 16 |
| `sp14`–`sp16` (14–16) | `sp3` | Exact or near; level 3 is 16 |
| `sp20` (20.0) | `sp4` | Round up to 24 |
| `sp24` (24.0) | `sp4` | Exact; level 4 is 24 |
| `sp28` (28.0) | `sp5` | Round up to 32 |
| `sp32` (32.0) | `sp5` | Exact; level 5 is 32 |
| `sp36`, `sp40`, `sp44`, `sp48` (36–48) | `sp5` | Clamp to 32 (23 call sites lose ~1/3 spacing) |
| `base` | `sp2` | Base was 8.0; level 2 is 8 |
| `padding`, `margin` | `pd2`, `mg2` | Base-derived; 8.0 values |
| `reducedMargin` | `mg1` | Was `base / 2` = 4.0; level 1 is 4 |
| `spacingSize`, `sizedBox` | Inline `Size(sp2, sp2)` / `SizedBox.square(dimension: sp2)` | No longer convenience members |

**Call-site migration (radius)**:

| Old | New | Justification |
|-----|-----|---|
| `r8`, `r10` | `r2` | Both ≤ 8; level 2 is 8 |
| `r12`–`r16` | `r3` | 12–16 range; level 3 is 16 (16 sites see visibly rounder corners) |
| `r20`, `r24` | `r4` | 20–24 range; level 4 is 24 |
| `base` | `r2` | Base was 8.0; level 2 is 8 |
| `borderRadius` | `br2` | Was `BorderRadius.circular(base)` = 8.0 |

**Visual consequences** (accepted):
- 23 old `sp48` (48.0) call sites now render at `sp5` (32.0) — a 33% tightening. This tightens spacing on some large containers but is preferable to overriding the entire ramp.
- 16 old `r12` (12.0) call sites now render at `r3` (16.0) — corners are visibly rounder.
- Consumers migrating incrementally must ensure all sites are updated together to avoid visual inconsistency.

**`full` and `innerRadius` retained** on assumption: The ramp does not express a pill shape; removing `full` would force 3 call sites to hardcode 999 (a functional regression). Keeping one extra member is trivially reversible; re-deriving pill shapes is not. If the maintainer confirms pill shapes should be removed, this is a one-line field deletion plus 3 call-site updates.

### Review Trigger

**Revisit if**:
- Consuming apps report that the ramp is too coarse (e.g., 24 is too large and 16 is too small) — revisit the five-level scale.
- The visual tightening of the 23 `sp48` → `sp5` sites is confirmed to be a problem — consider aliasing the old `sp48` as `sp5 + 8` or reverting to a six-level ramp.
- Pill shapes should be removed entirely — this is a one-line change once confirmed.

---

## D47: Dense Parameter Removed from the Input Family

**Date**: 2026-08-20  
**Status**: Decided  
**Category**: API Design / Feature Scope

### Context

The `dense` parameter was introduced as a public boolean on `LayrzTextInput` and inherited by all input-family components. Its purported purpose was to enable compact rendering with tighter padding. However, analysis of production usage showed:

1. **Two call sites only** in the codebase itself: the navigation search field in the drawer and the search field in the rail.
2. **Both call sites also pass an explicit `padding:` parameter** that overrides the default, making `dense` ineffective for padding control.
3. **The parameter adds friction**: threaded through two public widgets (LayrzTextInput and picker wrappers), documented across ~31 references, and maintained through 91 lines of code (InputDensitySpec abstraction and related logic).

The cost of maintaining the parameter significantly outweighed its utility.

### Decision

**Remove the `dense` parameter and the `InputDensitySpec` abstraction entirely.**

All inputs now use a single, uniform default: `pd2` (8 logical pixels) on all four sides. The `padding` parameter survives as an escape hatch for callers who need non-standard padding.

### Rationale

**Usage data**: Two call sites in the entire codebase, both with overriding `padding:` parameters, means `dense` is not earning its API surface. Removing it eliminates:
- A boolean with unclear semantics (what is "dense" without measuring the actual reduction?)
- A parameter that silently had no effect on its two production consumers
- 91 lines of abstraction code and ~31 wiki/engineering doc references

**Future extensibility**: If a future use case genuinely needs tighter geometry, it can be addressed by:
1. Passing an explicit `padding:` parameter (already available).
2. Creating a purpose-built, compact-input component with its own name and contract (e.g., `LayrzCompactTextInput`), rather than resurrecting a confusing boolean.

**Breaking-change timing**: The parameter was public from 0.0.9 onward, but production consumers of layrz_ui are zero at removal time (2026-08-20); the breaking change is free to execute now.

### Consequences

**Removed entirely**:
- `dense: bool` parameter from `LayrzTextInput` and all picker-style inputs
- `InputDensitySpec` abstraction file (`lib/src/inputs/src/input_density.dart`, 91 lines)
- All references in wiki and engineering documentation

**Retained**:
- The `padding: EdgeInsets?` parameter on `LayrzTextInput`, defaulting to `pd2` (8px uniform)
- Two constants that were unused: `kLayrzLayoutSearchFieldPaddingHorizontal` (10.0, not on token ramp) and `kLayrzTextInputDenseIconSize` (14.0)

**Visual change**: Two production call sites (drawer and rail search fields) now render with `body` (16px) text and 8px uniform padding (vs. 14px text and 10px horizontal / 8px vertical under the old dense rendering). The change is intentional and aligns with the single-density design.

### Removal Strategy

When removing a parameter or abstraction:
1. **Delete the parameter entirely** (not `@deprecated`) — forces all call sites to fail at compile time.
2. **Search for references** beyond the parameter itself (e.g., constants used only by that feature).
3. **Clean up orphaned code** (the abstraction file, derived getters, helper methods).

This is preferred over deprecation cycles because:
- Dart has no feature flags; deprecation leaves dead code in production binaries.
- layrz_ui is 0.0.x (pre-release); clean breaks are expected and free.
- Forcing compile-time failure ensures no code silently uses a removed feature and behaves incorrectly.

### Related Decisions

- **D32** (Filled Visual Language) — established the input interaction matrix and padding as a design token.
- **D33** (Read-Only as Rest + Lock Icon) — part of the same M3 input family contract.

### Review Trigger

**Revisit if**:
- A consuming app reports that the removal of `dense` blocks a critical workflow, requiring a purpose-built compact-input component be created instead.

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

---

## D48: Navigation Panel Unification and Logo/Search Field Refactor

**Date**: 2026-08-20  
**Status**: Decided  
**Category**: Code Refactoring / Design System

### Context

The navigation panel appeared twice in `LayrzLayout`:
- `LayrzLayoutRail` (386 lines) in `lib/src/layout/src/rail.dart` — persistent sidebar on desktop (md, lg, xl breakpoints)
- `LayrzLayoutDrawer` (385 lines) in `lib/src/layout/src/drawer.dart` — off-canvas drawer on mobile (sm, xs breakpoints)

The two widgets were ~91% identical in structure, differing only in two behavioural axes:
1. Width: 178px (rail) vs. 260px (drawer)
2. Closure mode: no close affordance (rail) vs. callback-driven closure on navigation item tap (drawer)

Both rendered the same internal structure: logo block, search field, navigation items, user chrome, notifications footer. The duplication introduced:
- Risk of divergent behaviour between presentations (e.g., search filtering differently, logo sizing inconsistently)
- 69 lines of actual code difference across ~770 lines total — roughly 9% divergence, or about 91% duplication
- Maintenance burden: a change to logo rendering or search filtering required edits in two places

Additionally, the logo block carried six hardcoded constants (`kLayrzLayoutLogoWidthFactor`, `kLayrzLayoutLogoHeight`, etc.), and the search field carried four more (`kLayrzLayoutSearchFieldHeight`, etc.). Analysis showed these constants were used nowhere else and were not consumed by external packages.

### Decision

**Chose: Merge into a single internal widget, `LayrzLayoutNavigatorPanel`, parameterised on width and closure mode.**

The merged widget:
- Takes `width: double` (caller passes 178 or 260)
- Takes `onClose: VoidCallback?` — **null means persistent (rail) mode; non-null means drawer mode**
- Derives shadow rendering from the `onClose` flag: shadow (`elevation2`) only when persistent; no shadow in drawer mode (sits on backdrop)
- Renders a unified logo block and search field

### Rationale

**Deduplication**: Eliminating duplication reduces defect risk and maintenance cost. A single implementation path for logo and search ensures both presentations behave consistently.

**Parameterisation strategy**: The two axes of variance (width and closure behaviour) map cleanly to constructor parameters. The choice to derive shadow from `onClose` is semantic: a persistent panel needs visual separation from the body; a drawer is a floating overlay on a backdrop and reads correctly without shadow.

**Constant removal**: The ten deleted constants were examined for external use (grep across `lib/`, `test/`, `example/`) and found to be unused outside their definition within this repository. Removing them simplifies the token landscape. This is a genuine breaking change: the constants were public via `lib/src/constants/src/layout.dart` → `lib/src/constants/constants.dart` → `lib/layrz_ui.dart`, and the impact on consuming packages is unknown. External consumers may reference them at upgrade time and will need to migrate their code.

**Two normalisations applied during merge**:
1. Logo block now guarded by `logo.isNotEmpty` in both modes (drawer previously rendered an empty `LayrzImage` for empty logo, rail omitted it)
2. Logo block made edge-to-edge via `LayoutBuilder` + symmetric `kLayrzLayoutItemPaddingHorizontal` on left/right, with `maxHeight` ceiling at 100px allowing aspect-ratio scaling via `BoxFit.contain`

### Consequences

**Code removed**:
- `lib/src/layout/src/rail.dart` (386 lines)
- `lib/src/layout/src/drawer.dart` (385 lines)
- Ten public constants from `lib/src/constants/src/layout.dart`:
  - Logo: `kLayrzLayoutLogoTileSize`, `kLayrzLayoutLogoTileRadius`, `kLayrzLayoutLogoGap`, `kLayrzLayoutLogoWidthFactor`, `kLayrzLayoutLogoHeight`, `kLayrzLayoutLogoLeftPadding`
  - Search: `kLayrzLayoutSearchFieldHeight`, `kLayrzLayoutSearchFieldInternalPaddingHorizontal`, `kLayrzLayoutSearchFieldFontSize`, `kLayrzLayoutSearchFieldIconSize`

**Public API impact**: `LayrzLayoutRail` and `LayrzLayoutDrawer` were **never exported** from `lib/src/layout/layout.dart`, so their removal is not a public breaking change. However, the ten constants *were* public, making their removal a **genuine breaking change** for any consumer code referencing them by name.

**Known wart**: `kLayrzLayoutRailPaddingHorizontal` and `kLayrzLayoutRailPaddingVertical` retain the `Rail` prefix despite applying to both presentations. Renaming would introduce a second breaking change. These constants are candidates for a future breaking release.

### Review Trigger

**Revisit if**:
- Drawer and rail presentations show visual divergence in logo rendering or search filtering, indicating the merged implementation is insufficient for future variance.
- A consuming app reports that removal of the ten constants blocks critical custom styling, requiring a feature-flag constant restoration strategy.

---

## D49: Surface Color Tokens — Collapse to Numbered Ramp `sf1`–`sf4`, Remove Pure White

**Date**: 2026-08-20  
**Status**: Decided  
**Category**: Design Tokens / Breaking Change

### Context

layrz_ui currently has four surface color tokens with inconsistent naming:
- `background` (#FCFCFC) — canvas/scaffold color
- `surface` (#FFFFFF) — card/dialog color
- `surface2` (#F7F7F7) — nested container color
- `surface3` (#F0F0F0) — deepest nesting color

The naming is ad-hoc (no semantic pattern), and the use of pure white (#FFFFFF) for `surface` is problematic:
1. **Rendering contrast**: All elevation shadows are calculated assuming the card sits on a #FCFCFC canvas. A white card on a light-gray canvas has no visual elevation separation, requiring shadow to do all the visual work.
2. **Inconsistency with ramp logic**: The spacing and radius token refactors (D46) introduced semantic level ramps (1–5). Surfaces should follow the same pattern for consistency.
3. **Naming confusion**: Neither `background` nor `surface` clearly communicates the ramp structure or values. A numbered sequence is unambiguous.

### Options Considered

| Option | Pros | Cons |
|--------|------|------|
| (a) Keep as-is | No breaking change | Inconsistent naming; pure white causes visual flattening; not aligned with D46 ramp pattern |
| (b) Rename to `surface1`–`surface4` | Clearer numbering | Still `surface` prefix; does not address white issue |
| (c) Use `sf1`–`sf4` numbered ramp and promote on-canvas fills to #F7F7F7 (chosen) | Aligns with D46 ramp pattern; removes pure white; improves elevation shadow contrast; clear 1–4 ordering | Breaking change affecting ~108 call sites across lib/, test/, example/ |

### Decision

**Chose (c): Collapse to `sf1`–`sf4` numbered ramp, promote on-canvas fills to #F7F7F7, remove pure white.**

### Token Values

| New | Value | Replaces | Usage |
|-----|-------|----------|-------|
| `sf1` | #FCFCFC | `background` | Canvas/scaffold background, overlay fills (dropdowns) |
| `sf2` | #F7F7F7 | `surface` (promoted) | On-canvas fills: cards, dialogs, panels, alerts |
| `sf3` | #F0F0F0 | `surface2` | Nested containers, secondary elevations |
| `sf4` | #E8E8E8 | — (new) | Deepest nesting, maximum contrast |

### Rationale

**Ramp consistency**: Spacing (D46) and radius (D46) now use semantic level ramps (1–5). Surfaces follow the same pattern for mental coherence. The prefix `sf` (surface fill) is unambiguous and compact.

**Contrast improvement**: Promoting on-canvas fills from white (#FFFFFF) to #F7F7F7 (old `surface2`) creates visual separation from the #FCFCFC canvas, reducing reliance on shadow alone. Shadows are now computed with `surfaceColor: #F7F7F7` (instead of #FFFFFF), making them calibrated to the actual background they appear on.

**Removal of pure white**: Pure white has no place in a light-mode system with a light-gray canvas. It reads as "too bright" and forces surfaces to rely entirely on shadow or border for elevation cues. The ramp is now a true grayscale progression: #FCFCFC → #F7F7F7 → #F0F0F0 → #E8E8E8.

**New `sf4` step**: Adds a fourth step for cases requiring maximum contrast (e.g., deepest nested panels, edge cases). Currently unused in shipped components, but available for future expansions.

### Consequences

**Breaking changes**:
- Removed: `LayrzColorTokens.background`, `.surface`, `.surface2`, `.surface3` (all four fields).
- Removed: constant `kLightBackgroundColor` from `lib/src/constants/src/colors.dart`.
- Added: `LayrzColorTokens.sf1`, `.sf2`, `.sf3`, `.sf4` (all in `copyWith`, `==`, `hashCode`).
- Updated: `LayrzThemeData.backgroundColor` getter now returns `.sf1` (was `.background`); `surfaceColor` returns `.sf2` (was `.surface`).

**Call-site count**: ~108 across lib/ (~40), test/ (~33), example/ (~35).

**Migration table**:
- `colors.background` → `colors.sf1`
- `colors.surface` → `colors.sf2` (on-canvas fills) or `colors.sf1` (overlays)
- `colors.surface2` → `colors.sf2`
- `colors.surface3` → `colors.sf3`

**Rendering changes**:
- `LayrzShadowTokens` default `surfaceColor` updated from #FFFFFF to #FCFCFC.
- `LayrzAvatar` private background constant `_kWhiteBackground` updated from #FFFFFF to #FCFCFC.
- All elevation shadows now render against light gray, improving visual separation.

**Shadow seeding**: `LayrzTokens.light()` factory wires shadow `surfaceColor` to `colors.sf2` (the new on-canvas fill), ensuring shadow calculations are consistent with the surfaces they shade.

### Revert — 2026-08-20

The promotion of on-canvas fills to `sf2` (option c, above) was implemented in DESIGN-111 but reverted immediately. The decision to elevate surface colors was reversed because **elevation shadows provide sufficient visual separation without a colour step**.

**What was reverted**:
- Cards, panels, alerts, and dialogs: `sf2` → `sf1`
- `LayrzThemeData.surfaceColor`: returns `sf1` (was `sf2`)
- `LayrzTokens.light()` shadow seeding: `surfaceColor` wired to `sf1` (was `sf2`)
- All `flattenOn()` bases in interactive alert styling: `sf2` → `sf1`

**Why the revert**:
1. **Elevation is a sufficient separator.** Testing showed that elevation shadow (blur, opacity, offset) alone distinguishes cards/panels from the `sf1` canvas. The intermediate step (`sf2`) was redundant.
2. **Reduces visual complexity.** Using `sf1` for both canvas and on-canvas fills simplifies the palette: fewer distinct grays, fewer cognitive categories.
3. **Maintains semantic clarity.** On-canvas elements still have distinct shadow tokens; shadow is the elevation cue, not color.

**Correct migration table** (replacing the one above):
- `colors.background` → `colors.sf1`
- `colors.surface` → `colors.sf1` (all on-canvas fills now; elevation shadows provide separation)
- `colors.surface2` → `colors.sf1`
- `colors.surface3` → `colors.sf3`

**Shadow seeding** (corrected): `LayrzTokens.light()` factory wires shadow `surfaceColor` to `colors.sf1` (the canvas color), not `sf2`.

### Review Trigger

**Revisit if**:
- Adopters report that `sf1` (light gray overlay on light gray canvas) reads as insufficient visual separation for persistent overlay panels (dropdowns, popovers). Contingency: add an `sf0` (#FAFAFA) or shift overlay fills to `sf2`.
- The ramp is too shallow (4 steps) and components need intermediate nesting levels. Contingency: expand to 5–6 steps.


---

## D50: Material-Free Text Selection — Field Actions, Page Toolbar, Flutter Traps

**Date**: 2026-08-20  
**Status**: Decided  
**Category**: Design / Selection Framework

### Context

Text selection in Flutter's `EditableText` and `SelectableRegion` is deeply coupled to Material Design conventions. layrz_ui, being Material-free, needed to:
1. Customize the selection toolbar in text fields to show configurable actions (copy, cut, paste, select all)
2. Provide toolbar for page-wide text selection (under `SelectableRegion` in `LayrzLayout`)
3. Understand and work around five non-obvious Flutter defaults that silently break selection if left unchecked

### Design

**Field selection toolbar**: `LayrzTextInput` adds an `actions` parameter:
- When `null`, the field offers all four built-in actions (copy, cut, paste, select all) as permitted by field state
- When `const {}`, the toolbar is suppressed entirely
- When populated with a set of `LayrzSelectableAction` instances, those actions appear in the toolbar
- The set is intersected with what the field's state permits: obscured fields never offer copy/cut; read-only fields never offer cut/paste

**Built-in actions**: Exposed as static methods on `LayrzSelectableAction`:
- `copy()`, `cut()`, `paste()`, `selectAll()`

**Custom actions**: Callers create `LayrzSelectableAction(label: (context) => '...', onPressed: () => ...)`

**Important constraint**: Custom actions cannot be const. The type overrides `operator==`, making const instances non-hashable (Dart error). Workaround: use `static final` instead.

**Page-wide selection**: `SelectableRegion` under `LayrzLayout` now displays a copy-only toolbar when text is selected. This is hardcoded and non-customizable.

### Rejected Options

**`LayrzSelectableTools` shared provider**: A previous draft proposed a shared context-scoped controller/provider that both field and page region would read to determine available actions. This was rejected because:
1. The field carries its own `Set<LayrzSelectableAction>`, which is the source of truth
2. A shared provider conflates field-level and page-level concerns, mixing two independent selection contexts
3. It adds unnecessary indirection without solving a real problem (both can independently resolve their actions)

**Android ProcessTextService extras**: Android has a built-in mechanism to pass action intents to custom apps (e.g., "share to Twitter"). We deliberately exclude this from the toolbar because:
1. It is Android-only and not portable to iOS/web
2. layrz_ui does not target that use case; the toolbar is lightweight
3. Integrating it would complicate the toolbar builder significantly

### The Five Flutter Traps

During implementation, five silent-failure defaults were discovered:

#### Trap 1: `rendererIgnoresPointer` defaults to false

`EditableText.rendererIgnoresPointer` defaults to `false`. When false, `RenderEditable` claims pointer events and wins the gesture arena, so a fully-wired `TextSelectionGestureDetectorBuilder` never fires.

**Fix**: Set `rendererIgnoresPointer: true`. Material does this at `text_field.dart:1726`.

**Why silent**: The gesture detector is wired correctly; it's just never invoked because the renderer blocks it first.

#### Trap 2: `selectionControls` and `magnifierConfiguration` must be stable instances

`EditableText.didUpdateWidget()` disposes and recreates the selection overlay whenever `selectionControls` or `magnifierConfiguration` differs (lines 3464–3473). Showing the toolbar itself triggers a rebuild of the parent, which creates a new set of these objects, which disposes the overlay mid-display, which crashes.

**Fix**: Cache both as instance variables, initialized once in `initState()`, and reuse the same reference across rebuilds.

**Why silent**: The overlay shows momentarily, then vanishes. If the tap happens to be captured before disposal completes, no crash is visible. The behavior looks like a tap not opening the toolbar.

#### Trap 3: `TextSelectionControls` must mix in `TextSelectionHandleControls`

`TextSelectionControls` alone is insufficient. The `contextMenuBuilder` parameter is ignored in favour of the deprecated `buildToolbar()` method unless the controls mix in `TextSelectionHandleControls` (text_selection.dart:472–481, documented at `:74-85`).

**Fix**: Use `class LayrzTextSelectionControls extends TextSelectionControls with TextSelectionHandleControls`.

**Compounding trap**: Stubbing `buildToolbar()` to return an empty container then yields a toolbar that shows correctly and is blank. This reads like the custom toolbar is working, but `contextMenuBuilder` is never called.

**Why silent**: `buildToolbar()` is deprecated but still invoked. The callback parameter is documented as ignored in the presence of `buildToolbar()`, but the relationship is not obvious in the API.

#### Trap 4: `showSelectionHandles` defaults to false

`EditableText.showSelectionHandles` defaults to `false` (editable_text.dart:862). The overlay builds the handles then hides them (`:4531-4532`).

**Fix**: Drive `showSelectionHandles` per `SelectionChangedCause` in the field's `onSelectionChanged` callback. Material sets it to true for long-press and drag, false for keyboard-driven selection (text_field.dart:1168, `:1424-1426`, `:1692`).

**Why silent**: Without this, selection works (keyboard, toolbar appear), but the draggable handles are invisible. It reads like selection is broken, not that handles are just hidden.

#### Trap 5: Selection overlay is not created eagerly

The selection overlay is created lazily, not eagerly. It requires the field to be **focused** and the selection to have changed **with a cause**. Calling `showToolbar()` on an unfocused field returns `false` silently (editable_text.dart:5184–5212).

**Consequence**: Tests must focus the field and use a real gesture (not a synthetic selection assignment) to trigger the overlay. `controller.selection = TextSelection(...)` alone will not show handles or toolbar.

**Why silent**: The API returns `false`, but callers rarely check. The toolbar never appears, which reads like the implementation is broken.

### Consequences

- All five traps must be addressed in code. Omitting any one of them results in plausible-looking but broken text selection.
- None of the traps are discoverable from the API surface (no warnings, no errors, no inline documentation).
- **Lifecycle fact that looks like a bug**: The selection overlay is not created until the field is focused AND the selection changes with a cause. This is intentional for efficiency but counter-intuitive.
- `LayrzLayout`'s `SelectableRegion` needs its own `contextMenuBuilder` once the text selection controls mix in `TextSelectionHandleControls`, or page selection crashes with a null check (selectable_region.dart:1389).

### Related Decisions

- D32, D33, D34: Text input styling and layout
- D15: Interaction state affordances (no size/geometry changes on hover/press)

### Review Trigger

If Flutter's text selection API is refactored in a future version, revisit these traps to see if any are no longer necessary.

---

## D51: Text Wraps by Default — Component Structural Limits Own Truncation

**Date**: 2026-08-21  
**Status**: Decided  
**Category**: Design System / Typography

### Context

`LayrzTextTheme` in the type scale historically included `overflow: TextOverflow.ellipsis` in two places: the `titleStyle` builder (feeding `display`, `headline`, and `title` styles) and the `bodyStyle` builder (feeding `body` and `label` styles). This assumption was that all text should truncate with an ellipsis when it did not fit.

This conflates two concerns: **typography** (how text looks) and **layout** (whether text may wrap or must truncate). A type scale defines semantic roles and visual appearance, not layout constraints. Whether text wraps depends entirely on the container's dimensions and layout rules — which the type scale has no visibility into. Additionally, the implementation created a hidden API contract: developers wanting wrapped text had to pass `overflow: TextOverflow.visible` at every `Text()` call site, overriding the type scale's default. This was inverted and unintuitive.

The assumption also masked a shipped bug. `LayrzButton` rendered labels at fixed size with `TextOverflow.ellipsis` inside the button's chrome, so buttons with long labels silently truncated instead of alerting the developer to a layout problem (DESIGN-78).

### Decision

**Text wraps by default. Truncation is an explicit decision, owned by the component.**

### Rule

- **Text in unbounded space** needs no special handling — wrapping is the default and sufficient.
- **Height-locked containers, single-line badges, fixed-geometry chrome** take explicit `maxLines: 1` plus explicit `overflow: TextOverflow.ellipsis`.
- **Deliberate multi-line caps** take `maxLines: N` plus explicit `overflow`.
- **`RichText` must set `overflow` on its own constructor**, because it ignores `style.overflow`. The `RichText.overflow` parameter defaults to `TextOverflow.clip`; callers pass `overflow: TextOverflow.ellipsis` explicitly if they need a three-dot truncation.
- **Measurement-only `TextPainter`s take neither.** `TextPainter` never reads `TextStyle.overflow`; it exposes an `ellipsis` field on the painter itself. Measurement painters (used for intrinsic-width calculations) should not set ellipsis.

### Three Critical Facts (do not re-litigate)

1. **`TextPainter` ignores `TextStyle.overflow` entirely.** `RenderParagraph` translates `overflow == TextOverflow.ellipsis` into `textPainter.ellipsis = '…'` (`packages/flutter/lib/src/rendering/paragraph.dart:377,633`); the painter honours only its own `ellipsis` field. Measurement-only painters (e.g., at `lib/src/buttons/src/button.dart:728` and `lib/src/chips/src/chip.dart:81` for intrinsic-width calculation) are unaffected by `TextStyle.overflow` and should not be given an ellipsis value.

2. **`RichText` never reads `TextStyle.overflow`.** `RichText.overflow` is its own constructor parameter defaulting to `TextOverflow.clip`. Only `Text` / `Text.rich` fall back to reading `style.overflow`. So no `RichText` site in layrz_ui was ever affected by the type scale's ellipsis, and none need it.

3. **Field label is unbounded; hint/placeholder is layout-locked.** The field label is the `RichText` at `input_chrome.dart:191`, sets neither `maxLines` nor `overflow`, and already wrapped freely. The hint/placeholder is at `input_chrome.dart:260-261` and `:274-275`, renders in a fixed-height chrome row, and takes `maxLines: 1` + `overflow: TextOverflow.ellipsis` because the row height is locked to `density.contentHeight`. These are different layout concerns.

### Rationale

- **Ownership**: Components know their layout constraints; type scales do not. A component that renders text in a constrained geometry should own the decision to truncate.
- **Correctness**: Silent truncation masks layout bugs. Wrapped text that grows the layout alerts developers to re-size containers or re-word labels. This is better than invisible `…` that hides the problem (DESIGN-78).
- **Simplicity**: Removing `overflow` from the type scale means `Text` calls in unbounded slots (paragraphs, descriptions, alert content, tooltips) need no overrides. This is the common case, so the default should be the simplest one.
- **Measured containers**: Components that measure text for intrinsic sizing (buttons, chips) cannot use `ellipsis` in the painter without corrupting width calculations. Ownership at the render site (not in the type scale) ensures painters are clean.

### Consequences

- **Behavioural breaking change** (no API change). `Text` widgets with no explicit `overflow` that sit in height-constrained space now wrap instead of truncating. Examples: alert titles, tooltip content/title. Components that already set `overflow` explicitly are unchanged (button labels, chip labels, navigator rail items all use `RichText` with explicit truncation). Code that was silently truncating may now wrap and grow layouts. Callers must verify their layouts still fit or explicitly add `maxLines: 1` + `overflow: TextOverflow.ellipsis` where space is genuinely limited.
- **No compile-time failure.** Existing `Text(label)` calls compile and render unchanged unless the new wrapping causes layout overflow. This silence is intentional and the trade-off of a behavioural change: the alternative (always truncate) masks bugs like DESIGN-78.
- **Eleven sites across six files** now explicitly set truncation where text was previously truncated by the type scale:
  - Avatar emoji/initials/fallback: three sites in `lib/src/images/src/avatar.dart` (emoji in `.emoji()`, initials in fallback, emoji in `_buildFromSource()`) — all use `maxLines: 1` + `overflow: TextOverflow.ellipsis`
  - Selection-toolbar action labels: one site in `lib/src/selection/src/selection_toolbar.dart` (`LayrzSelectionToolbar`) — uses `maxLines: 1` + `overflow: TextOverflow.ellipsis`
  - Input shortcut badge and slot text: two sites in `lib/src/inputs/src/input_chrome.dart` — both use `maxLines: 1` + `overflow: TextOverflow.ellipsis`
  - Input error text: two sites in `lib/src/inputs/src/input_error_block.dart` (one in the errors-only branch, one in `_ErrorAndCounterRow`) — both use `maxLines: 2` + `overflow: TextOverflow.ellipsis` for legible multi-line error messages
  - Dropdown plain label and shortcut badge: two sites in `lib/src/menus/src/dropdown_items.dart` (`LayrzDropdownLabel` and `LayrzDropdownEntry`) — both use `maxLines: 1` + `overflow: TextOverflow.ellipsis`
  - Navigator section caption: one site in `lib/src/layout/src/navigator_panel.dart` (uppercase section caption) — uses `maxLines: 1` + `overflow: TextOverflow.ellipsis`
- **Text in wrappable slots** (alert titles, tooltip content/title, empty-state literals, input field label) is left unchanged and wraps freely. No `maxLines` was added to them.
- **No `DefaultTextStyle` safety net.** Setting `overflow` on `DefaultTextStyle` would re-apply ellipsis to every `Text` in the tree, re-creating DESIGN-78. Setting `maxLines` on `DefaultTextStyle` would cap all text globally. Both are rejected.

### Related Decisions

- **D27** (Component Enum Trims): Records the design rule that `LayrzButton` continues to render labels with `TextOverflow.ellipsis` / `maxLines: 1` (line 1705). This now lives at the render site (`lib/src/buttons/src/button_content.dart:104-105`) rather than inherited from the type scale.
- **D23** (Five-Style Type Scale): Established the scope of `LayrzTextTheme` as five semantic roles. D51 removes a detail (overflow) that never belonged in the type scale.
- **D50** (Text Selection): Affects the same text-rendering layer; both decisions honor correct Flutter semantics.

### Review Trigger

If consuming apps report a pattern of needing `maxLines: 1` in many call sites, consider a wrapper component or extension to reduce boilerplate. Do NOT add overflow back to the type scale.

### Amendment (2026-08-21) — Input Error Text Capped at Two Lines

**What changed**: Input error text is now capped at `maxLines: 2` with `overflow: TextOverflow.ellipsis`. The original task description stated errors "have no `maxLines` and no `overflow`, so they already wrap freely — correct as-is; leave alone", and this was accepted at plan time. Device testing disproved it: when two validation errors were joined into one string ("Must be at least 8 characters, Must contain uppercase letter"), the error text wrapped to two lines and pushed the form downward, reflowing the page.

**General lesson**: A slot being _unbounded_ is not the same as it being _safe to grow_. Input error text is attached to a field in a form, so its vertical growth reflows everything below it. While single-line errors are rare enough that unbounded wrapping was acceptable when combined with field-level rules, real-world validation messages are often compound, and letting them grow without limit degrades the UX. The fix is a deliberate middle position: capped multi-line (`maxLines: 2`) rather than either extreme (no cap / silent truncation).

**This is the fourth error found in the task description** — the first three are recorded in "Three Critical Facts". But they are not the same kind. The first three were **factually wrong about the code and SDK** (TextPainter's behaviour, the field layout distinction, RichText's overflow handling) and were caught by reading the source. This fourth is **factually correct about the code but wrong about the consequence** — the code was right that errors had no `maxLines`, but the inference that unbounded therefore meant safe was wrong. Only running the app on a device surfaced it. The lesson: reading source catches errors about implementation; consequence-finding requires testing.

**Why this is no longer an exception**: A slot with `maxLines: N` + explicit `overflow` is no longer a special case — it is now an instance of the Rule's "Deliberate multi-line caps" bullet, which already covers the pattern. The change makes error text consistent with the system's architecture.

---

## D52: Picker Surfaces Are Adaptive — Anchored Overlay on Desktop, Bottom Sheet Below `md`

**Date**: 2026-08-21  
**Status**: Decided  
**Category**: API Design / Interaction Design

### Context

M3 introduces three picker-style inputs — `LayrzComboBoxInput`, `LayrzSelectInput`, and `LayrzDurationInput` — all of which need to present a list or surface for selection. The question of "desktop popup vs. mobile sheet" affects the implementation and the public API of all three components.

### Decision

**Picker surfaces are adaptive:**
- **Desktop (md/lg/xl, ≥ 960px)**: Anchored overlay panel that flips up or down based on available vertical space
- **Mobile (sm/xs, < 960px)**: `LayrzBottomSheet` modal or persistent

The boundary is the `isCompact` breakpoint (< 960px). No dialog primitive is used in M3; desktop uses the anchored overlay, mobile uses the sheet.

### Rationale

**No dialog in M3 scope**. DESIGN-96 `LayrzDialog` and DESIGN-99 `LayrzAdaptiveModal` remain out of scope. Dialogs would require pulling two more rows into M3. The anchored overlay is lighter-weight and appropriate for inline form picking.

**Container-driven flip logic**. The overlay's position is computed from available vertical space, never declared by the caller. A caller cannot know at build time whether a field sits near the bottom of a scrolled viewport. layrz_theme already overrode declared positions that did not fit, making the parameter advisory.

**Width matching on desktop**. The anchored overlay matches its anchor (the field) width — like a classic web combobox. This distinguishes it from `LayrzDropdownMenu`, which clamps to 160–320px.

### Consequences

- All three picker-component APIs are simplified: no `position` or `surface` parameter
- `LayrzBottomSheet` becomes a required M3 prerequisite (DESIGN-97)
- DESIGN-96 `LayrzDialog` and DESIGN-99 `LayrzAdaptiveModal` deferred to M4 or later

### Related Decisions

- **D53** (`LayrzSelectItem<T>`): Shared item type across pickers
- **D59** (ComboBox free-form): Enabled by adaptive surface

---

## D53: `LayrzSelectItem<T>` — Minimal Data Container

**Date**: 2026-08-21  
**Status**: Decided  
**Category**: API Design / Component Reuse

### Context

Three M3 components need to represent list items: `LayrzRadioInput`, `LayrzComboBoxInput`, and `LayrzSelectInput`. A shared item type would unify the three and simplify documentation.

### Decision

**Introduce `LayrzSelectItem<T>` as a shared container:**

```dart
class LayrzSelectItem<T> {
  final String labelText;
  final T? value;
  final Widget? child;
  final Set<String> searchableAttributes;
}
```

Consumed by `LayrzRadioInput`, `LayrzComboBoxInput`, and `LayrzSelectInput`.

### Rationale

**Responsibility split: rendering vs. identity**. The design system owns search and the field's display text. The consumer owns row rendering via `child`. If `child` is null, the field renders `labelText` as a fallback.

**`labelText` is always required** because search and the collapsed field display both depend on it, even when `child` is supplied.

**Dropped from layrz_theme:** `icon`, `leading`, `content`, `onTap`, `isRemoved`, and a proposed `Color? color` field. Follows D27/D28 trimming pattern.

**`searchableAttributes`** defaults to `{labelText}`, allowing custom search hints (e.g., a contact item can include a phone number in search even if the row only shows the name).

### Consequences

- New shared type `LayrzSelectItem<T>` exported from `lib/layrz_ui.dart`
- Three M3 components consume it consistently
- No per-component item duplication

---

## D54: Checkbox and Switch Are Separate Components

**Date**: 2026-08-21  
**Status**: Decided  
**Category**: Component Design / Code Organization

### Context

`ThemedCheckboxInput` in layrz_theme supported four styles, cramming two semantically different inputs (checkbox vs. toggle) and three style variants into one component.

### Decision

**Implement two separate components**: `LayrzCheckboxInput` and `LayrzSwitchInput`.

**Dropped styles:**
- `asCheckbox2` (design-refresh duplicate)
- `asField` (callers use `LayrzSelectInput<bool>` instead)

**Scope:** Boolean only; tristate is not supported. Labels are trailing and tappable.

### Rationale

**One concern per file**. A checkbox and a switch share no paint code. One file holding both violates single-responsibility for no practical gain. Splitting makes each component's intent clear.

**`asField` drops cleanly**. It was `LayrzSelectInput<bool>` with hardcoded Yes/No labels. Callers can compose their own once `LayrzSelectInput` lands.

**Interaction state compliance (D15)**. Both vary only colour and opacity on hover/press/focus; size and padding never change. Tests explicitly assert this.

**Accessibility (WCAG 1.4.1)**. State is not colour-only:
- Checkbox: checkmark glyph when checked
- Switch: thumb position (left/right)

### Consequences

- `LayrzCheckboxInput` and `LayrzSwitchInput` are separate exports
- No tristate checkbox
- No style variants

---

## D55: Multiline Text Is a Sibling Component Over Shared Chrome

**Date**: 2026-08-21  
**Status**: Decided  
**Category**: API Design / Component Architecture

### Context

Supporting multiline in `LayrzTextInput` would require either widening its public API (breaking DESIGN-33's review scope) or creating a separate component. `LayrzTextInput` ships in 0.0.12 awaiting team review.

### Decision

**`LayrzTextAreaInput` is a sibling widget over shared input chrome, not a mode of `LayrzTextInput`.**

**`LayrzTextInput`'s public API remains byte-identical to 0.0.12.**

**Shared plumbing extracted into library-private modules:**
- `LayrzEditableField` (not exported): encapsulates text selection controls and magnifier config
- `LayrzInputChrome.variableHeight`: aligns the trailing cluster to the **top** of tall fields instead of vertically centring

### Rationale

**Preservation of review scope**. DESIGN-33 is already under review; widening its public surface would change the component being reviewed. Deferring multiline to DESIGN-34 keeps reviews coherent.

**Code reuse without duplication**. Duplicating ~600 lines of text-selection wiring introduces drift risk. Extracting shared plumbing allows both to use it without exposing an intermediate API.

### Consequences

- New `LayrzTextAreaInput` component (DESIGN-34)
- Defaults: `minLines: 3`, `maxLines: 10`, then scrolls
- **No change to `LayrzTextInput`'s public API**
- Two new private types not exported

---

## D56: `LayrzSearchInputMode` — Inline and Overlay Forms

**Date**: 2026-08-21  
**Status**: Decided  
**Category**: API Design / Responsiveness

### Context

`ThemedSearchInput` supported two presentations via a boolean flag, forcing every consumer to implement responsive logic themselves with `LayoutBuilder`.

### Decision

**Introduce `LayrzSearchInputMode` enum:**

```dart
enum LayrzSearchInputMode { field, icon, auto }
```

- `field`: inline `LayrzTextInput` with magnifier prefix, × clear suffix
- `icon`: magnifier button that opens an anchored overlay
- `auto`: selects between them based on available space (default)

### Rationale

**Enum over boolean**. Aligns with D27/D28 trimming of style parameters. The `auto` member lets the component decide for the caller.

**Computed from constraints**. Overlay direction is computed from available space, not declared. Like D52, overlay position is flexible.

**Position parameter dropped**. layrz_theme's `position { left, right }` is not ported because direction is computed, and layrz_theme already overrode declared positions that did not fit.

### Consequences

- New `LayrzSearchInputMode` enum exported
- No `asField` boolean or `position` parameter
- Icon mode available for dense toolbars

---

## D57: `LayrzStepper` Owns the Whole Flow

**Date**: 2026-08-21  
**Status**: Decided  
**Category**: Component Design / Scope

### Context

This row's spec raised a critical question: does the widget render only the step header or own the whole flow (header + body + actions)?

### Decision

**`LayrzStepper` owns the whole flow** — header, current step body, and back/next actions.

**`LayrzStep` is a data class carrying `label`, `body`, and `state`.**

**Plus a controller**: `LayrzStepperController` allows programmatic navigation. Follows established conventions: never swapped, and disposed only if created by the widget.

### Rationale

**Header-only was the recommendation and was overruled deliberately.** A full stepper is heavier but bakes in navigation layout. Consumers needing custom actions can request escape hatches later.

**Scope trims (D27/D28):**
- Horizontal only
- Step states: `upcoming / active / completed / error` (not Material's full set)
- Below `md` breakpoint, header collapses to *"Step X of Y"* instead of scrolling

**Accessibility (WCAG 1.4.1)**. Completed steps carry `MdiIcons.check`, errors carry `MdiIcons.alertCircle`. State is never colour-only.

### Consequences

- `LayrzStepper` ships with full flow ownership
- `LayrzStep` is a simple data class
- `LayrzStepperController` required for navigation
- Responsive header collapse below `md`

---

## D58: Responsive Option Grids Use `LayrzCol` Integer Spans

**Date**: 2026-08-21  
**Status**: Decided  
**Category**: API Design / Grid System

### Context

This row's spec defined responsive layout using a `Sizes` enum. However, **decision D9 deleted the `Sizes` enum**, making the spec unbuildable.

### Decision

**Radio/checkbox grid layouts use per-breakpoint `int` spans (1–12), mirroring `LayrzCol`'s API:**

```dart
LayrzRadioInput<T>(
  xs: 12,  sm: 6,  md: 4,  lg: 3,  xl: 2,
  items: [...],
  onChanged: (v) => …,
)
```

Layout uses the real `LayrzRow` + `LayrzCol`, not a reimplementation.

### Rationale

**Vocabulary consistency**. `LayrzCol` already implements cascading fallback. Reusing its parameter names means one concept for developers, not two.

**Avoid boilerplate**. A single `columns: int` parameter forces callers to hand-roll responsiveness. Per-breakpoint spans let the component handle it.

**No new enum**. Introducing a `Columns` enum would duplicate cascade logic and risk divergence.

### Consequences

- `LayrzRadioInput` takes `xs: 12` (non-nullable), `sm/md/lg/xl` (nullable, cascade)
- Grid layout uses actual `LayrzRow` and `LayrzCol` children
- Follow-through on D9 (deleting Sizes)

---

## D59: Combobox Free-Form Entry Is Opt-Out

**Date**: 2026-08-21  
**Status**: Decided  
**Category**: API Design / Feature Scope

### Context

`LayrzComboBoxInput` is editable (unlike `LayrzSelectInput`, which is read-only). Should typed values be valid by default, or should the field lock to the options list?

### Decision

**Free-form entry is the default. Set `allowFreeForm: false` to lock to options.**

When `allowFreeForm: true`: Any typed text is valid, submitted on Enter or blur. Overlay is a suggestion aid.

When `allowFreeForm: false`: Field reverts to the last matching option on blur.

### Rationale

**Free-form is the reason combobox exists separately from select.** If locked-to-options was the design, `LayrzSelectInput` already handles that. Free-text is what combobox adds, so it is the default.

**Opt-out rather than opt-in**. Making free-form require an explicit flag would force the typical case to be opt-in, which is backwards.

### Consequences

- `LayrzComboBoxInput` ships with `allowFreeForm: true` by default
- Invalid typed values (when `allowFreeForm: false`) revert on blur without error

---

## D60: Duration Units Are Configurable and Capped Per Unit

**Date**: 2026-08-21  
**Status**: Decided  
**Category**: Component Design / Data Modeling

### Context

`LayrzDurationInput` must convert between user-visible UI and Dart's fixed-length `Duration` type. Which units should be visible, how should they map to Duration, and what are the bounds?

### Decision

**Units are configurable:**
- `visibleUnits: {day, hour, minute, second}` defaults to all four
- Each unit is **capped to its natural range**: hour 0–23, minute 0–59, second 0–59, day unbounded

**Result: exactly one field representation per `Duration`.**

### Rationale

**Capped ranges give a unique representation**. Uncapped (e.g., allow minute: 90) makes the mapping ambiguous: two different field states represent the same Duration. Capping ensures exactly one representation.

**No year/month/week support**. These are not fixed-length and cannot map onto `Duration`. Callers who want any number of minutes use `LayrzNumberInput` and construct `Duration` themselves.

### Consequences

- New `LayrzDurationInput` component (DESIGN-44)
- New `LayrzDurationUnit { day, hour, minute, second }` enum
- Per-unit field capping
- Surface: anchored overlay on desktop, `LayrzBottomSheet` below `md` (D52)

---

## D61: M3 Scope Trim — MultiSelect and DualList Move to M4

**Date**: 2026-08-21  
**Status**: Decided  
**Category**: Release Planning / Scope Management

### Context

The original M3 scope included DESIGN-41 `LayrzMultiSelectInput` and DESIGN-43 `LayrzDualListInput`. Both would consume M3 picker-surface decisions. However, M3 is already at 9 rows + 1 prerequisite, and adding two more risks the release.

### Decision

**Move DESIGN-41 and DESIGN-43 to M4 (Pickers).**

M3 ships with: 8 input components, 1 stepper, and supporting work (bottom sheet, anchored panel, select item).

### Rationale

**M3 scope is at the limit**. 9 components + 1 prerequisite is already substantial. Adding 2 more would stretch testing and review.

**No architectural blocker**. Both would build on top of existing M3 decisions. Deferring them does not require rework.

**Better released than rushed**. M3 ships solid and ready for review; M4 absorbs the pickers without tight deadline.

### Consequences

- DESIGN-41 `LayrzMultiSelectInput` → M4
- DESIGN-43 `LayrzDualListInput` → M4
- M3 scope: 9 input/surface rows + 1 prerequisite
- 0.0.13 does not include multi-selection inputs

---

## D62: Remove Flutter Widget Preview System

**Date**: 2026-08-22  
**Status**: Decided  
**Category**: Build System / Developer Experience

### Context

Flutter 3.47 introduced the stable `@Preview` widget-preview API. Early in layrz_ui development, this system was adopted to enable quick preview of widgets without launching a device. However:

1. The preview system adds build complexity (`flutter/widget_previews.dart`, `LayrzPreviewTheme`, `.widget_preview/` project).
2. Maintenance burden: every visual widget needs a corresponding preview function.
3. Low adoption: the team rarely uses widget previews during development; device testing is the primary workflow.
4. Minimal productivity gain: previews save time only for isolated components; most work involves integration testing across the app.

### Decision

**Remove the entire Flutter widget-preview system from layrz_ui.**

- Delete all `@Preview` annotations from widgets
- Delete all preview functions and dedicated preview files (`*_previews.dart`, `*_preview.dart`)
- Delete the `lib/src/preview/` module and `lib/preview.dart` barrel
- Delete the `.widget_preview/` project
- Remove preview-related imports (`package:flutter/widget_previews.dart`, `package:layrz_ui/preview.dart`)
- Update documentation (CLAUDE.md, engineering docs)

### Rationale

**Complexity vs. benefit**: The preview system adds real complexity (import decisions, test harnesses, a separate Flutter project) for limited practical return. Development workflow is device-based; static previews do not accelerate that.

**Maintainability**: Removing the system eliminates an entire category of maintenance (keeping `LayrzPreviewTheme` aligned with the real theme, documenting preview patterns, ensuring preview functions are updated when widgets change).

**SDK floor unchanged**: The decision to remove `@Preview` does not affect the Flutter 3.47 floor — `RawTooltip`, `RawMenuAnchor`, and `RawRadio` remain hard requirements that justify staying on 3.47+.

### Consequences

- 10+ preview test files removed (minor coverage reduction; no behavioral tests lost)
- 14 dedicated preview files deleted
- 54 `@Preview` annotations and related functions removed
- CLAUDE.md rule #3 removed entirely
- Decision D18 (preview.dart placement rationale) remains in history, marked as superseded
- `.widget_preview/` and all its contents removed from the repository
- Documentation updated to reflect no preview system
- SDK constraint section revised (no mention of `@Preview` API requirement)

---

## D63: No Input Wraps Another Input — Every Field Composes `LayrzInputChrome` Directly

**Date**: 2026-08-23  
**Status**: Decided  
**Category**: API Design / Component Architecture

### Context

An audit of `development` @ `b639d2a` on 2026-08-23 examined how all ten M3 input components obtain their visual chrome (border, label, help text, error state, prefix/suffix slots). Three compositions exist:

- **Uses `LayrzInputChrome` directly (4)**: `LayrzTextInput` (`text_input.dart:375`), `LayrzTextAreaInput` (`textarea_input.dart:390`, `.variableHeight` — see D55), `LayrzSelectInput` (`select_input.dart:331` desktop / `:426` mobile), `LayrzDurationInput` (`duration_input.dart:288` / `:354`).
- **Wraps another input (3)**: `LayrzSearchInput` (`search_input.dart:223`), `LayrzComboBoxInput` (`combobox_input.dart:480`), `LayrzNumberInput` on its `hideStepButtons=true` path (`number_input.dart:561`).
- **Neither — control with a label, not a field (3)**: `LayrzRadioInput`, `LayrzCheckboxInput`, `LayrzSwitchInput`.

The wrapping pattern is not hypothetical risk — it has already produced three concrete defects:

1. **`LayrzNumberInput` accepts `errors` and never forwards it** on the `hideStepButtons=true` path (`number_input.dart:561`). The identical defect was already found and fixed on the *other* path of the same `if`, after the maintainer saw it on a physical device: the chrome painted a red border and danger-tinted caps while the field interior stayed neutral grey. One widget, two architectures, and the bug survived in the branch nobody looked at.
2. **`LayrzSearchInput` cannot show an error at all** — it does not accept `errors`, `isRequired`, or help text, and never sets `readOnly` (`search_input.dart`, constructor).
3. **`LayrzNumberInput` is the only input that duplicates the chrome's border**, rebuilding it in an outer `Container` (`number_input.dart:618-620`) because it needed step buttons at the sides and wrapping left it no way to place them there. It is the sole real visual duplication in the module — the borders in `checkbox_input.dart:257-260` and `radio_option.dart:202-207` are the *control glyph's* border (the checkbox box, the radio circle), not field chrome, and are not duplication of this kind.

### Decision

**No input widget wraps another input widget. Every input composes its own (editing primitive + `LayrzInputChrome`) pair directly.**

`LayrzInputChrome` is the shared visual layer for inputs that are *fields*. An input must never obtain its chrome by wrapping a sibling input, because the wrapper then inherits chrome it cannot control and must forward every property by hand — and, as the evidence above shows, forwarding is where properties get dropped.

**Explicitly excluded from this rule**: `LayrzCheckboxInput`, `LayrzSwitchInput`, `LayrzRadioInput`. These are controls with a label, not bordered fields — they own their visual state deliberately, and forcing them through `LayrzInputChrome` would impose a field shape they do not have. This exclusion is a deliberate part of the decision, not an omission: it exists to be found by whoever later reads "no input wraps another input" as universal and goes looking for a fourth migration.

### Rationale — undeclared coupling, and why now

The primary reason for this decision is **blast radius, not flexibility**. As the maintainer put it:

> "Lo que no quiero es, si el día de mañana necesitamos cambiar el TextInput por X o Y, no rompa el resto de inputs." — *(What I don't want is: if tomorrow we need to change the TextInput for whatever reason, that it breaks the rest of the inputs.)*

Wrapping creates coupling that nothing in the codebase declares. `LayrzTextInput` is not just a widget here — it is a de facto base class for `LayrzSearchInput`, `LayrzComboBoxInput`, and `LayrzNumberInput`'s `hideStepButtons=true` path (see Context above), without that relationship being stated anywhere or enforced by anything. A change to `text_input.dart` therefore has a blast radius of four widgets, and the three downstream ones are only discovered by whoever happens to break them.

That coupling shows up as **silent property drift, not compile errors** — the defects in Context are exactly this: `number_input.dart:561` accepts `errors` and never forwards them; `LayrzSearchInput` never accepted `errors`, `isRequired`, or help text at all. Neither failure failed a build. One shipped and was found on a physical device. Composition against a stable, minimal editing primitive bounds the blast radius: each input owns its own chrome and its own forwarding, so a change to one input's chrome cannot leak into another.

**This is not hypothetical — it is the next scheduled change to this file.** DESIGN-141 is already specified and will add `hint`, `tooltip`, and a required-indicator `label` to `LayrzTextInput`'s `Semantics` node. Under the current (wrapping) architecture, that change propagates automatically into `LayrzSearchInput` and `LayrzComboBoxInput` because they wrap it — and it would land on top of an unresolved contradiction about whether those two already double-announce their semantics: an audit says they do, while a passing test on `combobox_input_a11y_test.dart` says the label is announced exactly once. Landing DESIGN-141 before this migration means shipping a semantics change into that unresolved contradiction, in three widgets at once instead of one.

**Sequencing constraint: DESIGN-142 (this migration) must land before DESIGN-141.** DESIGN-141's `Semantics` change should touch exactly one widget, which is only true once `LayrzSearchInput` and `LayrzComboBoxInput` no longer wrap `LayrzTextInput`. This is the more expensive ordering — DESIGN-142 is the larger piece of work, since it requires the editing-core extraction and the public-API decision that follows from Dart's per-library privacy (see Consequences below) — but the alternative is landing 141's change three times, on a wrapping architecture this decision is retiring anyway.

M3 Inputs is largely built; **M4 Pickers is entirely ahead** (D61), and it supplies a secondary, supporting reason to settle this now rather than later. Every picker is field-shaped: a non-editable or semi-editable field with a trailing affordance that opens a panel, and typically wanting both an identifying glyph and a clear action.

The two existing inputs closest to that shape — `LayrzSelectInput` and `LayrzDurationInput` — **already use `LayrzInputChrome` directly, and are the healthy ones.** The one input that needed a control at its side (`LayrzNumberInput`'s step buttons) took the wrapping route instead and had to duplicate the border to place them. M4 is roughly a dozen pickers with that same requirement — an identifying glyph plus a trailing action — so the pattern is worth settling now, on three migrations, rather than discovering it midway through twelve. Going through the chrome directly keeps its prefix/suffix slots available to each picker and leaves room for a trailing action button — flexibility that wrapping a text input forecloses, because the wrapper only ever sees what the wrapped input's own constructor chose to expose. Unlike the coupling argument above, this reason is temporary: M4 ends, and it does not restate the decision's rationale after M4 ships.

### Scope

**In scope — 3 inputs to migrate:**
- `LayrzSearchInput` (currently wraps, `search_input.dart:223`)
- `LayrzComboBoxInput` (currently wraps, `combobox_input.dart:480`)
- `LayrzNumberInput`'s `hideStepButtons=true` path (currently wraps, `number_input.dart:561`)

**Explicitly out of scope — `LayrzCheckboxInput`, `LayrzSwitchInput`, `LayrzRadioInput`.** See the exclusion above; do not read this decision as calling for their migration.

### Consequences

- **Known prerequisite**: for `LayrzSearchInput` and `LayrzComboBoxInput` to compose `LayrzInputChrome` directly, the text-editing core of `LayrzTextInput` must be extractable without its chrome. Dart privacy is per-library (per-file, absent `part`), so extracting that core into its own file means it **cannot remain underscore-private** — it becomes public API needing a name and documentation, or the extraction uses `part`. This already cost a round with `NumberFieldControl`; this decision creates that API-surface question for the text core and does not itself settle it.
- `LayrzNumberInput`'s outer-`Container` border duplication (`number_input.dart:618-620`) is retired once its `hideStepButtons=true` path is migrated; step buttons become a chrome-native affordance instead of an outer wrapper.
- `LayrzSearchInput` gains `errors`, `isRequired`, help text, and `readOnly` support as a direct consequence of going through the chrome — not as separate follow-up work.
- Three inputs' migrations are tracked as the concrete deliverable of this decision; see the M4 Pickers milestone for scheduling.

### Open Question

Whether `LayrzInputChrome`'s single `suffixSlot` + `onSuffixTap` can carry **two** trailing affordances at once — a picker's identifying glyph *and* a clear button — or whether the chrome needs an explicit action slot separate from suffix. This is left open, to be settled during the migration rather than during M4 planning.

### Review Trigger

After the three in-scope migrations ship, confirm the open question above is resolved one way or the other before M4 Pickers begins consuming `LayrzInputChrome`, so no picker has to guess at a slot contract still in flux.

### Amendment (2026-08-24) — NumberInput Scope Corrected; Outer Border Stays; Acceptance Criterion Reworded

Three corrections, found during DESIGN-142 implementation and settled by the maintainer.

**1. Scope was wrong about `LayrzNumberInput`.** The Context and Scope sections above name only the `hideStepButtons=true` path (`number_input.dart:561`) as wrapping, which implies the step-button path (`:641`) already composed the chrome directly. It did not — **both branches wrapped `LayrzTextInput`**, and the selector at `:499` is `!hideStepButtons && !disabled`, so `disabled: true` routed through the `:561` path too, regardless of `hideStepButtons`. That is **three configurations**, not two, and all three wrapped before this migration.

**2. The outer `Container` border does NOT retire — this decision's Consequences was wrong to say it would.** Consequences originally stated: *"`LayrzNumberInput`'s outer-`Container` border duplication (`number_input.dart:618-620`) is retired once its `hideStepButtons=true` path is migrated; step buttons become a chrome-native affordance instead of an outer wrapper."* This was never coherent with Scope as written — the outer `Container` exists only on the step-button path, which the original Scope excluded. Independent of that internal contradiction, **the maintainer ruled during implementation that the outer `Container`, its border, and the full-height step caps are intended design, not duplication, and they stay.** That consequence is **withdrawn**, not deferred. `LayrzNumberInput` migrated all three configurations onto `LayrzInputChrome` directly (`develop` @ `a86644a`), and the outer border and caps render exactly as before.

   One more pre-existing, deliberately-unfixed detail worth recording here so nobody "fixes" it later: the outer `Container` and the chrome it now contains both paint `spec.backgroundColor` — a double *fill*, not a double border. It is invisible (same opaque colour resolved from the same spec) and left alone.

**3. Acceptance criterion 1 was too literal.** As written — *"No widget under `lib/src/inputs/` constructs another `Layrz*Input`"* — it fails a mechanical grep even after a correct migration, because two compositions construct an input from inside another input's **panel surface**, not by wrapping for chrome:
   - `lib/src/inputs/src/select/select_input_surface.dart:175` — a `LayrzTextInput` used as the search box inside the select picker's panel.
   - `lib/src/inputs/src/duration/duration_picker_panel.dart:95,119,145,171` — four `LayrzNumberInput`s used as the day/hour/minute/second spinners inside the duration picker's panel.

   Both are the same category of deliberate exclusion this decision already carves out for `LayrzCheckboxInput`/`LayrzSwitchInput`/`LayrzRadioInput`: a control embedded in a panel, not chrome obtained by wrapping. The criterion now reads:

   > No input widget obtains its visual chrome by wrapping another input widget. (Exclusions: `LayrzCheckboxInput`, `LayrzSwitchInput`, `LayrzRadioInput` — controls, not fields, per the Decision above; `select_input_surface.dart:175` and `duration_picker_panel.dart:95,119,145,171` — inputs embedded inside a panel surface, not chrome inherited by wrapping.)

   Named explicitly so the next reader does not "find" a fifth or sixth migration that was never in scope.

