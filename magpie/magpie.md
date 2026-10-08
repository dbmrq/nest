# Magpie

Magpie keeps a user's Agent Skills and AGENTS.md files in sync across their machines and projects. Users normally interact with it by talking to their AI agent; the agent speaks to Magpie through its CLI, and a small GUI covers browsing and settings.

This document is Magpie's source. **Compiling** means handing this spec to an AI agent and asking it to generate the executable (e.g. "compile Magpie into Python"). **Installing** means handing this spec to an agent and asking it to install Magpie.

## For the builder

Agent guidance for building Magpie in its repository lives in `AGENTS.md`. This spec remains the source of truth for behavior; Done means defines when a build is compiled. Magpie is one of a pair: its interface with Cuckoo is defined once in `../contract.md`.

## Concepts

- **Skill** — an Agent Skill: a directory containing a `SKILL.md` plus optional supporting files.
- **AGENTS.md file** — an agent context file; Magpie syncs these as whole files.
- **Item** — a skill or an AGENTS.md file; the unit Magpie identifies, syncs, and installs.
- **Scope** — where content lives: *machine* (usable everywhere on the machine) or *project* (one directory).
- **Upstream** — user-owned shared storage used to sync across machines and projects; a git repository by default.
- **Library** — Magpie's local copy of everything upstream, installed or not; a git checkout by default.
- **Install** — a copy of an item placed at a location on this machine; install choices are local and never sync.

## Non-goals

- **No adoption step.** Magpie does not distinguish files it wrote from files other tools wrote: every skill or AGENTS.md file found in a configured location is an item, with no import or registration step.

## Installing and configuring

- The installer checks for an existing Magpie binary and state. If there is no binary, it compiles and installs one, then configures it. It is idempotent and safe to re-run.
- It detects earlier or foreign Magpie state — including incompatible layouts — and reuses it, migrates it, or stops with a clear report. It never deletes data it did not create, and Magpie itself refuses to operate on state it doesn't recognize.
- It discovers where this machine's agents keep skills and AGENTS.md files, starting with its own, and records those locations in config. When a harness supports several locations, it picks the most generic one. It also looks for other harnesses installed on the machine and adds their locations.
- The binary must not hardcode agent-specific locations; everything machine- or harness-specific comes from configuration. This keeps Magpie compatible with any agent, including ones that don't exist yet.
- Magpie's home is a single directory (e.g. `~/.magpie`) holding the config file, its local state, and the library.
- Configuration lives in one versioned file (e.g. `~/.magpie/config`) and covers at least: content locations, project roots to scan, upstream location, and sync schedule. Users can change all of it from the GUI, the CLI, or by asking an agent.
- The installer offers automatic sync — triggered by file changes, run on a schedule as a fallback, or both.

## Identity

- Every item carries a stable identity: a UUID in an `id` key of a YAML frontmatter block. Magpie creates the frontmatter if the file has none. The frontmatter is inert to agent harnesses.
- This ID convention is tool-neutral and documented standalone in the repo so other tools can adopt it too. Magpie reads `id` or `uid` and writes `id`.
- Magpie adds the key on sight, minimally and idempotently: it preserves the rest of the file byte-for-byte, never rewrites an existing conforming `id`, and ignores non-UUID values.
- IDs are the source of truth. For files without one, Magpie matches by name and content similarity, merging only what's clearly the same and treating the rest as distinct rather than asking.
- Merging uses identity, not paths: a change propagates to every machine, project, and scope that uses the item. Anything that can't be merged without losing information is reported to the user or agent, never overwritten silently.

## Projects

- A project is any directory where agents are used. Magpie finds projects by scanning configured roots for agent artifacts (`.agents/`, `.cursor/`, `.github/`, `AGENTS.md`, and so on); users can also add or remove projects manually. Scanning is read-only.
- A project is identified by the ID of its root AGENTS.md file. Magpie adds it when the project is added or when something is installed into it, so the same project is recognized on every machine.
- The GUI shows the projects known on this machine and what skills and AGENTS.md files are active in each, with actions to install, promote (project → machine), and cross-install between projects.

## Upstream, sync, and installs

- Upstream is any storage the user owns that all their machines can reach. Default to a git repository when git is available; otherwise ask the user to point Magpie at a suitable one.
- The library is a git checkout of upstream, with items stored by ID (`skills/<uuid>/…`, `agents/<uuid>.md`) plus an optional generated index. ID-keyed storage makes renames free and collisions impossible.
- Sync folds edits made in install locations back into the library — reporting any local divergence — then commits, pulls remote changes, and pushes. Everything works offline; commits wait until the next sync.
- Deletions propagate as commits; no tombstones. A deletion removes the item from the library and removes installed copies that are untouched; copies edited locally are reported instead.
- When the same item changed on two machines, sync reports a conflict, exits with a distinct code, and keeps both versions; it never picks a winner silently. Resolution is explicit.
- Two states are separate: an item is *available* (in the library) and possibly *installed* (copied to a location here). Sync updates the content of installed items but never installs or uninstalls; install choices are local and never sync.
- Machine-scope items sync everywhere; project-scope items sync to the same project on other machines. Any item can be installed into a project or promoted to the machine.
- Sync is machine-agnostic: any machine that can reach upstream can participate. It can run manually, on a schedule, or when watched files change.

## Installs

- Install targets are configured locations. The simplest policy that makes content available to all harnesses wins: install to the most generic location(s) that reach everyone, and add a harness-specific location only when that harness can't see the generic one.
- Locations are labeled (generic or harness-specific, scope, path) and configurable. Real paths are resolved and deduplicated, so symlinked locations (`~/.cursor/skills` → `~/.agents/skills`) never cause double installs.
- Magpie treats every configured location as fair game, including stowed or symlinked directories: both Magpie and the other tools stay aware of the same files rather than drifting apart.
- `install` and `uninstall` take an item and a scope (machine or project), with an optional location override.

## CLI

The CLI is Magpie's programmatic interface; the GUI and bundled skills use it too.

- Core commands, stable across compiled builds so habits, scripts, and docs carry over: `list` (skills and AGENTS.md files by scope, with installed state), `install`, `uninstall`, `sync`, `ui` (open the GUI), `config`, `status`. Extra commands are welcome.
- Agents can consume output as JSON (`--json`) and discover usage via `--help`. Exit codes are meaningful, so a conflict is distinguishable from an error.

## Bundled Agent Skills

The agent is Magpie's primary interface, so Magpie ships its own Agent Skills that teach agents to drive it. They must cover at least: listing skills, showing what's missing on this machine and installing it, installing a topic's skills into the current project, syncing, and opening the GUI. They reference only commands the CLI actually provides, and a test keeps it that way.

## GUI

A visual overview of the user's skills and AGENTS.md files, with two tabs plus a Sync button and a settings section:

- **Machine** — machine-scoped content known to Magpie, with convenient install buttons for anything missing locally.
- **Projects** — projects and everything active in them, with cross-install and promote actions.

Frontmatter properties (`id` aside) are shown as visible tags on every item, so marks like Cuckoo's `generated_by` stand out without Magpie needing to know what they mean. Items can be opened in the user's editor or revealed in the file manager; edits made either way are ordinary local changes: sync folds them in and propagates them. Removing an item is one action.

Default to a web UI for portability; use a TUI or native app only when the environment clearly favors one. It binds to loopback by default, and every action it exposes is available on the CLI. When Cuckoo is installed, the GUI links to Cuckoo's proposal inbox and can start a mining run.

## Done means

Magpie is compiled when its acceptance suite exists and passes. The suite is black-box (drives the `magpie` CLI only), offline (a local bare git repository stands in for upstream), runs with one command, uses a temporary home directory per case, and ships in the repo so future compiles can reuse it. It must cover:

- **CLI contract** — core commands, `--help`, JSON output, meaningful failure codes.
- **ID tagging** — the ID lands in frontmatter, a second run changes nothing, the rest of the file is preserved.
- **Identity matching** — same ID unifies; id-less identical copies converge; different items stay distinct.
- **Two-machine sync round-trip** — install on one machine, sync, install on the other, edit, sync, update propagates.
- **Deletion** — removes untouched installs and the library entry; locally edited copies are reported; a local uninstall leaves upstream untouched.
- **Conflict safety** — concurrent edits are reported, both versions survive, nothing is overwritten silently.
- **Scopes and installs** — machine vs project, promote, no duplicate copies, correct "missing here" answers.
- **Targets and symlinks** — generic targets win; symlinked aliases don't double install.
- **Frontmatter display** — listings surface frontmatter properties other than `id`, so tool marks are visible.
- **UI smoke** — `magpie ui` serves the two tabs' data on loopback and exits cleanly.
- **Skills contract** — bundled skills are valid and reference only existing CLI commands.

## Example requests

These should work from any agent session, powered by the bundled skills:

- "Which of my skills aren't installed on this machine?" → list them and offer to install.
- "Install my iOS/Swift skills in this project." → triage by topic and install into the current project.
- "Sync my AGENTS.md files." → push new changes upstream and pull missing ones down.
- "Show me all my skills." → open the GUI.
