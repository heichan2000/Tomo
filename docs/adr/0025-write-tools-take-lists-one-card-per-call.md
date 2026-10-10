# ADR-0025: The agent's write tools take lists, and each call is one card

- **Status:** Parked with the AI layer ([ADR-0029](0029-mvp-ships-without-ai-and-never-goes-online.md)); accepted for a future AI version
- **Date:** 2026-10-07
- **Decided in:** [#14 Agent tool contracts & system prompt](https://github.com/heichan2000/Tomo/issues/14)

`create_task`, `update_task` and `delete_task` each take a **list of 1–10
rows**, and one call produces **one confirmation card**. Each row on the card
can be unticked before approving. `create_task` may also name a **new project**
in place of an existing one, so a new piece of work becomes one card.

A reader of the PRD will expect one task per call, since the tool names are
singular. The reason for lists is the free tier. Groq's default model can't make
parallel tool calls, and its free limit is 8K tokens a minute. Every card costs
one more request (the model's reply after the card), at roughly 1.5–2.5K tokens
each. Breaking a goal into five tasks, the agent's main use, would mean five
cards in a row and five extra requests. That is five taps for the user, and
the minute's limit runs out partway through. With lists it is one card and one
request, however many rows.

## Considered options

- **One task per call, as the PRD's names suggest.** Rejected for the request
  cost above.
- **Lists for create only.** Not chosen. Bulk "mark these done" and "delete
  the old ones" have the same cost, and one shape for all three tools gives the
  card and the loop one code path.
- **All-or-nothing cards (no per-row ticks).** Not chosen. Keeping four of five
  suggested tasks would otherwise take a decline and another round with the
  model.
- **A fifth `create_project` tool.** Not chosen. A project and its tasks would be
  two cards and two requests.

## Consequences

- At most one card is shown at a time. If a provider sends several write calls
  in one answer anyway (some ignore `parallel_tool_calls: false`), only the first
  gets a card and the rest are answered "not run".
- Approved rows are written in one transaction. A storage failure undoes all of
  them. A row hit by a race (its task deleted, or a block started, while the
  card was up) is skipped and reported, and the others still apply.
- The task service gains a way to apply several rows in one transaction. Its
  per-row rules, errors and the task lock (ADR-0024) are unchanged.
