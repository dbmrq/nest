---
id: b5d289ad-aca2-4eec-90b2-ee14a0c22104
---

# Magpie and Cuckoo repository

This repository holds two sister apps, designed together but built and used separately:

- **Magpie** (`magpie/magpie.md`) — manages the user's Agent Skills and AGENTS.md files, keeping them in sync across machines and projects.
- **Cuckoo** (`cuckoo/cuckoo.md`) — turns the user's agent sessions into new Agent Skills and AGENTS.md entries, autonomously but safely.

`contract.md` is the single definition of how the two compose, and each spec relies on it. Everything here implements the specs; when this file and a spec disagree, the spec wins.

Each app's source is its spec — a natural-language document. Compiling means handing that spec, together with `contract.md`, to an AI agent and asking it to generate the executable (e.g. "compile Magpie into Python"); installing means asking an agent to install the app from its spec. Builds run as small Ralph loops (`.agents/skills/ralph-loop`): one checklist item per fresh agent run, verified before it is checked off.

## Layout

- `contract.md` — the Magpie–Cuckoo interface, defined once.
- `magpie/` — Magpie's spec and app-specific guidance; generated compiles live under `magpie/implementations/`.
- `cuckoo/` — Cuckoo's spec and app-specific guidance; generated compiles live under `cuckoo/implementations/`.
- `<app>/implementations/<implementation-name>/` — generated compile output for one implementation attempt. Keep package manifests, source, tests, build artifacts, bundled runtime skills, implementation-specific docs, and the Ralph-loop plan here instead of mixing them with the app spec.

## For agents building Magpie or Cuckoo

- Proceed autonomously; ask the user only when an important decision can't be inferred from the spec or the machine.
- Pick the language, stack, and packaging that fit the environment best; prefer an executable or a standard package that provides the app's command (e.g. `magpie`, `cuckoo`), keeping dependencies moderate.
- Use stable, well-maintained third-party libraries for common functionality instead of reinventing it.
- Where a spec leaves a choice open — config format, GUI framework, scheduler integration — pick the simplest option consistent with the environment and document it briefly in the repo.
- Put each new compile in its own implementation subdirectory (`magpie/implementations/<name>/`, `cuckoo/implementations/<name>/`, etc.). The app spec directory root is for the spec and agent guidance, not generated implementation files.
- Build with a small Ralph loop: write a short checklist plan inside that implementation directory (for example, `magpie/implementations/<name>/plan.md`), then run `scripts/ralph-loop.sh` with it. Unless otherwise specified, pass your own harness and model as the agent command.
- A build is compiled only when the acceptance suite described in the spec's **Done means** section exists and passes; unit tests are optional, behavior is what matters.
- The GUI should be fully exercised end to end through automated tests, simulating the behavior of real users and generating thorough screenshots. The automated tests should go through all available CLI actions from the GUI, ensuring they succeed.
- For Magpie specifically, GUI acceptance must prove the Settings tab, Sync feedback, item accordions/actions, and AGENTS.md-backed project discovery work in the browser; a passive page with dead controls is not compiled.
- The GUI screenshots should be analyzed by a vision capable AI model, and any identified issues or improvements should be handled.