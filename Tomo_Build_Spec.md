# Tomo — Build Spec (MVP)

**Companion to:** `Tomo_PRD_MVP.md` (the product argument) and
`Tomo_Tech_Stack_Architecture.md` (the stack rationale).
**This document owns the resolved specifics:** numbers, schemas, contracts,
state tables, screen specs and copy. Read the other two first, then read this
front to back and build.

**Where it comes from.** Two wayfinder maps:
[Wayfinder: Tomo build-ready MVP spec](https://github.com/heichan2000/Tomo/issues/1)
and [Wayfinder: Tomo pixel look, light and dark](https://github.com/heichan2000/Tomo/issues/32).
Each decision lives in full in its ticket's resolution comment; the *why* of the
hard-to-reverse ones lives in `docs/adr/`; the vocabulary lives in `CONTEXT.md`.
This spec gists, links and settles. It does not re-argue.

**When documents disagree**, the order is: this spec, then the ADRs, then the
ticket resolutions (a later ticket over an earlier one), then the PRD and the
architecture doc. §17 lists every contradiction found while assembling this and
how it was settled.

---

## 0. What changed since the PRD

The PRD and architecture doc still describe the product's argument correctly.
These decisions change what gets built:

| PRD / architecture said | Now | Where |
|---|---|---|
| Optional AI pet-agent, bring-your-own key | **No AI in MVP, and Tomo never goes online.** No chat, no key, no `INTERNET` permission, no `http`. Parked for a future version. | ADR-0029 |
| Coins and cosmetics | **None.** EXP is the only reward number. | ADR-0007 |
| Name the pet and watch it hatch on first launch | **The egg hatches at the end of the first finished focus block.** | ADR-0012 |
| One pet | **Three starters** (Geode, Joe, Lily); the user picks one at setup and keeps it forever. Not a collection. | [#9](https://github.com/heichan2000/Tomo/issues/9) |
| Vector pet, Rive rigs | **Pixel art**, painted from text grids in the Dart code, moved by sliding six parts in whole pixels. | ADR-0014, ADR-0018, ADR-0020 |
| (unspecified) | **Light and true-black dark themes**, accent copied from the pet. | ADR-0015 |
| "Current streak" on Stats | **No streak.** *Days focused*, which only grows. | ADR-0026 |
| Android auto-backup disabled | **The pet travels in the phone's own backup.** No export file. | ADR-0028 |
| Crash reporting must scrub the key | **No telemetry.** A local, allowlisted diagnostic log the user can share. | ADR-0004 |
| Sound for the reward | **No audio.** Two haptics. | ADR-0013 |

---

## 1. Scope at a glance

**Ships:**

- Projects → tasks (title, notes, status, planned blocks), managed by tapping.
- A timestamp-anchored focus timer: blocks of 10–120 minutes, breaks, optional
  auto-start, three timer notifications.
- One pet, picked at setup from three starters, hatched by the first finished
  block, growing through four stages on EXP earned by finished blocks.
- A lightweight Stats screen (four all-time numbers).
- Settings: rename pet, personality, Calm pet, auto-start, notifications,
  appearance, About with *Share diagnostics*.
- English only, all copy in ARB. iPhone and Android phones, portrait.

**Nine routes:** Onboarding, Home, Task picker, Focus, Work (project list),
Project (task list), Task detail, Stats, Settings. The hatch is a takeover
inside Focus, not a route.

**Does not ship:** see §19.

---

## 2. Vocabulary

`CONTEXT.md` is the glossary and is binding: code, tests and copy use its words.
The ones that trip people up:

- **Focus block** (the timed stretch) vs **focus cycle** (block plus its break).
  Never "session".
- **Minimise** (costs nothing) vs **early stop** (costs the block). Never "exit".
- **Settle** — record a finished block, exactly once.
- **Block record** — the permanent row a settle writes. Stats is built from these.
- **Planned blocks** — what screens call a task's estimate. Screens never say
  "Pomodoros".
- **Beat**, **beat run**, **seen** — momentary celebrations and their replay rule.
- **Pet voice** (good news, species rules) vs **plain voice** (Tomo's own, all
  bad news and anything explaining a setting).
- **Pixel** (pet grid) vs **UI pixel** (chrome) vs **screen dot** (the phone).

---

## 3. Reward economy

From [Reward economy: the numbers](https://github.com/heichan2000/Tomo/issues/2),
ADR-0001, ADR-0007.

| Rule | Value |
|---|---|
| EXP per completed focus minute | **10** |
| Block length | **10–120 minutes** (see §4.7) |
| Early stop | **0**, and no trace at all |
| Break | **0** |
| Level | `floor(total_exp / 600) + 1` — flat forever, so **level is hours focused**. Derived, never stored. |
| Evolution stages | **4**, beginning at levels **1 / 10 / 40 / 100** (≈ week 1, month 1, month 3 for 100 min a day). Derived from level, never stored. |
| Completion bonus | `bonus_exp = task.cumulative_focus_minutes` (10% of what the task's own blocks earned). **Once per task, ever**, on the first change into `done`, whatever route. Zero focus pays zero. |
| EXP storage | `pets.exp`, 32-bit signed bound enforced by the reward code (SQLite ints are 64-bit). No designed cap. |

A 25-minute block grants 250 EXP; a 50-minute block 500. Every grant is linear
in finished minutes, so no length, task split or timing earns more for the same
minutes.

---

## 4. The focus cycle

From [Session state machine & timer reconciliation rules](https://github.com/heichan2000/Tomo/issues/3),
amended by [Drift schema & storage inventory](https://github.com/heichan2000/Tomo/issues/10),
[Task service seam contract](https://github.com/heichan2000/Tomo/issues/11)
and this consolidation (§17, items R22–R23).

### 4.1 States

`idle` · `focusRunning` · `focusComplete` · `breakRunning` · `breakComplete`

- `idle` with a task picked is Focus's *Ready* screen. No cycle row exists in `idle`.
- Reward is granted on **entry to `focusComplete`** (the settle). The beat is a UI
  reaction to it, not a state.
- `focusComplete` is the awaiting-next-action state.

### 4.2 The machine is a projection

There are no tick, timer-fired or resumed events:

```
project(cycle, now) -> (state, effects)
```

The same call drives the live screen (re-projected as needed) and a cold start
days later. With the `focus_cycle` row from §6.2:

| condition | state | effects |
|---|---|---|
| no row | `idle` | — |
| `now < start_at` | `idle`, row discarded | `clockNotice` |
| `now < end_at` | `focusRunning` | — |
| `now ≥ end_at`, no break started | `focusComplete` | `settle` if `block_record_id` is null |
| break started, not skipped, `now < break_start_at + break_minutes` | `breakRunning` | `settle` if owed |
| break skipped, or `now ≥ break_start_at + break_minutes` | `breakComplete` | `settle` if owed |

`break_start_at` is written by *Take break* (as `now`) or, when `auto_start` is
on, by the settle (as `end_at`). `break_skipped_at` is written by *Skip break*.
So the projection stays a pure function of the row and `now`.

### 4.3 Commands

| | StartBlock | StopEarly | TakeBreak | SkipBreak | Leave |
|---|---|---|---|---|---|
| `idle` | → `focusRunning` | – | – | – | – |
| `focusRunning` | – | → `idle`, **zero** | – | – | – |
| `focusComplete` | → `focusRunning` | – | → `breakRunning` | – | → `idle` |
| `breakRunning` | → `focusRunning` (implicit skip) | – | – | → `breakComplete` | → `idle` |
| `breakComplete` | → `focusRunning` | – | – | – | → `idle` |

- Illegal pairs (`–`) are **no-ops in release and `assert` failures in debug and
  tests**.
- `StartBlock` validates length (10–120) and the task: a `done` task returns
  `taskDone`. It may target a different task. It sets a `todo` task to `doing`
  in the same transaction that writes the row (§5.4). From a complete or break
  state it replaces the row.
- **Marking a task done is not a cycle command.** It is a task write (§5). It is
  refused while `focusRunning` (the task lock) and otherwise **leaves the cycle
  where it is**; the cycle just can no longer start another block on that task.
  *(This replaces #3's `MarkDone → idle`; decided at consolidation, §17 R22.)*
- *Leave* deletes the row. It is *Done for now* and Android back from a complete
  state. (*Close* on Ready just leaves Focus; `idle` has no row.)
- Answering the estimate prompt is a task write too.

### 4.4 Reconciliation

**Replay forward through anything that grants nothing; stop at anything that
would grant something.** So:

- **At most one block is credited per absence.** Auto-start never anchors a
  block into an absence. Gone four hours with auto-start on → one block
  credited, its break counted as taken, landing in `breakComplete`.
- Killed mid-block and reopened days later → one block credits, the beat plays.
- Timezone or DST change mid-block → no effect; anchors are absolute instants.
- Powered off across `end_at` → credits normally on boot.
- **Clock moved backward** past `start_at` → the block is discarded at zero with
  the clock notice (shown on Home, §8.3). A forward jump is believed (trust
  model). A small NTP correction is absorbed because `now` stays past `start_at`.

### 4.5 Exactly-once settle

One transaction, run by the focus-cycle code (never by the task service):

```
INSERT block_records (..., exp_granted = minutes*10,
                           pet_exp_after = pets.exp + minutes*10)
pets.exp                       += minutes * 10
pets.hatched_at                 = now      -- only if null
tasks.actual_pomodoros         += 1
tasks.cumulative_focus_minutes += minutes
tasks.last_focused_at           = now
focus_cycle.block_record_id     = <new id> -- "credited"
focus_cycle.break_start_at      = end_at   -- only if auto_start
```

Killed mid-settle → rolls back whole, settles next launch. Killed after → the
link is set, nothing owed. Never lost and never doubled from one rule.

### 4.6 Early stop

Behind a confirmation (§8.6). Then: delete the row, write nothing, land in
`idle`; the derived notification schedule empties itself (§11). **A stopped
block leaves no trace**, so no started-versus-finished number can ever be shown.
If `end_at` passes while the confirmation is open, the block **completed**:
dismiss the sheet and credit it.

### 4.7 Block and break length

*(Custom was never designed by a ticket; decided at consolidation with the user,
§17 R23.)*

- Focus's Ready screen offers **25 min · 50 min · Custom**.
  - **25 min** comes with a **5-minute** break; **50 min** with a **10-minute** break.
  - **Custom** opens a sheet with two −/+ steppers: **Focus** 10–120 minutes in
    steps of 5, and **Break** 1–30 minutes in steps of 1, then *Use these*.
    While a custom pair is chosen, the third chip reads **Custom · 15 min**
    (the focus length).
- The chosen pair is remembered (`lastFocusMinutes`, `lastBreakMinutes`, §6.3).
  A pair equal to 25/5 or 50/10 shows as that preset.
- **The first block ever defaults to 15 minutes**, break 5 (onboarding's
  initial values; it shows as *Custom · 15 min*).
- Labels carry the real lengths: *Take a 5-min break*, *Another 25-min block*.
- Length lives only on Ready. The only timer item in Settings is auto-start.

### 4.8 Auto-start

Off by default; changes what happens next, never what is earned. Snapshotted
into the row at block start.

- After a block, the settle starts the break by itself (`break_start_at =
  end_at`), with the plain-voice note on Focus.
- **A break ending while Focus is on screen** shows a **10-second countdown**
  (*Start now* / *Not yet*); at zero the UI issues an ordinary `StartBlock`.
  *Not yet* stays in `breakComplete`. **Off screen nothing starts**
  ([ADR-0011](docs/adr/0011-foreground-only-auto-start-countdown.md)).
- If the cycle's task is now `done`, there is no next block: no countdown, and
  Break over shows the done-task choices (§8.5).

### 4.9 The estimate prompt

Fires on entry to `focusComplete`, after the beat, when `estimate is not null
&& actual_pomodoros ≥ estimate && estimate_prompted_at is null`; then sets
`estimate_prompted_at`, never cleared. Once per task, ever; estimate edits do
not re-arm it. Shown as an ignorable inline card (§8.5).

---

## 5. Tasks and projects

From [Task service seam contract](https://github.com/heichan2000/Tomo/issues/11),
ADR-0022, ADR-0024. With the AI parked, the UI is the service's only caller;
the seam stays so a future agent calls the same code.

### 5.1 The interface

```dart
abstract class TaskService {
  // writes: one transaction each; return success or one of the five errors
  Future<Result<Task>>    createTask({required int projectId, required String title,
                                      String? notes, int? estimate});  // always todo
  Future<Result<Task>>    updateTask(int id, TaskPatch patch);         // title, notes,
                                                                       // estimate, projectId, status
  Future<Result<void>>    deleteTask(int id);
  Future<Result<Project>> createProject(String name);
  Future<Result<Project>> renameProject(int id, String name);
  Future<Result<void>>    deleteProject(int id);                       // cascades its tasks

  // reactive reads the UI watches
  Stream<List<Project>> watchProjects();              // most recent activity first
  Stream<List<Task>>    watchTasksInProject(int id);  // doing, todo, done; recency
  Stream<List<Task>>    watchPickerTasks();           // doing, todo; most recently focused; no done
  Stream<Task?>         watchTask(int id);            // null = deleted
}
```

Screens may add reads freely; reads can't break invariants. The writes are fixed.

### 5.2 Errors — a sealed set of five

| error | when | carries |
|---|---|---|
| `notFound` | task or project doesn't exist | kind, id |
| `invalid` | a validation rule failed | field, rule (`empty` / `tooLong` / `outOfRange`), limit |
| `blockRunning` | the task lock refused | task id |
| `taskDone` | a block was asked for on a done task | task id |
| `storageFailed` | the database failed | nothing; writes a diagnostic entry |

Writes return `Result<T>`, never throw, so an unhandled case fails to compile.

### 5.3 Validation

| field | rule |
|---|---|
| task title | trimmed, not empty, ≤ 200 grapheme clusters |
| notes | optional, trimmed, blank → `NULL`, ≤ 5,000 |
| estimate (planned blocks) | optional, integer 1–20, blank → `NULL`; 0 rejected |
| project name | trimmed, not empty, ≤ 60; duplicates allowed |
| a task's project | must exist |
| status | every transition legal, including `todo → done`; only the lock limits it |

### 5.4 The rules

1. **The bonus lives in the status change.** Any change into `done` runs one
   transaction: status, `completed_at`, and — if `completion_bonus_granted_at`
   is null — `pets.exp += cumulative_focus_minutes` plus the flag. Leaving
   `done` clears `completed_at` and nothing else.
2. **Earned numbers have no setter:** `actual_pomodoros`,
   `cumulative_focus_minutes`, `last_focused_at`, `estimate_prompted_at`,
   `completion_bonus_granted_at`. Only the settle (§4.5) and the bonus move them.
3. **Task lock** ([ADR-0024](docs/adr/0024-a-running-block-locks-its-task.md)):
   while `focusRunning`, deleting the task, deleting its project and marking it
   done are refused with `blockRunning`.
4. **After the block** (`focusComplete`, `breakRunning`, `breakComplete`):
   - **Delete** task or project: one transaction settles if still owed, ends
     the cycle as *Leave* does, then deletes. An unseen beat run is dropped with
     the row; the EXP stays.
   - **Mark done**: settles if owed, then the status change (with the bonus).
     **The cycle carries on** — a break can still be taken or finished — but no
     block can start on that task. *(Changed at consolidation, §17 R22.)*
5. Moves, edits, and to-do/doing changes never touch a live cycle. A block
   record keeps the project the task had **at settle**.
6. **Starting a block sets `doing`** on a `todo` task; nothing ever moves a task
   back. **A done task can't be focused**; reopening is the user's move.
7. **Concurrency:** updates are patches (`Value.absent()` for untouched fields);
   no version check; writes run in order; writing a value the row already has
   succeeds and changes nothing.
8. **Deletes are real; block records outlive their tasks**
   ([ADR-0022](docs/adr/0022-block-records-outlive-their-tasks.md)): the words
   go, the block records stay with `task_id`/`project_id` set to null.

**Reopening from the ring** (one tap on a done task's status glyph, §8.7) sets
`doing` if the task has any finished blocks, otherwise `todo`. No "previous
status" is stored. *(Consolidation call, §17 C1.)*

---

## 6. Storage

From [Drift schema & storage inventory](https://github.com/heichan2000/Tomo/issues/10),
[Data portability](https://github.com/heichan2000/Tomo/issues/49) (ADR-0028),
[Postpone the AI layer](https://github.com/heichan2000/Tomo/issues/50) (ADR-0029).

### 6.1 Four places

| Store | Holds | Phone backup |
|---|---|---|
| Drift `tomo.sqlite` (application-support dir) | projects, tasks, pet, block records, the live cycle | **included** |
| Key-value (`shared_preferences`) | the six keys in §6.3 | **included** |
| Device-only file (application-support, e.g. `device.json`) | `notificationPermissionAsked` | **excluded** |
| Diagnostic log (application-support, plain rotating file) | allowlisted error entries (§13) | **excluded** |

There is **no secure storage**: it held only the AI key, and the AI is parked.

### 6.2 Drift schema (`schemaVersion = 1`)

Conventions: `INTEGER PRIMARY KEY AUTOINCREMENT` (ADR-0023); every instant an
`INTEGER` of UTC epoch milliseconds named `*_at` (no Drift `DateTime`); enums
stored as text (`textEnum`); `PRAGMA foreign_keys = ON` in `beforeOpen`.

**`projects`** — `id`; `name` text not null; `created_at` not null. Sorted by
most recent activity: max of its own and its tasks' `created_at` /
`last_focused_at` / `completed_at`, computed in the query.

**`tasks`**

| column | type | notes |
|---|---|---|
| `id` | int PK | |
| `project_id` | int not null, FK `projects` ON DELETE CASCADE | never null; onboarding seeds a project |
| `title` | text not null | |
| `notes` | text null | |
| `status` | `todo`/`doing`/`done`, default `todo` | |
| `estimated_pomodoros` | int null | null = no plan |
| `actual_pomodoros` | int not null default 0 | +1 per settle |
| `cumulative_focus_minutes` | int not null default 0 | the bonus scales on it |
| `estimate_prompted_at` | int null | set once |
| `completion_bonus_granted_at` | int null | set once |
| `created_at` | int not null | |
| `last_focused_at` | int null | set at settle |
| `completed_at` | int null | set entering done, cleared on reopen |

Index `(project_id, status)`.

**`pets`** — exactly one row in MVP; **its existence is "onboarding complete"**.

| column | type | notes |
|---|---|---|
| `id` | int PK | |
| `species` | `geode`/`joe`/`lily` not null | permanent |
| `personality` | `quiet`/`chatty`, default `quiet` | editable |
| `name` | text null | null until the hatch names it |
| `hatched_at` | int null | **null is the egg** |
| `exp` | int not null default 0 | the truth |
| `created_at` | int not null | |

**`block_records`** — written once by the settle, never updated except the FK
nulling.

| column | type | notes |
|---|---|---|
| `id` | int PK | |
| `pet_id` | int not null, FK `pets` | |
| `task_id` | int null, FK ON DELETE SET NULL | |
| `project_id` | int null, FK ON DELETE SET NULL | the project **at settle** |
| `started_at`, `ended_at` | int not null | the anchors |
| `minutes` | int not null | |
| `local_date` | text `YYYY-MM-DD` not null | the local day it **ended** |
| `utc_offset_minutes` | int not null | at settle |
| `exp_granted` | int not null | rebuilds the beat run |
| `pet_exp_after` | int not null | `pet_exp_after - exp_granted == 0` ⇒ **this was the hatch** |
| `settled_at` | int not null | |

Indices `local_date`, `task_id`.

**`focus_cycle`** — at most one row (`CHECK (id = 1)`); deleted on exit to
`idle`.

| column | type | notes |
|---|---|---|
| `id` | int PK, default 1 | not auto-incremented (C18) |
| `task_id` | int not null, FK `tasks` ON DELETE RESTRICT | the service always ends the cycle before a delete (§5.4); RESTRICT is the backstop |
| `start_at`, `end_at` | int not null | anchors |
| `focus_minutes`, `break_minutes` | int not null | |
| `auto_start` | bool not null | snapshotted at block start |
| `break_start_at` | int null | *Take break*, or `end_at` under auto-start |
| `break_skipped_at` | int null | *Skip break* |
| `block_record_id` | int null, FK `block_records` | non-null = credited |
| `seen_at` | int null | the beat run was had (§7.4) |

**Migrations ship in v1:** `drift_dev` schema snapshots committed per released
version (`drift_schemas/`), step-wise migrations, generated upgrade tests from
every past version. **A failed migration never wipes:** show the error block,
write a diagnostic entry, leave the file untouched.

One `openTomoDatabase(QueryExecutor)` builds the database for production and
tests (`NativeDatabase.memory()`), so `beforeOpen` and migrations are the same
code. The clock is injected, and `start()` reports a failed open (C19).

### 6.3 Key-value store

| key | type | default |
|---|---|---|
| `appearance` | `system`/`light`/`dark` | `system` |
| `autoStart` | bool | `false` |
| `calmPet` | bool | `false` |
| `lastFocusMinutes` | int | **15** |
| `lastBreakMinutes` | int | 5 |
| `lastProjectId` | int | absent → most recently active project |

Every read falls back to its default; no migrations. `notificationPermissionAsked`
lives in the device-only file instead, so a restored phone asks again.

### 6.4 Phone backup (ADR-0028)

- **Android:** `allowBackup="true"`; `dataExtractionRules` (and pre-12
  `fullBackupContent`) **include exactly** the database and the shared-prefs
  file, for both `cloud-backup` and `device-transfer`. "The database" is
  `tomo.sqlite` with its `-wal` and `-journal` side files (C16).
- **iOS:** default backup on; the device-only file and the diagnostic log are
  marked excluded from backup.
- No restore logic: a restored running cycle goes through §4.4 (at most one
  block), notifications rebuild through §11, an older app meeting a newer
  database falls under "a failed migration never wipes". Switching between
  iPhone and Android brings nothing across, and About says so.

---

## 7. The pet

### 7.1 Species, stages, art

Three starters, **Geode** (a rock that grows crystals, then a crown), **Joe** (a
paper chick that refolds) and **Lily** (a creature that stands up). The full
arc, colours, parts, faces, eggs and voices are in
[`docs/pet-art-style-guide.md`](docs/pet-art-style-guide.md); the approved art
is the code in `lib/art/` (moving to `packages/tomo_core/lib/art/`, §15.4).

- One **48×48 pet grid** per species for every stage and the egg, standing on
  the same bottom row. Stage 1 is the Tomo Pixel Starters sprite (with two
  approved fixes). ADR-0014.
- Seven colours per pet, no outline, no shine, **one colour set for both
  themes**, judged by eye.
- Painted as squares of a **whole number of screen dots** per pixel, rounded
  down, never smoothed. Spots: **Home 192 pt**, **Focus 168 pt**, **hatch
  takeover 192 pt**, **setup tiles 96 pt**; nothing below 2 dots per pixel.
- Stages 1–3 look clearly bigger each time; stage 4 is stage 3's size, finer,
  with one new nameable thing. Grow-only.

### 7.2 The pet look

`look(state, pending)` → `stage`, `face`, `movement`, `species`. A pure
function, never stored ([ADR-0009](docs/adr/0009-derived-pet-look-persisted-beat-queue.md),
amended by ADR-0018).

- `stage` comes from level, **except** it holds the old stage while an evolution
  beat is **pending**. When the beat starts, `look` reports the new stage and the
  pet flickers.
- `movement` is `full` or `reduced` (the OS reduce-motion flag).
- **Face, one value off one ladder, highest wins:**

  ```
  1. Celebrating   a level-up, task-done, evolution or hatch beat is playing
  2. Pleased       the block-done beat is playing
  3. Still         Calm pet is on
  4. Drowsy        breakRunning
  5. Pleased       focusRunning
  6. Resting       idle, focusComplete, breakComplete
  ```

  *Thinking* and *Puzzled* had only AI triggers and are parked (ADR-0029); their
  eye drawings stay in the art files. **Calm pet replaces the three everyday faces
  with Still and never touches a beat**, so the block-done beat's Pleased bob
  ranks above it. *(#16's ladder had every beat as Celebrating; ADR-0019 made the
  block beat Pleased, §17 R25.)*
- **Before the hatch** the pet's spot holds the species' egg, which is outside
  the ladder. During a running block the egg shows its pictures (whole, then
  each crack step) in **equal shares of the block** (Geode 4 pictures, Joe 6,
  Lily 5), derived from elapsed minutes, stored nowhere. Stopping early discards
  the crack with the block; **the egg is never animated shut on screen**.

### 7.3 How it moves

ADR-0018. Each stage is six parts — `body`, `head`, `eyes`, `limbA`, `limbB`,
`accent` — and every movement slides parts in **whole pixels**, holding each
position; nothing slides smoothly. Expressions swap only the eyes, from one eye
sheet per species. Movement code is shared by all twelve stages; a species only
names which parts ride, lean, twitch and lift (its per-species settings,
fingerprinted with the stage).

| Movement | Full | Reduced (nothing moves > 1 pixel) |
|---|---|---|
| Breath (Resting) | upper body 1 px down/up, 0.8 s each way | 1.6 s each way |
| Blink | bottom eye row only, 0.15 s, every 2.6–6.4 s | same |
| Pleased (block running) | bob 1, 2, 1 px at 0.07 s, then breath | 1 px for 0.21 s |
| Drowsy (break) | sinks 1 px, breath 1.6 s each way | same |
| Celebrating | jump 1,2,3,3,2,1 px at 0.07 s, head lands 0.14 s late, every 0.9 s; species parts lift per the style guide | 1 px hop for 0.28 s |
| Still | nothing moves, no blink | same |
| Evolution flicker | old/new swap **five times** at 0, 500, 950, 1350, 1700 ms; nothing else moves | 0.6 s cross-fade |

### 7.4 The beat queue

Five beat kinds: `blockCredited(minutes, exp)`, `levelUp(level)`,
`evolution(from, to)`, `taskCompleted(bonusExp)`, `hatch(species)`.

- `blockCredited`, `levelUp`, `evolution` and `hatch` are **rebuilt from the
  block record** (`exp_granted`, `pet_exp_after`) whenever the live cycle has
  `block_record_id` set and `seen_at` null. Nothing else stores them.
- A run plays **in order, one at a time, never overlapping**.
- **Only Focus drains a run.** A block that ends while minimised waits: the
  banner becomes the finished strip and **the beat waits for the tap**.
- **`seen_at`** is set when the run finishes, is skipped (tap anywhere), or is
  walked away from (minimise, Leave). **Only process death leaves it unset**, so
  an interrupted run replays exactly once. Ending the cycle without returning to
  Focus drops the run with the row; the EXP stays.
- `taskCompleted` plays only if a pet is on screen (Focus); otherwise it is
  dropped (marking done on Work is quiet, §8.7).
- **One spoken line per run, at its start**: plain facts first, then the pet's
  name and its shown line (§10.4).
- Each beat fires one **reward tap** as it plays (§11.5).

### 7.5 The reward ladder

[ADR-0019](docs/adr/0019-reward-ladder-twinkle-in-pet-pixels.md). The rarer,
the bigger; each keeps what the commoner has. Effects are drawn **in pet
pixels** on the pet's grid; sparkles are Twinkle (open and close in place,
never travel); nothing flashes except the evolution flicker, which plays alone.

| Beat | Pet | Around it | Screen | ≈ length |
|---|---|---|---|---|
| Block done | Pleased bob | nothing | "+250 EXP" rises in the accent; the 20-block EXP bar lights block by block | 1.3 s |
| Level-up | Celebrating | 6 medium sparkles in a ring | dither; "Level 13" plate under the EXP bar; bar fills, empties, refills | 2 s |
| Task done | Celebrating | confetti (36) + 3 sparkles | dither; "Task done" plate; "+100 EXP"; the bar | 2.4 s |
| Evolution | still for the flicker, then Celebrating | small sparkles close in (0.6 s) → the flicker alone → 12 large sparkles in a wave, 8 medium, confetti (44) | dither held from the level-up; no plate | 4 s |
| Hatch | egg shakes, breaks open with the pet there (no flicker), then Celebrating | shell in 7 pieces; 12 + 16 large sparkles; confetti (64) | screen cleared; the accent arrives | to naming ≈ 3.7 s |

Timings, sprite grids, colours and confetti physics are in
[Pixel reward effects](https://github.com/heichan2000/Tomo/issues/39#issuecomment-5945625543)
and its [hatch amendment](https://github.com/heichan2000/Tomo/issues/39#issuecomment-5945647494):

- **Block beat:** bob at 0; "+EXP" from 100 ms rising 1 UI pixel per 60 ms to 9,
  settling at 8, gone at 1.2 s; bar from 300 ms, blocks 70 ms apart, each popping
  1 UI pixel taller for 70 ms; choices step in at 1.3 s.
- **Level-up:** dither on; plate from 100 ms in steps −4 −2 0 +1 0 UI pixels at
  70 ms, held, gone by 1.84 s; bar empties at 300 ms, refills from 400 ms
  (90 ms apart); sparkles from 150 ms.
- **Evolution:** closing-in 0–0.6 s, flicker 0.6–2.3 s, burst from 2.3 s,
  choices ≈ 4 s.
- **Hatch:** shakes ±1 pixel in 80 ms steps at 0.3 s and 1.1 s, then harder and
  faster at 1.8 s (60 ms steps for 0.6 s); **shell breaks at 2.5 s** with the
  pet there, sparkles, confetti and colour arrive; naming steps in at **3.7 s**.
- **Shell rule:** the egg's pixels split into 7 pieces by angle around the
  centre of its bounding box, starting straight up, clockwise; the crack's dark
  flies with the shell and only the peeking eyes stay.
- **Sparkle:** 4 frames at 70 ms; medium plays `1 2 3 3 2 1`, large
  `1 2 3 4 4 3 2 1`, small `1 2 2 1`. Arms in the theme's accent, centre in a
  lighter colour of the same pet (neutral pair before the hatch).
- **Confetti:** the pet's own colours that reach 1.45:1 on the ground (never its
  eyes); fluttering squares, 50 ms whole-pixel steps, gone at 2.4 s.

**Reduced:** confetti, flying shell and every rise are dropped; the bar jumps;
"+EXP" and plates cross-fade in place; **sparkles stay, held still** (frame 3 at
level-up and task done, frame 4 at evolution and hatch); evolution and hatch are
the 0.6 s cross-fade; the egg's 1-pixel shake stays.

Moments use the **dither** behind them, not a tint; they may run past #12's
1.5–3 s Moment budget where the ladder says so.

### 7.6 Ambient life

From [The pet's ambient life outside sessions](https://github.com/heichan2000/Tomo/issues/31).
None of this is a beat or part of `look`; it lives only in the pet widget, is
never saved, and is never announced.

- **No clock.** Time of day and time away never change the pet. `Drowsy` means a
  break and nothing else.
- **Idle moves**, only on the `Resting` face (Home, and Focus when nothing is
  running): one every 15–30 s at random, never the same twice in a row —
  **Glance**, **Look up**, **Double blink**, **Twitch** (Geode's crystals/crown,
  Joe's cap, Lily's ears), **Wiggle**. Timings and reduced forms in #31.
- **Hello:** the hop (1, 2, 1 pixels at 0.07 s, happy eyes 0.6 s) each time the
  app **opens** onto Home with the pet resting — the same however long you were
  away. Switching tabs is not opening. A cold start routed to Focus has no hello.
- **Tap** on the resting pet: the hop. Taps during a move are ignored. During a
  block or break, a tap does nothing.
- **The waiting egg** wobbles 1 pixel left then right (150 ms steps) every
  15–30 s and when tapped.
- **Calm pet** stills all of it — no breath, blink, idle moves, hello or tap
  reaction, and the egg holds still. Block cracks still show (they are progress).

### 7.7 Calm pet vs reduce motion

Two knobs, two needs ([ADR-0005](docs/adr/0005-graded-reduce-motion.md)).
**Reduce motion** (OS flag, vestibular) governs choreography: nothing moves more
than one pixel, cross-fades replace travel, every reward payload survives.
**Calm pet** (Settings, off by default, distraction) governs ambient movement
through the face only. Neither seeds nor overrides the other; with both on, the
Celebrating face also takes the reduced limits. Neither affects haptics.

---

## 8. Screens

Designs approved on prototypes (throwaway, private to the owner):
[Tomo Pixel Screens](https://claude.ai/artifact/D9UgrmZN21UEny28Td3kpY) (Home,
Focus, Onboarding, celebrations, hatch),
[Tomo Task Screens](https://claude.ai/artifact/Qc97YEMfYmbVrFt2qfLjFR) (Work,
project, task detail), [Tomo Stats Screen](https://claude.ai/artifact/BsyZwYQkhc4A5RHQrRwsBS),
[Tomo Voice Pass](https://claude.ai/artifact/FBM1THYCj3u4S4PURAgJAE) (every line
in place). Behaviour comes from the tickets below; where a prototype and this
spec differ, this spec wins.

### 8.1 Navigation

From [Screen inventory & navigation model](https://github.com/heichan2000/Tomo/issues/5),
ADR-0003, ADR-0029.

- **Two tabs: Home · Work.** The shell never changes shape; each tab keeps its
  own stack; cold start never restores the last tab.
- **Routes:**

| Route | Presentation | Leave by |
|---|---|---|
| Onboarding (2 screens) | full screen above the shell, once ever | finishing → Home |
| Home | tab root | — |
| Task picker | modal bottom sheet | dismiss, or pick → Focus Ready |
| Focus (all five states) | full-screen takeover above the shell, tab bar hidden | Minimise, Leave, Close (Ready), Stop early |
| Work (project list) | tab root | — |
| Project (= its task list) | push | back |
| Task detail (= edit) | push | back |
| Stats | push from Home's level chip | back |
| Settings | push from Home's gear | back |

- **Focus is a minimizable takeover** ([ADR-0003](docs/adr/0003-minimizable-focus-takeover.md)).
  Minimising ends nothing; the **running-block banner** docks above the tab bar
  on every tab and re-opens Focus. **Focus has four doors:** Home's *Start
  focusing*, task detail's *Start focusing*, the banner, and a cold start whose
  projection is not `idle`.
- **Android back:** Ready → leaves Focus, discards the pick; `focusRunning` and
  `breakRunning` → **minimise**, never Stop early; stop sheet open → closes the
  sheet; `focusComplete` / `breakComplete` → *Leave*.
- **Cold start projects, then routes:** not `idle` → Focus; `idle` → Home. So
  exactly one surface plays the per-block beat (Focus) and one shows the clock
  notice (Home).
- **Home's *Start focusing* while a cycle is live** opens Focus, like the banner.
  *(Consolidation call, §17 C3.)*
- **The task picker** opens from Home's *Start focusing*, from the task row on
  Focus Ready, and from *Start another task* on Focus. A flat cross-project list:
  `doing` first, then `todo`, most recently focused first, project label per row,
  no `done`. Its *New task* row creates and goes, under the last-used project
  shown as a tappable chip.
- **Dialogs are sheets, not routes:** Stop this block?, delete task, delete
  project, new project, move to project, custom length, the row menu. The share
  sheet is the OS's.

### 8.2 Onboarding

From [Onboarding & hatch flow design](https://github.com/heichan2000/Tomo/issues/18)
(ADR-0012), [Pet voice system](https://github.com/heichan2000/Tomo/issues/30),
[Redraw Home, Focus and Onboarding](https://github.com/heichan2000/Tomo/issues/45).
Neutral grey chrome throughout. No account, no permissions, nothing taught.

1. **Choose your pet.** Title and one line; the three starters as tiles at
   stage 1 (96 pt), the chosen one a sunken shade with a check before its name.
   Below: the chosen pet's description line (**the pet speaking**, switching with
   personality), the **Personality** segmented control **Quiet / Chatty**
   (Quiet selected), its hint, *Next*.
2. **What are you working on?** Back; title and one line; one text field;
   *Done* (primary), *Skip* (quiet, muted). The line becomes **both the seeded
   project's name and the first task**. Skipped → one plain default project and
   no task.

Nothing is written until screen 2 finishes or is skipped; then **one
transaction** creates the pet row (species, personality, `name` and
`hatched_at` null), the project, and the task if typed. A kill before that
restarts onboarding from screen 1.

### 8.3 Home

- **Top:** level chip (*Lv 7*, opens Stats) at the left, gear (Settings) at the
  right.
- The pet at 192 pt (hello, idle moves, tap hop); its **name** at pet-name size;
  the **20-block EXP bar** with "480 / 600 EXP" (one block = 30 EXP); *Start
  focusing*; the tab bar.
- **Before the hatch:** no chip, no name, no bar. The species egg (wobbling), and
  the pet-voice **egg line** under it.
- **Clock notice:** a sunken strip above the pet with a close (×), in plain
  voice; never a dialog. Held in memory until dismissed or the app process ends.
  *(Lifetime is a consolidation call, §17 C2.)*
- **Banners:** running (sunken; 4-pixel accent square; task; "19 min left" in
  muted caption; chevron up) and finished (accent strip, "Block done · 25 min
  counted" or "Break over", wraps at large text).

### 8.4 Focus

From [Focus view design](https://github.com/heichan2000/Tomo/issues/17)
(ADR-0010, ADR-0011), #45, ADR-0019. **Pet first, quiet clock.** Focus follows
the theme; no night tone; the screen is not kept awake.

**Header (every state):** Minimise (chevron down) at the top left — *Close* (×)
on Ready; task title (title size) and project (caption); bell-off at the top
right once notifications are denied (opens the phone's settings). Notes
(auto-start, "while you were away") are sunken strips under the header.

| State | Content, top to bottom |
|---|---|
| **Ready** (`idle`) | pet; the plain-voice framing line (permission not yet asked) or the denial line (once); task row (opens the picker); length control **25 min / 50 min / Custom**; *Start focusing* |
| **Running** | pet 168 pt (Pleased); the **quiet clock** "about 19 min left" as a tap target — exact `mm:ss` for 5 s on tap; 2-UI-pixel progress line; **Focus** chip under it (body size); *Stop early* (quiet, muted) at the bottom |
| **First block** | as Running, with the egg cracking in the pet's place |
| **Block done** | the beat run (§7.5), then pet, pet line, settled EXP bar and the **choices** (§8.5) |
| **Break** | same layout: pet (Drowsy), muted progress line, **Break** chip, "about 4 min of rest left", pet line, *Skip break* (secondary, never confirmed, lands on Break over) |
| **Break over** | pet line, then the Break over choices (§8.5) |
| **Next block in 10** | countdown line, *Start now* (primary) / *Not yet* (secondary) |

- **The quiet clock** ([ADR-0010](docs/adr/0010-quiet-clock.md)): "about N min
  left", "under a minute left"; on the banner "19 min left" / "Break · about
  4 min", updated once a minute. The exact time is plain Ark Pixel text.
- **Permission flow** (§11.4) lives on Ready.
- **The estimate card** sits above the choices after the beat: "Is this task
  done?", the pet's fact line, *Not yet* (secondary) / *Mark done* (primary).
  Picking any choice counts as not yet; while it shows, *Mark task done* hides.
- **Coming back** to a block that finished away: Focus opens with the pet-voice
  *while you were away* note at the top ("Finished at 2:25 PM…", device time
  format), the **full beat plays**, then the choices; the note stays until a
  choice is picked.

### 8.5 The choices

*(The task-done sets are consolidation's, following the user's call in §17 R22.)*

| When | Primary | Secondary | Quiet |
|---|---|---|---|
| After a block | *Take a 5-min break* | *Another 25-min block* | *Mark task done* |
| After *Mark task done* from a finished block (`focusComplete`) | *Take a 5-min break* | *Start another task* (picker) | *Done for now* |
| Break over | *Start another block* | *Mark task done* | *Done for now* |
| Break over, task already done | *Start another task* | — | *Done for now* |
| After *Mark task done* from Break over | *Start another task* | — | *Done for now* |

*Done for now* is *Leave*. Lengths in labels are the cycle's own (§4.7). The
Task done celebration plays before its choices (a pet is on screen).

### 8.6 Stop early

A plain muted text button at the bottom of Running, never next to a frequent
control. It opens a sheet over the dither: title **Stop this block?**, body
**Only finished blocks count, so this one won't. Everything you've finished
before stays.**, then *Keep going* (primary) above *Stop early* (destructive),
8 UI pixels (≥ 12 pt) apart. No pet name, no minute count, no haptic. The sheet
scrolls at large text.

### 8.7 The hatch

A **full-screen takeover inside Focus**, the only thing in Tomo that clears the
screen. After the first block's ordinary beat (the egg, at its last crack
picture, holds still in the pet's place while "+150 EXP" rises and the bar
lights), chrome and buttons go; the egg (192 pt) shakes and breaks; **the accent
changes from grey to the species colour** with the burst; then the pet's hatch
line, a **Name** field **pre-filled with the species name**, and *Done*. *Done*
returns to Focus's choices. There is no minimise during the takeover and the
banner never shows it; Android back does nothing during the animation and acts
as *Done* on the naming step. *(The egg during the beat and back behaviour are
consolidation calls, §17 C5–C6.)*

A user who never finishes a block never meets a pet. Accepted (ADR-0012).

### 8.8 Work

From [Task & project management screens design](https://github.com/heichan2000/Tomo/issues/19).

- **Work tab:** "Work" (title) and + (*New project*: a sheet with one field and
  *Create project*, which opens the new project). Project rows: name, then
  `4 open · 3 done` (`All 2 done`, `No tasks`), chevron. No progress bar.
- **Project:** header with back, name, `4 open · 3 done`, ⋯ (*Rename project*,
  *Delete project*). Tasks grouped **doing → to do → done**, recent first;
  **done stays at the bottom, greyed**; no fold, search, filter or drag. An
  **"Add a task" field at the end of the open tasks** (title only; Enter adds and
  keeps the field ready). All done: a sunken line with the done icon above the
  done tasks.
- **Task row:** status glyph (48 pt target), title, meta in words —
  `2 of 4 blocks`, `5 blocks · planned 4`, `1 block`, or none — a *Doing* chip
  (the accent *Focus* chip on the running task), ⋯. **Tap the ring** toggles
  done and back (§5.4 note); long-press or ⋯ opens a sheet with the status
  control, *Move to another project* and *Delete task*. Marking done here is
  **quiet**: the ring fills at once and the row slides down after ≈ 450 ms. No
  sparkles, no EXP shown; the bonus is still paid.
- **Task detail:** back; title field; notes (*Add notes*); **Project** row (a
  *Move to project* sheet); **Status** segmented control *To do / Doing / Done*;
  **Planned blocks** −/+ stepper (− from 1 gives *No plan*); **Focus so far**
  (`2 blocks · 50 min` or *None yet*, read-only); *Start focusing*; *Delete task*
  (quiet, destructive colour). Fields save as you go.
  - Done task: no *Start focusing*; the done-task line instead.
  - Its block running: the button is *Back to focus*.
  - Another task's block running: *Start focusing* turned off, with the
    another-block-running line.
- **Task lock refusals** land where you tapped, as a sunken line (under the row,
  the status control, *Delete task*, or *Delete project*). The ring doesn't change.
- **Deletes ask first, no undo:** a sheet saying what goes and that focus time
  stays in Stats; *Cancel* (secondary) above *Delete* (destructive).
- **Empty states:** a surface card with a 2× icon, a title, one line and one
  manual action. Never the AI, never a teaser.

### 8.9 Stats

From [Stats screen scope & the definition of a streak](https://github.com/heichan2000/Tomo/issues/21)
(ADR-0026). Back + "Stats"; four surface rows, label muted left, number ink right,
wrapping at large text. No pet, no icons, no buttons. Counted fresh from
`block_records` each time it opens:

| Row | Source | Format |
|---|---|---|
| Level | `floor(pets.exp / 600) + 1` | `28` |
| Time focused | `SUM(minutes)` | `26 h 40 min` / `15 min` |
| Blocks finished | `COUNT(*)` | `64` |
| Days focused | `COUNT(DISTINCT local_date)` | `23` |

Locale grouping for numbers. **No empty state**: Stats opens only from the level
chip, which appears at the hatch, which writes a block record. Deliberately
absent: streaks, today, weeks, charts, per-project time, records, comparisons,
tasks finished.

### 8.10 Settings

Pushed from Home's gear. Rows:

| Group | Row |
|---|---|
| Pet | **Rename pet** · **Personality** (Quiet / Chatty) · **Calm pet** (switch) |
| Focus | **Auto-start** (switch, off) |
| Notifications | permission status + *Open system settings* |
| Appearance | **Match phone / Light / Dark** (full-width segmented control, wraps at large text) |
| About | version; licences (Ark Pixel OFL registered); the `about` and `aboutOs` lines; **Share diagnostics** with its entry count (disabled at zero) and the `shareDiag` line |

Species is permanent; name and personality are not.

### 8.11 Error block

In release, `ErrorWidget.builder` renders a small plain block with the `error`
line naming *Settings > About > Share diagnostics*. No pet, no pet voice.

---

## 9. The look

### 9.1 Themes and colours

[ADR-0015](docs/adr/0015-light-and-true-black-accent-from-the-pet.md). Light and
true black; follows the phone unless Settings → Appearance says otherwise. Every
route, Focus included, follows the theme.

| Role | Light | Dark |
|---|---|---|
| ground | `#F5F1EA` | `#000000` |
| surface | `#FCFAF6` | `#161412` |
| sunken | `#EAE4DA` | `#24211D` |
| ink | `#24211D` | `#EDE7DC` |
| ink-muted | `#6A6359` | `#A39B8F` |
| boundary (text fields only) | `#8E867A` | `#756E64` |
| destructive | `#A3402C`, white label | `#FF4D40`, black label |

**Species accent — one of the pet's own colours, copied exactly from its colour
key** (never a new colour):

| | Light (white label) | Dark (black label) |
|---|---|---|
| Geode | `#3a6470` body | `#6ee0c6` crystal |
| Joe | `#4a57b8` cap | `#6f7ed8` light blue |
| Lily | `#4a2a44` nose | `#c89ab3` body |
| Before the hatch | `#4A443C` | `#EDE7DC` |

**No status colours** — no success, warning or red/green focus-vs-break. State is
shape, word and list position. Contrast: 4.5:1 text, 3:1 large text and UI parts,
**per theme** (computed test, §16). Pet art is exempt and judged by eye.

### 9.2 Type

[ADR-0016](docs/adr/0016-one-pixel-font-sharp-sizes.md). **One font: Ark Pixel
12px Proportional, regular**, bundled as a ~27 KB Latin subset, never fetched,
OFL registered in `LicenseRegistry`. Missing characters fall back to the phone's
font; Pixeloid Sans is the fallback font if Ark fails on a device.

- **Sharp sizes only:** `fontSize = 12 × n / devicePixelRatio`; a custom
  `TextScaler` after any clamp rounds to the nearest `n` at 100% and **up**
  above it. Line height whole font pixels (16).
- **Type steps** in dots per font pixel: caption = body − 1, **body =
  `round(1.667 × dpr)`**, title = body + 1, pet name = 2 × body. No bold.
- **Numbers and the pet's name stop growing at 130%**, then step down to the
  largest sharp size that fits. A time or number never scrolls or wraps.
- Digits are all 6 font pixels wide, so changing numbers are plain text.

### 9.3 Chrome: quiet steps

[ADR-0017](docs/adr/0017-quiet-steps-pixel-chrome.md); parts with states in
[Pixel interface kit](https://github.com/heichan2000/Tomo/issues/38#issuecomment-5943949410).

- **Calm chrome, warm pet:** the pet is the only detailed, saturated, lively
  thing; chrome is quiet.
- **UI pixel = one body-text font pixel** (≈ 1.5–1.7 pt). Lines, corners, gaps,
  icon strokes and movement are whole UI pixels; they don't grow with text size.
- Shapes stand apart **by shade only**; outlines only on text fields (1 UI pixel
  boundary, 2 in the accent while typing); no shadows; **every corner loses
  exactly one pixel**.
- **Dither** (every other dot in the ground colour) behind sheets, dialogs and
  Moments, in both themes.
- Buttons ≥ 48 pt: primary (accent), secondary (sunken), quiet (text),
  destructive. Pressed = one shade toward ink at once; turned off = solid sunken,
  muted text; keyboard focus = 1-pixel accent ring with a 1-pixel gap.
- The **EXP bar** is 20 blocks with 1-pixel gaps; it is a reward object and may
  spring.
- Segmented controls **wrap** rather than clip; sheets **scroll** when nearly
  full; the finished banner wraps; rows and fields wrap and the screen scrolls.
- **Status glyphs** (10×10 on the icon grid): to-do empty ink ring; doing accent
  ring, left half filled; done filled muted with the check cut out.

### 9.4 Motion tiers

| Tier | Uses | Full | Reduced |
|---|---|---|---|
| Feedback | press, toggle, tab change | instant shade change; 120 ms | same |
| Transition | routes, sheets, Focus takeover/minimise | 280 ms slide of 24 pt in UI-pixel steps, decelerate | 150 ms cross-fade |
| Beat | block beat, EXP fill, pet reaction | 600–900 ms (block beat ≈ 1.3 s), spring allowed | values jump; pet shows the pose |
| Moment | level-up, task done, evolution, hatch | per the ladder (§7.5); dither behind, chrome holds still | cross-fade + still sparkles |

**Everything moves in whole UI pixels and nothing fades**, except the
cross-fades reduce motion asks for. **Only the pet and reward objects spring.**

### 9.5 Icons

[Draw the icon set](https://github.com/heichan2000/Tomo/issues/43). 12×12, 1-pixel
lines, one UI pixel per icon pixel, outline for everyday use, filled only for
the selected tab; colour applied at run time (ink, muted, accent, on-accent).
**Ships, 20 icons:** `home`, `homeF`, `workClip`, `workClipF` (the Work tab is a
clipboard), `back`, `next`, `up`, `down`, `close`, `plus`, `minus` (the draft
#19 kept for the stepper), `more`, `gear`, `trash`, `external`,
`check`, `bellOff`, and the status glyphs `todo`, `doing`, `done`. `minus` was
a draft that #19 chose to use; the user
[approved it](https://github.com/heichan2000/Tomo/issues/43#issuecomment-6094789501)
after consolidation. **Not
shipped:** `chat` and `chatF`, and the drafts `send`, `eye`, `eyeOff` and `info`,
which stay in #43 parked with the AI. *(Consolidation call, §17 C4: the release
art test refuses drafts.)*

### 9.6 Art storage and approval

[ADR-0020](docs/adr/0020-pixel-art-as-text-grids-in-code.md) (amended by #47).

- **All pixel art is text grids in Dart source**, one character per pixel, `.`
  clear, plus a colour key: pets (egg + 4 stages × 6 parts + eye sheet per
  species), sparkles, icons, the Tomo egg. Compiled in; the app paints them.
  Model `pixel_art.dart`, one file per species.
- **Claude draws; the user approves** on a review page generated from the code
  (`node tool/art/review_page.mjs`). No pixel editor.
- Each drawing is **Draft** or **Approved**; approval holds a fingerprint (first
  16 hex of SHA-256 over the canonical text defined in `pixel_art.dart`) and a
  link to where the user said yes. Changing one pixel, colour or motion setting
  makes it a draft.
- **One art test fails a release build** if any drawing is missing, a draft, or
  doesn't match its fingerprint.
- **Status today:** all 18 pet drawings are approved in code. **The icons
  (#43), the sparkle (#39) and the Tomo egg (#44) are approved but still live as
  grids in their ticket comments**; moving them into the code is an early build
  step (§18).

### 9.7 App icon and splash

[App icon and splash screen](https://github.com/heichan2000/Tomo/issues/44). The
**Tomo egg** — a plain cream egg, belonging to no species, eyes peeking from its
crack — on `#4A443C`, from one approved 36×36 grid. It stays the egg after the
hatch. iPhone 1024 master (default, dark on `#000`, one-colour with the crack
cut out; Liquid Glass off on the egg layer); Android adaptive (2 dp per pixel
over the 72 dp visible area; grey background, egg foreground, monochrome);
splash = the egg at 4 pt per pixel in a 160 pt `#4A443C` circle on the theme
ground. **Generated by Tomo's own script from the grid and committed**; a test
fails if they differ. No launcher-icon or splash packages.

---

## 10. Voice and copy

### 10.1 Rules

[ADR-0021](docs/adr/0021-plain-voice-bad-news-quiet-chatty-personality.md),
[The pet's written voice](https://github.com/heichan2000/Tomo/issues/51).

- **Pet voice keeps good news only**: reward and Focus lines, the hatch line,
  the egg line, timer notifications, setup descriptions.
- **Plain voice** for all bad news and anything that explains a setting: the
  clock notice, notifications denied and the permission framing, the auto-start
  note, lock refusals, stop early, deletes, empty states, About, the error block.
- **Species rules no shading may erase:** Geode — present tense, no future, no
  "you", durations, **numbers spelled in words** (so `tomo_core` needs a small
  English number-to-words helper); Joe — exact digits, no "you"; Lily — the only
  one who says "you", and every question closes itself.
- **Personality is Quiet / Chatty**: how much the pet volunteers. Quiet is the
  script; Chatty adds **one** detail where a real one exists, and only things
  that can't go down (counts that grow, firsts, this cycle). Never streaks,
  comparisons or time away. Timer notifications are Quiet only.
- **ARB layout:** one entry per moment with the three pets side by side (a
  `select` on species); Chatty entries separate, named by their detail
  (`blockDoneChattyTaskTotal`), falling back to Quiet when missing or the detail
  isn't true; plain-voice entries have no per-pet split.

### 10.2 The script

**The full script — every pet-voice line (Quiet and Chatty, per species), the
notifications, the plain-voice lines and the screen-reader runs — is in
[#51's resolution](https://github.com/heichan2000/Tomo/issues/51#issuecomment-6052038890).**
Write the ARB file from it with numbers, task and project names as placeholders.
It is not copied here so it has one home.

### 10.3 Lines written at consolidation

New surfaces from §4.7 and §8.5, in plain voice:

| Where (key) | Line |
|---|---|
| Custom sheet, title `customTitle` | Custom length |
| Custom sheet, focus stepper `customFocus` | Focus |
| Custom sheet, break stepper `customBreak` | Break |
| Custom sheet, button `customUse` | Use these |
| Length chip `customChip` | Custom · {minutes} min |
| Choice `startAnotherTask` | Start another task |

The other labels in §8.5 already exist in the script and the approved screens.

### 10.4 Screen reader

The pet is one node: "Geode, level 7. 480 of 600 EXP toward level 8. Stage 1 of
4." The egg: "Geode egg. It hatches when you finish a focus block." The clock:
"About 19 minutes left on Write the intro." A run speaks **once, at its start**:
"Block done: 25 minutes on Write the intro. Geode gained 250 EXP and reached
level 8. Geode: Level eight. Another hour in me." Full set in #51.

---

## 11. Notifications and haptics

### 11.1 Exactly three notifications

[ADR-0008](docs/adr/0008-derived-notification-schedule-no-inline-actions.md),
[Notification content & platform configuration](https://github.com/heichan2000/Tomo/issues/15).

| Notification | Fires at | Android channel | iOS category |
|---|---|---|---|
| Block complete | `end_at` | `focus_block_v1` | `focusBlock` |
| Block complete + break begun (auto-start) | `end_at` | `focus_block_v1` | `focusBlock` |
| Break complete | `break_start_at + break_minutes` | `break_v1` | `break` |

**Nothing else, ever:** no reminders, re-engagement, streak nudges, ongoing
countdown, foreground service or Live Activity.

- **Title** is the pet's name, or **"Your egg"** before the hatch (the first
  block's body hints at the hatch). **Bodies** are facts that stay true when read
  hours late: the task and minutes counted; never EXP, level, imperatives or
  time words. Copy in #51.
- **Lock-screen privacy is the OS's:** Android `VISIBILITY_PRIVATE` with a public
  version; iOS `hiddenPreviewsBodyPlaceholder`. No Tomo toggle.
- **No actions.** A tap opens the app. The payload carries only the cycle's
  `start_at`: if that cycle is still live, Focus un-minimises; otherwise the
  normal cold-start rule applies.

### 11.2 The schedule is derived

```
syncNotifications(cycle, now, isForeground)   // idempotent
desired = isForeground ? {} : this cycle's notifications with fireAt > now
```

Called on **every cycle write** and **every lifecycle change**. Fixed ids per
slot (block end, break end). Delivered notifications are cleared on foreground.
Every alarm is scheduled **in UTC** as an absolute instant. A boot receiver
reschedules after a reboot. Accepted: a process that dies in the foreground with
no lifecycle callback schedules nothing; the block still credits on next open.

### 11.3 Platform

- **Android:** two channels, both `HIGH`, system default sound and vibration:
  `focus_block_v1` "Focus block finished" / "When a focus block you started
  reaches its end."; `break_v1` "Break finished" / "When a break reaches its end."
  **`USE_EXACT_ALARM`** under Play's timer-app category (fallback if Play rejects
  it: `SCHEDULE_EXACT_ALARM`); each sync uses `exactAllowWhileIdle` if allowed,
  else `inexactAllowWhileIdle`. **Never `setAlarmClock`.**
- **iOS:** interruption level **`timeSensitive`** (Time Sensitive capability),
  `UNNotificationSound.default`, thread `focusCycle`, no provisional
  authorisation.

### 11.4 Permission

Asked at the **first `StartBlock`**, never at launch. While `notDetermined`,
Ready shows the plain-voice framing line; Start opens the OS dialog and **the
block anchors only after it closes**, whatever the answer. Denied → the
plain-voice denial line once on Ready, then the bell-off icon at Focus's top
right for good. Never re-asked automatically; the bell and Settings →
Notifications lead to system settings. Android 13+ uses `POST_NOTIFICATIONS`
(≤ 12 skips the flow); dismissed without answering → asked again at the next
start. Status is re-read on every resume. `notificationPermissionAsked` lives in
the device-only file. **The permission buys convenience, never reward.**

### 11.5 Haptics, no audio

[ADR-0013](docs/adr/0013-no-audio-haptics-only.md). Tomo plays **no audio**.

| Haptic | Fires | Primitive |
|---|---|---|
| Reward tap | each beat as it plays, the same for all five kinds | `HapticFeedback.lightImpact()` |
| Timer buzz | a block or break ends while Tomo is open and no beat will play | `HapticFeedback.vibrate()` |

```
haptic(event, isForeground, beatWillPlay) =
  beatWillPlay → reward tap;  isForeground → timer buzz;  otherwise → none
```

A break ending on Focus takes the buzz. Silent on purpose: stop early, anything
during a running block, ordinary UI, permission denial. No settings row; reduce
motion and Calm pet don't affect haptics. **Nothing may rely on a haptic as its
only channel.** No haptics package.

---

## 12. Accessibility and localisation

[Accessibility & localization baseline](https://github.com/heichan2000/Tomo/issues/8),
ADR-0005. **Enumerated behaviours; Tomo claims conformance to nothing.**

1. **All 9 routes operable** with VoiceOver and TalkBack; every control labelled.
2. **The pet is one semantic node, silent between beats.** It announces only
   what the user caused (a run), never ambient changes. Labels state what the pet
   is, never what the user failed to do.
3. **The countdown is never a live region**; its label is minute-granular and
   read on demand; no milestone callouts.
4. **Reduce motion is graded** (§7.7): the payload survives, the choreography
   goes.
5. **Text to 200%**: screens scroll rather than clip; display numerals and the
   pet's name clamp at 1.3× (§9.2).
6. **Contrast** 4.5:1 / 3:1 per theme. **No state by colour alone**: shape or
   icon plus word, except task lists, where position carries status.
7. **48×48 targets**; the target may exceed the visual. *Stop early* never sits
   next to a frequent control.
8. **English only; all copy in ARB from the first commit** (`flutter_localizations`
   + `gen_l10n`). Dates and times from the device locale via `intl`; 12/24 h from
   `alwaysUse24HourFormat`; first day of week from the locale.
9. **A block stores its local date and UTC offset at settle**; travel and DST
   never move a day.

---

## 13. Diagnostics and privacy

[ADR-0004](docs/adr/0004-no-telemetry-allowlisted-diagnostics.md), ADR-0029,
ADR-0028.

- **No telemetry**: no crash SDK, analytics or Firebase.
- **The diagnostic log**: a plain rotating file outside Drift, ~200 entries
  under a byte ceiling, fire-and-forget, swallowing its own errors, no clear row.
  An entry holds **only** the exception type name, the stack trace, a
  Tomo-authored enumerated code, app version/build, OS version, device class,
  locale and a timestamp — **allowlisted by construction**; message text,
  `toString()` and user content are not expressible.
- **One `Log` facade**, the only emit path, taking the same allowlisted type.
  Debug prints it to the console; release writes errors to the log.
  `print`/`debugPrint` are banned by the `tomo_lints` rule.
- `FlutterError.onError` and `PlatformDispatcher.onError` both record to the log.
- **Share diagnostics** hands the OS share sheet a `.txt`; the user picks where.
- **The privacy claim:** *Tomo never connects to the internet.* The data stays
  on the phone, apart from what the user sends with Share diagnostics, the
  phone's own backup the user turned on, and crash reports the phone's OS may send
  under its own settings, which Tomo neither enables nor sees. Never say
  "nothing is logged".

---

## 14. Release builds

[Release build size](https://github.com/heichan2000/Tomo/issues/53), ADR-0004.

- **No `--obfuscate` and no `--split-debug-info`**, on both platforms. A stack
  trace in a shared log stays readable with no symbol file to keep; obfuscation
  would also scramble the type name the log keeps. Measured saving: ~0.66 MB
  installed, ~0.3 MB download (~3%).
- **No size budget.** One release-checklist tripwire: **Android arm64 release APK
  under 25 MB, or find out why** (skeleton measured at 19.0 MB).

---

## 15. Project and platform

[Project structure, package manifest & platform baselines](https://github.com/heichan2000/Tomo/issues/24)
(ADR-0027), amended by ADR-0028 and ADR-0029.

### 15.1 Versions

- **Flutter 3.47.6 / Dart 3.13.5, pinned with FVM** (`.fvmrc`). `sdk: ^3.13.0`,
  `flutter: ">=3.47.0"`. Upgrades are deliberate, one commit each.
- **iOS 15**, iPhone only (`TARGETED_DEVICE_FAMILY = 1`). **Android 8 (API 26)**;
  compile/target SDK are Flutter's defaults.
- Portrait only. On Android screens ≥ 600 dp the phone layout sits in a centred,
  phone-width column on the theme ground.

### 15.2 Packages

App (`^`, `pubspec.lock` committed): `flutter_riverpod` ^3.4.3 (hand-written
providers, no codegen, app only) · `drift` ^2.35.2 (core) · `drift_flutter`
^0.3.1 · `shared_preferences` ^2.5.6 · `flutter_local_notifications` ^22.3.1
(also requests the permissions) · `timezone` ^0.11.1 (UTC scheduling) · `intl`
^0.20.3 + `flutter_localizations` · `path_provider` ^2.1.6 · `share_plus`
^13.3.1 · `package_info_plus` ^10.2.2.

Dev: `build_runner` ^2.16.1 (C9), `drift_dev` ^2.35.1, `mocktail` ^1.0.5, `crypto`
^3.0.7, `test`, `flutter_test`, `flutter_lints`. `tomo_lints` alone also asks for
`analysis_server_plugin`, `analyzer`, `analyzer_testing` and
`test_reflective_loader`.

**Deliberately absent:** `http`, `flutter_secure_storage` (ADR-0029), `rive`,
`flutter_svg`, `lottie`, `google_fonts`, any crash/analytics SDK or Firebase,
`dio`, `mockito`, `riverpod_generator`, `riverpod_lint`, `permission_handler`,
`flutter_timezone`, `device_info_plus`, `flutter_launcher_icons`,
`flutter_native_splash`, `sqlite3_flutter_libs` (end of life; current `sqlite3`
bundles SQLite, including for host tests). A test keeps the resolved set to a
written allowlist, `docs/package-allowlist` (§16). *Absent* means Tomo never
asks for these and never imports them: `http` and `sqlite3_flutter_libs` are
still resolved, because packages Tomo does use depend on them (C13).

### 15.3 Lints

`flutter_lints`, which includes `lints/recommended`, for the app and both
packages, from **one `analysis_options.yaml` at the root** (C10);
`strict-casts`, `strict-inference`, `strict-raw-types`; `unawaited_futures`,
`avoid_print` as an error, `prefer_final_locals`; plus
**`packages/tomo_lints`**, one rule, an error: no `print` or `debugPrint`
outside the `Log` facade.

### 15.4 Layout — a Dart workspace

```
tomo/
├─ .fvmrc
├─ pubspec.yaml               ← the app; declares the workspace
├─ lib/                       ← Flutter app, feature-first
│  ├─ main.dart
│  ├─ app/                    ← routes, 2-tab shell, two ThemeData, startup, wide-screen column
│  ├─ ui/                     ← pixel kit: grid painting, icons, buttons, sheets, text sizing
│  ├─ home/ focus/ work/ stats/ settings/ onboarding/
│  ├─ pet/                    ← painting the pet, movements, sparkles
│  ├─ platform/               ← plugin wrappers: notifications, share, haptics
│  └─ l10n/                   ← ARB + generated lookups
├─ test/                      ← mirrors lib/
├─ assets/fonts/              ← Ark Pixel Latin subset + OFL
├─ packages/
│  ├─ tomo_core/              ← plain Dart: no Flutter, no Riverpod, no plugins
│  │  ├─ lib/ focus/ rewards/ pet/ tasks/ notifications/ stats/ diagnostics/
│  │  │       data/ (the Drift database, tables, migrations)
│  │  │       art/  (pixel_art.dart, pets/, icons, sparkles, Tomo egg)
│  │  │       testing/ (exported as package:tomo_core/testing.dart)
│  │  ├─ drift_schemas/
│  │  └─ test/
│  └─ tomo_lints/
├─ docs/manual-checks.md      ← the release checklist (§16)
└─ tool/
   ├─ art/                    ← review page generator (Node)
   └─ check                   ← the one "done" command
```

`tomo_core` has no Flutter dependency, so a Flutter import there fails to
compile; its tests run under plain `dart test`. Plugins reach core only through
small interfaces the app implements in `platform/`. *(No `chat/` or `agent/`
folders: ADR-0029.)*

### 15.5 Android

- Permissions: `POST_NOTIFICATIONS`, `USE_EXACT_ALARM`, `SCHEDULE_EXACT_ALARM`
  (`maxSdkVersion="32"`), `RECEIVE_BOOT_COMPLETED` with the notifications
  package's boot and scheduled-notification receivers. **No `INTERNET`** in the
  release manifest (Flutter's debug/profile manifests keep theirs for tooling).
- Backup per §6.4.
- `screenOrientation="portrait"`; core library desugaring on; the notifications
  package's R8 keep rules.
- Debug installs beside the real app: `applicationIdSuffix ".dev"`, label
  **Tomo Dev**.

### 15.6 iOS

- Deployment target 15.0; iPhone only; portrait only.
- **No `UIBackgroundModes`** — Tomo never runs in the background.
- Time Sensitive Notifications capability; the `UNUserNotificationCenter`
  delegate set in `AppDelegate`.
- `ITSAppUsesNonExemptEncryption = NO`; `PrivacyInfo.xcprivacy` with no tracking,
  no collected data, and the UserDefaults reason.
- Default backup on; the device-only file and diagnostic log excluded.
- Debug: display name **Tomo Dev**, bundle id `.dev` (Debug xcconfig).

### 15.7 Builds

- **No flavors.** Debug and release differ only in the `Log` sinks.
- **Generated files are committed:** Drift `.g.dart`, `gen_l10n` output,
  `drift_schemas/`, the icon and splash files.
- **`tool/check`** runs `build_runner`, `gen_l10n`, the analyzer (with
  `tomo_lints`; `dart analyze --fatal-infos`, C11) and every test in the app and
  both packages, and fails if any generated file changed or the Flutter on PATH
  is not the pinned one. It is a Dart script, `tool/check.dart`, behind
  `tool/check` and `tool/check.cmd` (C12). CI is out of scope.
- Windows build notes (#53): Gradle 9.3 needs JDK 17+ (`flutter config
  --jdk-dir`); Kotlin incremental compilation fails when the project and the pub
  cache are on different drives.

---

## 16. Testing — the promises list

[Test inventory and coverage bar](https://github.com/heichan2000/Tomo/issues/52)
supersedes the architecture doc's §10.

- **Done means `tool/check` passes.** No coverage number.
- **Every promise has a keeper:** *Types* (analyzer or type system makes the
  broken version inexpressible), *Core* (unit test in `tomo_core`), *Data*
  (`openTomoDatabase(NativeDatabase.memory())`), *Widget*, *File* (a test over
  repo files), *Release* (a line in `docs/manual-checks.md`).
- **No golden tests, no `integration_test` suites in MVP.**
- The one test of a rule itself: the `tomo_lints` rule is proven to flag `print`.
- **Never online is asserted:** a test fails if the release manifest asks for
  `INTERNET` or if `pubspec.lock` (transitive included) holds a package outside the
  written allowlist; the release checklist reads the release APK's final
  permission list.

The 38 promises, with sources and keepers, are listed in
[#52's resolution](https://github.com/heichan2000/Tomo/issues/52#issuecomment-6054154459).
Three additions from this consolidation:

| # | Promise | Source | Keeper |
|---|---|---|---|
| 39 | Marking a task done never ends the cycle; a cycle whose task is done offers no next block and no auto-start countdown. | §4.3, §5.4 | Core + Data |
| 40 | Block length is 10–120 min; presets carry their break (25/5, 50/10); the custom pair is remembered. | §4.7 | Core |
| 41 | A ring tap on a done task reopens to `doing` if it has blocks, else `todo`. | §5.4 | Data |

The release checklist is [`docs/manual-checks.md`](docs/manual-checks.md), run in
full on a real iPhone and a real Android phone **before every store release**.

---

## 17. Contradictions found, and how they were settled

**Settled by the later decision** (no new choice made):

| # | Clash | Settled as |
|---|---|---|
| R1 | Everything AI (PRD, arch §8, #4, #6, #14, #20, #24, #28, 3 tabs, 12 routes, seven faces, secure storage, chat tables, AI keys, `http`, `INTERNET`) vs ADR-0029 | Parked, no trace. Two tabs, 9 routes, five faces, three stores + device file. |
| R2 | #24 / arch §5 "Android backup disabled" vs ADR-0028 | Backup on, database and settings only. |
| R3 | #10 kept `notificationPermissionAsked` in key-value vs #49 | Device-only file. |
| R4 | #3, #15 wrote the denial and framing lines in the pet's voice vs ADR-0021 / #51 | Plain voice. |
| R5 | #15's notification copy vs #51 | #51's script. |
| R6 | Focus pet ~240/190 pt (#17), 128 pt (ADR-0014) vs #45 | 168 pt. |
| R7 | Fredoka, tick cells, exact ticking timer (#12) vs ADR-0010, ADR-0016 | Quiet clock in plain Ark Pixel. |
| R8 | Block beat = Celebrating hop (#17), chrome dims to 30% (#17) vs ADR-0019, ADR-0017 | Pleased bob; dither, no tint; plates under the EXP bar. |
| R9 | Evolution cross-fade (#16, #29), six/seven swaps (#37), flickering hatch (#37, #39) vs ADR-0019 | Five-swap flicker for evolution only; the hatch shakes and breaks. |
| R10 | Hatch naming at 4.8 s (#39, #45 notes) vs #39's amendment | Shell breaks at 2.5 s, naming at 3.7 s. |
| R11 | Moment budget 1.5–3 s (#12) vs evolution ≈ 4 s and hatch ≈ 5 s (ADR-0019) | The ladder's lengths win for those two beats. |
| R12 | Home egg sentence in plain words (#18, #45) vs #51 | Pet-voice `egg` line. |
| R13 | A Stats zero state (#5) vs #21 | None can occur. |
| R14 | Personality chosen at the hatch, permanent (#9) vs #18, #30 | Chosen at setup, Quiet default, changeable. |
| R15 | Fallback pet (#16) vs ADR-0020 | Retired. |
| R16 | `movement: none` for Calm pet (#16) vs ADR-0018 | `full`/`reduced`; Calm pet acts through the face. |
| R17 | Task picker "from Home only" (#5) vs #17 (Ready's task row) and #45 (*Start another task*) | Three doors (§8.1). |
| R18 | Lock lines "Stop it first" (#19) vs #51 | "Stop it or let it finish first." |
| R19 | Privacy claim built around chat (#7) vs ADR-0029, ADR-0028 | §13. |
| R20 | Arch doc §10 testing vs #52 | The promises list. |
| R21 | `docs/manual-checks.md` written when building (#52) vs at consolidation (#53) | Written now. |
| R24 | Stage 1 "hatches at onboarding" (#2, `CONTEXT.md`) vs ADR-0012 | Hatches at the first finished block. |
| R25 | #16's face ladder shows Celebrating for every beat, below which Calm pet's Still sits — vs ADR-0019's Pleased block beat, which Still would then cancel | The block-done beat's Pleased ranks above Still, so Calm pet still never touches a beat (§7.2). |

**Settled with the user at consolidation:**

| # | Clash or gap | Decision |
|---|---|---|
| R22 | #3 / #11 / ADR-0024: *Mark done* ends the cycle — vs #45's approved *Take a 5-min break* after Task done | **Marking done never ends the cycle**; it only removes "another block on this task". The break stays. Choices in §8.5. |
| R23 | *Custom* length was never designed; break length unspecified | **Two steppers**: focus 10–120 in 5s, break 1–30; presets carry 5 and 10; both remembered (§4.7). |

**Small calls made at consolidation** (overrule freely; none is hard to change):

| # | Gap | Call |
|---|---|---|
| C1 | "Tap the ring: done ↔ previous status" — previous status isn't stored | Reopen to `doing` if the task has blocks, else `todo`. |
| C2 | Clock notice lifetime (its cycle row is gone) | In memory until dismissed or the process ends. |
| C3 | Home's *Start focusing* while a cycle is live | Opens Focus, like the banner. |
| C4 | Icon drafts would fail the release art test; `minus` was kept by #19 but is still a draft | `minus` [approved by the user](https://github.com/heichan2000/Tomo/issues/43#issuecomment-6094789501); `send`, `eye`, `eyeOff`, `info` and the two Chat icons stay parked in #43. |
| C5 | Minimise and Android back during the hatch | No minimise; back is ignored during the animation and acts as *Done* on naming. |
| C6 | The first block's beat with an egg in the pet's place | The egg holds still at its last crack picture; "+EXP" and the bar play as usual; then the takeover. |
| C7 | `focus_cycle.task_id` delete action (#10 left it to #11, which didn't name it) | `ON DELETE RESTRICT`, as a backstop. |
| C8 | Device-only file format | A small JSON file in application-support, excluded from backup. |

**Small calls made while building** (same rule: overrule freely):

| # | Gap | Call |
|---|---|---|
| C9 | `build_runner` ^2.16.2 cannot share a lock with `test` on Flutter 3.47.6: it needs `analyzer` 14.3+, and the only `test` that fits Flutter's pinned `test_api` needs `analyzer` below 14 | `build_runner` ^2.16.1. Raise it with the next Flutter upgrade. |
| C10 | An `analysis_options.yaml` inside a package switches the `tomo_lints` plugin off for that package | One file at the root for everything; a test fails if a nested one appears. `tomo_core` is held to `flutter_lints`, which includes `lints/recommended`. |
| C11 | On Flutter 3.47.6 `flutter analyze` returns before analyzer plugins report, so it never shows a `tomo_lints` finding | `tool/check` runs `dart analyze --fatal-infos`. Do not trust a bare `flutter analyze`. |
| C12 | `tool/check` has to run on Windows | A Dart script with two thin wrappers; it also fails if the Flutter on PATH is not the one `.fvmrc` pins. |
| C13 | `http` (through `timezone` and `package_info_plus`) and `sqlite3_flutter_libs` (through `drift_flutter`) are resolved whatever Tomo asks for | Both are on the allowlist as brought-in packages. The never-online test fails if any pubspec asks for a deliberately absent package or Tomo's own code imports one. |
| C14 | The project needs an application id before store prep picks the real one | Placeholder `io.github.heichan2000.tomo`. Changing it later makes a fresh install, so settle it before dogfooding a real pet. |
| C15 | A Windows checkout turned line endings into CRLF, which broke `tool/art` | `.gitattributes` keeps LF everywhere (`.cmd`/`.bat` excepted). |
| C16 | "The database" in the Android backup rules: SQLite can leave recent writes in a side file | The rules name `tomo.sqlite`, `tomo.sqlite-wal` and `tomo.sqlite-journal`, plus `FlutterSharedPreferences.xml`. So the database file must be called `tomo.sqlite`, and the six settings must go through the plugin's shared-preferences backend, not its DataStore one. |
| C18 | The id convention is `AUTOINCREMENT`, but `focus_cycle` has `CHECK (id = 1)`: an auto-incremented second cycle would get id 2 and be refused | `focus_cycle.id` is a plain primary key that defaults to 1. |
| C19 | How "a failed migration never wipes" reaches the screen | `TomoDatabase.start()` opens the file at start-up and returns `ready` or `failed`. On `failed` the file is untouched (every migration step runs in one transaction; a file from a newer Tomo is refused outright), a `storageStartFailed` diagnostic entry is written, and the caller shows the error block. |
| C17 | Marking the device-only file and the diagnostic log as left out of the **iPhone** backup needs native code; no package Tomo has can set that flag | Not written yet. It belongs with the code that creates those two files, and can only be checked on a Mac. |

---

## 18. What the builder inherits

The map's *Not yet specified* section is empty. These are known, not unknown:

**First steps (in order):**
1. Move `lib/art/` to `packages/tomo_core/lib/art/` and update
   `tool/art/review_page.mjs`'s paths.
2. Move the approved grids that still live in tickets into the code under the
   same model: the icon set ([#43](https://github.com/heichan2000/Tomo/issues/43)),
   the sparkle ([#39](https://github.com/heichan2000/Tomo/issues/39)) and the
   Tomo egg ([#44](https://github.com/heichan2000/Tomo/issues/44)). Their pixels
   don't change, so each can be marked approved pointing at its ticket comment,
   but the fingerprint is new — show them on a generated review page once.
   `minus`'s approval is [its own comment](https://github.com/heichan2000/Tomo/issues/43#issuecomment-6094789501).
3. Write the icon/splash generator script and its test.
4. Write `docs/package-allowlist` (or equivalent) for the never-online test.
   *(Done: `docs/package-allowlist`, `test/never_online_test.dart`.)*

**Checks only a real phone can answer** (all in `docs/manual-checks.md`):
- Text and dither **start on whole dots** on a 2.625× Android phone (#35, #38).
- Whether Android's `vibrate()` needs a manifest permission (#22 expects not).
- iOS release size (unmeasured; needs a Mac) (#53).
- Play review accepting `USE_EXACT_ALARM` (fallback pre-decided, #15).

**Accepted holes, on purpose:**
- A user who never finishes a block never meets a pet (ADR-0012).
- A process that dies in the foreground with no lifecycle callback schedules no
  notification; the block still credits on next open (#15).
- A beat run dropped by ending the cycle without returning to Focus is never
  shown; the EXP stays (ADR-0009).
- Android haptics can be silently swallowed by a system setting Tomo can't read
  (ADR-0013); nothing relies on them.

---

## 19. What this spec does not cover

Silence here is not an answer. Out of scope for this effort (see the map's
[Out of scope](https://github.com/heichan2000/Tomo/issues/1) section):

- **Store and launch preparation:** bundle ids, store listings, screenshots,
  privacy policy text, data-safety forms, TestFlight/Play tracks.
- **CI/CD.**
- **Monetization** — none, by the PRD.
- **Everything in the PRD's Future Versions**, now including **the AI
  pet-agent** (ADR-0029). Its parked decisions are the starting point for that
  effort: [#4](https://github.com/heichan2000/Tomo/issues/4),
  [#6](https://github.com/heichan2000/Tomo/issues/6),
  [#14](https://github.com/heichan2000/Tomo/issues/14),
  [#20](https://github.com/heichan2000/Tomo/issues/20),
  [#27](https://github.com/heichan2000/Tomo/issues/27),
  [#28](https://github.com/heichan2000/Tomo/issues/28), ADR-0002, ADR-0025,
  `docs/research/2026-08-18-ai-provider-free-tiers.md`, and the *Chat and the
  agent* section of `CONTEXT.md`. Time-sensitive facts (free tiers, terms) must
  be re-checked.
- **Dropped, not deferred:** coins, cosmetics and a shop (ADR-0007); a streak
  (ADR-0026).
- **Writing the app and producing any further art.**

---

## 20. North-star check

*Does the specified product keep real-life task progress as the reward, with
EXP only visualising it?*

- **Every grant is linear in finished focus minutes**; nothing pays for block
  length, task splitting, timing, estimates or tapping. The task bonus is 10% of
  the task's own minutes, once.
- **Nothing can go down.** No decay, no streak, no time-of-day moods, no "welcome
  back" that measures absence, no Stats number a delete can lower, no Chatty
  detail that can fall. Stopping early costs that block and nothing before it,
  and the egg never closes on screen.
- **Nothing nags.** Three notifications, all for timers the user started; no
  buzz during a block; the pet never speaks ambiently; bad news is plain.
- **The pet is earned**: it hatches from the first finished block, and every
  stage after is hours focused.
- **Nothing is gated** by progress or payment; there is nothing to buy.
- **The real work stays the point:** marking a task done on Work is quiet; the
  celebration lives on Focus, beside the work. Task done is a bigger beat than
  level-up, because finishing the real thing is rarer than another hour.

It holds.
