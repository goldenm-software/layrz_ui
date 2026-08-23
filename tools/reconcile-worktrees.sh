#!/usr/bin/env bash
#
# reconcile-worktrees.sh
#
# WHY THIS EXISTS
#   In the agent-teams pipeline, implementer agents are spawned into their own
#   git worktree under .claude/worktrees/agent-<id>/. The failure mode this
#   script defends against: an agent finishes work but exits WITHOUT reporting
#   it, so the orchestrator never learns the work exists. Two cases, in
#   priority order:
#
#     1. Uncommitted changes inside a live worktree — UNRECOVERABLE if that
#        directory is later deleted or pruned. Highest priority.
#     2. Commits on a branch that were never merged into the integration
#        branch and never reported — recoverable, but easy to miss.
#
#   This script enumerates every worktree, flags both situations, and prints
#   a summary so nothing goes unnoticed before a worktree is cleaned up.
#
# THIS SCRIPT IS STRICTLY READ-ONLY.
#   It must NEVER run a mutating git command. Specifically forbidden:
#   `worktree prune`, `worktree remove`, `branch -d`/`-D`, `checkout`,
#   `switch`, `reset`, `clean`, `stash`, `commit`, `merge`, `rebase`, `push`,
#   `gc`. Only read-only commands are used: `worktree list`, `status
#   --porcelain`, `rev-list`, `rev-parse`, `log`, `branch --list`,
#   `diff --stat`. Do NOT add cleanup/pruning logic to this file — if
#   automated cleanup is ever wanted, it belongs in a separate, explicitly
#   named script so a read-only audit tool never grows a destructive side
#   effect by accident.
#
# USAGE
#   tools/reconcile-worktrees.sh [repo-path] [--base <ref>]
#
#   repo-path   Path to the git repository to inspect.
#               Defaults to /home/mochi/Projects/layrz_ui.
#   --base ref  Integration branch to diff unmerged commits against.
#               Defaults to "development", falling back to "main" if
#               "development" does not exist locally. If neither exists,
#               the script reports that explicitly instead of silently
#               treating every worktree as fully merged.
#
# EXIT CODES
#   0   No findings: every non-skipped worktree is clean and fully merged.
#   1   At least one finding (uncommitted changes and/or unmerged commits),
#       or a fatal setup error (bad repo path, no base ref available).
#       This makes the script usable as a CI/pipeline gate.
#
set -euo pipefail

# Repo path, defaulting to the layrz_ui checkout this tool was written for.
REPO_PATH="/home/mochi/Projects/layrz_ui"
# Integration branch findings are compared against; resolved in resolve_base_ref.
BASE_REF_OVERRIDE=""

## parse_args
## Parses the optional positional repo path and the optional --base flag.
## Leaves the results in the REPO_PATH and BASE_REF_OVERRIDE globals.
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --base)
        if [[ $# -lt 2 ]]; then
          echo "error: --base requires an argument" >&2
          exit 1
        fi
        BASE_REF_OVERRIDE="$2"
        shift 2
        ;;
      -h|--help)
        sed -n '2,45p' "$0"
        exit 0
        ;;
      *)
        REPO_PATH="$1"
        shift
        ;;
    esac
  done
}

## resolve_base_ref
## Determines which local branch unmerged commits are measured against.
## Honors --base if given; otherwise prefers "development", falling back to
## "main". Exits with an error if none of those refs exist locally, rather
## than silently reporting zero unmerged commits everywhere.
## Echoes the resolved ref name on success.
resolve_base_ref() {
  local repo="$1"
  local candidate

  if [[ -n "$BASE_REF_OVERRIDE" ]]; then
    if git -C "$repo" rev-parse --verify --quiet "$BASE_REF_OVERRIDE" >/dev/null; then
      echo "$BASE_REF_OVERRIDE"
      return 0
    fi
    echo "error: --base ref '$BASE_REF_OVERRIDE' does not exist in $repo" >&2
    exit 1
  fi

  for candidate in "development" "main"; do
    if git -C "$repo" rev-parse --verify --quiet "$candidate" >/dev/null; then
      echo "$candidate"
      return 0
    fi
  done

  echo "error: neither 'development' nor 'main' exists locally in $repo -- cannot compute unmerged commits" >&2
  exit 1
}

## Field separator used between the parsed record's columns. Deliberately
## NOT a tab: bash's `read` treats tab as "IFS whitespace" and silently
## collapses consecutive tabs into one delimiter (even with IFS set to a
## single tab character), which drops the empty `branch` field on a detached
## worktree and shifts every flag after it out of alignment. The ASCII unit
## separator (0x1F) is an ordinary character to `read`, so empty fields
## round-trip correctly.
readonly FIELD_SEP=$'\x1f'

## parse_worktree_porcelain
## Reads `git worktree list --porcelain` output from stdin and prints one
## record per line, columns joined by FIELD_SEP: path, head, branch, flags.
## flags is a comma-separated subset of {bare,detached,locked,prunable}.
## branch is empty for a detached worktree. Records in the porcelain format
## are separated by a blank line, so a blank line flushes the current record.
parse_worktree_porcelain() {
  local path="" head="" branch="" flags=""
  local line key value

  flush_record() {
    if [[ -n "$path" ]]; then
      printf '%s%s%s%s%s%s%s\n' \
        "$path" "$FIELD_SEP" "$head" "$FIELD_SEP" "$branch" "$FIELD_SEP" "$flags"
    fi
    path="" head="" branch="" flags=""
  }

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then
      flush_record
      continue
    fi
    key="${line%% *}"
    value="${line#"$key"}"
    value="${value# }"
    case "$key" in
      worktree) path="$value" ;;
      HEAD) head="$value" ;;
      branch) branch="${value#refs/heads/}" ;;
      bare) flags="${flags:+$flags,}bare" ;;
      detached) flags="${flags:+$flags,}detached" ;;
      locked) flags="${flags:+$flags,}locked" ;;
      prunable) flags="${flags:+$flags,}prunable" ;;
      *) : ;; # ignore unknown/optional fields (e.g. lock reason text)
    esac
  done
  flush_record
}

## has_flag
## Returns success if the comma-separated flag list ($1) contains flag ($2).
has_flag() {
  local flags="$1" flag="$2"
  [[ ",${flags}," == *",${flag},"* ]]
}

## inspect_uncommitted
## Reports uncommitted changes (tracked + untracked) in the worktree at
## $1. Prints a block if any are found and returns 1; prints nothing and
## returns 0 if the worktree is clean.
##
## A worktree directory can go missing while `git worktree list` still lists
## it (e.g. a locked worktree, whose entry git deliberately never marks
## `prunable`). In that case there is no working tree left to inspect, which
## is itself the worst outcome this script watches for: any uncommitted
## changes that lived only in that directory are already gone beyond
## recovery. This is reported as a distinct, dedicated finding rather than
## silently treated as "clean" or crashing on a raw git error.
inspect_uncommitted() {
  local wt_path="$1"
  local status_output count

  if [[ ! -d "$wt_path" ]]; then
    echo "  [MISSING] worktree directory does not exist -- any uncommitted"
    echo "            changes it held are already unrecoverable"
    return 2
  fi

  status_output="$(git -C "$wt_path" status --porcelain)"
  if [[ -z "$status_output" ]]; then
    return 0
  fi

  count="$(printf '%s\n' "$status_output" | wc -l | tr -d ' ')"
  echo "  [UNCOMMITTED] $count changed file(s):"
  printf '%s\n' "$status_output" | head -10 | sed 's/^/    /'
  if [[ "$count" -gt 10 ]]; then
    echo "    ... and $((count - 10)) more"
  fi
  return 1
}

## inspect_unmerged
## Reports commits reachable from ref $2 (a branch name or a detached HEAD
## sha) but not from base ref $3. Prints a block if any are found and
## returns 1; prints nothing and returns 0 if the ref is fully merged.
##
## Runs against $1, the shared repository path (normally the main
## worktree), NOT the individual worktree's own directory: commit objects
## and refs live in the shared object database, so this still works even
## when the specific worktree directory is missing -- committed work is
## never at risk the way uncommitted changes are.
inspect_unmerged() {
  local repo_path="$1" ref="$2" base_ref="$3"
  local count

  count="$(git -C "$repo_path" rev-list --count "${base_ref}..${ref}")"
  if [[ "$count" -eq 0 ]]; then
    return 0
  fi

  echo "  [UNMERGED] $count commit(s) not in '$base_ref':"
  git -C "$repo_path" log --oneline "${base_ref}..${ref}" -n 5 | sed 's/^/    /'
  if [[ "$count" -gt 5 ]]; then
    echo "    ... and $((count - 5)) more"
  fi
  return 1
}

## main
## Orchestrates parsing, enumeration, per-worktree inspection, and the
## final summary. Sets the process exit code per the header contract.
main() {
  parse_args "$@"

  if [[ ! -d "$REPO_PATH" ]]; then
    echo "error: repo path does not exist: $REPO_PATH" >&2
    exit 1
  fi
  if ! git -C "$REPO_PATH" rev-parse --git-dir >/dev/null 2>&1; then
    echo "error: not a git repository: $REPO_PATH" >&2
    exit 1
  fi

  local base_ref
  base_ref="$(resolve_base_ref "$REPO_PATH")"

  local main_worktree
  main_worktree="$(git -C "$REPO_PATH" rev-parse --show-toplevel)"

  local records
  records="$(git -C "$REPO_PATH" worktree list --porcelain | parse_worktree_porcelain)"

  local inspected=0
  local skipped_main=0
  local skipped_prunable=0
  local with_uncommitted=0
  local with_missing_dir=0
  local with_unmerged=0
  local findings=0

  echo "Reconciling worktrees in: $REPO_PATH"
  echo "Base ref for unmerged-commit comparison: $base_ref"
  echo

  local wt_path wt_head wt_branch wt_flags ref locked_note
  while IFS="$FIELD_SEP" read -r wt_path wt_head wt_branch wt_flags; do
    [[ -z "$wt_path" ]] && continue

    if [[ "$wt_path" == "$main_worktree" ]]; then
      skipped_main=$((skipped_main + 1))
      continue
    fi
    if has_flag "$wt_flags" "prunable"; then
      skipped_prunable=$((skipped_prunable + 1))
      continue
    fi

    inspected=$((inspected + 1))
    ref="$wt_head"
    if [[ -n "$wt_branch" ]]; then
      ref="$wt_branch"
    fi

    locked_note=""
    if has_flag "$wt_flags" "locked"; then
      locked_note=" (locked -- git will not prune this even if it becomes stale)"
    fi

    local block uncommitted_rc unmerged_block unmerged_rc
    block="$(inspect_uncommitted "$wt_path")" && uncommitted_rc=0 || uncommitted_rc=$?
    unmerged_block="$(inspect_unmerged "$REPO_PATH" "$ref" "$base_ref")" && unmerged_rc=0 || unmerged_rc=$?

    if [[ $uncommitted_rc -ne 0 || $unmerged_rc -ne 0 ]]; then
      findings=$((findings + 1))
      echo "== $wt_path"
      echo "   branch: ${wt_branch:-<detached: $wt_head>}${locked_note}"
      if [[ $uncommitted_rc -eq 2 ]]; then
        with_missing_dir=$((with_missing_dir + 1))
        printf '%s\n' "$block"
      elif [[ $uncommitted_rc -ne 0 ]]; then
        with_uncommitted=$((with_uncommitted + 1))
        printf '%s\n' "$block"
      fi
      if [[ $unmerged_rc -ne 0 ]]; then
        with_unmerged=$((with_unmerged + 1))
        printf '%s\n' "$unmerged_block"
      fi
      echo
    fi
  done <<< "$records"

  echo "----------------------------------------"
  echo "Summary"
  echo "----------------------------------------"
  echo "Inspected:                 $inspected"
  echo "Skipped (main worktree):   $skipped_main"
  echo "Skipped (prunable):        $skipped_prunable"
  echo "With uncommitted changes:  $with_uncommitted"
  echo "With missing directory:    $with_missing_dir (uncommitted state unrecoverable)"
  echo "With unmerged commits:     $with_unmerged"
  echo "Total findings:            $findings"

  if [[ "$findings" -gt 0 ]]; then
    exit 1
  fi
  exit 0
}

main "$@"
