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
#     1. Uncommitted changes inside a live worktree -- UNRECOVERABLE if that
#        directory is later deleted or pruned. Highest priority.
#     2. Commits on a branch that were never merged into the integration
#        branch and never reported -- recoverable, but easy to miss.
#
#   This script enumerates every worktree, flags both situations, and prints
#   a summary so nothing goes unnoticed before a worktree is cleaned up.
#
#   Every worktree is inspected, including ones git marks `prunable` -- that
#   flag means a broken `.git` link, not "already gone": the directory can
#   still hold uncommitted work. Uninspectability is decided by whether the
#   state could actually be read, never by the `prunable` flag.
#
# WHY THIS STAYS ONE FILE
#   This script exceeds the project's ~400-line file-size guidance
#   (CLAUDE.md) by design -- a documented exception, not an oversight. A
#   shell tool that `source`s a sibling file must resolve that sibling's
#   path at runtime relative to itself, and stops being copy-runnable from
#   an arbitrary working directory, or when copied elsewhere on its own.
#   This script's whole point is being runnable against an arbitrary repo
#   path, from anywhere. The tradeoff -- one longer file over several
#   short, non-portable ones -- is accepted, not accidental.
#
# THIS SCRIPT IS STRICTLY READ-ONLY.
#   It must NEVER run a mutating git command. Specifically forbidden:
#   `worktree prune`, `worktree remove`, `branch -d`/`-D`, `checkout`,
#   `switch`, `reset`, `clean`, `stash`, `commit`, `merge`, `rebase`, `push`,
#   `gc`. Only read-only commands are used: `worktree list`, `status
#   --porcelain --no-optional-locks --untracked-files=all`, `rev-list`,
#   `rev-parse`, `log`, `branch --list`, `diff --stat`, `merge-base`,
#   `for-each-ref`. Every `status` call passes `--no-optional-locks`: plain
#   `status` takes `index.lock` and refreshes the index as a side effect,
#   which is exactly the metadata this tool is auditing before a delete
#   decision. Every `status` call also passes `--untracked-files=all`:
#   plain `status --porcelain` honors `status.showUntrackedFiles`, which
#   `git help status` documents as settable to `no` as a performance
#   setting on large repos (in `~/.gitconfig`, system config, or the
#   repo's own config) -- silently hiding exactly the untracked,
#   unrecoverable work this tool exists to catch. The command-line flag
#   overrides that config unconditionally. `.gitignore` is still honored
#   deliberately (no `--ignored`): every Flutter worktree carries
#   regenerated build artifacts (`build/`, `.dart_tool/`, `coverage/`), and
#   reporting those would mark every worktree dirty forever and train the
#   operator to ignore the output. Do NOT add cleanup/pruning logic to this
#   file -- if automated cleanup is ever wanted, it belongs in a separate,
#   explicitly named script so a read-only audit tool never grows a
#   destructive side effect by accident.
#
# USAGE
#   tools/reconcile-worktrees.sh [repo-path] [--base <ref>] [--branches]
#
#   repo-path   Path to the git repository to inspect.
#               Defaults to /home/mochi/Projects/layrz_ui.
#   --base ref  Integration branch to diff unmerged commits against.
#               Defaults to "development", falling back to "main" if
#               "development" does not exist locally. If neither exists,
#               the script reports that explicitly instead of silently
#               treating every worktree as fully merged.
#   --branches  Additionally sweep every local branch -- not just the ones
#               attached to a worktree -- for commits not reachable from
#               the base ref, printed as their own section. Off by default:
#               it widens scope from "the worktrees" to "the whole repo".
#
# EXIT CODES
#   0   No findings, and every non-skipped worktree was fully inspected.
#   1   At least one finding (uncommitted changes and/or unmerged commits,
#       including from --branches), OR a fatal setup error (bad repo path,
#       no base ref available, an unknown --base ref). The code alone does
#       not distinguish a finding from a setup error; read stderr for that.
#   2   No findings, but at least one worktree could not be inspected for
#       uncommitted state (directory gone, or git metadata unreadable).
#       Kept distinct from 0 so "clean" is never confused with "unknown".
#   This makes the script usable as a CI/pipeline gate.
#
set -euo pipefail

# Git exports GIT_DIR / GIT_WORK_TREE / GIT_INDEX_FILE (and the object-dir
# vars) into any hook or subprocess it invokes. An inherited GIT_DIR takes
# precedence over every `git -C <path>` call below, so this script would
# silently inspect the leaked repo instead of each worktree -- reporting
# everything clean and greenlighting `git worktree prune` over real
# unmerged work. Same failure class as CLAUDE.local.md's 0.0.0-unknown
# incident, fixed there as 15200d6. `cd` does not help; only unsetting does.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES

# Repo path, defaulting to the layrz_ui checkout this tool was written for.
REPO_PATH="/home/mochi/Projects/layrz_ui"
# Integration branch findings are compared against; resolved in resolve_base_ref.
BASE_REF_OVERRIDE=""
# Whether --branches was passed; see parse_args.
WITH_BRANCHES=0
# Populated by sweep_branches when --branches is passed: the count of local
# branches carrying commits not reachable from the base ref. Read by main to
# fold --branches findings into the exit-code tally. Left at 0 when
# --branches is not passed, so it is always safe to add into `findings`.
BRANCH_FINDINGS=0

## parse_args
## Parses the optional positional repo path, the optional --base flag, and
## the optional --branches flag. Leaves the results in the REPO_PATH,
## BASE_REF_OVERRIDE, and WITH_BRANCHES globals. Rejects an unrecognized
## `-`-prefixed option and a second positional argument explicitly, instead
## of silently treating either as the repo path -- a mistyped flag would
## otherwise fail confusingly later, pointing at the wrong cause. A bare
## `--` ends option parsing, so a repo path that itself starts with a dash
## is still reachable.
parse_args() {
  local repo_path_given=0

  ## set_repo_path
  ## Assigns positional argument $1 to REPO_PATH, or errors if REPO_PATH
  ## was already assigned by an earlier positional argument.
  set_repo_path() {
    if [[ $repo_path_given -eq 1 ]]; then
      echo "error: unexpected extra argument: $1 (repo path already set)" >&2
      exit 1
    fi
    REPO_PATH="$1"
    repo_path_given=1
  }

  local end_of_options=0
  while [[ $# -gt 0 ]]; do
    if [[ $end_of_options -eq 1 ]]; then
      set_repo_path "$1"
      shift
      continue
    fi
    case "$1" in
      --)
        end_of_options=1
        shift
        ;;
      --base)
        if [[ $# -lt 2 ]]; then
          echo "error: --base requires an argument" >&2
          exit 1
        fi
        BASE_REF_OVERRIDE="$2"
        shift 2
        ;;
      --branches)
        WITH_BRANCHES=1
        shift
        ;;
      -h|--help)
        print_header
        exit 0
        ;;
      -*)
        echo "error: unknown option: $1" >&2
        exit 1
        ;;
      *)
        set_repo_path "$1"
        shift
        ;;
    esac
  done
}

## print_header
## Prints the leading comment block -- shebang to first non-comment line --
## to stdout. Used by --help so usage text has one source of truth and
## cannot fall out of sync as the header grows (a fixed `sed` range
## previously truncated the header's last line).
print_header() {
  awk 'NR == 1 { next } /^#/ { print; next } { exit }' "$0"
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
    # --end-of-options: BASE_REF_OVERRIDE is user-supplied and may start
    # with a dash; without this, git would try to parse it as an option.
    if git -C "$repo" rev-parse --verify --quiet --end-of-options "$BASE_REF_OVERRIDE" >/dev/null; then
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

## build_admin_map
## Builds path -> admin-dir records for every worktree under the repo's
## common git dir ($1), by reading each worktree's own `gitdir` file and
## stripping the trailing `/.git`. That is the same value the porcelain's
## `worktree <path>` line is derived from, so it matches by construction --
## including a phantom path and a collision-suffixed admin dir name.
## Deliberately NOT basename-matching: git only guarantees that until a
## collision forces a suffix.
##
## A relative `gitdir` (worktree.useRelativePaths) is resolved against its
## OWN admin dir ($common_dir/worktrees/<name>), because that is the base
## git itself resolves it against -- common_dir is the wrong base and was
## an earlier, inert attempt at this fix. The result can still contain
## literal `..` segments, while the porcelain reports a fully-resolved
## path and lookup_admin_dir matches by exact string equality; so, when the
## resolved path exists on disk, it is additionally normalized via
## `cd && pwd -P`. That normalization is skipped (not attempted, not
## required to succeed) when the path does not exist, so a phantom
## worktree's raw, unresolved path still lands in the map -- it must, so
## the caller's later `-d` check reports "directory gone" instead of the
## entry silently disappearing. Prints one record per line, path and
## admin_dir joined by FIELD_SEP. Read-only; no judgment about prunable.
build_admin_map() {
  local common_dir="$1"
  local admin_dir gitdir_file target path resolved

  [[ -d "$common_dir/worktrees" ]] || return 0

  for admin_dir in "$common_dir"/worktrees/*/; do
    admin_dir="${admin_dir%/}"
    gitdir_file="$admin_dir/gitdir"
    [[ -f "$gitdir_file" ]] || continue
    target="$(<"$gitdir_file")"
    [[ "$target" == /* ]] || target="$admin_dir/$target"
    path="${target%/.git}"
    if [[ -d "$path" ]]; then
      resolved="$(cd "$path" && pwd -P)" || resolved=""
      [[ -n "$resolved" ]] && path="$resolved"
    fi
    printf '%s%s%s\n' "$path" "$FIELD_SEP" "$admin_dir"
  done
  return 0
}

## lookup_admin_dir
## Pure lookup over the records produced by build_admin_map ($2), returning
## the admin dir for worktree path $1 on stdout, or nothing if not found.
## No filesystem access -- callers pass the already-built map.
lookup_admin_dir() {
  local wt_path="$1" admin_map="$2"
  local map_path map_admin

  while IFS="$FIELD_SEP" read -r map_path map_admin; do
    if [[ "$map_path" == "$wt_path" ]]; then
      printf '%s' "$map_admin"
      return 0
    fi
  done <<< "$admin_map"
  return 0
}

## inspect_uncommitted
## Reports uncommitted changes (tracked + untracked) in the worktree at $1,
## using the admin-dir map entry $2 (may be empty) as a fallback when the
## worktree's own .git link is unreadable. Prints a block and returns 1 if
## changes are found; nothing and returns 0 if clean. Returns 2 (directory
## gone) or 3 (git metadata unreadable) with a NOT INSPECTED note if
## uncommitted state could not be determined -- the two rc's let the
## caller report which cause applies, rather than lumping both into one
## unexplained bucket.
##
## Three rungs, tried in order: (1) directory missing/phantom -> no working
## tree left to read, immediately uninspectable; (2) `git -C <path>
## --no-optional-locks status --untracked-files=all` -> works for every
## ordinary worktree, including a locked one whose directory survives;
## (3) `git --git-dir=<admin> --work-tree=<path> --no-optional-locks
## status --untracked-files=all` -> the fallback for a prunable worktree
## whose directory survives: its own `.git` link points nowhere (that is
## what "prunable" means), so `-C` fails with rc=128 even though the
## working tree and the admin dir are both still readable via the explicit
## form. `--no-optional-locks` on both: plain `status` takes `index.lock`
## and refreshes the index as a side effect, which this audit tool must
## not do to metadata it is inspecting before a delete decision.
## `--untracked-files=all` on both: without it, `status.showUntrackedFiles
## = no` in any applicable git config would silently hide untracked
## files -- exactly the unrecoverable case this script exists to catch.
## See the header for the full rationale, including why `.gitignore` is
## still honored (no `--ignored`).
##
## A git failure on either attempt is captured and never allowed to
## propagate as this function's return code, or to leak "fatal:" text to
## the caller's stderr -- reported through rc 2/3 instead, never silently
## folded into "clean" or miscounted as "uncommitted".
inspect_uncommitted() {
  local wt_path="$1" admin_dir="$2"
  local status_output rc count

  if [[ ! -d "$wt_path" ]]; then
    echo "  [NOT INSPECTED] worktree directory does not exist -- uncommitted state unknown"
    return 2
  fi

  rc=0
  status_output="$(git -C "$wt_path" --no-optional-locks status --porcelain --untracked-files=all 2>/dev/null)" || rc=$?

  if [[ $rc -ne 0 && -n "$admin_dir" && -d "$admin_dir" ]]; then
    rc=0
    status_output="$(git --git-dir="$admin_dir" --work-tree="$wt_path" --no-optional-locks status --porcelain --untracked-files=all 2>/dev/null)" || rc=$?
  fi

  if [[ $rc -ne 0 ]]; then
    echo "  [NOT INSPECTED] worktree's git metadata is unreadable -- uncommitted state unknown"
    return 3
  fi

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
## sha) but not from base ref $3, using the merge-base form so a stale
## branch's own history never gets miscounted against a moving base ref.
## Prints a block and returns 1 if any are found; nothing and returns 0 if
## fully merged. Runs against $1, the shared repository path, NOT the
## worktree's own directory: commit objects live in the shared object
## database, so this still works even when the worktree directory is gone.
## If the merge base itself cannot be computed (unrelated histories), or if
## `rev-list` itself fails, that is reported as a finding rather than
## silently "zero unmerged commits" -- never-silently-clean is the point of
## this script. (A failed `rev-list` inside the tested `... || rc=$?` call
## at the caller disables `set -e` for this whole function, so an empty
## `count` must be checked explicitly -- `[[ "" -eq 0 ]]` is true in bash.)
inspect_unmerged() {
  local repo_path="$1" ref="$2" base_ref="$3"
  local mb count

  mb="$(git -C "$repo_path" merge-base "$base_ref" "$ref" 2>/dev/null)" || mb=""
  if [[ -z "$mb" ]]; then
    echo "  [UNMERGED?] cannot compute merge-base against '$base_ref' -- treating as a finding"
    return 1
  fi

  count="$(git -C "$repo_path" rev-list --count "${mb}..${ref}" 2>/dev/null)" || count=""
  if [[ -z "$count" ]]; then
    echo "  [UNMERGED?] cannot count commits against '$base_ref' -- treating as a finding"
    return 1
  fi
  if [[ "$count" -eq 0 ]]; then
    return 0
  fi

  echo "  [UNMERGED] $count commit(s) not in '$base_ref':"
  git -C "$repo_path" log --oneline "${mb}..${ref}" -n 5 | sed 's/^/    /'
  if [[ "$count" -gt 5 ]]; then
    echo "    ... and $((count - 5)) more"
  fi
  return 1
}

## sweep_branches
## Sweeps every local branch in $1 (not just ones attached to a worktree)
## for commits not reachable from base ref $2, using the same merge-base
## form as inspect_unmerged. Prints a separate section listing every branch
## with a nonzero count, sorted descending, and sets the BRANCH_FINDINGS
## global to the qualifying count so the caller can fold it into the
## findings/exit-code tally. Read-only: `for-each-ref`, `merge-base`,
## `rev-list --count`. A branch with unrelated history (merge-base fails)
## is skipped, not forced into a finding -- unlike inspect_unmerged, this
## is a best-effort whole-repo sweep, not a per-worktree safety check.
sweep_branches() {
  local repo_path="$1" base_ref="$2"
  local ref mb count total branch_lines branch_total

  branch_lines=""
  total=0

  while IFS= read -r ref; do
    [[ -z "$ref" || "$ref" == "$base_ref" ]] && continue

    mb="$(git -C "$repo_path" merge-base "$base_ref" "$ref" 2>/dev/null)" || mb=""
    # No merge base means unrelated history (orphan branch, imported or
    # grafted history, a squash-rebuilt branch) -- skip it, since a sweep
    # should not manufacture a finding out of an unresolvable comparison,
    # but warn: silently dropping it would leave the branch's commits
    # unaccounted for with no signal, and would also throw off the
    # "N of M" subtotal below with no explanation for the mismatch.
    if [[ -z "$mb" ]]; then
      echo "warning: branch '$ref' shares no history with '$base_ref' -- skipped" >&2
      continue
    fi

    # A failed rev-list here is skipped with a note rather than forced into
    # a finding: this is a best-effort whole-repo sweep, not the per-
    # worktree safety check that inspect_unmerged is.
    count="$(git -C "$repo_path" rev-list --count "${mb}..${ref}" 2>/dev/null)" || count=""
    if [[ -z "$count" ]]; then
      echo "warning: could not count commits for branch '$ref' -- skipped" >&2
      continue
    fi
    if [[ "$count" -gt 0 ]]; then
      branch_lines="${branch_lines}${count}${FIELD_SEP}${ref}"$'\n'
      total=$((total + 1))
    fi
  done < <(git -C "$repo_path" for-each-ref --format='%(refname:short)' refs/heads/)

  branch_total="$(git -C "$repo_path" for-each-ref --format='%(refname)' refs/heads/ | wc -l | tr -d ' ')"

  echo "----------------------------------------"
  echo "Local branches with unmerged commits"
  echo "----------------------------------------"
  if [[ -n "$branch_lines" ]]; then
    printf '%s' "$branch_lines" | sort -t"$FIELD_SEP" -k1,1nr | while IFS="$FIELD_SEP" read -r c r; do
      printf '  %3d  %s\n' "$c" "$r"
    done
  fi
  echo "Branches carrying unmerged commits: $total of $branch_total"

  BRANCH_FINDINGS="$total"
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

  local common_dir
  common_dir="$(git -C "$REPO_PATH" rev-parse --path-format=absolute --git-common-dir)"

  local admin_map
  admin_map="$(build_admin_map "$common_dir")"

  local records
  records="$(git -C "$REPO_PATH" worktree list --porcelain | parse_worktree_porcelain)"

  local inspected=0
  local clean=0
  local skipped_main=0
  local with_uncommitted=0
  local unmerged_inspected=0
  local not_inspected=0
  local not_inspected_dir_gone=0
  local not_inspected_metadata=0
  local unmerged_not_inspected=0
  local findings=0

  echo "Reconciling worktrees in: $REPO_PATH"
  echo "Base ref for unmerged-commit comparison: $base_ref"
  echo

  local wt_path wt_head wt_branch wt_flags ref locked_note admin_dir
  while IFS="$FIELD_SEP" read -r wt_path wt_head wt_branch wt_flags; do
    [[ -z "$wt_path" ]] && continue

    if [[ "$wt_path" == "$main_worktree" ]]; then
      skipped_main=$((skipped_main + 1))
      continue
    fi

    ref="$wt_head"
    if [[ -n "$wt_branch" ]]; then
      ref="$wt_branch"
    fi

    locked_note=""
    if has_flag "$wt_flags" "locked"; then
      locked_note=" (locked -- git will not prune this even if it becomes stale)"
    fi

    admin_dir="$(lookup_admin_dir "$wt_path" "$admin_map")"

    local block uncommitted_rc unmerged_block unmerged_rc
    block="$(inspect_uncommitted "$wt_path" "$admin_dir")" && uncommitted_rc=0 || uncommitted_rc=$?
    unmerged_block="$(inspect_unmerged "$REPO_PATH" "$ref" "$base_ref")" && unmerged_rc=0 || unmerged_rc=$?

    case "$uncommitted_rc" in
      0) inspected=$((inspected + 1)); clean=$((clean + 1)) ;;
      1) inspected=$((inspected + 1)); with_uncommitted=$((with_uncommitted + 1)) ;;
      2) not_inspected=$((not_inspected + 1)); not_inspected_dir_gone=$((not_inspected_dir_gone + 1)) ;;
      3) not_inspected=$((not_inspected + 1)); not_inspected_metadata=$((not_inspected_metadata + 1)) ;;
      # inspect_uncommitted only ever returns 0-3, traced; this default
      # arm exists so a future rc value fails loudly (uncounted + exit 1)
      # instead of silently passing through with no counter incremented,
      # which could let a genuine problem exit 0.
      *) echo "internal error: unexpected rc $uncommitted_rc from inspect_uncommitted" >&2; exit 1 ;;
    esac

    if [[ $unmerged_rc -ne 0 ]]; then
      if [[ $uncommitted_rc -eq 2 || $uncommitted_rc -eq 3 ]]; then
        unmerged_not_inspected=$((unmerged_not_inspected + 1))
      else
        unmerged_inspected=$((unmerged_inspected + 1))
      fi
    fi

    # Print a block for any real finding OR any uninspectable entry, so the
    # operator can always see WHICH worktree could not be checked -- only a
    # fully clean, fully merged, fully inspected entry stays silent.
    # Uninspectability alone still does not count toward `findings`.
    if [[ $uncommitted_rc -ne 0 || $unmerged_rc -ne 0 ]]; then
      if [[ $uncommitted_rc -eq 1 || $unmerged_rc -ne 0 ]]; then
        findings=$((findings + 1))
      fi
      echo "== $wt_path"
      echo "   branch: ${wt_branch:-<detached: $wt_head>}${locked_note}"
      if [[ $uncommitted_rc -ne 0 ]]; then
        printf '%s\n' "$block"
      fi
      if [[ $unmerged_rc -ne 0 ]]; then
        printf '%s\n' "$unmerged_block"
      fi
      echo
    fi
  done <<< "$records"

  echo "----------------------------------------"
  echo "Summary"
  echo "----------------------------------------"
  echo "Inspected:              $inspected"
  echo "  clean:                $clean"
  echo "  uncommitted changes:  $with_uncommitted"
  echo "  unmerged commits:     $unmerged_inspected"
  echo
  echo "Skipped (main worktree): $skipped_main"
  echo
  # Two distinct causes can make an entry uninspectable (directory gone vs.
  # git metadata unreadable). When every entry shares one cause, keep the
  # single-cause wording as-is; when they are mixed, break out the counts
  # per cause so the summary never attributes a false reason. Either way
  # the closing "unmerged commits were still checked" line is load-bearing
  # and must survive -- without it a reader assumes NOT INSPECTED entries
  # were skipped entirely, when their unmerged state was in fact checked.
  if [[ "$not_inspected_metadata" -eq 0 ]]; then
    echo "NOT INSPECTED:         $not_inspected"
    echo "  directory gone -- uncommitted state"
    echo "  CANNOT BE KNOWN for these entries."
    echo "  Unmerged commits were still checked:"
    echo "    $unmerged_not_inspected entries carry commits not in"
    echo "    '$base_ref' (listed above)."
  else
    echo "NOT INSPECTED:         $not_inspected"
    echo "  $not_inspected_dir_gone directory gone"
    echo "  $not_inspected_metadata git metadata unreadable"
    echo "  uncommitted state CANNOT BE"
    echo "  KNOWN for these entries."
    echo "  Unmerged commits were still"
    echo "  checked: $unmerged_not_inspected entries carry"
    echo "  commits not in '$base_ref' (listed above)."
  fi
  echo

  # The sweep must run and fold into `findings` BEFORE the Findings line is
  # printed -- printing it first would let the line read 0 while the exit
  # code goes nonzero moments later because of a --branches-only finding,
  # which is exactly the kind of contradiction a tool gating a destructive
  # decision must never show.
  if [[ "$WITH_BRANCHES" -eq 1 ]]; then
    sweep_branches "$REPO_PATH" "$base_ref"
    findings=$((findings + BRANCH_FINDINGS))
    echo
  fi

  echo "Findings:               $findings"

  if [[ "$findings" -gt 0 ]]; then
    exit 1
  elif [[ "$not_inspected" -gt 0 ]]; then
    exit 2
  else
    exit 0
  fi
}

main "$@"
