# ADR-0024: A running block locks its task

- **Status:** Accepted
- **Date:** 2026-10-06
- **Decided in:** [#11 Task service seam contract](https://github.com/heichan2000/Tomo/issues/11)
- **Amended by:** [ADR-0029](0029-mvp-ships-without-ai-and-never-goes-online.md) (the agent's pre-card check is parked with the agent) and by consolidation ([Consolidate: write Tomo_Build_Spec.md](https://github.com/heichan2000/Tomo/issues/25), `Tomo_Build_Spec.md` §17 R22): **after the block, marking the task done no longer ends the cycle.** It settles if owed and applies the done (with the bonus), and the cycle carries on so the break can still be taken; only another block on that task is ruled out. Deleting still ends the cycle as *Leave* does. The lock itself is unchanged.

While a focus block is running, the task service **refuses** to delete its
task, to delete the project that holds it, or to mark it done. It returns
`blockRunning`, and the Work tab says in plain voice to stop the block first.
The agent's tool layer runs the same check before it shows a confirmation card,
so the user is never asked to approve a write that is bound to fail. Edits,
moves and to-do/doing changes are still allowed and never touch the block.

The reason is that *early stop* costs the whole block, and it has a single door:
the *Stop early* button, behind a confirmation that states the rule. If delete
or mark-done could end a running block, there would be a second, hidden door
that throws away a block in progress as a side effect of tidying the list.
Mark-done has a second problem: if the block kept running instead, the
completion bonus would be paid before that block's minutes were added, and the
user would lose bonus on the block they were in.

Once the block has ended (post-block, on a break, or break over), delete and
mark-done are allowed. One transaction settles the block if it is still owed,
ends the cycle as *Leave* does, then applies the change. A finished block is
never lost.

## Considered options

- **Delete the task and discard the running block.** Rejected. The user loses
  a block in progress without being asked, which is the unearned loss
  grow-only rules out.
- **Delete the task but let the block run on with no task.** Rejected. The
  live cycle needs a task: Focus, the banner and the timer notification all
  name it.
- **Mark done and let the block keep running.** Rejected for the bonus
  ordering above.

## Consequences

Stopping early stays the only way a running block ends before its end time.
The agent path has a write that can fail after approval only through a race
(a block starts between the card appearing and the tap), and the service
answers that with the same `blockRunning` error.
