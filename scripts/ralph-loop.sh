#!/usr/bin/env bash
#
# A small Ralph loop: run a fresh agent per checklist item until every box in
# the plan is checked, progress stalls, or the run cap is reached.
#
# Usage:
#   scripts/ralph-loop.sh --plan magpie/plan.md --agent "opencode run --model opencode-go/deepseek-v4.1-flash"
#   scripts/ralph-loop.sh --plan magpie/plan.md --agent "claude -p" --max-runs 30
#   scripts/ralph-loop.sh --plan cuckoo/plan.md --agent "codex exec" --dry-run
#
# The prompt is appended as the final argument of the agent command.
# Logs land in .ralph-loop/logs/. See .agents/skills/ralph-loop/SKILL.md.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAN=""
AGENT="${RALPH_AGENT:-}"
MAX_RUNS=20
MAX_STUCK=3
DRY_RUN=false

usage() {
    cat <<'EOF'
Usage: scripts/ralph-loop.sh --plan <file> --agent <command> [options]

  --plan <file>       Markdown checklist with "- [ ]" items (required)
  --agent <command>   Agent command; the prompt is appended as its last
                      argument (or set RALPH_AGENT). Use your own harness
                      and model unless another was specified.
  --max-runs <n>      Stop after n agent runs (default: 20)
  --max-stuck <n>     Stop after n runs with no checkbox progress (default: 3)
  --dry-run           Print the first prompt and exit
  -h, --help          Show this help
EOF
}

die() { printf '[ralph-loop] %s\n' "$*" >&2; exit 1; }
log() { printf '[ralph-loop] %s\n' "$*"; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --plan) PLAN="${2:?--plan needs a file}"; shift 2 ;;
        --agent) AGENT="${2:?--agent needs a command}"; shift 2 ;;
        --max-runs) MAX_RUNS="${2:?}"; shift 2 ;;
        --max-stuck) MAX_STUCK="${2:?}"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done

cd "$REPO_ROOT"
[[ -n "$PLAN" && -f "$PLAN" ]] || die "plan file not found: ${PLAN:-<missing>} (pass --plan)"
[[ -n "$AGENT" ]] || die "no agent command (pass --agent or set RALPH_AGENT); use your own harness and model"
[[ "$MAX_RUNS" =~ ^[0-9]+$ && "$MAX_RUNS" -gt 0 ]] || die "--max-runs must be a positive integer"
[[ "$MAX_STUCK" =~ ^[0-9]+$ && "$MAX_STUCK" -gt 0 ]] || die "--max-stuck must be a positive integer"
read -r -a AGENT_CMD <<< "$AGENT"

count_unchecked() {
    grep -cE '^[[:space:]]*-[[:space:]]*\[[[:space:]]\]' "$PLAN" || true
}

make_prompt() {
    cat <<EOF
You are running inside an automated Ralph loop.

Goal: complete the next unchecked item in \`$PLAN\`, verify it, and mark it done only if verification actually passed.

Rules:
- Read \`$PLAN\` first; it is the source of truth for scope and order. Run everything from the repo root.
- Work on only the first unchecked item. Keep changes scoped and follow existing patterns.
- Run the item's verification command (or the fastest relevant check) and record the exact command and result.
- Change \`[ ]\` to \`[x]\` only when verification passed. If blocked, note it under the item, leave it unchecked, and stop.
- Add a short "Notes for later items:" when you learn something non-obvious.
- Do not commit; the outer agent or user handles git.
- Stop after this one item.

Report: what changed, the verification command and its result, and whether the item was checked.
EOF
}

PROMPT="$(make_prompt)"

if [[ "$DRY_RUN" == true ]]; then
    printf '%s\n' "$PROMPT"
    exit 0
fi

mkdir -p .ralph-loop/logs
initial="$(count_unchecked)"
[[ "$initial" -gt 0 ]] || { log "no unchecked items in $PLAN"; exit 0; }
log "plan: $PLAN | unchecked: $initial | agent: $AGENT"

stuck=0
for ((run = 1; run <= MAX_RUNS; run++)); do
    before="$(count_unchecked)"
    [[ "$before" -gt 0 ]] || { log "plan complete"; exit 0; }
    logfile=".ralph-loop/logs/run-$(printf '%03d' "$run").log"
    log "run $run/$MAX_RUNS: $before unchecked"
    if ! "${AGENT_CMD[@]}" "$PROMPT" 2>&1 | tee "$logfile"; then
        die "agent run $run failed (see $logfile)"
    fi
    after="$(count_unchecked)"
    if [[ "$after" -lt "$before" ]]; then
        stuck=0
        log "progress: $before -> $after unchecked"
    else
        stuck=$((stuck + 1))
        log "no checkbox progress ($stuck/$MAX_STUCK)"
    fi
    [[ "$after" -eq 0 ]] && { log "plan complete"; exit 0; }
    if ((stuck >= MAX_STUCK)); then
        die "stuck with $after unchecked item(s); see $logfile"
    fi
done
die "max runs reached with $(count_unchecked) unchecked item(s)"
