# Magpie and Cuckoo

Two sister apps that compose into one loop for agent context:

- **Magpie** manages the user's Agent Skills and AGENTS.md files, keeping them in sync across machines and projects.
- **Cuckoo** turns the user's agent sessions into new Agent Skills and AGENTS.md entries, autonomously but safely.

Neither app requires the other. Together they share the conventions defined once in [`contract.md`](contract.md).

Each app's source is a natural-language spec. **Compile** one by handing its spec — together with the contract — to an AI agent (e.g. "compile Magpie into Python"), which builds it with a small Ralph loop (`scripts/ralph-loop.sh`); **install** one by asking an agent to install it from the spec.

- [`magpie/magpie.md`](magpie/magpie.md) — the Magpie spec
- [`cuckoo/cuckoo.md`](cuckoo/cuckoo.md) — the Cuckoo spec
