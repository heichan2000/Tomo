# Tomo — Context

Single-context repo (see `docs/agents/domain.md`). This file is the glossary:
the vocabulary the code, the issues, and the spec all use. Terms are added
lazily, as decisions actually resolve them.

Decisions with a genuine trade-off live in `docs/adr/`.

## Glossary

### Focus and sessions

**Focus block** — a single timed stretch of focus on exactly one task,
**10–120 minutes**: *25 min* (with a 5-minute break), *50 min* (with a
10-minute break), or *Custom* (focus 10–120 in steps of 5, break 1–30), the
last pair used being remembered. A block either *completes* (the anchored end
timestamp passes) or is *stopped early*. Not "session", which is ambiguous
between the block and the block-plus-break cycle. See `Tomo_Build_Spec.md` §4.7.

**Completed focus minute** — the unit the entire reward economy is denominated
in. Only minutes inside a completed focus block count. Minutes inside a
stopped-early block count for nothing, and break minutes count for nothing.

**Focus cycle** — one focus block plus the break that follows it, and the unit
the timer's state machine is named for. This is the concept "session" was
ambiguous *about*; now that it has a name, "session" stays retired. A cycle ends
when the user leaves (*Done for now*) or a new block starts and replaces it.
**Marking its task done does not end it**: the break can still be taken, and
only another block on that task is ruled out (decided at consolidation,
`Tomo_Build_Spec.md` §17 R22).

**Break** — the rest interval between focus blocks. Skippable, and grants no
reward. Skipping a break is never penalized.

**Anchor** — the pair of absolute instants (start and end) stored when a focus
block begins. The anchors are the *sole* ground truth for whether a block
completed: the countdown on screen and the timer notification are both
conveniences derived from them, and neither can grant or withhold reward. This
is why a completed block is never lost — reopening the app days later still
reads the same two instants. Being absolute instants, they are indifferent to
timezone and DST changes.

**Incoherent anchor** — an anchor whose start instant is in the future, which
can only happen if the device clock moved backward. How long the user focused is
then unknowable, and Tomo has no notion of partial credit, so the block is
discarded at zero with a plain explanation. A clock moving *forward* is simply
believed; see *Trust model*.

**Settle** — to record a completed focus block: its reward to the pet, its minute
and Pomodoro counts to the task, all at once and **at most once, ever**. The
guarantee runs both ways — a block interrupted mid-settle is settled on next
launch, and a block already settled can never be settled again.

**Trust model** — the standing rule that Tomo does not police the user. It does
not detect or penalize app-switching, and it does not fight clock changes. There
is no leaderboard, no paid tier and nothing to win, so gaming the timer only
cheats the user. The pet is the conscience, not a cop.

**Auto-start** — the off-by-default preference that chains the next block or
break hands-free. It changes **advance behavior only, never reward**: it may
carry the user forward through anything that grants nothing, but it never starts
a focus block the user was absent for. Whatever the user was away for, at most
one focus block is ever credited. While the Focus route is **on screen**, a
break that ends starts the next block after a visible 10-second countdown the
user can decline (*Not yet*); off screen it waits at `breakComplete`. See
[ADR-0011](docs/adr/0011-foreground-only-auto-start-countdown.md).

**Early stop** — ending a focus block before its end timestamp, behind a
confirmation. Grants exactly zero. This all-or-nothing stake is the mechanism
behind the pet's motivational pull, so "partial credit" is not a concept Tomo
has. A stopped block **leaves no trace**: only completed blocks are ever
recorded, so a started-versus-finished ratio is not a number Tomo can show. A
block whose end instant passes while the confirmation is still open has
*completed* — it is credited, because the anchors are the truth. Skipping a
break is not an early stop and needs no confirmation. Reached by a plain, muted
*Stop early* button at the bottom of Focus; the confirmation states the rule, not
the loss (no pet name, no minute count). It is the **only** way a running block
ends before its end instant: nothing else, including deleting the task or
marking it done, can end one (see *task lock*).

**Quiet clock** — the rule that a running block or break shows **rough minutes**
("about 19 min left"), never a ticking number, with the exact `mm:ss` revealed
for five seconds on tap. Applies on Focus, in the break and on the running-block
banner. See [ADR-0010](docs/adr/0010-quiet-clock.md).

**Block record** — the permanent record of one completed focus block, written
when it is *settled* and never changed after. It is what Stats is built from.
It **outlives its task**: deleting a task or project removes the task's words
but keeps its block records, unlinked, so nothing Stats shows can go down
because the user tidied their list. Stopped-early blocks have no record. See
[ADR-0022](docs/adr/0022-block-records-outlive-their-tasks.md) and issue #10.
_Avoid_: session record, history entry

**Pomodoro (actual Pomodoros)** — the count of completed focus blocks against a
task, incremented by one per completed block *regardless of its length*. It is a
**count, not a duration** — which is why nothing in the reward economy may scale
on it. Compare *cumulative focus minutes*.

**Cumulative focus minutes** — total completed focus minutes recorded against a
task. The quantity the completion bonus scales on. Distinct from *actual
Pomodoros*, and both are stored.

### Tasks

See issue #11 for the task service contract.

**Earned numbers** — the parts of a task that only focusing can change: its
*actual Pomodoros*, *cumulative focus minutes*, when it was last focused, and
whether its estimate prompt and *completion bonus* have happened. Nobody edits
them, not the user and not the pet: they move only when a block is *settled* or
the bonus is given. Everything else about a task (title, notes, estimate,
project, status) is the user's to change.
_Avoid_: stats (that is the screen), counters

**Task lock** — the rule that while a focus block is running, its task cannot
be deleted or marked done, and its project cannot be deleted. The user is asked
to stop the block first. Once the block has ended, both are allowed and the
block keeps its credit. The lock exists so that *early stop* has exactly one
door. See [ADR-0024](docs/adr/0024-a-running-block-locks-its-task.md).

**Planned blocks** — what the screens call a task's *estimate* (1–20, or *no
plan* when blank). The count beside it is *blocks*, so a row reads "2 of 4
blocks", and over the plan "5 blocks · planned 4": a fact with no colour,
warning or "over". The interface never says "Pomodoros"; that word stays in
the schema and the PRD. See issue #19.
_Avoid_: Pomodoros (in copy), target, goal, budget

**Doing** — the status a task takes when the user starts focusing on it. Tomo
sets it once, on a to-do task, as the block starts, and never moves a task
back. A *done* task cannot be focused on; it is reopened first, so *done*
always means the user said so. One tap on a done task's ring reopens it to
*doing* if it has any finished blocks, otherwise to *to-do*; no earlier status
is stored.

### Reward economy

See [ADR-0001](docs/adr/0001-flat-level-curve.md) and issue #2 for the full
derivation and the rejected alternatives, and
[ADR-0007](docs/adr/0007-no-currency-no-cosmetics.md) and issue #13 for why EXP
is the only reward number.

**EXP** — the pet's cumulative progress number, and the **only** reward number
Tomo has: there is no currency. Granted at **10 EXP per
completed focus minute**. Stored on the pet entity, never on the user account.
32-bit signed int; its maximum is a technical bound, not a designed cap.

**Level** — `floor(total_exp / 600) + 1`. Flat curve, 600 EXP (60 focus minutes)
per level, forever, so **level is hours focused**. **Derived, never stored.**

**Evolution stage** — one of **four** visual forms of the pet, at levels **1 /
10 / 40 / 100**. Stage 1 is what hatches from the egg at the end of the first
finished focus block (ADR-0012). **Derived from level, never stored.** The egg
is *not* a stage.

**Completion bonus** — a one-time grant when the user marks a task done: 10% of
the EXP that task's own focus generated, i.e. `bonus_exp = focus minutes`. Fires **at most once per
task, ever**; a reopened-and-recompleted task grants nothing further. Zero focus
grants zero.

### Pet

**Hatch** — the moment the egg opens and the pet emerges, at the end of the
user's **first completed focus block** — not during onboarding
([ADR-0012](docs/adr/0012-earned-hatch.md)). A full-screen takeover, the only
thing in Tomo that ever clears the screen; the species accent arrives with it
and the user names the pet there. It happens **once ever**, which makes it the
rarest celebratory beat in the product.

**Egg** — what the user holds between onboarding and the hatch. It is that
species' egg: the species is chosen at setup, so **pre-hatch** means *no name
and no pet yet*, never *no species*. The egg occupies the pet's slot on Home and
Focus, and splits progressively across a running block — derived from the
cycle's elapsed minutes, stored nowhere. The crack is part of the egg's
*drawing*: the egg is drawn whole, then once per **crack step** (Geode's egg has
three, Lily's four, Joe's five). The egg's pictures — whole, then each crack step —
share the block **equally**, so the last share shows the eyes peeking out
(#45). Stopping a block early discards the
crack with the block and the egg is whole again, but it is **never animated shut
on screen**.

**Grow-only** — the standing rule that the pet never decays, never becomes sad,
and is never harmed by absence. Any mechanic that would make time away cost the
user something is out of bounds by definition.

### Pet art

See [ADR-0014](docs/adr/0014-starter-sprites-one-grid-whole-screen-dots.md) and
issue #33 for the pixel pet rules and the rejected alternatives.

**Pet grid** — the one 48×48 grid every stage of a pet, and its egg, is drawn
on, all standing on the same bottom row at the same pixel size. Stage 1 is the
pet's starter sprite, unchanged, so the pet visibly grows into the grid as it
evolves.
_Avoid_: canvas, sprite size, frame (a frame is a moment in an animation)

**Pixel** — one square of the *pet grid*: the unit pet art is drawn in. Not a
physical dot on the phone's screen.
_Avoid_: "px", bare, in anything about pet art

**Screen dot** — one physical dot on the phone's screen. A pet *pixel* is always
drawn as a whole number of screen dots, which is what keeps every pixel sharp
and the same size.
_Avoid_: device pixel, physical pixel

**Tomo egg** — the egg on the app icon and the splash screen: a plain cream egg
with eyes looking out of its crack, belonging to **no species**. It stands for
Tomo before anyone has a pet. Not the *egg* the user holds, which is always one
species' egg; the species eggs are drawn as its relatives. See issue #44.
_Avoid_: "the egg", bare, when the icon is meant

**Drawing** — one piece of pixel art Claude draws and the user judges: a pet
stage, an egg, an eye sheet, a sparkle, an interface icon or the *Tomo egg*.
Each is a text grid plus its colour key, and each is either a *draft* or
*approved*. See [ADR-0020](docs/adr/0020-pixel-art-as-text-grids-in-code.md) and
issue #36.
_Avoid_: asset, sprite (both also cover the font and generated icon files)

**Approved** — a *drawing* the user has said yes to, for exactly the pixels and
colours they saw. Change one pixel or one colour and it is a *draft* again. A
release can only ship approved drawings.

**Draft** — a *drawing* not yet approved, or changed since it was. It can show
in the app while work is under way, but never in a release.
_Avoid_: work in progress, placeholder

### Pet animation

See [ADR-0009](docs/adr/0009-derived-pet-look-persisted-beat-queue.md) and issue
#16 for the full contract and the rejected alternatives, issue #29 for why the
pet is animated in Flutter rather than Rive, and
[ADR-0018](docs/adr/0018-pixel-pets-slide-whole-pixels-flicker-evolution.md) and
issue #37 for how a pixel pet moves.

**Pet look** — everything about the pet's appearance that can be worked out from
a snapshot: its *stage*, its *face*, its movement level (*full* or *reduced*,
from the phone's reduce-motion setting) and its species. A pure function,
`look(state, pending)`, recomputed freely and never stored. The pet's other
channel is the *beat queue*, and the split is the whole of ADR-0009: appearance
derives, celebration does not.

**Part** — one of the six layers every pet stage is drawn in: `body`, `head`,
`eyes`, `limbA`, `limbB`, `accent`. A pet moves by sliding its parts in whole
*pixels*, never by swapping whole drawings, so every movement is written once
for all twelve stages.
_Avoid_: bone, rig, frame

**Eye sheet** — one pet's small set of eye drawings, one per *face* plus the
blink, placed over the eyes at every stage. The only extra drawing a face needs.
No face on any pet is lopsided.

**Lean** — *(parked with the AI layer, ADR-0029)* how a pixel pet tilts its head for `Thinking` (left) and `Puzzled`
(right): the lower head slides one pixel, the top two, with the step always
above the eyes. Pixel art can't be rotated without smearing, so a lean is the
tilt.
_Avoid_: tilt, rotation

**Evolution flicker** — how the pet changes stage on screen at an evolution: old
and new swap five times, faster each time,
never more than three swaps in any one second, so the new one is showing at the
end and stays. Nothing else moves while it plays. Under reduce motion it is a
cross-fade. The hatch does not flicker: the egg shakes, then breaks open with the
pet already there.
_Avoid_: morph, transformation

**Face** — which of the five expressions the pet wears: `Celebrating`, `Still`,
`Drowsy`, `Pleased`, `Resting`. A **single value off one
ordered ladder**, never a set of flags, which is why contradictory faces are not
expressible and Tomo has no list of illegal combinations. A beat sets the face
while it plays: `Celebrating`, except the block-done beat, which is `Pleased`
(ADR-0019). *Calm pet* replaces the three everyday faces with `Still` and never
touches a beat's face — it governs ambient movement, not rewards, and it works
only through the face. Order: `Celebrating` (beat) > `Pleased` (block-done
beat) > `Still` > `Drowsy` > `Pleased` (block running) > `Resting`. `Thinking`
and `Puzzled`, triggered only by the AI, are parked with it (ADR-0029).

**Idle move** — one of the small extra moves the pet plays now and then while
its face is `Resting`: **Glance**, **Look up**, **Double blink**, **Twitch**
(each pet's own bit — Geode's crystal, Joe's cap, Lily's ears) and **Wiggle**.
One every 15–30 seconds at random, never the same twice in a row. Each one only
slides parts the pet already has, so none needs a new drawing. Never during a
block or a break, never under *Calm pet*, never announced. Not a *beat*: it lives
only in the pet on screen and is never saved. See issue #31.
_Avoid_: fidget, animation (too broad), beat

**Hello** — the hop (up 1, 2, 1 pixels, happy eyes) the resting pet plays each
time the app opens on Home. The same hello whatever the time away, so it never
measures absence; that is what keeps it inside *grow-only*. Tapping the resting
pet plays the same hop. Wordless, never announced. The waiting *egg*'s
counterpart is a one-pixel wobble.
_Avoid_: welcome back, greeting (both suggest it knows you were gone)

**Beat** — one momentary celebration: a credited block, a level-up, an evolution,
a completed task, a hatch. An *edge*, not a state, which is exactly why it cannot
be derived from a snapshot the way the *pet look* is.

**Beat run** — the ordered set of beats a single settle produces, played one at a
time and never overlapping. The block that crosses a level fires two; the one
that also crosses an evolution fires three. A run is spoken aloud as **one
composed line at its start**, not one line per beat: the plain facts first
(minutes, task, EXP, level, stage), then the pet's name and its shown line, so
the facts are never the part a listener skips. See issue #51.

**Seen** — the mark (`seenAt`) recording that the user has had their chance at a
*beat run*. Set when the run finishes, is skipped, or is walked away from; left
unset only by process death, which is what makes an unseen run replay on next
launch. The same never-lost-never-doubled trick as *settle*'s `creditedAt`,
applied to the celebration instead of the grant.

**Reward ladder** — the rule that sets how big each *beat* looks: the rarer it
is, the bigger, and each one keeps everything the commoner one has and adds
something. Block done has nothing around the pet; level-up adds *sparkles*;
task done adds confetti; evolution adds the flicker and a wave of large
sparkles; the hatch adds the egg shaking and its shell breaking apart, with
no flicker. Differences come from what
surrounds the pet, because the face, the haptic and the motion tier are shared.
See [ADR-0019](docs/adr/0019-reward-ladder-twinkle-in-pet-pixels.md) and issue #39.
_Avoid_: reward hierarchy, celebration tiers (a tier is a *motion tier*)

**Sparkle** — Tomo's one reward glint: a four-point star that opens and closes
in place in four frames, drawn in *pet pixels* in the species accent with a
lighter colour of the same pet at its centre. It never travels, so under reduce
motion it stays, held still and cross-faded.
_Avoid_: twinkle (the style's name, not the sprite), star, glitter

### Chat and the agent

*Parked with the AI layer: MVP ships no chat or agent
([ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md)). These
terms are kept for a future AI version.*

See [ADR-0002](docs/adr/0002-user-visible-chat-history.md) and issue #4 for the
full derivation and the rejected alternatives.

**Thread** — the user's single, continuous conversation with their pet. There is
one, it persists across launches, and there is no thread list and no "new chat".
Persisting it is what the PRD's "relationship with one pet" positioning requires;
a pet that greets you fresh every launch contradicts it. Capped at **500
messages**, oldest pruned.

**User-visible message** — the user's own text, the pet's prose, or a *notice*:
the only things the thread stores. Tool calls and tool results are **wire-only** — they live for
one turn's loop and are never persisted. This is why every window cut is
protocol-valid and why the pet never answers from a stale task list.

**Notice** — a line in the thread that Tomo says, not the pet: a *lapsed
proposal*, an *interrupted reply*, a *can't-answer notice* or the *running-low*
line. Stored as *which* line, not its words, so
the current copy always shows, and **never sent to the provider**: the model
must not see Tomo's words as something the pet said.
_Avoid_: system message (that is the system prompt on the wire)

**Interrupted reply** — the notice added when the app died while waiting for
the provider's answer, so the user's last message never dangles unanswered. The
counterpart of the *lapsed proposal*, which covers dying while a confirmation
card was showing. Plain voice. See issue #10.

**Can't-answer notice** — the notice added when a chat turn fails, naming which
of the five *failure groups* it was. Only the latest one offers *Try again*,
which resends the user's last message. The technical detail shows on tap.
Plain voice, with the pet's face carrying the feeling. See issue #14.
_Avoid_: error message (one of the five, *limit reached*, is a normal condition)

**Failure group** — one of the five reasons a chat turn can't be answered:
**limit reached** (the provider's free quota, a normal condition, not an error),
**no connection**, **key not working**, **setup not found** (wrong model or
URL), and **got stuck** (everything else: provider outages, tool calls that
make no sense, an answer Tomo can't read, the per-turn request limit). Each has
one plain-voice line. See issue #14.

**Running-low** — the notice shown once a day, under the pet's reply, when the
provider itself reports that fewer than a tenth of today's requests are left.
Tomo never counts requests on its own, so only a provider that reports it (Groq)
ever shows it. See issue #14.

**Wire window** — what is actually sent to the provider on a turn: the system
prompt plus the **last 20** messages from the user and the pet, **or fewer** if
those would run past a fixed size, oldest dropped first (*notices* are
never sent). Deliberately decoupled from
the disk cap, because the two answer to different pressures — disk to privacy
footprint, wire to free-tier limits. There is no summarization pass; free tiers
throttle on requests before tokens, so spending a request to save tokens is the
wrong trade.

**Lapsed proposal** — what a pending confirmation becomes when the app dies
before the user answers it. The card is not restored; a deterministic line in
*plain voice* is appended so the thread never dangles. Approved and rejected
confirmations need no equivalent: the mutation and the pet's reply both persist
on their own.

**Preset** — a ready-made provider choice on the setup screen: **Groq**, then
**OpenRouter**. Each one shows its provider's own age rule in one line. A preset
is Tomo recommending that provider. Any other endpoint, Gemini included, goes
through **Advanced**, which recommends nothing. See issue #28.
_Avoid_: "supported provider" (any OpenAI-compatible endpoint is supported; a
preset is a recommendation)

**Data note** — the short notice above the key field on the setup screen. It
says what is sent, where and when, plus one line for the chosen preset or
Advanced. It informs and does not block: connecting is the user's OK. It is
written in Tomo's plain voice, never the pet's. See issue #28.
_Avoid_: consent screen, disclaimer, data-use gate

### Voice

**Pet voice** — words the pet says, written to its species' voice rule (Geode:
present tense, no future; Joe: exact numbers; Lily: says *you*, asks
questions). Reward and Focus lines, timer notifications, the hatch line, the
egg line and the setup descriptions are in pet voice. (Chat replies and the
"chat isn't set up" explainer are parked with the AI layer.) See issues #30 and
#51.

**Plain voice** — words Tomo itself says: the same for every pet, in no
species' voice. **Bad news is always in plain voice** — notifications denied,
the clock notice, the task lock's refusals, the stop-early confirmation, the
delete sheets — as are the error screen and any line that explains a setting
(the notification framing, the auto-start note, Settings → About). The parked AI
lines (failure causes, running-low, lapsed proposal, data note) are plain voice
too. The pet's voice keeps good
news only, including the in-app note after a block finished while away
(issue #51).
The pet may still show how it feels through its *face*; the plain words carry
the facts. See issue #30.
_Avoid_: "neutral pet voice", "shared voice" (there is no pet voice shared by
all three species)

**Personality** — how much the pet *volunteers*: **Quiet** or **Chatty**,
picked at setup next to the species. It sets what the pet offers unprompted,
never how fully it answers when asked. It never changes the species' voice rule and never
runs toward harsh. **Quiet** is the script: every pet-voice line is written in
its quiet form. **Chatty** adds one extra detail to certain lines, and only when
there is a real one to add; otherwise a chatty pet says the quiet line. The
detail must be something that **can't go down**: a count that only grows, a
first or a record, or what just happened this cycle. Never a streak, a
comparison, or time away. Timer
notifications are quiet-only. Changeable in Settings at any time, like the
pet's name; only the species is permanent. See issue #30.
_Avoid_: mood, temperament, tone (mood and tone suggest something that shifts
with what the user does; personality does not)

### Screens and navigation

See [ADR-0003](docs/adr/0003-minimizable-focus-takeover.md) and issue #5 for the
full route inventory and the rejected alternatives.

**Shell** — the two-tab frame the app lives in: **Home** and **Work**. It never
changes shape. Each tab keeps its own navigation stack. (The Chat tab is parked
with the AI layer, ADR-0029.)

**Home** — the pet's screen and the app's landing tab. Holds the pet, its name,
level and EXP progress, and the primary **Start focusing** action. The level
chip opens stats and the gear opens settings.

**Focus route** — the single full-screen takeover that renders **all five**
focus cycle states. There is no break screen: one state machine, one route.
Reached four ways — Home's *Start focusing*, task detail's *Start focusing*, the
*running-block banner*, and a cold start whose projection is not `idle`.

**Minimise** — leaving the focus route without ending anything. Anchors,
notification and projection are untouched, so credit is unaffected. Distinct
from *early stop* in every way that matters, and the two must never be confused
in copy or in code: minimise costs nothing, early stop costs everything. Android
hardware back from `focusRunning` **is** minimise.

**Running-block banner** — the persistent strip above the tab bar showing task
and remaining time (rough minutes, per the *quiet clock*) while a cycle is
minimised. The app's only cross-tab element, and the fourth door into the focus
route. When the block or break ends while minimised it turns into a filled
accent strip ("Block done · 25 min counted", "Break over"); the beat waits for
the tap and never pulls the user back by itself.

**Task picker** — the modal sheet that fills the cycle's `taskId` before the
focus route is useful. It opens from Home's *Start focusing*, from the task row
on Focus's Ready state, and from *Start another task* on Focus. A flat **cross-project** list —
`doing` first, then `to-do`, most-recently-focused within each; `done` excluded.
Its *New task* row is the fast create path.

**Default project** — the single ordinary project seeded at onboarding, so a
task never lacks a parent and the first focus block is two taps from Home. When
the user types an answer to *What are you working on?*, it names this project
and becomes its first task.
Renameable and deletable like any other; it is not special-cased anywhere.
*Project → Task* is literally true, and `project_id` is non-null.

### Notifications

See [ADR-0008](docs/adr/0008-derived-notification-schedule-no-inline-actions.md)
and issue #15 for the platform configuration and the rejected alternatives.

**Timer notification** — the pet telling a user who has left the app that a
timer *they started* has reached its end. There are exactly three: *block
complete*, *block complete with the break begun* (auto-start), and *break
complete*. Tomo sends no other notification of any kind, so the pet reaches the
lock screen only when the user set it in motion. Written to stay true when read
hours late: it states what happened — the task, the minutes that counted — and
never commands, never says "now", and never shows EXP or level, which belong to
the reward beat.

**Derived schedule** — the rule that which timer notifications are pending is a
function of the focus cycle and whether Tomo is on screen, recomputed whenever
either changes, never scheduled and cancelled by hand. Nothing is pending while
Tomo is open, because the app itself is then the surface. This is the same move
the projection made for state, and why a stale notification cannot fire.

### Haptics

See [ADR-0013](docs/adr/0013-no-audio-haptics-only.md) and issue #22 for the
platform mapping, the deliberate silences and the rejected alternatives.

**Reward tap** — the single light haptic that accompanies a *beat* as it plays.
It is the same tap for all five beat kinds: the hatch feels like the level-up
feels like an ordinary credited block, because the screen is what tells them
apart. One tap per beat, so a *beat run* taps once per beat at the queue's own
spacing, and a skipped run stops tapping.

**Timer buzz** — the stronger haptic fired when a block or break reaches its end
while Tomo is open and no beat is going to play: the user is on another tab, or
a break has ended and breaks have no beat. Its job is to reach someone who is
not looking, which is why it is a buzz rather than a tap.

**Derived haptic** — the rule that a single event never produces two haptics.
Which one fires is a function of whether a beat will play and whether Tomo is on
screen: a beat takes the reward tap, anything else on screen takes the timer
buzz, and a backgrounded Tomo takes neither because the timer notification
already vibrates. The same move the *derived schedule* made for notifications.

**Never the only channel** — the standing rule that nothing may depend on a
haptic to be noticed. Android's system touch-feedback setting gates every
haptic Tomo can fire and Tomo cannot read it, so a haptic may be silently
absent on a device that looks fine; everything that buzzes is also visible.

### Visual language

See [ADR-0015](docs/adr/0015-light-and-true-black-accent-from-the-pet.md) and
issue #34 for both themes' token sets, the ratios and the rejected alternatives.
It supersedes [ADR-0006](docs/adr/0006-light-only-visual-language.md) (light
only, issue #12).

**Calm chrome, warm pet** — the rule every visual decision is checked against.
The pet is the only saturated thing on screen; the chrome is quiet, and its
warmth comes from the warm ground and one-pixel corners, not from added colour. In
pixels this is *quiet steps* (ADR-0017): shapes stand apart by shade, never by
outline or shadow. The same rule applies to motion: chrome never overshoots,
only the pet and reward objects spring.

**UI pixel** — the unit the chrome is drawn in: one font pixel of body text
(about 1.5–1.7 pt). Lines, corners, gaps, icon strokes and every movement are
whole UI pixels. It stays fixed when the phone's text size changes; only text
grows. Distinct from a *pet pixel* (ADR-0014), which is larger and sized by the
pet's spot. See [ADR-0017](docs/adr/0017-quiet-steps-pixel-chrome.md).

**Quiet steps** — Tomo's pixel chrome: no outlines except on text fields, no
shadows or ledges, and every corner cut by exactly one pixel. Pressing a button
changes its shade at once.

**Dither** — what sits behind a sheet or dialog: every other dot covered with the
ground colour, in both themes. It replaces #12's tinted scrim, which did nothing
on true black.
_Avoid_: scrim, overlay tint

**Type step** — a text role's size, counted in whole dots per font pixel from
body: caption body − 1, title body + 1, pet name 2 × body. Numbers and the pet's
name stop growing at 130% of the phone's text setting.

**Theme** — one of Tomo's two colour sets: **light** (ground `#F5F1EA`) and
**dark** (true black `#000`). Tomo follows the phone's setting unless the user
picks otherwise in Settings' **Appearance** row (*Match phone / Light / Dark*).
Every route, Focus included, follows the theme.
_Avoid_: night mode, night tone (Focus has no look of its own)

**Ground** — the screen background of the current theme: `#F5F1EA` in light,
`#000` in dark. A pet's colours are the same on both grounds; whether it shows
up well is judged by eye, not by a luminance number.

**Species accent** — the one chromatic colour the chrome uses: **one of the
hatched pet's own seven colours, copied exactly**, never a new colour beside it.
Each theme takes the one that stands out on its ground. Light: Geode's body,
Joe's cap, Lily's nose. Dark: Geode's crystal, Joe's light blue, Lily's body.
Lily never uses her teal ears, which sit too close to Geode's mint. Before hatch
the accent is neutral (warm grey in light, off-white in dark), so no species
colours the choice.

**Motion tier** — one of four classes every animation belongs to: **Feedback**
(120 ms), **Transition** (280 ms), **Beat** (600–900 ms, spring allowed; the
block beat runs about 1.3 s), and **Moment** (about 1.5–4 s as the *reward
ladder* sets it; the *dither* goes behind and the chrome holds still). Each tier fixes its own
*reduced form*. Everything moves in whole *UI pixels* and nothing fades, except
the cross-fades reduce motion asks for (ADR-0017).

**Pixel type** — all of Tomo's text, set in one font: **Ark Pixel 12px
Proportional**, regular only. Headings stand out by size, never by a bold.
Its digits share one width, so changing numbers hold still without help.
See [ADR-0016](docs/adr/0016-one-pixel-font-sharp-sizes.md) and issue #35.

**Sharp size** — a text size at which every font pixel covers a whole number of
screen dots (`fontSize = 12 × n / devicePixelRatio`). Tomo only ever draws text
at sharp sizes: the phone's text-size setting is snapped to the nearest one at
100% and rounded **up** above it, so text is never smaller than asked for. The
type counterpart of the pet's whole-dot rule (ADR-0014).
_Avoid_: pixel-perfect (it says nothing about which sizes)

### Diagnostics

See [ADR-0004](docs/adr/0004-no-telemetry-allowlisted-diagnostics.md) and issue
#7 for the full derivation and the rejected alternatives.

**Diagnostic log** — the bounded, on-device record of errors the user may share.
A plain rotating file, ring-rotated at ~200 entries under a byte ceiling, held
**outside Drift** so that a database failure is still recordable. Written
fire-and-forget, never on a UI path, swallowing its own exceptions. It has no
*clear* affordance, because it holds nothing to clear.

**Console logging** — transient output rendered to the device console in debug
builds only. Never persisted, never shipped. The other half of the word "log",
kept separate from the *diagnostic log* on purpose: a privacy promise built on a
word with two meanings is not a promise.

**Diagnostic entry** — one record in the diagnostic log, and the only thing the
`Log` facade can emit. Exception type name, stack trace, a Tomo-authored
enumerated code, app and OS metadata, timestamp. **Allowlisted by construction**
— third-party message text, `.toString()` output and interpolated values are not
merely stripped, they are *not expressible*. This is why the log is safe to
share sight-unseen, and why nothing scrubs anything.

**Unbidden network call** — one Tomo makes on its own initiative rather than in
answer to a user action. Tomo makes none, and that — not "nothing is logged" —
was the privacy claim. In the MVP it is stronger: **Tomo never connects to the
internet at all** (ADR-0029). The one way data leaves is *Share diagnostics*, to
a destination the user picks through the phone's share sheet; the phone's own
backup and OS crash reports are the phone's, not Tomo's. (A future AI version
adds a chat turn to the user's own provider as a second user-initiated exit.)

**Share diagnostics** — the Settings → About row that hands the OS share sheet
the diagnostic log as a `.txt` attachment. Shows the entry count, disabled at
zero. A share sheet is an OS surface, not a route, so the 9-route inventory
stands.

### Accessibility and language

See [ADR-0005](docs/adr/0005-graded-reduce-motion.md) and issue #8 for the full
derivation and the rejected alternatives.

**Enumerated behaviors** — the form Tomo's accessibility commitment takes: a
specific, testable list written into the spec, rather than conformance to an
external standard. Tomo borrows WCAG's numeric contrast ratios (4.5:1 body,
3:1 large text and UI components) and **claims conformance to nothing**. The
list binds exactly what it says, which is why an unstated deferral is not an
acceptable answer anywhere in it and an argued one always is.

**Reduced form** — what an animation becomes when the OS reduce-motion flag is
on. Every animation in Tomo has one, and an animation whose reduced form is
unstated is unfinished. The rule that generates them: **the payload survives,
the choreography does not** — travel, scale and parallax are suppressed
(confetti and the flying shell are dropped, the EXP bar jumps, hatch and
evolution cross-fade, *sparkles* are held still, and the pet moves no more than
one pixel) while the reward itself, down to the announcement, is unchanged.

**Calm pet** — the off-by-default Settings toggle that reduces the pet to a
static pose. Deliberately **not** the reduce-motion flag: that flag is a
vestibular control and governs *choreography*, while Calm pet answers a
distraction need the flag is a poor proxy for and governs *ambient movement*.
Neither seeds nor overrides the other. It exists in MVP because nothing else in
Tomo ever stills the pet, so without it no rig would ever have a still pose.
Under it there are no *idle moves*, no *hello*, no reaction to a tap, and the
waiting egg does not wobble.

**Silent between beats** — the pet's rule under a screen reader. It is one
semantic node with a composed label (name, level, progress, stage), and it
announces only on events the **user caused** — a block completing, a level-up,
an evolution. Ambient idle and expression changes are never announced, because
an interruption the user did not cause is noise.

**Local day** — the calendar date a completed focus block is filed under for
stats, stored with its UTC offset at settle time. Distinct from the
*anchor*, which is an absolute instant and answers a different question: the
anchor says whether the block completed, the local day says where the user was
standing when it did. Storing it is what makes history immutable — travel and
DST can never retroactively move a day.

**Days focused** — the number of *local days* that hold at least one block
record. One finished block of any length is enough; a block counts for the day
it ends. It only grows: a day without focus costs nothing, and there is no
streak to break. It replaces the PRD's "current streak". See
[ADR-0026](docs/adr/0026-no-streak-days-focused.md) and issue #21.
_Avoid_: streak, days in a row, active days

## Terms Tomo deliberately avoids

- **"XP"** — spell it **EXP**, matching the PRD.
- **"Session"** — stays retired now that both halves of its ambiguity have
  names: say *focus block* for the timed stretch, *focus cycle* for the
  block-plus-break unit. This includes "session state machine", which is the
  **focus cycle state machine**.
- **"Streak", "days in a row"** — as things Tomo has. It has none (issue #21).
  A count that resets after a missed day is a loss, which grow-only rules out;
  say **days focused**, which only grows.
- **"Gems", "points", "score"** — the pet's number is *EXP*, and nothing else.
- **"Tick cell"** — retired by ADR-0016. The pixel font's digits are all one
  width, so a changing number is plain text.
- **"Coins", "currency", "cosmetics", "accessories", "shop"** — as things Tomo
  has. It has none (ADR-0007). They are not deferred or planned for later,
  so they are not spoken of as upcoming either.
- **"Penalty", "punish", "miss"** — grow-only means there is nothing to lose, so
  the vocabulary of loss does not apply to the pet.
- **"Conversation history", "message log"** — the user has one *thread*, and it
  stores *user-visible messages*. Naming it a log invites storing the tool
  traffic that ADR-0002 keeps off disk.
- **"Break view", "break screen"** — the break is a *state* of the focus route,
  not a screen. Naming it a screen invites splitting one state machine across
  two routes.
- **"Status colours", "success green", "warning yellow"** — Tomo has none
  (ADR-0015). State is shape, word and list position; the only colours are the
  *species accent*, the destructive red and the pre-hatch neutral.
- **"Toast", "snackbar"** — Tomo has none. Feedback lands where the action
  happened, with a screen-reader announcement for anything the user caused.
- **"Logged", bare, in privacy copy** — it meant two different things in two
  different documents (*retained by Tomo as a service*, and *printed to a
  console*), which is how "nothing is synced or logged by Tomo" survived as long
  as it did. Say *diagnostic log* or *console logging*, and state the claim as
  **no unbidden network calls**.
- **"Telemetry", "crash reporting", "analytics"** — as things Tomo has. It has
  none. The *diagnostic log* is not a quiet version of them: it never leaves the
  device unless the user sends it somewhere themselves.
- **"Scrub", "redact", "sanitise"** — there is no filter in the pipeline to name.
  A diagnostic entry cannot express a credential or user content in the first
  place; say **allowlisted by construction**. Reaching for the vocabulary of
  scrubbing is the first step back toward a denylist.
- **"Exit the focus view", "quit the session"** — say *minimise* or *early
  stop*, and mean exactly one of them. Vague exit language is how the
  costs-nothing action and the costs-everything action get confused.
- **"Accessible", "WCAG compliant", "meets AA"** — as claims Tomo makes. It
  makes none. Tomo ships *enumerated behaviors* and borrows WCAG's contrast
  numbers; a conformance claim it cannot back is worse than no claim, and this
  is the same failure mode as the retired "nothing is synced or logged".
- **"Reduce motion"**, when what is meant is *Calm pet* — and vice versa. Two
  knobs, two needs, two names. Collapsing them in copy or in code re-couples
  exactly what ADR-0005 separated, and there is then no way to serve one
  population without the other.
- **"Reminder", "alarm"** — for a timer notification. Tomo reminds the user of
  nothing they did not start, and a focus block is not an alarm; the word
  invites both unbidden nudges and `setAlarmClock`, which ADR-0008 rules out.
- **"Rig", "rigging", "state machine"** — for the pet. #29 dropped Rive, so there
  is no rig and no rig file: a stage is six pixel *parts* painted from text
  grids in the code (ADR-0020), and the pet's behaviour is a *pet look* plus a
  *beat queue*. The word invites back the
  one-file-or-four question ADR-0009 records as dissolved.
- **"Trigger"** — for a *beat*. A trigger is something fired at an animation;
  a beat is a row in a queue that is rebuilt from disk, and the difference is the
  entire reason a celebration survives the app being killed.
- **"Day"**, bare, in anything stats-shaped — say **local day**, and
  mean the stored date, not whatever the device thinks today is. The bare word
  is how a read-time timezone rule creeps back in and history starts moving.
- **"Sound", "chime", "audio cue", "SFX"** — as things Tomo has. It plays no
  audio at all (ADR-0013). The only sound Tomo causes is the OS tone on a
  *timer notification*, which belongs to the OS and is not Tomo's to design.
  Naming an in-app sound invites back an audio session, assets and a settings
  row, all of which that ADR exists to keep out.
- **"Age gate", "age check"** — as things Tomo has. Tomo never asks a user's
  age and has no minimum age of its own. The provider checks age when the user
  gets a key, and each *preset* shows that provider's rule (issue #28).
- **"Vibration", "buzz", bare** — when what is meant is a *reward tap* or a
  *timer buzz*. Two haptics, two jobs, two names, and only one of them is
  allowed to fire per event.
