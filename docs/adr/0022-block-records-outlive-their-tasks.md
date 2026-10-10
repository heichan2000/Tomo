# ADR-0022: Block records outlive their tasks; deletes are real

- **Status:** Accepted
- **Date:** 2026-10-06
- **Decided in:** [#10 Drift schema & storage inventory](https://github.com/heichan2000/Tomo/issues/10)
- **Amended by:** [ADR-0026](0026-no-streak-days-focused.md) — no streak ships;
  Stats counts *days focused*, which only grows.

Deleting a task or project is a **hard delete** that removes the user's words
(title, notes, project name) for good, but the task's *block records* stay,
with their task and project links set to null (`ON DELETE SET NULL`). Stats is
built from block records, so nothing it shows (blocks completed, the streak if
one ships) can go down because the user tidied their list. Grow-only applied to
history. The pet's EXP is unaffected either way, because it is stored on the
pet and not summed from blocks.

## Considered options

- **Soft delete (a hidden flag).** Rejected. Every task query grows a filter.
  Worse, "delete" stops deleting: text the user asked to remove stays on disk,
  which works against the privacy story ADR-0002 and ADR-0004 tell.
- **Cascade the block records with the task.** Rejected. Totals and streaks
  would drop for an unrelated, tidy-minded action. That is unearned loss, the
  same thing #3 and #8 rule out.
- **Keep a copy of the task title on each block record.** Rejected for the same
  reason as soft delete: the words would outlive the delete in a hidden place.

## Consequences

A block record is a fact about the past and is never rewritten. It keeps the
project the task was in **when the block was settled**, even if the task moves
project later. Unlinked records still count everywhere a count is shown. They
just can't say what they were for.
