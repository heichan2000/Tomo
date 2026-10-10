# ADR-0021: Bad news is in plain voice; personality is Quiet or Chatty, added on top of one script

- **Status:** Accepted
- **Date:** 2026-10-05
- **Decided in:** [#30 Pet voice system: per-starter voices and the hatch personality choice](https://github.com/heichan2000/Tomo/issues/30)
- **Amended by:** [ADR-0029](0029-mvp-ships-without-ai-and-never-goes-online.md) — the AI lines (the five failure causes, running-low, the lapsed proposal, the chat explainer, the data note) and the system-prompt rules are parked. Quiet/Chatty and plain voice for bad news stand; the written lines are in [#51](https://github.com/heichan2000/Tomo/issues/51).

## Context

Two earlier decisions multiply. #9 gave each of the three starters its own
voice, with one rule no shading may erase (Geode: present tense, no future;
Joe: exact numbers; Lily: says *you*, asks questions). It also gave the user a
personality choice, which #18 moved to the first setup screen, next to the
species, before the user has met the pet.

Three species × N personalities × every line the pet says is 150 strings at
N = 2 and 225 at N = 3. All copy lives in one ARB file (#8) so that a voice pass
is reading one file. With no AI key, which graceful degradation makes a hard
requirement, every one of those strings is written by hand. With a key, the
model can drift away from them, and the pet reads as a different character the
day a key is added.

The ticket's first idea was to write the bad-news lines once, in a warm-neutral
voice shared by all three pets. That idea fails on the species rules
themselves. A shared line cannot say "try again later" (Geode has no future
tense) and cannot say "you" (only Lily does). It would either break a species
or say nothing.

## Decision

**Bad news is in Tomo's plain voice, never the pet's.** This covers the AI
failure causes, the running-low warning, notifications denied, the clock
notice, a lapsed proposal and the Stats empty state (which #21 found can
never show: Stats opens only after the hatch). It joins the error screen
(#7) and the data note (#28). The pet still shows how it feels through its
face, while the plain words carry the facts. The "chat isn't set up" explainer
stays in pet voice, because it is the pet describing itself, not reporting a
failure.

**Personality is how much the pet volunteers: Quiet or Chatty.** It never
changes the species rule and never runs toward harsh. It sets what the pet
offers unprompted, never how fully it answers when asked.

**Quiet is the script, and Chatty adds to it.** Every pet-voice line is written
once, in Quiet form. Chatty adds one detail to the Focus lines (block done,
level-up, evolution, task done, break, break over, while you were away) and to
the hatch line, and only when a real detail exists. Otherwise it says the
Quiet line. Timer notifications are Quiet-only. A Chatty detail must be
something that **can't go down**: a count that only grows, a first or a
record, or what just happened this cycle. It is never a streak, a comparison or
time away.

**The copy file holds one entry per moment, with the three pets side by
side.** Chatty entries are separate and named by the detail they add, so a
missing one falls back to Quiet by construction. Plain-voice entries have no
per-pet split.

**Personality is changeable in Settings**, like the name. Quiet is selected by
default. Only the species is permanent.

**The AI path is bound by the same rules**: the species rule, "volunteers, not
answers", the can't-go-down limit, and real lines from the copy file as
examples. The AI never delivers bad news.

## Consequences

- The writing pass is about 15 pet-voice moments × 3 species in Quiet form, plus
  a smaller set of Chatty extras, plus one set of plain-voice lines, plus six
  setup lines. That is far below 150.
- The pet goes quiet at exactly the moments things go wrong. That is deliberate,
  but a reader without this record would likely try to "fix" it.
- The setup description line is the chosen pet speaking, and it switches
  between Quiet and Chatty, so the choice is explained by example rather than by
  a label.
- Changing personality rewrites nothing that has already been said. Past chat
  messages stay as they were.
- Lily's Chatty example in the style guide ("three days running") broke the
  can't-go-down rule and was rewritten.

## Alternatives rejected

**A shared pet voice for bad news.** Rejected because the three species rules
cannot all hold in one line (see Context).

**Personality as a full second script.** Rejected because it doubles the
writing, and every pair of lines is a chance for the two versions to drift into
two characters.

**Other axes** (playful vs calm, bouncy vs sleepy, gentle vs strict). Gentle vs
strict is forbidden by the PRD. The others either collide with a species (Geode
is already calm) or only make sense to someone who has met the pet.

**Permanent personality.** Rejected because it punishes a guess made before
the user has heard the pet speak, and Quiet/Chatty is not who the pet is.

**Streaks and "days running" in Chatty lines.** Rejected because a streak is
the one number in Tomo that resets. A pet that mentions it will be noticed on
the day it does not.
