# ADR-0030: Each pet has its own character, in place of Quiet or Chatty

- **Status:** Accepted
- **Date:** 2026-10-18
- **Decided in:** [#115 Give each pet its own personality, in place of Quiet or Chatty](https://github.com/heichan2000/Tomo/issues/115)
- **Amends:** [ADR-0021](0021-plain-voice-bad-news-quiet-chatty-personality.md) (its "personality is Quiet or Chatty" half; bad news in plain voice stands) and [ADR-0012](0012-earned-hatch.md) (the pick no longer has a personality choice).

## Context

ADR-0021 gave every pet a species voice (its grammar rule) and let the user
pick a **personality** on top: *Quiet* (the script) or *Chatty* (the script
plus one real detail). The pick sat on *Choose your pet* and in Settings.

The user wanted each pet to **come with its own personality** instead. A
choice of "how much it talks" made the three pets feel like one pet with a
volume knob. It also kept a pet-speaking preview on the pick screen, which
gets in the way of choosing a pet by its egg (#114).

## Decision

**Each pet has one fixed character, written into its lines:**

- **Geode**: a calm, gentle rock.
- **Joe**: a fussy, neat paper bird. He counts, folds and files everything.
- **Lily**: an encouraging, bright kid.

**The species rules stay underneath.** The character is who the pet is; the
rule is how it talks. Geode: present tense, no future, no "you", numbers in
words. Joe: exact digits, no "you". Lily: the only one who says "you", and her
questions answer themselves.

**There is no personality choice anywhere.** No control on *Choose your pet*,
no row in Settings, no `personality` column. Each pet has **one line per
moment**. A few moments also have a **fact line**, said only when its fact is
true (the task already has 2 or more blocks, a block ended today, and so on).
Otherwise the pet says the usual line. Each pet's character decides how much
of the fact it says.

**Two rules hold for every pet line:**

1. **A fact is something that can't go down**: a count that grows, a first, or
   what just happened. Never a streak, a comparison or time away. (Carried over
   from ADR-0021's Chatty rule.)
2. **No line suggests putting work off**: no napping, no "later", no "skip
   it". (Geode was first drafted as a sleepy, grumpy old rock. The user turned
   that down because a pet that wants to nap invites procrastination.)

The approved lines are in
[#115's record](https://github.com/heichan2000/Tomo/issues/115#issuecomment-6258694999).
They replace every pet-voice line of #51's script. Plain-voice lines are
unchanged.

## Consequences

- The copy file holds one entry per moment, plus one fact entry for six of
  them (`blockDoneTaskTotal`, `levelUpTotalTime`, `evolutionTotalTime`,
  `taskDoneTaskTotal`, `onBreakToday`, `breakOverToday`). `PetMoment.factHolds`
  says when the fact entry is used.
- The hatch line always names the first block's task, since there is no
  longer a Quiet version without it.
- *Choose your pet* has no Personality control or hint. The pet still
  introduces itself under the tiles.
- The version-1 schema loses `pets.personality`. Nothing had shipped, so the
  v1 snapshot was rewritten rather than migrated.
- Settings → Pet is *Rename pet* and *Calm pet*.

## Alternatives rejected

**Fix each pet to Quiet or Chatty for good.** This reused the approved lines,
but it only changed how much a pet talks, not who it is.

**Drop the species rules and start each character from a blank page.** The
rules are what make the three pets sound different at a glance, even in a
notification, and they gave every new line a shape to fit.

**Keep a "talk less / talk more" switch on top of the characters.** It doubles
the writing again, and a fussy Joe who says less than he wants to isn't Joe.
