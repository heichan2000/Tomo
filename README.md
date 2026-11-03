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

> **Status:** in development and not released yet. There is no download and no
> store listing. To try Tomo, build it from source (see below).

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

## Getting started

### Requirements

- **Flutter 3.47.6**, pinned in [`.fvmrc`](.fvmrc). [FVM](https://fvm.app)
  picks up the pin, or you can install that version yourself. `tool/check`
  fails if any other version is on your `PATH`.
- Android: min SDK 26. iOS: 15.0 or later.

### Run it

```sh
flutter pub get
flutter run
```

The repo is a Dart workspace, so a single `pub get` at the root resolves the
app and both packages.

### Check your work

```sh
tool/check        # tool\check.cmd on Windows
```

This is the one "done" command. It passes only if all of these hold:

1. Flutter is the pinned version.
2. `pub get`, `build_runner` and `gen_l10n` don't change any file.
3. `dart analyze --fatal-infos` is clean, including Tomo's own lint plugin.
4. Every test passes in the app, `tomo_core` and `tomo_lints`.

Some promises can't be covered by an automated test, such as notifications
on a dozing phone, backup and restore, and screen readers. They are listed in
[`docs/manual-checks.md`](docs/manual-checks.md) and get run on a real iPhone
and a real Android phone before a store release.

## Project layout

```
lib/                  The Flutter app: screens, painting, plugin wrappers,
                      Riverpod wiring. One folder per feature (focus, pet,
                      work, stats, settings, onboarding, ...).
packages/tomo_core/   Plain Dart, no Flutter: the focus cycle, reward rules,
                      pet look and beats, tasks, the Drift database and
                      migrations, notification schedule, stats, pixel art.
packages/tomo_lints/  Tomo's own analyzer rules (e.g. no print outside Log).
test/                 App tests, including repo-shape and never-online guards.
tool/                 tool/check, and the app-icon generator.
docs/adr/             Architecture decision records.
docs/research/        Dated research notes.
```

All the rules live in `tomo_core`, which can't import Flutter: its
`pubspec.yaml` doesn't list it, so the import won't compile. That keeps the
core logic testable with plain `dart test`
([ADR-0027](docs/adr/0027-plain-dart-core-package.md)).

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
