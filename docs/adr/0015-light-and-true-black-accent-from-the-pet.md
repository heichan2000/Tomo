# ADR-0015: Light and true-black themes, with the accent taken from the pet

- **Status:** Accepted
- **Date:** 2026-09-27
- **Decided in:** [#34 Light and dark colours](https://github.com/heichan2000/Tomo/issues/34)
- **Supersedes:** [ADR-0006](0006-light-only-visual-language.md)

## Context

ADR-0006 made Tomo light only. Its dark theme had passed every contrast check,
but it needed its own lightened accents, and those were new colours sitting
next to a pet whose colours are fixed. Against dark they looked like they were
fighting the pet, for every species.

Tomo is now pixel art ([#32](https://github.com/heichan2000/Tomo/issues/32)).
The user wants a true-black dark theme alongside the light one. Pets have seven
flat colours and no outline ([ADR-0014](0014-starter-sprites-one-grid-whole-screen-dots.md)),
so a pet's edge on each ground depends on its colours alone.

The prototype, *Tomo Light and Dark*, showed three ways to colour the app
around all three pets in both themes: lifted accents (the ADR-0006 failure
again), the pet's own colour, and no colour at all in dark.

## Decision

**Tomo has two themes, light and true black.** It follows the phone's
light/dark setting by default. Settings has one **Appearance** row: *Match
phone / Light / Dark*. Focus follows the theme and has no night look of its
own.

**The species accent is one of the pet's own seven colours, copied exactly.**
Each theme takes the pet colour that stands out best against its ground. It
can't clash with the pet because it comes from the pet.

| | Light (white label) | Dark (black label) |
|---|---|---|
| Geode | `#3a6470` body | `#6ee0c6` crystal |
| Joe | `#4a57b8` cap | `#6f7ed8` light blue |
| Lily | `#4a2a44` nose | `#c89ab3` body |
| Before hatch | `#4A443C` warm grey | `#EDE7DC` off-white |

**Chrome neutrals.** Light keeps ADR-0006's roles unchanged. Dark sits on true
black.

| Role | Light | Dark |
|---|---|---|
| ground | `#F5F1EA` | `#000000` |
| surface | `#FCFAF6` | `#161412` |
| sunken | `#EAE4DA` | `#24211D` |
| ink | `#24211D` | `#EDE7DC` |
| ink-muted | `#6A6359` | `#A39B8F` |
| boundary | `#8E867A` | `#756E64` |
| destructive | `#A3402C`, white label | `#FF4D40`, black label |

**One set of pet colours for both grounds**, the "lifted" set from *Tomo Pixel
Starters*. A pet looks the same in both themes.

**Still no status colours.** The only colours are the pet's, the destructive
red, and the neutral used before hatch.

**The contrast floor is checked per theme:** 4.5:1 for text, 3:1 for large text
and UI parts. Every value above passes in its theme. Pet art stays exempt.

## Consequences

- **Pet visibility is judged by eye, not by number.** The style guide's rule
  (body at least 0.30 luminance from the ground) is dropped. Joe's cream on
  light (0.07) and Geode's slate on black (0.11) both fail it, and both were
  approved by eye. Every Draw ticket shows its pet on both grounds for approval.
- **The hatch recolours the app in either theme,** from the neutral to the pet's
  colour. Before hatch, dark buttons are off-white with black labels.
- **Lily's light accent is her nose, a very dark plum.** It is the only one of
  her colours that carries white text and isn't close to Geode's teal.
- **Two values per role in code.** Flutter gives a light and a dark
  `ThemeData`, and the species accent is chosen from a pair per species.
- **Changing a pet's colours now changes the app's colours too.** The accent is
  copied from the sprite, so any colour change during the Draw tickets has to
  change both.
- **The destructive red differs between themes.** A lifted brick (`#E0785E`)
  read too close to Lily's pink body, so dark uses a truer red.
- **Settings gains a row** that the old screen list did not budget for.

## Alternatives considered

**Lifted accents in dark (ADR-0006 again).** New, brighter versions of the old
accents. Rejected because it is the same clash that ended the first dark theme.

**No accent in dark.** Dark chrome in off-white only, with the pet as the only
colour. Rejected in favour of the pet's own colour, which keeps each theme
feeling like that pet's app.

**Two sets of pet colours,** the originals on light and the lifted set on
black. Rejected: twice the colours to check, and the pet would change between
themes.

**Near black (`#0E0D0C`) instead of `#000`.** Avoids the faint trail some OLED
screens show when things move over pure black. Rejected because lists sit on
`#161412` cards, not on the black itself, and the pet only moves one pixel at a
time.

**Lily's shade (`#96739b`) or teal ears as her light accent.** The shade fails
4.5:1 with white text (4.0). The teal sits too close to Geode's mint.

**No red in dark.** A plain grey *Stop early*. Rejected in favour of a true red
that doesn't look like Lily.

**Follow the phone only, or an in-app switch only.** Rejected for both together:
following the phone is the expected default, and the row serves people who
want Tomo different from the rest of their phone.

**A separate night look for Focus.** Rejected because the theme already covers
it, and a screen that changes colour on its own mid-session would feel foreign.
