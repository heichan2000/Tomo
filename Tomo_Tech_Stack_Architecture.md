# Tomo — Tech Stack & Architecture

**Companion document to:** Tomo_PRD_MVP.md
**Scope:** MVP. The resolved specifics (schemas, contracts, screens, packages) are in **`Tomo_Build_Spec.md`**, which wins where the two differ. **The AI pet-agent is postponed to a future version and the MVP never goes online** ([ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md)); the sections that describe it are kept, marked parked.
**Build goal:** Product-optimized — every choice is judged on "does this ship the best Tomo," not on portfolio value.

---

## 1. Overview

Tomo is an offline-first Flutter application. The entire core experience — task management, the Pomodoro timer, the pet and its rewards, and stats — runs on-device with no network dependency. A single optional layer, the AI pet-agent, reaches out to a user-supplied LLM endpoint; everything else works with no connectivity and no account. *(MVP: the AI layer is parked, so Tomo never connects to the internet at all, [ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md).)*

The architecture is organized around three ideas that recur throughout this document:

- **Offline-first split.** The core loop is fully local; only AI chat requires the network. AI unavailability is a normal state the app wears comfortably, never an error that makes the app feel broken. *(MVP: no network use at all.)*
- **One seam per behavior.** Task reads and writes flow through a single Drift-backed service that both the UI and the AI agent call. Manual and agentic paths are the same code, tested once.
- **Ground truth over live state.** The timer is derived from stored timestamps, not a running tick, so it survives backgrounding, suspension, and the app being killed.

---

## 2. Stack at a Glance

| Layer | Choice | Why |
|---|---|---|
| Client framework | Flutter (iOS + Android) | One codebase; best-in-class custom animation for the pet and focus UI; modest native needs |
| Relational storage | Drift (typed, reactive SQLite) | Data is relational and growing; reactive streams; compile-time-checked queries; testable seam |
| Preferences/flags | Key-value store (shared_preferences) | Simple settings: appearance, auto-start, Calm pet, last-used lengths and project (selected pet and onboarding are the pet row; build spec §6.3) |
| Secret storage | *Parked with the AI layer* — flutter_secure_storage held only the API key | None in MVP |
| Timer | Timestamp-anchored + scheduled local notifications | Immune to OS suspension; reward reflects real elapsed time |
| State management | Riverpod + explicit session state machine | Layers over Drift streams; highly testable; explicit transitions where they matter |
| AI agent | *Parked with the AI layer:* hand-rolled tool loop vs OpenAI-compatible endpoint | Owns the confirm-on-write control flow; provider-agnostic; fully testable |
| Pet art | Pixel art as text grids in Dart, drawn by Claude, approved by the user | Diffable, testable, compiled in so it can't fail to load; no editor or image pipeline |
| Pet animation | Flutter, sliding six pixel parts in whole pixels | Shared, unit-testable movement code; no runtime dependency; driven from app state |
| Incidental FX | Small pixel sprites painted on the pet's grid | Sparkles and confetti in the pet's own pixels and colours |
| Testing | Unit + mocked-agent + in-memory Drift + light widget | Rigor concentrated on load-bearing correctness |

---

## 3. Client Framework — Flutter

Flutter is the client for the whole app, both platforms from one codebase. Tomo is UI- and animation-forward (a reactive pet, evolution transitions, reward moments, a focus view that must feel alive) with only modest platform-API needs (local storage, notifications, secure storage). That profile is Flutter's sweet spot: its widget and animation system makes the pet and focus UI a strength rather than a chore, and there is no second codebase to maintain.

Native (Swift + Kotlin) was rejected because it doubles the build for little gain at this app's complexity. React Native was rejected because it fights hardest on exactly the two things Tomo leans on most — custom animation and reliable background timing.

---

## 4. Data & Persistence

### 4.1 Three-way storage split

*(Amended by [ADR-0004](docs/adr/0004-no-telemetry-allowlisted-diagnostics.md), [ADR-0028](docs/adr/0028-pet-travels-in-the-phone-backup.md) and [ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md): the MVP stores data in the Drift database, the key-value store, a small device-only file and the diagnostic log; there is no secure storage. Inventory, schema and backup rules: build spec §6.)*

Storage is deliberately separated by kind of data, so nothing sensitive or relational lands in the wrong place:

- **Drift (SQLite)** — all app data: projects, tasks, pet, and completed sessions. Relational, queryable, reactive.
- **Key-value store** — non-secret preferences and flags: the auto-start toggle, onboarding-complete flag, selected pet, AI provider config that isn't secret (base URL, model name may live here or alongside the key).
- **flutter_secure_storage** — the API key only. Never in Drift, never in the key-value store.

### 4.2 Why Drift

Tomo's data is relational (a task belongs to a project) and gets more so over time (future due dates, tags, priority, multiple pets). Drift provides compile-time-checked queries, an easily-mockable data-access layer, and reactive streams that make the live-updating task list and stats screen nearly free. It also offers an in-memory database mode used heavily in testing (see §10).

### 4.3 Data model (MVP)

Two-level hierarchy, no subtasks:

- **Project** → **Task**
- **Task fields:** title, optional notes, parent project, status (to-do / doing / done), estimated Pomodoros, actual Pomodoros.
- **actual Pomodoros** increments by one each time a focus block on that task completes.

**Pet EXP is stored on a pet entity, not the user account.** MVP ships a single pet, but modeling EXP per-pet now makes the future multi-pet, per-pet-progression feature a data migration rather than a rewrite. The EXP field uses a 32-bit signed integer; its maximum (~2.1B) is a technical bound, not a designed cap.

Storage is local and single-device for MVP. No sync.

---

## 5. Security & Credential Handling

*(Parked with the AI layer, [ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md): the MVP holds no credential. "Android auto-backup is disabled" is reversed by [ADR-0028](docs/adr/0028-pet-travels-in-the-phone-backup.md) — the database and settings travel in the phone's own backup. "Error reporting must scrub it" is replaced by [ADR-0004](docs/adr/0004-no-telemetry-allowlisted-diagnostics.md)'s allowlisted diagnostic log. The MVP's privacy claim is build spec §13. The section below is kept for the future AI version.)*

The API key is the only true secret in MVP, and it is treated as sensitive **even though it is a free-tier key** — a leaked free key can still be abused against the user's quota or account.

- **Storage:** flutter_secure_storage, backed by iOS Keychain and Android Keystore.
- **Never synced:** Android auto-backup is disabled for MVP. Because Tomo is local-only single-device, nothing needs backing up, and disabling it guarantees the key never leaves the device.
- **Never logged:** the AI-provider layer must never log request bodies or headers containing the key, and error reporting must scrub it. This is a standing build convention, enforced during debugging as well.
- **Transmitted only** to the user's own configured provider endpoint, and only when the user uses chat.

**Data-egress summary (for privacy review):** task content leaves the device only on user-initiated chat, only to the user's configured provider, with the key held in the secure store. Nothing is synced or logged by Tomo.

---

## 6. The Timer — Timestamp-Anchored

The background timer is the hardest technical problem in Tomo, because mobile OSes aggressively suspend backgrounded apps. A naive in-app countdown that ticks every second will drift or freeze the moment the app loses foreground. Tomo therefore never depends on a running tick.

### 6.1 Design

- **Anchor on timestamps.** When a block starts, store its **start time** and intended **end time**. The on-screen countdown is a UI animation derived from `now` versus those anchors whenever the view is visible. If the app is suspended for ten minutes and resumes, the math is still correct because nothing depended on continuous ticking.
- **Schedule completion as a local notification.** A scheduled (alarm-style) local notification is registered for the end timestamp via `flutter_local_notifications`, so the OS alerts the user even if the app is fully suspended.
- **Reconcile on resume.** When the app returns to foreground, recompute elapsed time from the anchors. If the end timestamp has passed, treat the block as completed and grant the reward exactly as if the user had watched it finish.

### 6.2 Rulings this encodes

- **A block completes on elapsed wall-clock time.** If the user never reopens the app after a block ends, the reward is granted on next open by reconciling from timestamps. A completed block is never lost.
- **Early stop = hard zero, cleanly.** Stopping early cancels the scheduled notification and discards the anchors, so there is nothing to reconcile and nothing to credit. The early-stop and timestamp mechanics fit together.
- **The notification is a convenience, not the source of truth.** Reward accuracy depends on the timestamps, not on the notification firing punctually.

### 6.3 Platform permissions

*(Made concrete by [#15](https://github.com/heichan2000/Tomo/issues/15): Android declares `USE_EXACT_ALARM`, and the permission prompt anchors the block only after it closes. Build spec §11.)*

- **Android exact alarms:** requested, with graceful fallback. If denied, the completion notification may fire slightly late, but reconciliation-on-resume still credits the block correctly.
- **iOS notifications:** requested contextually at first session start, not at launch. If denied, the timer still completes correctly on resume — the user simply doesn't get the alert.

---

## 7. State Management — Riverpod

Riverpod is the app-wide state solution. It layers cleanly over Drift's reactive streams (the task list and stats screens simply watch providers), and its provider-override mechanism makes the reward engine, session state machine, and agent tool-layer trivially testable in isolation.

*(Amended by #24: those three, and every other rule that is not a screen, live in the plain-Dart `packages/tomo_core`, which has no Flutter or Riverpod dependency at all ([ADR-0027](docs/adr/0027-plain-dart-core-package.md)). Riverpod lives only in the app, written by hand without code generation, and wires core's plain classes to the screens.)*

The **session lifecycle is modeled as an explicit, enumerated state machine** (idle → running → completed → break / next block / done). This is Tomo's most transition-heavy and most bug-prone logic, so it is represented explicitly regardless of the surrounding tooling, and its transitions are directly unit-tested.

### 7.1 Session flow

1. Pick one task → enter focus view (task + timer + pet visible, everything else hidden).
2. Start block → timestamp anchors set, completion notification scheduled.
3. On completion → reward beat (pet animates, EXP granted), task's actual-Pomodoro count increments.
4. User chooses next action → **break**, **another block**, or **mark done** (fires the task-completion bonus).
5. Breaks grant nothing and are skippable.

**Manual advance is the default.** An optional **auto-start toggle** (off by default) chains the next block or break automatically, for users running planned long loops. When the actual Pomodoro count reaches the task's estimate, a **single "Is this task done?" prompt** appears, then stays quiet — the estimate never changes task state on its own.

**Trust model:** the timer runs via local notifications and continues if the user leaves the app. Tomo does not detect or penalize app-switching. Focus is rewarded on timer completion; the user is trusted. The pet is the conscience, not a cop.

---

## 8. AI Pet-Agent

*(Parked with the AI layer, [ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md). Nothing in this section ships in the MVP. Its decisions are kept for a future version; see build spec §19.)*

The agent is what makes Tomo more than a timer. It is an optional layer, gated behind the user supplying their own free-tier API key, and it is built as owned, provider-agnostic, fully-testable code.

### 8.1 Provider integration

The agent speaks a **generic OpenAI-compatible chat-completions interface** (base URL + API key + model name) rather than any single vendor's SDK. This reaches free-tier providers (e.g. a Gemini-compatibility endpoint, Groq, OpenRouter) and self-hosted servers through one integration. There is no first-party backend and no first-party key: the cost of AI is borne by the user via their own free-tier key.

### 8.2 The tool loop (hand-rolled)

The defining requirement — **advisory chat flows freely, but every data-mutating action pauses for user confirmation** — is a custom control flow. It is hand-rolled rather than delegated to an agent framework, because most frameworks assume autonomous tool execution and fight the mandatory human-in-the-loop pause.

Structure:

- **Tool registry** defines four tools, sent to the model each call:
  - `list_tasks` — read-only. On a read call, the loop executes it and feeds the result back automatically.
  - `create_task`, `update_task`, `delete_task` — writes. On a write call, the loop **does not execute**. It emits a `PendingConfirmation` (the confirmation card), suspends, and only runs the Drift mutation when the user approves. On rejection, the loop resumes with a "user declined" tool result so the model can respond gracefully. *(Amended by #14: each write tool takes a list of 1–10 rows and one call is one card, with rows the user can untick ([ADR-0025](docs/adr/0025-write-tools-take-lists-one-card-per-call.md)); `create_task` may name a new project; at most 6 provider requests per user message.)*
- **Confirmation as emitted intent.** The loop emits an intent and awaits a result; the UI renders the card and returns approve/reject. The loop stays UI-agnostic (and therefore unit-testable by feeding it synthetic approvals); the UI stays dumb.
- **One shared seam.** Both read and write tools call the **same Drift-backed task service the UI uses**, so manual and agentic paths are identical and identically tested.
- **Provider client** pulls the key from secure storage at call time and never logs it.
- **Non-streaming for MVP.** The loop waits for the full response before branching on tool calls; streaming advisory text is deferred polish.

### 8.3 Context — task-aware

The agent is task-aware via the read-only `list_tasks` tool it calls when needed, rather than injecting the full task list into every prompt. This keeps token usage proportional — small talk stays cheap, only task queries pull data — which matters on free-tier rate limits. Focus-history and stats awareness is deferred to a future version.

### 8.4 Setup & degradation

- **Setup:** a short list of **provider presets** (each prefilling base URL + a default model) plus an **"Advanced / custom endpoint"** escape hatch exposing the raw fields. The common path is "pick provider, paste key, done."
- **Validation:** after config entry, a single cheap test call confirms the key/endpoint/model work, distinguishing bad key (auth), wrong URL/model (not found), and no network — before saving to secure storage.
- **Model:** default per preset, editable in Advanced.
- **Gating:** the pet is always present and rewards work with zero key. Only the chat/agentic layer is gated; the key prompt appears the first time the user taps to chat.
- **Runtime failures:** when a call fails after setup (free-tier quota exhausted, network drop), the pet shows a friendly in-character "I can't think right now" state with the reason available on tap. The rest of the app is unaffected. Free-tier rate limits are treated as a normal condition, not an error. *(Amended by #14: the reason is one of five failure groups, shown as a plain-voice notice in the thread, never in the pet's voice (ADR-0021).)*
- **Manual equivalence:** every action the agent can take is also doable by tapping. The AI is a shortcut, never the only way to manage work.

---

## 9. Pet Art & Animation Pipeline

Tomo is **pixel art**, pets and chrome alike, in a light theme and a true-black dark theme. This section was rewritten by [Wayfinder: Tomo pixel look, light and dark](https://github.com/heichan2000/Tomo/issues/32); the earlier plan (a vector-style pet generated with Flux and rigged in Rive, later layered SVG) is gone. Full detail lives in the ADRs named below and in `docs/pet-art-style-guide.md`.

### 9.1 The art — text grids in the code

All pixel art is **text grids in Dart source**: one character per pixel, `.` for clear, plus a colour key ([ADR-0020](docs/adr/0020-pixel-art-as-text-grids-in-code.md)). That covers the pets, their eggs and eye sheets, the reward sparkles, the 12×12 interface icons and the *Tomo egg* on the app icon. The model is `lib/art/pixel_art.dart`; each species is one file in `lib/art/pets/`.

- **Claude draws, the user approves.** There is no pixel editor and no image generator. The user says what to change; Claude edits the grid.
- **Each drawing is a draft or approved.** An approval holds a fingerprint (SHA-256) of the exact pixels and colours. One art test fails a release build if any drawing is missing, a draft, or changed since approval.
- **Review pages are generated from the code** (`node tool/art/review_page.mjs`), showing each drawing on both grounds with every movement and its checks.
- **Compiled in.** The grids are part of the binary, so the pet is there on the first frame and nothing can fail to load. All three species ship; as text, all the art is a few hundred KB.
- **The only image files** are the app icon and splash, generated from the Tomo egg grid by a script and committed.

### 9.2 Painting — whole screen dots

A pet is drawn on one **48×48 pet grid**, every stage and the egg standing on the same bottom row ([ADR-0014](docs/adr/0014-starter-sprites-one-grid-whole-screen-dots.md)). The app paints each grid itself as squares of a **whole number of screen dots** per pixel, never smoothed, so every pixel is sharp and the same size on every phone. The species accent the chrome uses is read straight from the pet's colour key ([ADR-0015](docs/adr/0015-light-and-true-black-accent-from-the-pet.md)).

### 9.3 Movement — parts slide in whole pixels

Each stage is split into six **parts** (`body`, `head`, `eyes`, `limbA`, `limbB`, `accent`) and the pet moves by sliding them in whole pixels, never smoothly and never by swapping whole drawings ([ADR-0018](docs/adr/0018-pixel-pets-slide-whole-pixels-flicker-evolution.md)). Expressions swap only the eyes, from one **eye sheet** per species. Every movement is shared Flutter code over the parts, so it is written once for all twelve stages and unit-tested; a species only names which parts take part. What the pet shows is the *pet look* plus the *beat queue* ([ADR-0009](docs/adr/0009-derived-pet-look-persisted-beat-queue.md)), driven from Riverpod state.

- **Evolution** is the *evolution flicker*: old and new stage swap five times, never more than three in a second. The **hatch** shakes the egg and breaks its shell apart instead.
- **Reduce motion**: nothing moves more than one pixel, the breath runs at half speed, and the flicker and hatch become a cross-fade.

### 9.4 Reward effects

Celebrations are a **reward ladder** ([ADR-0019](docs/adr/0019-reward-ladder-twinkle-in-pet-pixels.md)): sparkles that open and close in place, confetti and the flying shell, all **small pixel sprites painted in pet pixels** on the pet's grid. They are not Lottie clips, and nothing is added to the dependency list for them.

### 9.5 Chrome and type

The interface is pixel too: *quiet steps* chrome measured in UI pixels ([ADR-0017](docs/adr/0017-quiet-steps-pixel-chrome.md)) and one bundled pixel font, Ark Pixel 12px Proportional (Latin subset), always drawn at sharp sizes ([ADR-0016](docs/adr/0016-one-pixel-font-sharp-sizes.md)). Two `ThemeData`s, light and dark.

---

## 10. Testing Strategy

*(Superseded by [#52](https://github.com/heichan2000/Tomo/issues/52): the MVP carries a **promises list**, each promise with a keeper, and done means `tool/check` passes, with no coverage number, no golden tests and no end-to-end suites. Build spec §16. The agent-loop and credential bullets below are parked with the AI layer.)*

Rigor is concentrated where correctness is load-bearing, not spread uniformly. The risk in Tomo is not whether a button renders — it is whether the reward math is exploitable, whether a session transition leaks a reward, and whether the agent can mutate data without confirmation. All of those are pure-logic or mocked tests that are cheap and fast.

**MVP testing depth:**

- **Unit tests (deep) on the three critical seams:**
  - *Reward engine:* completed block → linear-to-minutes reward; sub-10-minute sessions unrewarded; early stop → exactly zero; task-completion bonus fires once and only on user-marked completion.
  - *Session state machine:* every transition, especially early-stop → zero-reward path, and that the auto-start toggle changes only advance behavior, not reward.
  - *Estimate-hit prompt:* fires exactly once at estimate, never re-fires.
  - *Agent tool-loop* (provider faked with `http`'s built-in `MockClient`, Tomo's own seams with `mocktail`; no `mockito`, per #24): reads execute and feed back; writes emit `PendingConfirmation` and mutate only on approval; rejects resume gracefully; advisory turns mutate nothing.
- **Data layer:** tested against Drift's in-memory database — a real SQLite engine, no device needed.
- **Credential:** the key is read/written only via secure storage and never appears in logs or exported state.
- **Widget tests (light):** highest-stakes UI only — confirmation card rendering, focus-completion flow, onboarding hatch.
- **Integration tests:** broad end-to-end suites deferred; a couple of smoke-level tests are sufficient later.

Because task reads and writes share one Drift-backed service, there is a single behavior to verify rather than two divergent manual/agent paths.

---

## 11. Deferred (aligns with PRD "Future Versions")

The stack is chosen so these later features are extensions, not rewrites:

- **The AI pet-agent** ([ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md)) — §5 and §8 above, parked as written.
- **Cloud sync / multi-device** — the timestamp-anchored timer and Drift schema are sync-friendly; storage is local-only for now.
- **Multiple collectible pets with per-pet progression** — already enabled by storing EXP on a pet entity rather than the account.
- **Stats/history-aware agent** — an additional read tool and context, layered onto the existing tool loop.
- **Streaming agent responses** — an enhancement to the non-streaming MVP loop.
- **Achievements + analytics-grade stats screen**, **autonomous agent mode**, **due dates / tags / priority**, **subtasks**, **functional/paid unlocks** — all additive to the current model.
