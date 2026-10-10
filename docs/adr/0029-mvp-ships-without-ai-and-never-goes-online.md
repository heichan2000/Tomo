# ADR-0029: The MVP ships without AI and never goes online

- **Status:** Accepted
- **Date:** 2026-10-07
- **Decided in:** [#50 Postpone the AI layer to a future version](https://github.com/heichan2000/Tomo/issues/50)

The PRD names an optional AI pet-agent (bring-your-own OpenAI-compatible key,
confirm-on-write task tools) as part of MVP, and five tickets designed it in
detail. It is **postponed to a future version**, with no trace in the app: no
Chat tab, no provider setup, no key, no "coming soon". A future reader will
wonder why so much decided work never shipped, and why the PRD's headline
feature is missing.

The reason is scope. The AI layer was the part of Tomo with the most failure
states, the only part that depended on third parties, and the one still waiting
on a manual probe of live providers. The focus, task and pet experience was
always required to work fully without it, so it can ship on its own.

With the AI gone, the provider calls were the only network traffic Tomo had.
That is **locked in rather than left unused**. The Android `INTERNET`
permission and the `http` package are removed, so Tomo cannot go online even by
mistake, and Settings → About says plainly that Tomo never connects to the
internet. A future AI version adds the permission back (Android does not ask the
user again for a normal permission) and rewords the line.

What changes elsewhere:

- **Navigation:** two tabs, Home · Work. 9 routes, losing the chat thread and
  the provider setup modal.
- **Faces:** the ladder is five faces, Celebrating > Still > Drowsy > Pleased >
  Resting. Thinking and Puzzled had only AI triggers. Puzzled's eye grids stay
  in the art files, parked.
- **Storage:** the chat tables, `chatCardShowing` and the `ai*` settings keys
  go. With the API key gone, so does secure storage, which leaves three stores.
- **Parked, not voided:** ADR-0002, ADR-0025, the provider research and the
  closed AI tickets keep their content, marked parked, so a future AI effort
  starts from them. Time-sensitive facts such as free-tier limits must be
  re-checked.

## Considered options

- **A teaser ("chatting with your pet is coming").** Rejected. It promises a
  feature and breaks #5's rule that no surface advertises the AI.
- **A chat tab where the pet answers with written lines.** Rejected. It is a new
  feature with its own design work, not a postponement.
- **Keep the internet permission and `http` for an easier AI version later.**
  Rejected. The saving is one manifest line and one package, and it costs the
  strongest privacy promise Tomo can make.
- **Void the AI decisions.** Rejected. It throws away decided work that a
  future version would otherwise redo.
