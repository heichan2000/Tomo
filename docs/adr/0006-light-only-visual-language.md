# ADR-0006: Tomo ships one light theme, and the pet sets the palette

- **Status:** Superseded by [ADR-0015](0015-light-and-true-black-accent-from-the-pet.md)
- **Date:** 2026-09-16
- **Decided in:** [#12 Visual design system](https://github.com/heichan2000/Tomo/issues/12)

## Context

#12 resolves the tension the ticket named: Tomo has to be calm enough to work
inside and warm enough that the pet belongs there. The answer adopted is
**calm chrome, warm pet** — the pet is the only saturated thing on screen, and
the chrome takes a single accent **derived from the hatched species**, muted.

The design first committed to **both** light and dark, following the OS, on the
grounds that a focus app is used at night and that #9's style guide had already
constrained pet art against both grounds. #8 likewise wrote its contrast floor
"per theme".

The prototype (a component sheet and Home rendered for all three species × both
themes) overturned that. Every value in dark mode passed contrast — the failure
was not measurable by a ratio. A dark theme needs its own lightened accents,
lightened gold, lightened brick and a lifted ink, and each of those is a second
colour sitting next to a pet whose six flat colours are fixed. Against a dark
ground they read as competing hues rather than as the pet's world, for every
species. Changing the dark ground does not help, because the conflict is
between the chrome's colours and the pet's, not between either and the ground.

## Decision

**Tomo ships exactly one theme: light.** The app forces it regardless of the OS
appearance setting. There is no dark theme and no appearance row in Settings.

The palette is six fixed roles — ground `#F5F1EA`, surface `#FCFAF6`, sunken
`#EAE4DA`, ink `#24211D`, ink-muted `#6A6359`, boundary `#8E867A` — plus coin
gold `#A8720F`, destructive brick `#A3402C`, and one **species accent**: Geode
`#2E7563`, Joe `#3D4C8A`, Lily `#88507A`, neutral `#4A443C` before hatch. Full
derivation and every ratio: the #12 resolution comment.

## Consequences

**Night use gets a bright screen.** This is the real cost and it is accepted
knowingly. It moves pressure onto the one screen used longest at night: whether
the Focus route carries its own quieter tone is now a live question for #17,
with no app-wide dark theme to fall back on.

**#8's "per theme" contrast floor becomes a single-theme floor.** Nothing in it
is weakened; there is simply one theme to check.

**The style guide's theme-safety rule tests one ground.** Geode's dark-on-dark
failure disappears. **Joe's cream body becomes the only failure** — luminance
Δ 0.07 against the ground, against a floor of 0.30 — and no off-white ground can
fix it, since passing would require a ground too dark to be off-white. Judged
by eye on the prototype, Joe reads clearly anyway, so it is **accepted as
passing and kept unchanged**, recorded as an exception in the style guide.

**Reversal is cheap in code and expensive in design.** Flutter theming makes a
second `ThemeData` trivial to add; what it cannot do is re-derive a dark accent
set that sits with the pets, which is precisely what failed here. A future dark
theme is a fresh design effort against the pet art, not a flag.

## Alternatives considered

**Light and dark, following the OS, no in-app switch.** The original #12
answer. Every ratio passed; rejected on sight of the prototype because the
dark-theme colours competed with every species' fixed palette.

**Light and dark with an in-app switch.** Same colour conflict, plus a Settings
row #5 had not budgeted.

**A different dark ground.** Rejected because the conflict is chrome colour
against pet colour; the ground is not the variable that fails.

**Dark only.** Considered by symmetry; it inherits the same conflict and loses
the ground the pets were drawn on.
