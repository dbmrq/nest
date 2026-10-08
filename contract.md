# The Magpie–Cuckoo contract

Magpie and Cuckoo are independent apps that compose into one loop for agent context: Cuckoo creates content, Magpie manages and syncs it. This document is the single home for their interface — the rules both specs rely on. Each app must remain fully usable alone; integration is detected at runtime and never assumed.

## Shared conventions

Both apps speak the same file conventions, and Magpie's spec is their canonical definition:

- **Identity** — a stable UUID in the `id` key of a YAML frontmatter block. Cuckoo mints one for every item it creates; Magpie reads `id` or `uid` and writes `id` (`magpie/magpie.md`, Identity).
- **Scopes** — machine or project, with Magpie's semantics (`magpie/magpie.md`, Concepts).
- **Locations** — content lives in configured agent locations; each app discovers its own, and when both are installed they must agree on the same files rather than diverge.
- **No adoption** — every conforming file in a managed location is an item, whoever wrote it; there is no import or registration step (`magpie/magpie.md`, Non-goals).
- **Attribution** — Cuckoo marks generated content so any manager can recognize it: `generated_by: cuckoo` in frontmatter for items it creates, and entries it adds to shared files live inside regions fenced by `<!-- cuckoo:begin -->` and `<!-- cuckoo:end -->`. Magpie surfaces both. Removing the marking — the key or the fences — claims the content as the user's: Magpie stops treating it as generated, and Cuckoo treats it as user-authored, never re-marking it on its own.

## Handoff

- Cuckoo writes an accepted item to the location its scope calls for, with a conforming ID. When Magpie is installed, Cuckoo uses the locations Magpie knows and asks it to sync.
- Magpie needs no cooperation to pick it up: it treats every conforming file it finds as an item, folds it into the library, and propagates it to the user's other machines.
- Without Magpie, Cuckoo still applies items locally; installing Magpie later picks them up with no migration.
- Neither app hardcodes the other's internals. The interface is the conventions above and, at most, the companion's public CLI.
- When Magpie deletes content marked as Cuckoo-generated, it asks the installed Cuckoo to archive it, so the same idea isn't suggested again.

## Review state

Because every conforming file in a managed location is tracked, there is no applied-but-unsynced state to gate. Review happens either before an item is written (Cuckoo's review mode) or after it is applied, marked, and announced (Cuckoo's default).

## Awareness

When both are installed, the GUIs link to each other and can offer each other's safe top-level actions: Magpie's links to Cuckoo's inbox and can start a mining run, and Cuckoo's links to Magpie's library.

## Changing this contract

A change here means checking that both specs still agree with it. Keep this document lean; app-specific behavior stays in the specs.
