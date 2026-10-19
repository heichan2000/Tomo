# Tomo — Product Requirements Document (MVP)

**Product:** Tomo — a mobile project/task manager built around a Pomodoro timer, where completing focus sessions rewards a virtual pocket pet.
**Document status:** MVP scope. Every decision between this document and the first line of code is resolved in **`Tomo_Build_Spec.md`**, which wins where the two differ. The AI pet-agent is postponed to a future version ([ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md)).
**Platform:** Mobile (iOS + Android).

---

## Problem Statement

People who want to get work done struggle to actually *start* and *stay* on a single task. Existing task managers are good at listing work but do nothing to help a person focus on one thing at a time, and generic Pomodoro timers don't connect the act of focusing to any sense of progress or reward. The result is a to-do list that grows while attention scatters. Users want a tool that helps them commit to one task, focus for a real block of time, and *feel* that the effort added up to something — without the app policing them or turning into a game that replaces the real work.

## Solution

Tomo combines three things into one loop:

1. **Lightweight project/task management** — organize work into projects and tasks, one focus target at a time.
2. **A flexible Pomodoro timer** — pick a task, run a focus block, take a break; sessions can be preset or custom-length.
3. **A pocket pet as a commitment device** — completing a focus block rewards the pet with EXP; stopping early rewards nothing. The pet turns self-discipline into motivation through loss-aversion: the user focuses because they don't want to let *their* pet down, not because the app forces them to.

*(Postponed by [ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md): an **optional AI pet-agent**, chatting with the pet to create, modify, delete and scope tasks on the user's own free-tier key, is now a future version; see Out of Scope. The MVP works fully offline and never connects to the internet.)*

The guiding principle for the whole product: **EXP only *visualizes* progress — the real reward is the user's actual progress on real-life tasks.** Tomo is a task manager that motivates, not a game with tasks bolted on.

---

## User Stories

### Onboarding & first run
1. As a new user, I want to name my pet and watch it hatch on first launch, so that I feel an immediate personal bond with it. *(Amended by [ADR-0012](docs/adr/0012-earned-hatch.md): the user picks one of three starters at setup (each with its own personality, [ADR-0030](docs/adr/0030-each-pet-has-its-own-character.md)), and the egg hatches, and is named, at the end of their first finished focus block.)*
2. As a new user, I want to start managing tasks and running focus sessions without setting up anything technical, so that I can use the app instantly.
3. *(Moved to Future Versions with the AI layer, [ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md).)*

### Projects & tasks
4. As a user, I want to create projects, so that I can group related work.
5. As a user, I want to create tasks inside a project, so that my work is organized.
6. As a user, I want to give a task a title and optional notes, so that I know what it involves.
7. As a user, I want to set an estimated number of Pomodoros on a task, so that I have a sense of its size.
8. As a user, I want to see how many Pomodoros I've actually spent on a task, so that I can compare effort against my estimate.
9. As a user, I want to move a task between statuses (to-do, doing, done), so that I can track its state.
10. As a user, I want to edit or delete a task manually, so that I stay in control of my list without needing the AI.
11. As a user, I want to mark a task as done myself, so that completion always reflects my judgment.

### Focus sessions (Pomodoro)
12. As a user, I want to pick a single task and enter a focus view that hides everything else, so that I can concentrate on one thing at a time.
13. As a user, I want to choose a preset session length (e.g., 25/5, 50/10), so that I can start quickly. *(Presets are 25 min with a 5-min break and 50 min with a 10-min break; build spec §4.7.)*
14. As a user, I want to set a custom session length (minimum 10 minutes), so that the timer fits how I actually work. *(Custom: focus 10–120 minutes, break 1–30; build spec §4.7.)*
15. As a user, I want longer sessions to grant proportionally more reward, so that the reward reflects the time I actually focused.
16. As a user, I want the timer to keep running if I leave the app, so that stepping away from the screen doesn't break my session.
17. As a user, I want a notification when my block or break ends, so that I know when to switch without staring at the screen.
18. As a user, I want to stop a session early only after a confirmation, so that I don't lose my reward by accident.
19. As a user, I want stopping early to grant no reward, so that the stake of the session feels real.
20. As a user, when a block completes, I want to choose what happens next (break / another block / mark done), so that I keep control of my flow.
21. As a user, I want an option to auto-start the next block or break, so that I can chain sessions hands-free when I plan long stretches.
22. As a user, I want auto-start to be off by default, so that the app doesn't take control unless I ask it to.
23. As a user, I want breaks to grant no reward and be skippable, so that rest stays rest and I'm never punished for skipping it.
24. As a user, when my actual Pomodoros reach my estimate, I want a one-time prompt asking if the task is done, so that I'm reminded to close it out without being nagged.

### Pet, rewards & progression
25. As a user, I want my pet to gain EXP each time I complete a focus block, so that focusing feels rewarding.
26. As a user, I want a bonus reward when I complete a task, so that finishing what I started feels extra satisfying.
27. As a user, I want a short celebratory animation when a block completes, so that the reward moment feels good.
28. As a user, I want my pet to level up and evolve through visual stages as it gains EXP, so that long-term progress is visible.
29. *(Withdrawn by [ADR-0007](docs/adr/0007-no-currency-no-cosmetics.md): Tomo has no coins and no cosmetics.)*
30. As a user, I want my pet to only ever grow and never decay or get sad when I'm away, so that the app never guilts me for not using it.
31. As a user, I want my pet's EXP to keep accruing with no designed cap, so that there's always a number moving even after all evolutions.

### AI pet-agent

*Stories 32–42 moved to Out of Scope (Future Versions) with the AI layer ([ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md)).*

### Stats & history
43. As a user, I want a lightweight stats screen showing sessions completed, current streak, and pet level, so that I can see what I've accomplished. *(Amended by #21, ADR-0026: there is no streak. Stats shows level, time focused, blocks finished and **days focused**, a count of days with at least one finished block that only grows.)*

---

## Implementation Decisions

### Architecture: offline-first, never online
- The **whole app runs on-device and offline**: task CRUD, the Pomodoro timer, pet EXP and evolution, and stats. *(Amended by [ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md): with the AI layer postponed, Tomo **never connects to the internet**. The Android `INTERNET` permission and any HTTP client are absent, and a test enforces it.)*
- **No first-party backend.**

### AI provider integration and credential handling
*Moved to Out of Scope (Future Versions) with the AI layer ([ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md)). The decisions already made for it (provider presets, tool contracts, chat history, credential handling) are parked, not voided; see `Tomo_Build_Spec.md` §19.*

### Data model (MVP)
- **Two-level hierarchy: Project → Task.** No subtasks in MVP. If the agent needs to break work down, it creates sibling tasks.
- **Task fields:** title, optional notes, parent project, status (to-do / doing / done), estimated Pomodoros, actual Pomodoros.
- **Actual Pomodoros** increments by one each time a focus block on that task completes.
- **Pet EXP is stored on a pet entity, not on the user account.** MVP ships a single pet, but modeling EXP per-pet now makes the future multi-pet, per-pet-progression feature a data migration rather than a rewrite.
- **EXP ceiling** is the 32-bit signed integer maximum (~2.1B) as a technical bound, not a designed cap; no user is expected to reach it.
- **Storage:** local, single-device (e.g., on-device SQLite). No sync in MVP.

### Reward economy
- Reward is **linear in completed focus minutes** (more minutes focused → proportionally more EXP). Time is a genuine finite resource the user actually spends, so linear scaling plus the guardrails below removes farming without a super-linear curve.
- **Minimum session length: 10 minutes.** Prevents trivially short sessions from farming rewards.
- **Hard zero on early stop.** A block that is stopped before completion grants nothing. This all-or-nothing stake is the mechanism behind the pet's motivational pull.
- **Task-completion bonus** fires once when the user marks a task done.
- **Breaks grant nothing** and are skippable.
- Rewards are for *completed blocks only* — starting a long block and stopping early cannot collect partial credit.

### Session flow & control
- Focus flow: pick task → focus view (task + timer + pet, everything else hidden) → run block → on completion, reward beat + increment actual Pomodoros → user chooses next action (break / another block / mark done).
- **Manual advance by default;** an optional **auto-start toggle** (off by default) chains the next block/break automatically for users running planned long loops.
- **No auto-completion of tasks** on reaching the estimate. When actual reaches estimated Pomodoros, show a **single "Is this task done?" prompt**, then stay quiet.
- **Trust model:** the timer runs via local notifications and continues if the user leaves the app. Tomo does **not** detect or penalize app-switching. The pet is the conscience, not a cop — focus is rewarded on timer completion, and the user is trusted.

### Pet lifecycle (MVP)
- **Single pet**, EXP-driven **levels** with a finite set of **evolution stages**. *(Three starters — Geode, Joe, Lily — are offered at setup; the user picks one and keeps it forever. Four stages at levels 1/10/40/100, [ADR-0001](docs/adr/0001-flat-level-curve.md).)*
- **No currency and no cosmetics.** EXP is the pet's only reward number; there are no coins and nothing to buy ([ADR-0007](docs/adr/0007-no-currency-no-cosmetics.md)).
- **Grow-only. No decay, no neglect/sadness mechanic.** Absence never harms the pet.

### Onboarding
- First-run **hatch-and-name** moment: the user names the pet and sees it hatch. Minimal but real — it establishes the emotional hook immediately. *(Amended by [ADR-0012](docs/adr/0012-earned-hatch.md): setup is two screens and ends with an egg; the hatch and naming come at the end of the first finished focus block, so the hook is earned.)*

---

## Testing Decisions

Good tests here assert **external, user-observable behavior**, not internal implementation. The highest-value seams to test:

- **Reward engine** (pure logic, no UI/network): given a session's length and completion state, assert the EXP granted. Cover: completed block grants linear-to-minutes reward; sub-10-minute sessions are disallowed/unrewarded; early stop grants exactly zero; task-completion bonus fires once and only on user-marked completion; breaks grant nothing. This is the economically load-bearing logic and should be tested in isolation from UI.
- **Session state machine**: assert transitions — idle → running → completed → (break / next block / done) — including that early stop routes to the zero-reward path, and that the auto-start toggle changes only the advance behavior, not the reward.
- **Estimate-hit prompt**: assert the "is this done?" prompt fires exactly once when actual reaches estimated, and does not re-fire on subsequent blocks.
- **Task CRUD**: assert create/edit/delete/status-change behavior through the same interface the UI and the agent both use, so manual and agentic paths share one tested seam.
- *(Agent tool-calling boundary and credential storage: parked with the AI layer, [ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md).)*
- *(What the MVP promises, and how each promise is kept, is listed in `Tomo_Build_Spec.md` §16.)*

Prefer testing task CRUD through a single service/seam that both the UI and the agent call, so there is one behavior to verify rather than two divergent paths.

---

## Out of Scope (Future Versions)

The following are explicitly **not** in the MVP and are parked for later grill sessions:

- **The AI pet-agent** ([ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md)) — chatting with the pet to create, modify, delete and scope tasks, through a generic OpenAI-compatible endpoint on the user's own free-tier key (bring-your-own-key), with structured tool calls (`list_tasks`; `create_task`, `update_task`, `delete_task` behind a confirmation card), and the key held in the platform secure store, never logged, never backed up, and sent only to the user's own provider when they chat. Its user stories, moved here from the MVP list:
  - As a new user, I want the AI chat to stay out of my way until I choose to use it, so that the app never feels blocked behind setup. *(was 3)*
  - As a user, I want to be prompted to connect an AI provider only when I first tap to chat with my pet, so that the AI is opt-in and contextual. *(was 32)*
  - As a user, I want to use a free AI provider by supplying my own API key, so that the AI features cost me nothing. *(was 33)*
  - As a user, I want to configure any OpenAI-compatible endpoint (base URL, key, model), so that I can choose my provider. *(was 34)*
  - As a user, I want my API key stored securely on my device, so that my credential is never exposed, synced, or logged. *(was 35)*
  - As a user, I want to chat with my pet to create tasks, so that I can capture work naturally in conversation. *(was 36)*
  - As a user, I want the pet to ask me to confirm before it creates, modifies, or deletes any task, so that the AI never changes my data without my approval. *(was 37)*
  - As a user, I want advisory conversation (planning, scoping, breaking down a goal) to flow freely without confirmation prompts, so that talking to my pet feels natural. *(was 38)*
  - As a user, I want the pet to be aware of my current projects and tasks, so that it can answer "what should I focus on?" and avoid duplicates. *(was 39)*
  - As a user, I want every action the AI can take to also be doable manually by tapping, so that I never depend on the AI to manage my work. *(was 40)*
  - As a user, I want the app to work fully offline except for AI chat, so that a lost connection never stops me from focusing. *(The MVP is fully offline.)* *(was 41)*
  - As a user, I want my task content to be sent only to my own configured provider and only when I use chat, so that I control where my data goes. *(was 42)*

  Parked decisions to start from: issues #4, #6, #14, #20, #27 and #28; ADR-0002 and ADR-0025; `docs/research/2026-08-18-ai-provider-free-tiers.md`. Re-check free-tier limits and terms first.

- **Cloud sync / multi-device** — MVP is local, single-device.
- **Due dates, tags, and priority** on tasks.
- **Subtasks** (three-level hierarchy).
- **Multiple collectible pets** — planned: 3 default pet options plus more unlocked via achievements (e.g., 100 sessions, EXP thresholds — set to expand). Each pet has **individual progression** (a session rewards only the active pet). **Gacha-style** pet unlocks also deferred here.
- **Achievements system** and the **analytics-grade stats/history screen** it requires (MVP ships only a lightweight stats screen; the richer analytics redesign rides with achievements).
- **Stats/history-aware agent** — MVP agent is task-aware only; a future agent can see focus history, session stats, and pet state for richer coaching.
- **Autonomous agent mode** for power users — MVP is strictly confirm-on-write.
- **Functional or paid-tier unlocks** — MVP pet progression is purely visual; no features are gated behind progression or payment.

---

## Further Notes

- **Positioning:** the differentiator versus "a task app plus any timer" is the pet-as-commitment-device and the conversational agent as a *native* interface to task management *(the agent is now a future version, [ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md))*. The motivation mechanic depends on a *relationship with one pet*, which is why MVP deliberately ships a single companion rather than a roster.
- **Design north star:** EXP visualizes real progress; it is never the point. Every gamification decision should be checked against "does this keep the real-life task as the true reward?" — this is why there's no decay mechanic and no functional gating.
- **Graceful degradation** is a hard requirement: no connection and no API key must still yield a fully working focus/task/pet experience. The AI is an enhancement, never a dependency. *(In the MVP there is no network use at all.)*
- **Data-egress summary (for privacy review):** *(Rewritten by [ADR-0004](docs/adr/0004-no-telemetry-allowlisted-diagnostics.md), [ADR-0028](docs/adr/0028-pet-travels-in-the-phone-backup.md) and [ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md).)* **Tomo never connects to the internet.** Nothing leaves the device except a diagnostic log the user chooses to share (it holds no user content, by construction), and the user's data travelling in the phone's own backup, which the user turned on. The phone's operating system may send crash reports to Apple or Google under its own settings; Tomo neither enables that nor sees it. Tomo ships no telemetry.
