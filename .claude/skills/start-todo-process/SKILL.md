---
name: start-todo-process
description: Start work on one or more layrz_ui GitHub Project items — converts each draft item to a real Issue, sets its Status to In Progress, and creates the working branch. Use whenever the user says "start work on X", "let's do X", "/start-todo-process X", or picks a component off the board to begin.
---

# Start Todo Process

Turns board items into an active unit of work: real Issues, Status moved to **In Progress**, and one branch to work on.

## Project constants (verified 2026-08-13)

| Thing | Value |
|---|---|
| Org / project number | `goldenm-software` / **9** |
| Project ID | `PVT_kwDOAtlVQs4BgRmo` |
| Repository | `goldenm-software/layrz_ui` (**public**) |
| Repository ID | `R_kgDOSnMwYg` |
| Status field ID | `PVTSSF_lADOAtlVQs4BgRmozhaeejQ` |
| Status options | Todo `f75ad846` · In Progress `47fc9ee4` · Done `98236657` |
| Integration branch | `development` (default branch is `main`) |

Re-query if any ID is rejected — they change if the field is recreated:
```bash
gh api graphql -f query='
query{ organization(login:"goldenm-software"){ projectV2(number:9){
  id
  fields(first:50){ nodes{ ... on ProjectV2SingleSelectField { id name options{ id name } } } }
}}}'
```

## Critical facts — do not assume otherwise

- **Nothing sets Status to In Progress automatically.** The six enabled workflows on this project are *Auto-add sub-issues*, *Auto-close issue*, *Item added to project*, *Item closed*, *Pull request linked to issue*, and *Pull request merged*. **None of them sets In Progress.** This skill MUST set it explicitly, or the board silently stays on Todo while work is underway.
- **Converting a draft to an Issue is irreversible.** There is no "convert back". Only convert items actually being started.
- **This project has a corruption history.** A previous concurrent run duplicated one item three times and attached bodies to the wrong components. **Operate on one item at a time, sequentially, verifying each before moving on. Never in parallel, never in a background job.**
- Custom fields (Phase, Domain, Primitive, Blocker) survive conversion — but verify rather than trust.

## Steps

### 1. Identify the target item(s)
Take them from the user's arguments. If none were given, ask which item(s) to start — do not guess.

Multiple items in one invocation are **one unit of work**: they share a single branch, and the eventual PR closes all their issues. Separate branches means separate invocations — say so rather than inventing a multi-branch scheme.

### 2. Per item, sequentially
For each target, one at a time:

1. Locate the project item by title; confirm exactly one match. If ambiguous or missing, **stop and ask** — do not convert the wrong item.
2. If still a **draft**, convert with `convertProjectV2DraftIssueItemToIssue` (item id + repository id). If already an Issue, skip and say so.
3. **Set Status to In Progress** (`updateProjectV2ItemFieldValue`, option `47fc9ee4`). Nothing does this for you.
4. Re-fetch and verify: it is an Issue with a number, title and body intact, Phase / Domain / Primitive / Blocker unchanged.
5. Only then move to the next item.

### 3. Create the branch
```bash
git status --short            # must be clean; if not, stop and ask
git checkout development
git pull
git checkout -b {type}/{module}/{brief-name}
```
Naming is `{type}/{module}/{brief-name}` — types `feat`, `fix`, `chore`. Derive `module` from the item's **Domain** field (Buttons → `buttons`, Inputs → `inputs`, Foundation → `foundation`). For a batch, pick a name covering it and say what you chose.

**Ask before creating the branch** unless the user already named one — never auto-create without confirmation.

### 4. Report
- Each item: title → issue number → URL → Status now In Progress.
- The branch created and its base.
- The exact `Closes #N` lines the eventual PR will need, ready to copy.
- Anything skipped and why.

## Rules
- Delegate `gh` to the `gestor` agent and `git` to `chismoso`.
- **Never bulk-convert items that are not being started** — only the named targets. Shipped work is the one exception and it is already done (see D16).
- Never force push. Never use `--no-verify`.
- No checkboxes or progress markers in issue bodies — the Status field and issue state carry progress.
- On any mid-batch failure, **stop and report exactly which items converted and which did not.** Do not continue past a failure, and do not attempt a cleanup that could destroy data.
