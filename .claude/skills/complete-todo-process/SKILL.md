---
name: complete-todo-process
description: Finish a unit of work started with start-todo-process — verifies analyze/tests/format, opens the PR, merges it, confirms the linked issues closed and the board moved to Done, updates the milestone Status table, and cleans up the branch. Use when the user says "finish this", "complete the todo", "/complete-todo-process", or work on the current branch is ready to land.
---

# Complete Todo Process

Lands the work: PR, merge, issues closed, board on **Done**, milestone doc updated, branch cleaned up.

## Project constants (verified 2026-08-13)

| Thing | Value |
|---|---|
| Org / project number | `goldenm-software` / **9** |
| Project ID | `PVT_kwDOAtlVQs4BgRmo` |
| Repository | `goldenm-software/layrz_ui` (**public**) |
| Status field ID | `PVTSSF_lADOAtlVQs4BgRmozhaeejQ` |
| Status options | Todo `f75ad846` · In Progress `47fc9ee4` · Done `98236657` |
| Base branch for PRs | `development` |
| Branch protection | **none on `main` or `development`** (both return 404) |
| Merge methods | merge commit, squash and rebase all allowed |
| Auto-delete branch on merge | **off** — delete manually |

## Critical facts — do not assume otherwise

- **You cannot approve your own pull request.** GitHub refuses an approving review from the PR author; `gh pr review --approve` on your own PR fails, with no admin override. **Do not attempt it, and never claim the PR was approved.** Because this repo has no branch protection, approval is not required to merge — so skip the step and say why.
- **Nothing is guarding these branches.** No required reviews, no required status checks, force-push and deletion permitted on both `main` and `development`. The checks in step 1 are the only gate. Run them properly.
- **`Closes #N` in the PR body is what closes the issue.** Do not close issues as a separate step; let the merge do it, then verify.
- **Do not trust board automation blindly.** *Item closed* and *Pull request merged* workflows are enabled, but the API does not expose which value each sets. **Always verify Status after merging and set it explicitly if it did not move.**
- **This repo tracks progress in two places.** Per `CLAUDE.md`, the GitHub Project *and* the milestone document's Status table must both be updated in the same cycle.

## Steps

### 1. Verify the work is finishable
Run these and **show the output**:
```bash
flutter analyze                                              # must be ZERO issues
flutter test                                                 # must be fully green
dart format -o none --set-exit-if-changed lib/ test/ example/lib/ example/test/
grep -rn "package:flutter/material\|package:flutter/cupertino" lib/ example/lib/   # MUST be empty
grep -rn "TextTheme()" lib/                                  # MUST be empty (no GoogleFonts.*TextTheme)
cd example && flutter analyze && flutter test && flutter build linux --debug
```
Note `-o none` on the format check — plain `--set-exit-if-changed` **rewrites files** instead of just checking. The repo formats at `page_width: 120` from `analysis_options.yaml`; never pass `--line-length`.

**If anything fails, stop.** Do not open a PR on red.

### 2. Confirm tree and branch state
```bash
git status --short          # must be clean; if not, run /commit first
git branch --show-current   # must not be main or development
```
Never commit here — use the `/commit` skill.

### 3. Identify the linked issues
Work out which issues this closes, from the branch name or the user. Confirm each is **open** and its project Status is **In Progress**. If one is already closed, flag it and ask before proceeding.

### 4. Push and open the PR
```bash
git push -u origin $(git branch --show-current)
```
Open it with the `/pr` skill — **never `gh pr create` directly when `/pr` is available**. The body needs a `Closes #N` line for **every** issue in the batch, each on its own line. Base is `development` unless the user says otherwise.

### 5. Skip approval, explicitly
State that self-approval is impossible, and that no protection rule requires a review here. Do not fake it.

### 6. Merge
**Confirm with the user before merging** unless they already said to land it — merging is outward-facing and hard to undo. Prefer squash for a single-purpose branch. Never `--admin`, never force push.

### 7. Verify the outcome — the step that gets skipped
Do not report success until all of it checks out:
- Every `Closes #N` issue is **closed** with state reason `completed`.
- Every project item's Status is **Done**. **If automation did not move it, set it explicitly** (option `98236657`) and say that you had to.
- The PR shows merged into `development`.
- `development` contains the commits.

### 8. Update the milestone Status table
Set the matching row in `engineering/milestone-N.md` to `Done`. This is required — `CLAUDE.md` mandates progress in both the board and the docs. Commit that doc change (via `/commit`) as part of the cycle. **Plain table cells only — no checkboxes anywhere.**

### 9. Clean up
```bash
git checkout development && git pull
```
Delete the merged branch locally and remotely (auto-delete is off), but only after confirming the merge landed, and only if the user has not asked to keep it.

### 10. Report
- PR number, URL, and what it merged into.
- Each issue: number, closed, Status Done — and whether Status moved automatically or you set it.
- The milestone table row updated.
- Whether the branch was deleted.
- Anything that did not go to plan.

## Rules
- Delegate `gh` to the `gestor` agent and `git` to `chismoso`.
- Never use `--no-verify`. If a hook fails, fix the cause and make a NEW commit — never amend.
- Never force push unless explicitly asked.
- Do not fabricate an approval, and do not describe a merge as "reviewed" when nobody reviewed it.
