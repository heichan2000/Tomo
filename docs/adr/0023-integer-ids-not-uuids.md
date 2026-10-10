# ADR-0023: Rows are numbered with integers, not random IDs

- **Status:** Accepted
- **Date:** 2026-10-06
- **Decided in:** [#10 Drift schema & storage inventory](https://github.com/heichan2000/Tomo/issues/10)
- **Amended by:** [ADR-0029](0029-mvp-ships-without-ai-and-never-goes-online.md) — the deciding reason, the agent, is parked. Integer IDs stay: they are still the simplest choice, and a future agent gets them for free.

Every Drift table uses an auto-increment integer primary key. A future reader
may expect UUIDs, since the architecture doc calls the schema "sync-friendly"
and UUIDs are the usual sync-ready choice. That claim rests on the
timestamp-anchored timer, not on the shape of the IDs.

The deciding cost is the AI agent. Task IDs go over the wire on every
`list_tasks` result and come back in every `update_task` / `delete_task` call.
A 36-character UUID costs many tokens on free tiers that #6 showed are tight.
Models also garble them now and then, producing a call that points at nothing.
An integer like `14` is a few tokens and rarely mistyped. That cost would be
paid on every chat turn from day one. The integers' cost, clashing IDs across
two devices, is paid only if sync ever ships (it is out of scope with no plan),
and then once, by adding a random sync ID beside each integer in a migration.

## Considered options

- **UUID primary keys.** Rejected for the per-turn token and mistyping cost
  above.
- **UUID keys with short per-turn handles mapped by the tool layer.** Not
  chosen. A translation table inside the agent loop is more moving parts to
  pay for sync readiness nobody has asked for.
