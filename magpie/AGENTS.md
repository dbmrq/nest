---
id: 8a42deff-0b36-4a2f-92d2-7740665bd1e5
---

# Building Magpie

The spec is [`magpie.md`](magpie.md). The pair's interface with Cuckoo is [`../contract.md`](../contract.md), and repository-wide builder guidance is in the [root AGENTS.md](../AGENTS.md).

Start every new Magpie compile in a dedicated implementation directory such as `magpie/implementations/rust/` or `magpie/implementations/<date>-<stack>/`. Keep all generated code, package files, build artifacts, implementation-specific README files, bundled runtime skills, tests, and the Ralph-loop plan inside that directory. Do not mix them into the spec root.

For GUI work, do not count a rendered page as done. The acceptance suite must drive the UI like a user: click Machine, Projects, and Settings as separate tabs; expand and collapse list rows; press every visible item action or verify it is explicitly disabled; run Sync and assert visible feedback; validate Settings fields before and after save; and prove that each AGENTS.md under configured scan roots is treated as its own project.
