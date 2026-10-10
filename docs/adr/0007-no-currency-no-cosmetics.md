# ADR-0007: Tomo has no currency and no cosmetics

- **Status:** Accepted
- **Date:** 2026-09-16
- **Decided in:** [#13 Cosmetics catalogue & pricing](https://github.com/heichan2000/Tomo/issues/13)

## Context

The PRD gave the pet two reward numbers: **EXP**, which drives level and
evolution, and **coins**, whose only use was buying cosmetic accessories. #2
priced coins at one per completed focus minute and handed #13 the job of
designing the catalogue they buy.

#13 found that a cosmetic worn on the pet has to fit **3 species × 4 stages =
12 bodies**. Drawing each item again for every one of them would make the
catalogue cost several times the art of the pets themselves. So the ticket
narrowed cosmetics to two cheaper kinds: items **placed** beside or under the
pet (drawn once), and items **worn at the neck** (drawn once per species,
fitted to each stage by a position table). A prototype canvas put both on the
real art and exposed problems with worn items: **Geode has no neck**,
**Lily's stage 4 grows a ruff exactly where a neck item sits**, so the item
hides the evolution, and **Joe's stage-1 body has no legs**, so a cushion
under it floats. Placed items fitted better, but judged by eye neither kind
was worth shipping.

## Decision

**Tomo ships no cosmetics, and therefore no coins.** EXP is the pet's one
progress number. There is no currency, no shop, and no accessory. The idea is
**dropped, not deferred**: it is not parked in the PRD's Future Versions list.

The completion bonus survives unchanged in its EXP half (`bonus_exp = focus
minutes`, once per task ever) and loses its coin half.

## Consequences

- **The north star is taken literally.** "EXP and coins only visualize
  progress": without something to buy, a coin visualizes nothing EXP does not
  already show, since both are linear in completed focus minutes. Keeping it
  would print the same number twice.
- **The Shop route is gone** (#5's 12 routes become 11), and Home's coin
  balance, which opened the Shop, goes with it.
- **The `gold` colour role is gone** from #12's palette, and the fixed-width
  digit cells no longer need to cover a coin count-up.
- **The reward beat loses its coin fly-in.** ADR-0005's reduced form ("the
  balance changes instantly") no longer applies. EXP fill, level-up and
  evolution carry the beat alone.
- **Storage loses** the coin balance on the pet and the cosmetic-ownership
  table (#10).
- **Personalization rests on the starter choice and its name.** The PRD's
  "personalize it" story (29) is withdrawn rather than met some other way.
- ADRs 0001, 0005 and 0006 mention coins or gold as they stood when written.
  They are not edited. This ADR supersedes those mentions.

## Alternatives considered

**Placed items plus neck-worn items** (#13's first recommendation), costing
one drawing per placed item and three per worn item. Rejected after the
prototype because of the fit problems above and a look not worth the art.

**Coins kept as a display-only counter.** Rejected: it is EXP ÷ 10 under
another name, which is exactly the number with nothing to buy that #13 warned
against.

**Coins with a different use.** Food suggests hunger, which is decay and is
ruled out by grow-only. Unlocking features breaks the no-gating rule. Anything
decorative is cosmetics again.

**Deferring cosmetics to Future Versions.** Cheap, because completed blocks
store their minutes and a balance could be granted for past focus later.
Rejected in favour of dropping the idea outright.
