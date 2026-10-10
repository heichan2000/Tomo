# ADR-0002: The stored thread is what the user sees — tool traffic is wire-only

- **Status:** Parked with the AI layer ([ADR-0029](0029-mvp-ships-without-ai-and-never-goes-online.md)); accepted for a future AI version
- **Date:** 2026-08-18
- **Decided in:** [#4 Chat history: persisted, ephemeral, or capped?](https://github.com/heichan2000/Tomo/issues/4)

## Context

Tomo's agent runs a hand-rolled OpenAI-compatible tool loop: a read-only
`list_tasks` tool the model calls on demand, plus three write tools that suspend
on a confirmation card rather than executing. A turn therefore produces two
different kinds of message. Some are things the user reads — their own text and
the pet's prose. Others are protocol traffic the user never sees: an assistant
message carrying `tool_calls`, and the `tool` result that answers it.

Once chat history is persisted at all — decided in the same ticket, on the
grounds that a pet which forgets between launches contradicts the PRD's
"relationship with one pet" positioning — something has to say which of those
two kinds goes on disk.

The obvious answer is *all of it*. Almost every tool-calling implementation
keeps one message array, appends everything to it, and replays a suffix as
context. It is the least code and the highest fidelity: the model sees exactly
what happened.

That obvious answer carries two defects, and they only surface in long
conversations, which is to say after release.

**Orphaned pairs.** The protocol requires that an assistant message carrying a
`tool_call` be immediately followed by the matching `tool` result. Providers
reject a request where that invariant is broken. A sliding window is a *cut* at
a fixed offset, and nothing stops that cut landing between a call and its
result. The failure is a provider-side rejection that depends on where the
boundary happens to fall — intermittent, conversation-length-dependent, and
awkward to reproduce.

**Stale snapshots.** A `list_tasks` result is true at the instant it is
produced and decays immediately. Replayed three turns later it can lead the pet
to describe a task list that has since changed, or to reference a task the user
already deleted. This is a correctness problem wearing the costume of a model
hallucination, which makes it expensive to diagnose.

Both are solvable by adding machinery — boundary logic that never slices a pair,
plus a rule that strips or refreshes old tool results. That machinery is
permanent, and it is load-bearing for correctness.

## Decision

**Only user-visible messages are persisted.** The `chat_messages` table stores
the user's text and the pet's prose. Tool calls and tool results exist for the
duration of one turn's loop and are then discarded.

Storage and wire are **separately bounded**, because they answer to different
pressures:

- **Disk: 500 messages**, oldest pruned. Bounded by privacy footprint and how
  far anyone will ever scroll — not by space, since 500 messages is roughly
  100 KB.
- **Wire: the last 20 messages**, plus the system prompt. Bounded by free-tier
  provider limits.

No summarization pass. The window is a plain suffix of the stored thread.

## Consequences

**Every window cut is protocol-valid by construction.** The stored thread is a
flat alternation of user and assistant messages with no pairs to break, so the
orphaned-pair failure cannot occur — not "is handled", cannot occur. This is the
main reason for the decision.

**The pet never answers from a stale task list.** Task state is read fresh
through `list_tasks` or not at all, which makes the tool the single source of
task truth and keeps the transcript out of that job.

**The model may re-call `list_tasks` on consecutive turns**, having no record it
already looked. This is the accepted cost. It is a local SQLite read, it costs
no provider request, and fetching fresh is the behavior we want anyway.

**A 20-message window is defensible only because of this split.** The durable
facts live in the task database; the transcript carries short-range
conversational continuity — "break that down further", "no, the second one".
Long-range recall is the tool's job, not the transcript's, so the window can
stay small without the pet feeling forgetful.

**A pending confirmation cannot survive process death.** The suspended loop and
its un-persisted tool call are memory-resident. This is a direct consequence
rather than a separate decision, and it forces the lapsed-proposal line: on
interruption the thread gets a deterministic in-voice note, because whether the
model emitted prose alongside its `tool_call` varies by provider, and a thread
that sometimes dangles reads as a bug.

**Drift stays free of tool-call JSON**, and task-list snapshots never reach
disk — which keeps the privacy surface to the conversation itself and makes
`DELETE FROM chat_messages` a complete wipe.

**Reversing this is cheap.** Unlike the level curve, nothing user-facing depends
on it; a later version that wants full-fidelity transcripts adds a table and the
boundary machinery. The cost of the decision is paid in re-reads, not in
migration risk.

## Alternatives considered

**Persist and replay verbatim.** One message array, full fidelity, least code
up front. Rejected: it buys that simplicity by taking on both the orphaned-pair
failure and the stale-snapshot failure, each of which then needs permanent
correctness-critical machinery to contain.

**Persist in full, strip on replay.** Keeps a faithful transcript on disk for
debugging while sending only user-visible messages. Solves both failures.
Rejected: it puts tool JSON and task-list snapshots in Drift for no user-facing
benefit, enlarging the privacy surface to buy a debugging convenience that logs
serve better.

**Wire-only, plus a persisted action line** ("checked your tasks", "created
'Draft outline'"). Same correctness properties, with a richer scrollback
narrative and a light audit trail. Not rejected on merit — deferred. It is
additive, it is a copy and design question rather than a storage one, and it
belongs with the chat screen design (#20) and the pet's written voice.

**Summarized head plus recent window.** Best continuity per token. Rejected on
the specific economics of the providers Tomo targets: free tiers throttle on
**requests per minute first, tokens second**, so a summarization pass spends an
extra request to save tokens — the wrong currency — and adds a failure path when
the summarizing call itself is throttled.
