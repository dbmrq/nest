---
id: d10d701d-784d-4d09-9beb-6a2c633ef177
name: ralph-loop
description: Compile the apps in this repo with a small Ralph loop — repeated fresh-context agent runs against a short Markdown checklist, one verified item per run. Use when asked to compile or build Magpie or Cuckoo from its spec, or to resume an unfinished build.
---

# Ralph loop

Compiling an app here runs as a small Ralph loop: each run is a fresh agent that completes exactly one checklist item, verifies it, and checks it off. The plan and the working tree carry state between runs, so long builds stay reviewable and resumable.

## Before looping

1. Read the app's spec (`magpie/magpie.md` or `cuckoo/cuckoo.md`) and `contract.md`. The spec defines behavior; the plan defines scope and order.
2. Write a short plan next to the spec (`magpie/plan.md`, `cuckoo/plan.md`) if there isn't one:
   - One `- [ ] **N. Title.**` item per agent run, each with its exact verification command.
   - The first item picks the stack and stands up the acceptance-suite runner; early items build the suite skeleton, late items are integration, scenario, and cleanup work.
   - Keep checkboxes out of prose and examples, and end with a manual-validation section that has none.
3. Commit the plan if you want the loop's history in git.

## Running

From the repo root:

```bash
scripts/ralph-loop.sh --plan magpie/plan.md --agent "<agent command>"
```

`--agent` is your own harness and model, e.g. `opencode run --model opencode-go/deepseek-v4.1-flash` or `claude -p`; if the user didn't specify one, use the harness and model you are running on. The prompt is appended as the command's last argument. Logs land in `.ralph-loop/logs/`.

The loop stops when every box is checked, when progress stalls (`--max-stuck`), or at the run cap (`--max-runs`). Commit between runs if you want checkpoints.

## Rules for the agent inside a run

- Read the plan first; work on only the first unchecked item.
- Verify with the item's command before checking the box, and record the command and result.
- If blocked, note it under the item, leave it unchecked, and stop.
- Add short notes for later items when you learn something non-obvious.
- Do not commit. Stop after the one item.

## The finish line

A build is compiled only when the acceptance suite described in the spec's **Done means** section exists and passes. That is the loop's exit gate; manual validation comes after.
