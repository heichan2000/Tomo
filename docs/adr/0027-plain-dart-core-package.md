# ADR-0027: The rules live in a plain-Dart core package with no Flutter in it

- **Status:** Accepted
- **Date:** 2026-10-07
- **Decided in:** [#24 Project structure, package manifest & platform baselines](https://github.com/heichan2000/Tomo/issues/24)
- **Amended by:** [ADR-0029](0029-mvp-ships-without-ai-and-never-goes-online.md) — the agent tool loop and provider client are parked, so the MVP's core has no `agent/` folder and no fake provider. Everything else in core stands.

Tomo is a Dart workspace with two packages. The Flutter app sits at the root.
`packages/tomo_core` holds everything that is not a screen: the focus cycle,
the reward rules, the pet look and beat queue, the task service, the Drift
database and its migrations, the agent tool loop and provider client, the
notification-schedule decision, stats, the diagnostic log, and the pixel art.
Its `pubspec.yaml` lists no Flutter and no Riverpod, so importing either there
fails to compile. Plugins (secure storage, notifications, sharing) reach core
only through small interfaces the app fills in. The app is screens, painting,
plugin wrappers and the Riverpod wiring that joins them. Both sides use the
same feature folder names.

A reader may expect a single `lib/` with a `core/` folder, which is the usual
Flutter shape. The split exists because the load-bearing logic must be
testable without Flutter, and the project's habit is to make the wrong thing
impossible to write rather than check for it afterwards (ADR-0004's diagnostic
entry *cannot express* a key; ADR-0009's face cannot be two things at once).
A missing dependency is that kind of guarantee for "core never imports
Flutter". It also gives agents a clear line about where code goes, and core's
tests run under plain `dart test`.

## Considered options

- **One package, with a test that reads import lines and fails on a Flutter
  import in `lib/core/`.** Not chosen. It is simpler, but the rule is checked
  after the fact and the test itself can be wrong or skipped.

## Consequences

- The art model and species files move from `lib/art/` to
  `packages/tomo_core/lib/art/`, and `tool/art/review_page.mjs` follows them.
  This is the first setup step.
- Shared test helpers (in-memory database, fake provider) live in
  `package:tomo_core/testing.dart` so the app's widget tests can use them.
- There are two `pubspec.yaml` files to keep tidy, with one lock file and one
  `pub get` thanks to the workspace.
