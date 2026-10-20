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
| One pet | **Three starters** (Geode, Joe, Lily); the user picks one at setup, by its egg, and keeps it forever. What hatched is a surprise until the hatch (ADR-0031). Not a collection. | [#9](https://github.com/heichan2000/Tomo/issues/9) |
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
- One pet, picked by its egg at setup from three starters, hatched by the
  first finished block, growing through four stages on EXP earned by finished blocks.
- A lightweight Stats screen (four all-time numbers).
- Settings: rename pet, Calm pet, auto-start, notifications,
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
is the code in `packages/tomo_core/lib/art/` (§15.4).

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
  dropped (marking done on Work is quiet, §8.7). **If its bonus reaches a new
  level or stage, the level-up and the evolution follow it** in the same run
  (C26).
- **The first block's run ends on the hatch.** No level-up plays beside it,
  however long the block was (C25).
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

**Built** in [Reward effects](https://github.com/heichan2000/Tomo/issues/71).
`RunScript` (`tomo_core/pet/run_script.dart`) says what a run shows at each
moment: the pet, the sparkles, confetti and shell in pet pixels, "+EXP", the
plate, the bar, the dither and when the choices (or the naming) step in. Its
confetti uses the prototypes' own random numbers, so it falls as approved; its
colours are in `pet/reward_colours.dart`. In the app, `RunPlayer` and
`SkipRun` (`lib/pet/run_player.dart`) play a run, one reward tap per beat,
and report it finished or skipped; `RewardPet`, `RewardBar` and `DitherOver`
(`lib/pet/reward_view.dart`) paint a frame. Every run, pet, stage, theme and
motion setting is on the debug **Beats** screen (kit gallery). Approved by the
user on the emulator. Its calls: C84–C92.

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

**Built** in [Start-up and the app shell](https://github.com/heichan2000/Tomo/issues/92),
in `lib/app/`: `startTomo` (`start_up.dart`) opens the stores, brings the
cycle up to now and picks the first surface; the providers in `providers.dart`
hand out the database, the services, the logs and the stores; `TomoShell`
(`shell.dart`) is the two tabs, the banner's slot (`RunningBannerSlot`) and
`ShellTabBar`; `routes.dart` has `openFocus`, `pushInTab` and
`finishOnboarding`; `PhoneColumn` is the wide-screen column. Screens not yet
built were stand-ins in `placeholder_screens.dart`, gone since the last of them
was built. Approved by the user on the
emulator. Its calls: C64–C72.

The task picker is **built** in [Focus: the task picker and Ready](https://github.com/heichan2000/Tomo/issues/95),
in `lib/focus/task_picker.dart`: `pickTask` opens it and gives back a
`PickedTask` (the task and its project); Home's `openTaskPicker` opens
Focus on Ready with it. Its calls: C103–C105.

### 8.2 Onboarding

From [Onboarding & hatch flow design](https://github.com/heichan2000/Tomo/issues/18)
(ADR-0012), [Pet voice system](https://github.com/heichan2000/Tomo/issues/30),
[Redraw Home, Focus and Onboarding](https://github.com/heichan2000/Tomo/issues/45).
Neutral grey chrome throughout. No account, no permissions, nothing taught.

1. **Choose your egg.** Title and one line; the three starters' **eggs** as
   tiles, whole (96 pt), each with its egg's name (*Stone egg*, *Paper egg*,
   *Spotted egg*); the chosen one a sunken shade with a check in its top
   corner, so a long name stays on one line and no tile grows.
   Below: the chosen egg's **hint**, in the plain voice, *Next*. Nothing names
   the pet: it is a surprise until the hatch
   ([ADR-0031](docs/adr/0031-choose-the-pet-by-its-egg.md), #114). There is no
   personality to choose (ADR-0030).
2. **What are you working on?** Back; title and one line; one text field;
   *Done* (primary), *Skip* (quiet, muted). The line becomes **both the seeded
   project's name and the first task**. Skipped → one plain default project and
   no task.

Nothing is written until screen 2 finishes or is skipped; then **one
transaction** creates the pet row (species, `name` and
`hatched_at` null), the project, and the task if typed. A kill before that
restarts onboarding from screen 1.

**Built** in [Onboarding](https://github.com/heichan2000/Tomo/issues/93), in
`lib/onboarding/onboarding_screens.dart`: `PickPetScreen` pushes
`FirstTaskScreen`, which calls `Onboarding.complete` and then
`finishOnboarding`. The skipped project is called **My work**. Screens lay out
through `ScreenBody` (`lib/ui/screen_body.dart`). Its calls: C73–C77.

### 8.3 Home

- **Top:** level chip (*Lv 7*, opens Stats) at the left, gear (Settings) at the
  right.
- The pet at 192 pt (hello, idle moves, tap hop); its **name** at pet-name size;
  the **20-block EXP bar** with "480 / 600 EXP" (one block = 30 EXP); *Start
  focusing*; the tab bar.
- **Before the hatch:** no chip, no name, no bar. The species egg (wobbling), and
  the plain **egg line** under it, naming only the egg ("Your stone egg hatches
  when you finish a focus block.", ADR-0031).
- **Clock notice:** a sunken strip above the pet with a close (×), in plain
  voice; never a dialog. Held in memory until dismissed or the app process ends.
  *(Lifetime is a consolidation call, §17 C2.)*
- **Banners:** running (sunken; 4-pixel accent square; task; "19 min left" in
  muted caption; chevron up) and finished (accent strip, "Block done · 25 min
  counted" or "Break over", wraps at large text).

**Built** in [Home](https://github.com/heichan2000/Tomo/issues/94), in
`lib/home/home_screen.dart`: `HomeScreen` shows the pet through
`petStandingProvider`, which reads `PetReader` (`tomo_core/pet/pet_standing.dart`):
the pet, the live cycle and the owed run, so the look is `PetStanding.lookAt`.
The level chip and the gear push the Stats and Settings stand-ins; *Start
focusing* opens the task picker (`openTaskPicker`). Its calls:
C78–C83.

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

**Ready is built** in [Focus: the task picker and Ready](https://github.com/heichan2000/Tomo/issues/95),
in `lib/focus/`: `FocusScreen` shows `ReadyScreen` while a task is picked and
no block has started, and the live states' stand-in otherwise; `FocusHeader`
is the header every state shares; `chooseCustomLengths` opens the Custom
sheet (`length_sheet.dart`). Approved by the user on the emulator. Its calls:
C106–C109.

**Running, the break, Stop early and the banner are built** in [Focus: running, the break, Stop early and the banner](https://github.com/heichan2000/Tomo/issues/96):
`LiveFocus` (`lib/focus/live_focus.dart`) is Focus once a cycle is live: the
running block, the break, the countdown and the *Stop this block?* sheet,
with Android back minimising (or *Leave* from a finished state). The quiet
clock and its line are `QuietClock` (`clock_view.dart`); the banner is
`RunningBannerSlot` (`lib/app/running_banner.dart`). Approved by the
user on the emulator. Its calls: C110–C115.

**Block done, Break over, the choices and the estimate card are built** in [Focus: block done, break over and the choices](https://github.com/heichan2000/Tomo/issues/97):
`LiveFocus` plays the owed run (and *Task done* when the task is marked done
there), speaks it once, and marks it seen; `AfterBlock`
(`lib/focus/after_block.dart`) lays out the notes, the pet, its line, the bar,
`EstimateCard` and the choices. Which choices show is `choicesAfter`
(`tomo_core/focus/choices.dart`); which line a run shows is `runMoment`
(`tomo_core/voice/pet_moment.dart`). The hatch is §8.7's. Its calls: C116–C123.

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
line, a **Name your Geode** (*Joe*, *Lily*) field **pre-filled with the species
name**, and *Done*. The label says what hatched, since the egg kept it a
surprise (ADR-0031). *Done*
returns to Focus's choices. There is no minimise during the takeover and the
banner never shows it; Android back does nothing during the animation and acts
as *Done* on the naming step. *(The egg during the beat and back behaviour are
consolidation calls, §17 C5–C6.)*

A user who never finishes a block never meets a pet. Accepted (ADR-0012).

**Built** in [The hatch takeover](https://github.com/heichan2000/Tomo/issues/98):
`LiveFocus` plays the first block's run with Focus around it until the hatch
beat, then shows `HatchTakeover` (`lib/focus/hatch.dart`): the pet at 192 pt,
the hatch line, the **Name** field and *Done*. *Done* (or the keyboard's done
key, or Android back on the naming) writes the name through `PetService.rename`
(`tomo_core/pet/pet_service.dart`), which Settings → Rename pet will use too.
Its calls: C124–C129.

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

**Work and the project screen are built** in [Work and the project screen](https://github.com/heichan2000/Tomo/issues/99),
in `lib/work/`: `WorkScreen` (the tab, `newProject`, `EmptyCard`) and
`ProjectScreen` (the list, the quiet mark done, *Add a task*, the menus and
the deletes). A row is `TaskListRow`; the sheets are in `work_sheets.dart`
(`chooseProjectToMove` and `confirmDelete` are for Task detail too). The
screens watch `WorkLists` (`work_lists.dart`), fed by
`TaskService.watchProjectSummaries()` (each project with its open and done
counts) and `watchTasksInProject()`. Its calls: C133–C143.

**Task detail is built** in [Task detail](https://github.com/heichan2000/Tomo/issues/100),
in `lib/work/task_detail_screen.dart`: `TaskDetailScreen`, opened by
`openTaskDetail` from a task's row. It watches its task through
`workTaskProvider` and follows it to another project; the delete sheet and
*Move to project* are the project screen's. Its calls: C144–C149.

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

**Stats is built** in [Stats and Settings](https://github.com/heichan2000/Tomo/issues/101),
in `lib/stats/stats_screen.dart`: `StatsScreen`, pushed from the level chip,
reads `statsReaderProvider` once as it opens; a row is `StatRow`. The back
and title are `BackHeader` (`lib/ui/back_header.dart`), shared with Task
detail. Approved by the user on the emulator. Its calls: C150 and C155.

### 8.10 Settings

Pushed from Home's gear. Rows:

| Group | Row |
|---|---|
| Pet | **Rename pet** · **Calm pet** (switch) |
| Focus | **Auto-start** (switch, off) |
| Notifications | permission status + *Open system settings* |
| Appearance | **Match phone / Light / Dark** (full-width segmented control, wraps at large text) |
| About | version; licences (Ark Pixel OFL registered); the `about` and `aboutOs` lines; **Share diagnostics** with its entry count (disabled at zero) and the `shareDiag` line |

Species is permanent; the name is not. Each pet's character comes with its
species (ADR-0030), so there is no Personality row.

**Settings is built** in [Stats and Settings](https://github.com/heichan2000/Tomo/issues/101),
in `lib/settings/`: `SettingsScreen`, pushed from the gear, and
`LicencesScreen`. Every choice takes effect and is kept at once; there is no
save. *Share diagnostics* goes through `ShareSheet` (`lib/platform/share.dart`,
`shareSheetProvider`), which whole-app widget tests replace. Approved by the
user on the emulator. Its calls: C150–C156.

### 8.11 Error block

In release, `ErrorWidget.builder` renders a small plain block with the `error`
line naming *Settings > About > Share diagnostics*. No pet, no pet voice.
The same block, alone on the ground, is all that opens when the database
can't be (C19): `ErrorBlock` and `StartFailedApp` in `lib/app/error_block.dart`.

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

The values live in `packages/tomo_core/lib/look/palette.dart` (`Palette`), the
accent read from each pet's colour key; the contrast test is
`packages/tomo_core/test/look/palette_test.dart`. The app reads them through
`TomoTheme` (`lib/ui/tomo_theme.dart`), set above the navigator by `TomoLook`
(`lib/app/tomo_look.dart`).

### 9.2 Type

[ADR-0016](docs/adr/0016-one-pixel-font-sharp-sizes.md). **One font: Ark Pixel
12px Proportional, regular**, bundled as a Latin subset of its **TTF** build
(49 KB, §17 C45), never fetched, OFL registered in `LicenseRegistry`. Missing characters fall back to the phone's
font; Pixeloid Sans is the fallback font if Ark fails on a device.

- **Sharp sizes only:** `fontSize = 12 × n / devicePixelRatio`; a custom
  `TextScaler` after any clamp rounds to the nearest `n` at 100% and **up**
  above it. Line height whole font pixels (16).
- **Type steps** in dots per font pixel: caption = body − 1, **body =
  `round(1.667 × dpr)`**, title = body + 1, pet name = 2 × body. No bold.
- **Numbers and the pet's name stop growing at 130%**, then step down to the
  largest sharp size that fits. A time or number never scrolls or wraps.
- Digits are all 6 font pixels wide, so changing numbers are plain text.
- **Text is laid out in screen dots, not points** (`PixelText`, §17 C46): the
  font size is `12 × n` dots, drawn scaled back down from a whole dot. Laid out
  in points, letters land a fraction of a dot off on the real phone.

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

**Built** in [Pixel kit](https://github.com/heichan2000/Tomo/issues/69), in
`lib/ui/`: `PixelBox` (every box, its corners, outline and focus ring, painted
on whole dots), `PixelButton` / `PixelIconButton` and their shared `Pressable`,
`PixelTextField`, `PixelSegmented`, `PixelSwitch` / `PixelSwitchRow`, `ExpBar`,
`PixelRow`, `PixelChip`, `PixelIcon` / `StatusGlyph`, `showPixelSheet`,
`PixelPageRoute` and the motion tiers in `motion.dart`. Every part in every
state is on the **kit gallery** (`lib/ui/kit_gallery_screen.dart`, debug only,
C51). Approved by the user on the emulator in both themes. Its calls: C52–C58.

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
- **Status today:** all 40 drawings are approved in code: the 18 pet
  drawings, the 20 icons (`icons.dart`), the sparkle (`sparkle.dart`) and the
  Tomo egg (`tomo_egg.dart`). The art test is
  `packages/tomo_core/test/art/art_test.dart`; `drawings.dart` lists every
  drawing it checks. The review tool writes two pages, `pets.html` and
  `kit.html` (icons, sparkle, Tomo egg).

### 9.7 App icon and splash

[App icon and splash screen](https://github.com/heichan2000/Tomo/issues/44). The
**Tomo egg** — a plain cream egg, belonging to no species, eyes peeking from its
crack — on `#4A443C`, from one approved 36×36 grid. It stays the egg after the
hatch. iPhone 1024 master (default, dark on `#000`, one-colour with the crack
cut out; Liquid Glass off on the egg layer); Android adaptive (2 dp per pixel
over the 72 dp visible area; grey background, egg foreground, monochrome);
splash = the egg at 4 pt per pixel in a 160 pt `#4A443C` circle on the theme
ground. **Generated by Tomo's own script from the grid and committed**; a test
fails if they differ. No launcher-icon or splash packages. The script is
`dart run tool/app_icon.dart` (rules in `tool/app_icon/files.dart`); the test is
`test/tool/app_icon_test.dart` (C41 to C44).

---

## 10. Voice and copy

### 10.1 Rules

[ADR-0021](docs/adr/0021-plain-voice-bad-news-quiet-chatty-personality.md),
[ADR-0030](docs/adr/0030-each-pet-has-its-own-character.md),
[The pet's written voice](https://github.com/heichan2000/Tomo/issues/51),
[Give each pet its own personality](https://github.com/heichan2000/Tomo/issues/115).

- **Pet voice keeps good news only**: reward and Focus lines, the hatch line,
  timer notifications after the hatch.
- **Nothing before the hatch is in pet voice** (ADR-0031): the pick's egg
  names and hints, the egg line on Home, the egg's screen-reader label and
  the notifications before the hatch are plain, and name only the egg.
- **Plain voice** for all bad news and anything that explains a setting: the
  clock notice, notifications denied and the permission framing, the auto-start
  note, lock refusals, stop early, deletes, empty states, About, the error block.
- **Species rules no shading may erase:** Geode — present tense, no future, no
  "you", durations, **numbers spelled in words** (so `tomo_core` needs a small
  English number-to-words helper); Joe — exact digits, no "you"; Lily — the only
  one who says "you", and every question closes itself.
- **Each pet has its own character** (ADR-0030), on top of its species rule:
  Geode a calm, gentle rock; Joe a fussy, neat paper bird; Lily an
  encouraging, bright kid. There is no personality choice.
- **Facts can't go down.** A line may add a fact only if it is a count that
  grows, a first, or this cycle. Never streaks, comparisons or time away.
- **No line suggests putting work off**: no napping, no "later", no "skip it".
- **ARB layout:** one entry per moment with the three pets side by side (a
  `select` on species). Six moments also have a **fact entry**, named by its
  fact (`blockDoneTaskTotal`), said only when `PetMoment.factHolds`;
  plain-voice entries have no per-pet split.

### 10.2 The script

**Every pet-voice line, per species and including the notifications, is in
[#115's record](https://github.com/heichan2000/Tomo/issues/115#issuecomment-6258694999).**
It replaces the pet-voice lines of the first script. **The plain-voice lines
and the screen-reader runs are still in
[#51's resolution](https://github.com/heichan2000/Tomo/issues/51#issuecomment-6052038890).**
Write the ARB file from it with numbers, task and project names as placeholders.
It is not copied here so it has one home. *(Written: `lib/l10n/app_en.arb`. A
test holds every line to the script's wording, and `lib/voice/pet_voice.dart`
picks the line.)*

**Added after the script** by the user in
[Five lines the script doesn't cover](https://github.com/heichan2000/Tomo/issues/85),
and recorded with the script in #51:

| Case | Line |
|---|---|
| Lily, a task done in one block (`taskDoneTaskTotal`) | You finished {task} in just one block! That feels great, doesn't it? *(Rewritten in character by #115.)* |
| Lily, the estimate card, a plan of one block (`estimate`) | That's the one block you planned for it. You kept your word, didn't you? *(Rewritten in character by #115.)* |
| Delete project, tasks but no focus time (`delProjNoFocus`) | Its {count} tasks go with it, for good. They have no focus time, so your stats don't change. *(One task: Its 1 task goes with it, for good. It has no focus time, so your stats don't change.)* |
| Delete project, one task (`delProj`) | Its 1 task goes with it, for good. The {duration} you focused on **it** stays in your stats. |
| Delete task, an hour or more of focus time (`delTaskLong`) | "{task}" and its notes go for good. The {duration} you focused on it stays in your stats. *(Under an hour, the script's `delTask` with minutes.)* |
| The first block ever, under auto-start | No new line: the first-block notification, which doesn't mention the break. |

`deleteTaskBody` and `deleteProjectBody` in `pet_voice.dart` pick the delete
sheets' lines; `focusTime` writes a length as Stats does.

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
4." The egg: "Stone egg. It hatches when you finish a focus block." The clock:
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

- **Title** is the pet's name, or the egg's (**"Your stone egg"**) before the
  hatch. The first block's body is plain and hints at the hatch: "15 minutes of
  Write the intro, counted. Your stone egg is cracking!"; a break that ends
  before the hatch is seen says "Your break is over." (ADR-0031). **Bodies** are facts that stay true when read
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

**Built** in [Notifications and haptics on the phone](https://github.com/heichan2000/Tomo/issues/72):
`NotificationSync` in core (`notifications/notification_sync.dart`), run by
both services after every write and by `NotificationWatch`
(`lib/app/notification_watch.dart`) on every lifecycle change;
`PhoneNotifications` and `PhonePermission` in `lib/platform/notifications.dart`;
`notificationAccessProvider` for Ready and the bell (`ask()`, `openSettings()`,
re-read on resume). The timer buzz is `TimerBuzz` (`lib/app/timer_buzz.dart`),
around the whole app: it fires `SystemHaptics` from `hapticFor` at the moments
`timerEnds` gives, the same ones the notifications use. Focus fires only the
reward tap, through its beat run. Its calls: C93–C101.

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
│  ├─ app/                    ← routes, 2-tab shell, the look (theme, sharp text), startup, wide-screen column
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
│  │  │       look/ (palette.dart: the colours and their contrast)
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
| R12 | Home egg sentence in plain words (#18, #45) vs #51 | Pet-voice `egg` line. **Replaced by ADR-0031 (#114):** plain words, "Your stone egg hatches when you finish a focus block." |
| R13 | A Stats zero state (#5) vs #21 | None can occur. |
| R14 | Personality chosen at the hatch, permanent (#9) vs #18, #30 | Chosen at setup, Quiet default, changeable. **Replaced by ADR-0030 (#115):** no choice at all; each pet has its own character. |
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
| C20 | *Stop early* arriving after the block has ended (§4.6 says it completed) versus "illegal pairs assert" (§4.3) | `stopEarly` on a finished cycle is not an error: it credits the block if still owed and returns where the cycle stands. Only `stopEarly` with no cycle at all asserts. |
| C21 | Which UTC offset a block record stores | The phone's offset **at the instant the block ended**, as the phone knows it at settle. `local_date` is that instant's calendar day at that offset, so the pair always agrees. |
| C22 | A task with no focus marked done pays a bonus of zero: is its one bonus then used up? | Yes. "Once per task, ever, on the first change into done": the flag is set even when the amount is zero, so reopening it, focusing and finishing again pays no bonus. |
| C23 | "Recent first" inside a project's status groups was not defined | The latest of a task's creation, last focus and completion. The picker orders by last focus, then creation. |
| C24 | How long the onboarding line may be, given it names the project and is the first task | The project-name limit, 60. |
| C25 | Does a level-up play beside the hatch when the first block was 60 minutes or more? | **No** (the user, [#81](https://github.com/heichan2000/Tomo/issues/81)). That block's run is the block beat, then the hatch; the level chip simply shows level 2 or 3 when it first appears. |
| C26 | Does a task bonus that reaches a new level or stage celebrate it? | **Yes** (the user, [#81](https://github.com/heichan2000/Tomo/issues/81)), on Focus: *Task done*, then the level-up, then the evolution. On Work it stays quiet. |
| C27 | A block that crosses two levels at once | One level-up beat, to the level reached. |
| C28 | The egg between a block's end and its settle | It holds its last crack picture. |
| C29 | Under auto-start, with Tomo closed, nothing settles the block, so the row has no `break_start_at` when *Break complete* should fire | The schedule treats the break as beginning at `end_at` ahead of time, and announces its end at `end_at + break_minutes`. |
| C30 | A pet that hatched but was never named (killed on the naming screen) | Its notifications go by its species' name. |
| C31 | The diagnostic log's byte ceiling, file and shape were not fixed | `diagnostics.log` in application-support: one JSON line per entry, at most 200 entries and 512 KiB, the oldest dropped first, a stack trace kept to its first 30 frames. *Share diagnostics* gets it rendered as plain text. Device facts (app version and build, OS version, device class, locale) are stamped on each entry. |
| C32 | Debug builds and Flutter's own error report | In debug, an error Flutter caught is still printed by Flutter's own console report (with its message), as well as recorded. Release prints nothing. |
| C33 | The script's key `break` is a word Dart keeps for itself | The copy file calls it `onBreak` (and `onBreakToday`). |
| C34 | The script shows each line with sample numbers; other numbers need "1 block", "1 hour", "1 minute" | Only the noun changes with the number. No other word of an approved line is touched. Where that was not enough, the user wrote the line ([#85](https://github.com/heichan2000/Tomo/issues/85), §10.2). |
| C35 | When a fact line's fact "isn't true" (was the Chatty detail; #115) | Block done: the task's first block. Level-up and evolution: under one (or two) whole hours focused. Task done: no focus time. Break and break over: nothing finished yet today. |
| C36 | How Geode says numbers above one hundred | American style, no "and": "one hundred twenty", "four hundred twenty-five". |
| C37 | Screen labels that are not in the script (buttons, tab names, Stats row labels) | Not typed in here: the approved prototypes are private to the owner. Each screen ticket adds its labels to the copy file. |
| C38 | Icons and the sparkle are coloured at run time, so they have no colour key for the fingerprint | They fingerprint `paint <char> <role>` lines instead (icon `#` = `icon`; sparkle `#` = `arms`, `o` and `x` = `centre`). The Tomo egg has its own colour key. Ids are `icon.<name>`, `sparkle` and `tomo.egg`. Written out in `pixel_art.dart`. |
| C39 | The approved sparkle draws its centre with two characters, `o` and `x`, that are the same colour | Both kept exactly as drawn; both are the centre colour. |
| C40 | Where the sparkle's colours (ADR-0019's table) and the app icon's `#4A443C` background live | Not in the art. The sparkle is coloured where it is drawn (*Reward effects*); the background belongs to the icon generator. The kit review page copies both from the spec for display only. |
| C41 | The iPhone 1024 master is not a whole number of master pixels per egg pixel (28.4) | Each egg pixel's edges are rounded to the nearest master pixel: hard edges, no smoothing. A 3× home screen still shows exactly 5 dots per egg pixel. The masters have no alpha channel, as the App Store asks. |
| C42 | *Liquid Glass off on the egg's layer* needs an Icon Composer file, which only Xcode 26 on a Mac makes and checks | Not written. The generator writes the classic asset catalog (default, dark, tinted 1024 masters), which every Xcode accepts. The Icon Composer file belongs with the iPhone work, like C17. |
| C43 | Android 8 to 11 have no system splash screen | The launch background draws the same picture from a layer list: the ground, a 160 dp grey circle, the splash egg. On every version the app's window background is the theme's ground, so nothing flashes white before the first frame. |
| C44 | Where the generator lives and how its test compares | `dart run tool/app_icon.dart`, its rules in `tool/app_icon/` with a small PNG writer of its own. `tool/check` does not run it; `test/tool/app_icon_test.dart` fails if a committed file differs, comparing pictures by pixel, not byte, so a new zlib in a Flutter upgrade can't fail it. The Android colours (`tomo_icon_grey`, `tomo_ground`) and the iPhone `LaunchBackground` colour are generated too. |
| C45 | Which build of Ark Pixel to bundle: the research measured the OTF | The **TTF** build, subset to the same Latin range (49 KB, not ~27). On the real phone the OTF's outlines get nudged up and down by the phone's font engine, leaving edges about 4% soft even on whole dots; the TTF's come out exact. Measured on [#60](https://github.com/heichan2000/Tomo/issues/60). |
| C46 | Laid out in points, text starts on a whole dot but its letters don't stay on whole dots: at 2.8125× the letters right of mid-screen land a quarter dot off, and the renderer adds its own slight smear | **All text is laid out in screen dots**: `PixelText` sets the font size to `12 × n` dots inside `InDots`, which lays out in dots and draws scaled back down from a whole dot. Measured exact at 2.8125× and 3.75×, light and dark, 100–200% text ([#60](https://github.com/heichan2000/Tomo/issues/60)). Flutter's newer renderer (Impeller) stays on; turning it off is deprecated. |
| C47 | Text set smaller than the phone's default (below 100%) | Rounds to the nearest whole number of dots per font pixel, never below one, as at 100%. |
| C48 | Where the real-phone pixel check lives | `lib/ui/pixel_check_screen.dart`, a builder's tool, so its words are not in the copy file. It is how *Pixels on a real screen* in `docs/manual-checks.md` is run. Since [#69](https://github.com/heichan2000/Tomo/issues/69) it opens from the kit gallery (C51). Neither is ever in release. |
| C49 | `flutter_local_notifications` adds `VIBRATE` to the manifest | Accepted: an ordinary permission, never asked of the user. Checked anyway: with it removed, the timer buzz (`vibrate()`) and the reward tap (`lightImpact()`) are both felt ([#60](https://github.com/heichan2000/Tomo/issues/60)). |
| C50 | Where a pet stage's six parts and its eyes become one picture | `composeStage` in `packages/tomo_core/lib/art/compose.dart`, standing still, the same stacking as `tool/art/pose.mjs`. The pet-on-screen ticket adds the poses. |
| C51 | Where the kit is shown | The **kit gallery** (`lib/ui/kit_gallery_screen.dart`) is the app's first screen in debug and profile builds until the app shell exists; release opens on the bare ground. Its switches (theme, accent, text size, motion) set `lookOverride`, which `TomoLook` applies above the navigator, so sheets and pushed screens follow them. A builder's tool: its words are not in the copy file. |
| C52 | Pressing a primary button before the hatch, in dark: its fill is the ink, so "one shade toward ink" changes nothing | It moves one shade toward **muted** instead: slightly greyer. Chosen by the user ([#69](https://github.com/heichan2000/Tomo/issues/69)). The press share is 22%, as on the approved kit. |
| C53 | The approved kit's segmented options (5 UI pixels above and below a caption) come under the 48 pt target | Each option is **at least 48 pt tall**, padded like a button. Chosen by the user ([#69](https://github.com/heichan2000/Tomo/issues/69)). When the options don't all fit side by side in equal shares, they stack one per row, full width. |
| C54 | The focus ring's one-pixel gap | **See-through**, not painted in the ground colour, so it looks right on sheets and cards too. Chosen by the user ([#69](https://github.com/heichan2000/Tomo/issues/69)). The ring is painted outside the part, so it never moves the layout. |
| C55 | Boxes laid out in points land between dots | Layout stays in points; every box moves its start **and** end to the nearest whole dot when it paints (`PixelBox`, `wholeDotRect`). Every length inside is whole UI pixels, so text and boxes agree. Centred and end-aligned text has each line moved to a whole dot. Checked on the emulator (2.625×), light and dark, 100% and 200%: every dot of the gallery is exactly a kit colour. |
| C56 | The EXP bar's blocks and "every corner loses one pixel" | The blocks keep their corners, as on the approved kit: each is one pixel block. |
| C57 | The text field's text, caret and selection | Laid out in dots like all text (C46): `EditableText` inside `InDots`, caret one UI pixel wide and one line tall, blinking without a fade; selection a solid pressed-sunken. The selection handles and copy/paste menu are the phone's own. The outline is drawn over the padding, so the text doesn't move when it thickens. |
| C58 | What the screen does at its edges | No overscroll stretch or glow (they scale or blur the screen); the status bar's icons follow the theme. Both set in `TomoLook` / `TomoScrollBehavior`. |
| C59 | When the Pleased bob plays, and which faces blink | The bob plays **once, as the face begins**, then the breath (style guide: "one bob"). A beat that shows the face the pet already has (the block-done beat over a running block's Pleased) starts it over: `PetView(beat:)`. **Only Resting blinks**; Pleased and Celebrating show their happy eyes, Drowsy its lids, Still nothing. |
| C60 | How the random waits are drawn | Blinks: 2.6–6.4 s from one blink's end to the next one's start. Idle moves and the egg's wobble: 15–30 s from one start to the next. All in whole 10 ms steps. A tap's hop pushes a due idle move back by a fresh 15–30 s, so two moves never run back to back. The breath carries on under the idle moves, the wiggle included (the review page paused it for the wiggle). |
| C61 | Which egg is "waiting" | The egg wobbles only when no cycle is running and Calm pet is off: `EggLook.mayWobble`, worked out by `look`. Cracking during a block, and holding its last crack before the hatch, it stays still. |
| C62 | How the pet keeps time on screen | `PetView` has its own stopwatch, never the time of day. It wakes only when the picture next changes (at most a second away), not every frame, and sleeps while the app is hidden or its screen is covered. A move missed while asleep is dropped, not caught up. |
| C63 | Where the pet stands in its spot | Bottom-centred in a square the size of the spot (§7.1); the grid is the largest whole number of dots per pixel that fits. |
| C64 | Which `shared_preferences` API keeps the settings | The plugin's first API, `SharedPreferences.getInstance()` (`SharedPreferencesStore`, `lib/platform/stores.dart`). On Android it writes `FlutterSharedPreferences.xml`, the file the backup rules name (C16). The newer API's default is DataStore, and even its SharedPreferences backend writes a different file unless told otherwise. |
| C65 | Android back on a tab's first screen, and tapping the tab you are on | Back closes the tab's top screen; on Work's first screen it goes to Home; on Home's first screen it leaves the app. Tapping the tab you are on takes it back to its first screen. Chosen by the user ([#92](https://github.com/heichan2000/Tomo/issues/92)). |
| C66 | How debug builds reach the kit gallery once the app opens on the shell | A long press on the Home tab, in debug and profile builds only. Chosen by the user ([#92](https://github.com/heichan2000/Tomo/issues/92)). |
| C67 | Onboarding "above the shell" with no pet yet | Onboarding opens alone; finishing it puts the shell in its place, on Home. A cold start routed to Focus has the shell under it, so minimising lands on Home. |
| C68 | Sheets opened from inside a tab | Every sheet opens over the whole app, the tab bar and banner included (`showPixelSheet` uses the top navigator). Focus, Onboarding and the kit gallery do too; Project, Task detail, Stats and Settings push inside their tab. |
| C69 | The wide-screen column's width, and "600 dp" | From 600 pt of **width**, the column is **412 pt** (a large phone), both edges on whole dots; screens inside see that width and no side insets. |
| C70 | What the keyboard does to the shell | It covers the banner and the tab bar; the screen above shrinks to meet it, and nothing in the shell moves. The tab bar sits 4 UI pixels above the phone's own buttons or gesture bar, its surface reaching under them. |
| C71 | Start-up details | The settings are read before the database, so the error block wears the chosen theme. A cycle that can't be brought up to now at start-up also shows the error block. The hatched pet's species is read at start-up, so the first frame has the right accent. Tab names are in the copy file (`tabHome`, `tabWork`). |
| C72 | Widget tests of the whole app and the database's watched queries | Drift's watched queries never finish on a widget test's pretend clock. Whole-app tests use `pumpTomo` / `testTomo` (`test/app/app_harness.dart`): database work runs on the real clock, and watched streams are replaced (`speciesChangesProvider`, and `petChangesProvider`, which a test feeds with `petChanged`). Screen tickets that watch the database in widget tests need the same care. |
| C73 | The project made when *What are you working on?* is skipped | **My work** (`defaultProject`). Chosen by the user ([#93](https://github.com/heichan2000/Tomo/issues/93)). |
| C74 | *Done* with nothing typed | Turned off until the field holds more than spaces; *Skip* is right under it. The keyboard's Done key finishes only once a line is typed. Chosen by the user ([#93](https://github.com/heichan2000/Tomo/issues/93)). The field takes at most 60 characters (C24). |
| C75 | The setup tiles' eggs | The chosen egg sways now and then, as an egg waiting on Home does; the other two hold still. Its check sits in the tile's top corner, not before the name (the user's choice, #114): "✓ Spotted egg" didn't fit on one line, so the chosen tile grew. A tile is one button to a screen reader, named by its egg (*Stone egg*), with its selected state; the egg itself is not a separate item and doesn't sway on tap. (Pets until #114.) |
| C76 | Onboarding's write fails | Nothing is written (one transaction), so the screen stays, shows the plain `error` line in a sunken strip under the field, and both buttons try again. |
| C77 | How a screen fits its buttons and large text | `ScreenBody`: the approved padding (6 top, 12 sides, 10 bottom UI pixels, 6 between parts), the buttons at the foot at least 16 UI pixels below the content, and the whole screen, buttons included, scrolling once it doesn't fit. It keeps clear of the status bar, the gesture bar outside the shell, and the keyboard. Back on Onboarding 2 (and Android back) returns to screen 1 with the choices kept. |
| C78 | When the hello plays | On a cold start that lands on Home, and when the app comes back from the background (Flutter's *shown*, not a mere pause such as the notification shade) while Home is the screen showing: its tab chosen and nothing over it. Not after Onboarding, not on returning from Stats or Settings or Focus, not on a tab change. |
| C79 | Home's pet while a cycle is live, or a run is owed | Home follows the look like any screen: the egg cracks (and stops wobbling) through a running block, the pet is Pleased in a block and Drowsy on a break, and Home looks again at each minute of a block and at a break's end. The owed run only waits there: an unplayed hatch keeps the egg (so no chip, name or bar), an unplayed evolution keeps the old stage. Only Focus plays them. |
| C80 | Home's EXP and level before the beats are seen | The chip, name, bar and "480 / 600 EXP" show the stored EXP. The bar lights one block per whole 30 EXP. |
| C81 | Home to a screen reader | The pet is one item (`srPet`, or `srEgg`); the name, bar and EXP line under it are hidden behind that item, so they aren't read twice. The level chip reads "Level 13. Stats" (`srLevelChip`), the gear "Settings", the clock notice's close "Dismiss". The egg line is read as written. The chip's target is 48 pt, larger than the chip. |
| C82 | Where Calm pet is read | Once at start-up, then kept in `calmPetProvider`, whose `set` changes the pet at once and writes the setting (for *Stats and Settings*). |
| C83 | The task picker before its ticket | A stand-in sheet (`TaskPickerPlaceholder`) opened by `openTaskPicker`; *Focus: the task picker and Ready* replaces it. *Start focusing* opens Focus instead whenever the cycle projects to anything but `idle` (C3). |
| C84 | Lengths the ladder gives only roughly | As Tomo Pixel Screens plays them: block done 1.3 s, level-up 2.2 s, task done 2.45 s, evolution 4 s (reduced 2.7 s), hatch 3.7 s to the naming (reduced 4.3 s). The dither holds from one Moment to the next and goes 100 ms before the choices. The choices step up 4 UI pixels over 280 ms (reduced: a 150 ms cross-fade). |
| C85 | The evolution's last ring of closing-in sparkles ran 80 ms into the flicker on the prototype | Cut at 0.6 s, so the flicker plays alone (ADR-0019). |
| C86 | The pet once the choices are in | The screen's own look again (Resting on Focus), while the last beat's confetti finishes falling. A skip lands where everything is still. |
| C87 | Confetti colours and the face | Never the face's marks: `E` (eyes) and `F` (Geode's near-black mouth, Lily's nose), which read as specks of dirt. Chosen by the user ([#71](https://github.com/heichan2000/Tomo/issues/71)), as on Tomo Pixel Screens. |
| C88 | The bar in a block or bonus that reaches a new level | It fills to the end; the level-up empties and refills it. A first block of an hour or more fills it too, then the takeover clears it (C25). |
| C89 | Where the effects sit among the chrome | Drawn in front of the pet, over the header but under the bar, the pet line and the buttons below it; the dither covers the chrome only (`DitherOver`). The plate hangs centred 10 UI pixels below the bar and its caption; "+EXP" starts 3 pixels right of the picture and 2 down from its top, kept 8 UI pixels from the screen's edge. As on Tomo Pixel Screens. |
| C90 | The phone's haptics | `SystemHaptics` (`lib/platform/haptics.dart`): Flutter's own `HapticFeedback`, light impact for the reward tap, vibrate for the timer buzz. Built here for the reward tap; *Notifications and haptics on the phone* uses it for the buzz. |
| C91 | Who speaks a run's one line | Not the player: Focus composes it from `RunFacts` and announces it as it starts the run. |
| C92 | The three words the effects show | `beatGain` ("+250 EXP"), `beatLevelPlate` ("Level 13"), `beatTaskPlate` ("Task done"), from Tomo Pixel Screens (C37). |
| C93 | What the sync reads, and when | `NotificationSync` (core) reads the stored cycle, its task and the pet, and never settles: whoever opens Tomo next does that. A cycle whose start is after now (the clock moved back) announces nothing, because the next open discards it. Both services take an `afterWrite` hook, run unawaited after every write that commits; the app passes the sync. Syncs run one at a time, so the last reflects the last write. A phone that refuses is recorded as `notificationSyncFailed`. |
| C94 | What counts as "in the foreground" | Flutter's *resumed* and *inactive* (Tomo still in view, under the notification shade or beside another app), and the moment before the first frame. *Hidden*, *paused* and *detached* are the background. Opening Tomo syncs once, which clears what was delivered. |
| C95 | Telling a dismissed permission dialog from a refusal on Android | Android's own rationale flag, true only after a real refusal, read through a `tomo/notifications` channel in `MainActivity` (which also gives the Android version). A refusal is remembered in the device-only file; a dismissal isn't, so the next start asks again. Android 12 and older never ask: notifications on is granted, off is denied. Accepted: notifications turned off in the phone's settings before Tomo ever asked look like a dismissal, so Ready keeps the framing line and Start shows no dialog. |
| C96 | The status-bar icon | The Tomo egg in one colour with the crack cut out, filling 24 dp, edges rounded to whole dots at each density (`ic_notification`, written by `tool/app_icon.dart`). Android paints it in its own colour; Tomo sets none. |
| C97 | The Android notification's other settings | Priority high (to match the channel on old Android), no category (so Do Not Disturb treats it as an ordinary notification, not an alarm), auto-cancel on tap, no colour, no actions. |
| C98 | The channels' names in the copy file | `channelFocusBlock`, `channelFocusBlockAbout`, `channelBreak`, `channelBreakAbout`, with the spec's words. |
| C99 | A tap while Tomo is running, and Focus already open | The tap brings the cycle up to now first, then opens Focus only if its cycle is still the live one and Focus isn't already in the stack (`FocusRouteObserver`). A tap that starts Tomo needs nothing: the cold start already opens Focus on a live cycle. |
| C100 | Running the notification checks on a phone | Debug builds: kit gallery → *Notification check*. It shows the permission, whether alarms can be exact and what is pending, and starts blocks to leave running: 10 and 35 minutes through the service, and 1 minute written directly under the 10-minute floor (it credits the pet its minute). |
| C101 | Who fires the timer buzz | `TimerBuzz`, around the whole app, not Focus: a block can run out while the Work tab is showing. While Tomo is open it waits for each moment `timerEnds` gives (the block's end, then under auto-start the break's) and plays `hapticFor`; a block that runs out with Focus open gets nothing from it, because Focus's beat run fires the reward tap. Checked on a Galaxy S23 Ultra: it fires on time on the Work tab, but `vibrate()` is Android's long-press feedback and feels like a short bump ([#107](https://github.com/heichan2000/Tomo/issues/107) asks whether to make it a real buzz). |
| C102 | Stats writes `26 h 40 min` and `15 min`, but not a whole number of hours | `2 h`, with no `0 min`. Hours group their digits as the phone's language does (`1,234 h 5 min`). `focusTime` writes it for Stats and both delete sheets. |
| C103 | How the picker reads, given that watched queries can't run in whole-app widget tests (C72) | Once, as it opens: `TaskService.pickerTasks()` and `projects()`, the same lists `watchPickerTasks()` and `watchProjects()` give. It is a sheet over everything, so nothing else writes while it is open. |
| C104 | What "last-used project" means for *New task* (§6.3) | `lastProjectId`, set when a block starts (to its task's project) and when *New task* adds a task; absent or deleted → the most recently active project (`newTaskProject`). *New task* sits at the top of the picker with that project as a chip under it; the chip opens **Choose a project**, every project as a row with the chosen one checked. The picker's title is **Choose a task**. Both words chosen by the user ([#95](https://github.com/heichan2000/Tomo/issues/95)). |
| C105 | *New task* with no project left (every project deleted on Work) | It makes **My work** (`defaultProject`, as onboarding's skip does) and adds the task there. |
| C106 | How the denial line shows "once" (§11.4) | On the first Ready to open after the refusal (the refusal itself is followed at once by the block starting). Remembered in the device-only file as `notificationDenialShown`, so a restored phone, which asks again, can show it again. The bell shows on every Ready while notifications are off. |
| C107 | When the chosen length is remembered (§4.7) | When a block starts with it, not when it is chosen: a length picked and then left with *Close* is not kept. |
| C108 | Ready's header against the approved screen, which had only × at the top | The spec's header, title and project beside ×, though the task row repeats the title: every Focus state keeps the same header. Kept by the user ([#95](https://github.com/heichan2000/Tomo/issues/95)). |
| C109 | Parts Ready needed from the kit | `ScreenBody` takes a `middle` that sits halfway down the room between the top and the buttons (the approved screens' two "grow"s); `PixelStepper` (−/+ squares, the value between, turned off at a limit), for the Custom sheet and later Planned blocks; `PixelRow(selected:)` for lists to choose from. The words not in the script (*Task*, *Length*, *Custom*, *Leave*, *Notifications are off*, *Fewer*, *More*, *Doing*) are the approved screens'. |
| C110 | How "about N min" rounds (ADR-0010 says rough minutes) | To the nearest minute, a half minute already reading the lower number (4:30 left is *about 4*), so the words change at each half-minute mark. A minute or less reads *under a minute left*. The exact time is `mm:ss` with the seconds rounded up (`25:00` as a block starts, never `00:00` before it ends), three digits of minutes past 99. `quiet_clock.dart` in core. |
| C111 | Words for a break's last minute and the clock's screen-reader lines, which the script lacks | *under a minute of rest left*; the banner's *Break · under a minute*; spoken, *About 4 minutes of rest left.*, *Under a minute of rest left.* and *Under a minute left on {task}.* The clock's label stays in rough minutes while the exact time shows. Approved by the user ([#96](https://github.com/heichan2000/Tomo/issues/96)). |
| C112 | When the next block counts down (§4.8), and what it starts | Only when Focus sees the break run out (within 2 s, the app in front), auto-start on, the break not skipped and the task not done. The screen keeps the pet's break-over line above the countdown line, as the approved screen does. The block it starts has the cycle's own lengths and auto-start as it is set now, and sets `lastProjectId`. |
| C113 | Reads Focus and the banner needed | `TaskService.cycleTask()` / `watchCycleTask()`: the live cycle's task and its project (`CycleTask`), read at start-up and watched as `cycleTaskProvider`, so a rename on Work shows on the banner. `StatsReader.dayOf(now)`: the day's blocks and minutes for the break fact lines, by each block's stored `local_date`. Widget tests of the whole app feed both through `petChanged`. |
| C114 | Who settles a block that ends while Focus is minimised | The banner, as it sees the block end (`reconcile`), so under auto-start the break starts on time and the banner moves on with it. Focus also reconciles as it opens and as the clock moves its state. |
| C115 | Focus's running and break layout against the approved screen's three "grow"s | `ScreenBody`'s `middle` holds the pet, the line, the clock, the progress line and the chip as one group, halfway between the header and the one button. Kit parts added: `PixelChip(big:)` (body text, for *Focus* / *Break*), `ProgressLine` (2 UI pixels, grows in whole UI pixels), `PixelText.cut` (one line ending in "…", the running banner's task). |
| C116 | Which line a run shows (and speaks after its facts) when it has several beats | Its rarest beat's, by the reward ladder: hatch, then evolution, then task done, then level-up, then the block. So a block that levels up shows the level-up line, and a task bonus that reaches a level keeps the task-done line (`runMoment`). |
| C117 | When Focus says *while you were away* | When it opens on a block that ended unseen (its run still owed). The note sits under the header on every Focus state, the break included, until a choice is picked, and it opens the spoken run in place of "Block done: …". The time is the phone's own format. |
| C118 | What *Start another task* does with the cycle | Opens the picker; a pick ends the cycle (as *Leave*) and Focus goes to Ready on the picked task, so its length can be chosen. Closing the picker changes nothing. |
| C119 | The line after a run, and on coming back later | The run's line stays until a choice is picked. Opened later on a finished block whose run was seen, Focus shows the block-done line; Break over shows its break-over line. |
| C120 | When the estimate card is asked for | When a block's run ends (finished or skipped) on `focusComplete`: `takeEstimatePrompt` marks the task as prompted then. Under auto-start the settle starts the break, so there is no `focusComplete` and no card until a later block ends without it. The card is held in memory: minimised and back, it has gone. |
| C121 | *Mark task done* on a task whose bonus was already paid (done, reopened, done again) | *Task done* still plays, gaining 0 EXP: finishing the real task is the point. |
| C122 | Minimise while a run plays | The run counts as seen (spec §7.4, walked away from), so it doesn't play again. During the hatch, Android back does nothing until the naming, where it acts as *Done*. |
| C123 | Words for the choices and the card | `choiceBreak`, `choiceAnotherBlock`, `startAnotherBlock`, `markTaskDone`, `doneForNow`, `estimateTitle`, `estimateMarkDone`, and the countdown's `notYet`, from Tomo Pixel Screens. |
| C124 | How long a pet's name may be | 20 characters, counted as the reader sees them (an emoji or an accented letter is one); the field stops taking more. About what fits on one line in Home's name size. Approved by the user ([#98](https://github.com/heichan2000/Tomo/issues/98)). |
| C125 | A name cleared away, then *Done* | The pet keeps its species name: the name is never blank (C30). The name is trimmed before it is stored. Approved by the user ([#98](https://github.com/heichan2000/Tomo/issues/98)). |
| C126 | The pre-filled name and the keyboard | The keyboard does not open by itself, so it never covers the pet at the hatch; *Done* alone keeps the species name. The first tap on the field selects the whole name, so typing replaces it. Approved by the user ([#98](https://github.com/heichan2000/Tomo/issues/98)). |
| C127 | The name fails to write | The plain error line shows above *Done* and the naming stays; *Done* tries again. The old name (none) stays, logged as `petWriteFailed`. |
| C128 | Words for the naming | `hatchName` (*Name your Geode* since #114, the caption and the field's screen-reader label) and `hatchDone` (*Done*), from Tomo Pixel Screens. `PixelTextField` gained `label:` for this. |
| C129 | The accent in widget tests of the whole app | The harness feeds the hatched species through `petChanged`, as it feeds the pet (C113), so a test sees the grey turn to the species colour. |
| C130 | Dropping `pets.personality` (#115) | The version-1 schema changed in place and its snapshot was made again: nothing has shipped, so there is no one to migrate. `drift_dev make-migrations` refuses a changed v1, so the old `drift_schema_v1.json` was deleted first. |
| C131 | An egg's name inside a sentence (#114) | Lower case: "Your stone egg hatches…", "Your paper egg". `eggName` is the tile's *Stone egg*; `eggInLine` is the same name for use inside a line. |
| C132 | The egg's lines, now plain (#114) | `SetupMoment` and `EggMoment` are gone from `PetMoment`, since the pet no longer speaks before the hatch; the pick reads `eggHint`, Home reads `egg`. The run that hatches the egg is unchanged: its screen-reader announcement says "Your egg hatched." and then the pet's name and hatch line, at the reveal. |
| C133 | When the running task's row wears the accent *Focus* chip | Only while its block runs. In the break and after, the row shows *Doing*, as the task lock lifts then too. |
| C134 | How long a lock refusal's sunken line stays | Until the next touch anywhere on the screen, or a scroll (as Tomo Task Screens said). |
| C135 | *Delete task* or *Delete project* while the block runs | Refused at once, with the line under the row that was tapped in the menu; the delete sheet is never shown first. |
| C136 | A status picked in the row menu | Written at once; the sheet closes and the row holds, then slides, as after a ring tap. A refusal shows under the status control and the sheet stays. |
| C137 | *Rename project*, which the approved screens don't show | A sheet like *New project*: title *Rename project*, the field holding the name, and *Rename*. Both sheets' buttons are off until a name is typed; the field takes 60 characters (§5.3). |
| C138 | How the row moves after a ring tap | It holds 450 ms in its old place showing its new ring, then slides to its new place in 240 ms, easing out, in whole UI pixels; the rows it passes take their places at once. Under reduce motion it jumps. As Tomo Task Screens played it. |
| C139 | *Add a task*'s + and keyboard | The + shows only while the field is empty and not being typed in. Enter keeps the keyboard up for the next task. A failed add shows the error line under the field. Adding a task on Work doesn't change `lastProjectId` (C104). |
| C140 | Reads the Work screens needed, and widget tests | `TaskService.watchProjectSummaries()` / `projectSummaries()` and `tasksInProject()`. The screens watch them through `workListsProvider`, which whole-app widget tests replace; `petChanged` feeds the Work lists too (C72). |
| C141 | Screens inside the shell saw the keyboard, though the shell had already made room for it (found here: a project with a few tasks scrolled away under the keyboard) | The shell takes the keyboard and the bottom padding off one copy of the screen's facts, so the screens see neither (`TomoShell`). |
| C142 | A project just made, or deleted while its screen is open | Its screen goes back to Work once the project has been listed and then is gone; a project not listed yet is not taken for deleted. |
| C143 | Where a task opens before Task detail exists | `openTaskDetail` pushes a stand-in, `TaskDetailPlaceholder`, for *Task detail* to replace. *(Replaced by `TaskDetailScreen`, [#100](https://github.com/heichan2000/Tomo/issues/100).)* |
| C144 | Words for Task detail not in the script | *Add notes*, *Project*, *Status*, *Planned blocks*, *No plan*, *Focus so far*, *None yet*, `2 blocks · 50 min` and *Back to focus*, from Tomo Task Screens. The title and notes fields have no label on screen, so a screen reader calls them *Title* and *Notes* (`taskTitleField`, `notesField`). |
| C145 | When Task detail's typed fields save | When you leave the field: a tap elsewhere, the keyboard's Done, or leaving the screen while still typing. The title takes no new line; Enter finishes it. Everything else saves at once. |
| C146 | A title cleared away, then left | The old title comes back and nothing is written: a task always has a title (§5.3). |
| C147 | *Start focusing* when the cycle is live but no block runs (a break, or after a block) | The task lock has lifted (C133), so the button works as usual: Focus opens on Ready on this task, and starting there replaces the cycle, as *StartBlock* does (§4.3). *Back to focus* only while this task's block runs; turned off only while another task's does. |
| C148 | Where Task detail's refusals and failures show | Under the part used: the title, the notes, the project row, the status control, the stepper, *Delete task*. They go at the next touch or scroll (C134). A task deleted while its screen is open goes back to the project. |
| C149 | Parts Task detail needed | `PixelTextField` gained `step:` (the title is in title text), `minLines:` (notes are three lines tall when empty) and `keyboardType:`; `PixelStepper` gained `mutedValue:` for *No plan*. `WorkLists.task(id)` / `workTaskProvider` watch the one task, which whole-app widget tests feed like the lists (C140). |
| C150 | Words for Stats and Settings not in the script | Stats: *Level*, *Time focused*, *Blocks finished*, *Days focused*, from Tomo Stats Screen. No prototype has Settings, so its words follow §8.10: the group labels, *Rename pet*, *Calm pet*, *Auto-start*, *Open system settings*, *Match phone / Light / Dark*, *Version* `1.0.0 (1)`, *Licences*, *Share diagnostics*. Under the switches: *Your pet stays still, apart from celebrations.* and *When a block ends, the break starts by itself.*, chosen by the user. |
| C151 | Rename pet before the hatch | Not shown: an egg has no name to change. Once hatched, the row shows the name and opens the same name sheet as a project (`askName`), up to 20 characters (`maxPetNameLength`). |
| C152 | How the notification permission shows | One row, *Open system settings*, with the status under it: *Notifications are on*; *Notifications are off* (the bell's words); or *Not asked yet. Your phone will ask when you start your first block.* Tapping it opens the phone's notification settings for Tomo in every case. |
| C153 | How the licences show | In Tomo's own look, not Flutter's stock page: `LicencesScreen` lists each package once with how many licences it has, and opens their text. |
| C154 | What Share diagnostics hands over, and when it is off | `tomo-diagnostics.txt`, the log's export, to the phone's share sheet. Under the button, how many errors the log holds, counted as Settings opens; at none the button is off. |
| C155 | A Stats number too wide to sit beside its label | It drops under the label, at the right (Tomo Stats Screen). Numbers stop growing at 130% text and never wrap. |
| C156 | Parts Stats and Settings needed | `BackHeader` (back and an optional title, from Task detail's own); `askName` (the project name sheet, now for any name); `autoStartProvider`; `appVersionProvider` (`package_info_plus`). `placeholder_screens.dart` is gone. |
| C17 | Marking the device-only file and the diagnostic log as left out of the **iPhone** backup needs native code; no package Tomo has can set that flag | Not written. Both files are now created (`DeviceFile`, `FileDiagnosticLogStorage`), but the flag is iPhone native code that only a Mac can build and check, so it goes with the rest of the iPhone work, outside this build ([#92](https://github.com/heichan2000/Tomo/issues/92)). |

---

## 18. What the builder inherits

The map's *Not yet specified* section is empty. These are known, not unknown:

**First steps (in order):**
1. Move `lib/art/` to `packages/tomo_core/lib/art/` and update
   `tool/art/review_page.mjs`'s paths. *(Done.)*
2. Move the approved grids that still live in tickets into the code under the
   same model: the icon set ([#43](https://github.com/heichan2000/Tomo/issues/43)),
   the sparkle ([#39](https://github.com/heichan2000/Tomo/issues/39)) and the
   Tomo egg ([#44](https://github.com/heichan2000/Tomo/issues/44)). Their pixels
   don't change, so each can be marked approved pointing at its ticket comment,
   but the fingerprint is new — show them on a generated review page once.
   `minus`'s approval is [its own comment](https://github.com/heichan2000/Tomo/issues/43#issuecomment-6094789501).
   *(Done, with the art test: [#58](https://github.com/heichan2000/Tomo/issues/58).)*
3. Write the icon/splash generator script and its test.
   *(Done: [#59](https://github.com/heichan2000/Tomo/issues/59).)*
4. Write `docs/package-allowlist` (or equivalent) for the never-online test.
   *(Done: `docs/package-allowlist`, `test/never_online_test.dart`.)*

**Checks only a real phone can answer** (all in `docs/manual-checks.md`):
- Text and dither **start on whole dots** on a 2.625× Android phone (#35, #38).
  *(Done on a 2.8125× and a 3.75× phone, [#60](https://github.com/heichan2000/Tomo/issues/60): exact, with C45 and C46.)*
- Boxes, lines and corners of the kit **start and end on whole dots** on a real
  phone (#60 passed this to the kit). *(Done on the 2.625× emulator,
  [#69](https://github.com/heichan2000/Tomo/issues/69), C55; the real phone is
  in `docs/manual-checks.md`.)*
- Whether Android's `vibrate()` needs a manifest permission (#22 expects not).
  *(Done: it does not, [#60](https://github.com/heichan2000/Tomo/issues/60); C49.)*
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
  back" that measures absence, no Stats number a delete can lower, no pet
  fact that can fall. Stopping early costs that block and nothing before it,
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
