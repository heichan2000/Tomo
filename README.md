# Tomo

**A focus timer with a pocket pet.**

Tomo is a mobile task manager built around a Pomodoro timer. You choose one
task and focus on it for a set block of time. When the block finishes, your
pet gets EXP. If you stop early, it gets nothing. Over time the pet levels up
and evolves, and it never shrinks or decays. The EXP is only there to show your
progress. What you are really rewarded with is the work you get done.

Built with Flutter for iOS and Android. It is offline-first and has no
backend. **Tomo never connects to the internet**
([ADR-0029](docs/adr/0029-mvp-ships-without-ai-and-never-goes-online.md)).

> **Status:** a work in progress, not released and not available to install.

## What it does

- **Projects and tasks.** Each task has a title, optional notes, a Pomodoro
  estimate, the number of Pomodoros you have actually spent on it, and a status
  (to-do, doing, done).
- **One task at a time.** Focus covers the screen and shows only the task you
  picked.
- **Focus blocks.** Choose 25/5, 50/10, or a custom length (focus 10–120 min,
  break 1–30 min). The timer keeps going when you leave the app, and a
  notification tells you when the block or break is over.
- **All-or-nothing stake.** A finished block pays out EXP in proportion to its
  length. Stopping early asks you to confirm first and pays nothing. Breaks pay
  nothing either, and you can skip them without any penalty.
- **A pet that grows with you.** You pick one of three eggs during setup. It
  hatches at the end of your first finished block and evolves through four
  stages. Its EXP has no cap. It never gets sad when you're away.
- **Light stats.** Level, time focused, blocks finished and days focused.
  There are no streaks to break
  ([ADR-0026](docs/adr/0026-no-streak-days-focused.md)).
- **No currency, no cosmetics, no telemetry, no account.** Your data stays on
  the phone, and the phone's own backup can bring the pet across to a new
  device ([ADR-0028](docs/adr/0028-pet-travels-in-the-phone-backup.md)).

## Documentation

| Document | What it's for |
| --- | --- |
| [`Tomo_PRD_MVP.md`](Tomo_PRD_MVP.md) | The product: problem, user stories, scope. |
| [`Tomo_Build_Spec.md`](Tomo_Build_Spec.md) | Every resolved decision. **Wins wherever it differs from the PRD.** |
| [`Tomo_Tech_Stack_Architecture.md`](Tomo_Tech_Stack_Architecture.md) | Stack and architecture. |
| [`CONTEXT.md`](CONTEXT.md) | The glossary that the code, the issues and the spec all share (*focus block*, *anchor*, *settle*, ...). |
| [`docs/adr/`](docs/adr/) | Decisions that came with a real trade-off, and the reasons behind them. |
| [`docs/pet-art-style-guide.md`](docs/pet-art-style-guide.md) | How the pixel pets are drawn. |

## Contributing

Work is tracked in [GitHub issues](https://github.com/heichan2000/Tomo/issues),
triaged with the labels `needs-triage`, `needs-info`, `ready-for-agent`,
`ready-for-human` and `wontfix`. Outside pull requests are not used as a way
to request features, so please open an issue instead. See
[`docs/agents/`](docs/agents/) for the conventions.

Any new package has to be added to
[`docs/package-allowlist`](docs/package-allowlist) as well, or the
never-online test fails.

## License

[MIT](LICENSE) © 2026 Jin Chan. The bundled Ark Pixel font is under the SIL
Open Font License ([`assets/fonts/ArkPixel-OFL.txt`](assets/fonts/ArkPixel-OFL.txt)).
