# ADR-0004: No telemetry — diagnostics are allowlisted by construction and shared by the user

- **Status:** Accepted
- **Date:** 2026-08-19
- **Decided in:** [#7 Telemetry & error reporting: does MVP ship any?](https://github.com/heichan2000/Tomo/issues/7)
- **Amended by:** [ADR-0029](0029-mvp-ships-without-ai-and-never-goes-online.md) — the MVP has no AI and no key, and never connects to the internet, so the key-not-expressible guarantee is trivially true and the privacy claim is now *Tomo never connects to the internet* (`Tomo_Build_Spec.md` §13). The five-cause provider taxonomy is parked. The diagnostic log, the facade and the allowlist stand.

## Context

Two settled documents disagreed. The architecture doc required that "error
reporting must scrub" the API key, which presumes an error reporter exists. The
PRD's data-egress summary promised that "nothing is synced or logged by Tomo",
which forbids one. Something had to give.

The obvious resolution is to ship a crash SDK and scrub carefully. Every mobile
app does it; Sentry and Crashlytics are a dependency and twenty lines of setup,
and both offer data-scrubbing hooks aimed at exactly this problem.

That resolution costs more here than it does elsewhere. Tomo has no first-party
backend, holds a user-supplied provider key, and stakes its positioning on a
single promise: **nothing leaves the device unless the user asks it to.** A
crash SDK is a second network destination that fires *without* user initiation.
It does not merely add a line to the egress summary — it changes the shape of
the claim, from a rule with no exceptions to a rule with one, which is the
difference between a posture you state and a posture you explain.

The counter-pressure is real, and larger than it first appears. Store-provided
crash reporting is not a substitute for an SDK, because it barely covers Flutter
at all. App Store Connect and Play Console vitals see native crashes, OOMs and
ANRs. An uncaught **Dart** exception in a release build does not kill the
process: it routes through `FlutterError.onError` / `PlatformDispatcher.onError`,
prints to a device console nobody reads, and the app continues with a broken
subtree. Every bug Tomo can author — a reward that fails to credit, a focus
cycle wedged mid-transition, a Drift query throwing — produces **no** store
signal whatsoever. Store vitals cover the layer we did not write.

So "no telemetry" is not a mild trade. It is near-total blindness to our own
error class, and it is only defensible if something replaces it.

There is also a vocabulary problem underneath the technical one. The word "log"
was doing two incompatible jobs across the two documents: *retained or
transmitted by Tomo as a service* in the privacy claim, and *a transient line on
the device console* in the build convention. A promise built on a word with two
meanings is not a promise, and no amount of careful implementation fixes that.

## Decision

**No third-party crash reporting or analytics in MVP.** No Sentry, no
Crashlytics, no usage events.

**The replacement is a diagnostic log**: a bounded, on-device record of errors
that the user may share, by choice, from Settings → About.

**Its contents are allowlisted by construction, not scrubbed.** An entry holds
an exception type name, a stack trace, a Tomo-authored enumerated code, app and
OS metadata, and a timestamp. It never holds third-party message text, exception
`.toString()` output, or any interpolated value.

**A single `Log` facade is the only permitted emit path**, and it accepts that
same allowlisted event type. `print` and `debugPrint` are banned by analyzer
lint. Debug renders events to console; release persists error-level events to
the diagnostic log and prints nothing. One type, two sinks.

**The vocabulary is split explicitly.** *Diagnostic log* is the persisted,
bounded, redacted, shareable file. *Console logging* is transient debug output.
Bare "logged" is banned from privacy copy.

**The egress claim is rewritten** rather than defended: Tomo makes no unbidden
network calls, all egress is user-initiated, and the OS may separately send
crash data to Apple or Google under the user's own device setting — which Tomo
neither enables nor reads nor can disable on the user's behalf.

## Consequences

**The key is unreachable rather than filtered.** #6 gave the provider layer an
enumerated taxonomy of five failure causes; raw transport exceptions are not
permitted to escape that layer. A key can appear in a `DioException`'s URL or
headers. It cannot appear in a member of a five-value enum. There is no scrubber
to get wrong, which is the whole point — a denylist is a bet that you enumerated
every shape the secret can take, re-taken every time a dependency changes its
error formatting.

**The diagnostic log is safe to share sight-unseen.** This is what makes the
fallback usable by a real user, who will not read a stack trace before sending
it. It is also why there is no preview screen and no "Clear diagnostics" Settings
row: the file holds no user content, so verifying it and erasing it both protect
nothing. This mirrors #4 — make the safety property hold by construction, and
the downstream machinery disappears.

**Diagnostic value is genuinely lower.** Exception messages are often the most
informative part of an error, and we are discarding them. The compensation is
that a Tomo-authored enumerated code sits at every site we anticipated, so the
loss is concentrated on *unanticipated* errors, where type and stack still
localise the fault.

**Every emit site is shaped by the event type.** Developers cannot log an ad-hoc
string during debugging. This is the intended friction — the architecture doc
already required the never-log rule be "enforced during debugging as well",
because a developer working against a live provider on a real device is exactly
when a real key reaches a console. Retrofitting free-form messages later is a
wide change, which is what makes this decision expensive to reverse and worth an
ADR.

**The diagnostic log cannot live in Drift.** A database failure is precisely
what you most want recorded, and a Drift-backed log cannot record its own
storage layer failing. It is a plain rotating file in the app-support directory,
ring-rotated at ~200 entries under a byte ceiling, written fire-and-forget off
any UI path, swallowing its own exceptions — an error recorder that can crash
the app is worse than none.

**Release builds are not obfuscated and do not split debug info.** Both strip
Dart symbol names, and a shared stack trace is now the only diagnostic signal
that exists; a mislaid symbol file would turn a bug report into permanent noise.
Obfuscation protects nothing here, since the app embeds no secret. Revisit under
the performance and asset-size budget, not in isolation. *Revisited and
confirmed in [Release build size: ship unobfuscated?](https://github.com/heichan2000/Tomo/issues/53):
on an arm64 release skeleton (19.0 MB APK) both flags together save ~0.66 MB
installed and ~0.3 MB of download (~3%), and obfuscation also scrambles the
exception type name the diagnostic log keeps. There is no size budget, only a
release-checklist tripwire at 25 MB.*

**There is a new user-facing error surface, and it is deliberately voiceless.**
Release installs `ErrorWidget.builder` to render a plain "something went wrong
here" block naming Settings → About → Share diagnostics, because Flutter's
default blank subtree produces the bug report "it looks weird" and no route to
the evidence. The pet does not speak here: a crash is the moment the character
conceit should step aside, and the pet's own Rive rig may be what failed.

**Reversing the telemetry half is cheap; reversing the logging half is not.**
Adding an SDK later is a dependency and a settings toggle. Loosening the event
type reaches every call site in the codebase.

## Alternatives considered

**Opt-in crash reporting.** Ship an SDK, disabled until the user enables it.
Honest, and preserves the egress claim by making the exception user-authorised.
Rejected on arithmetic: opt-in rates on a privacy-positioned app round to zero,
so this pays the SDK cost, the scrubbing burden and the egress-summary rewrite
in exchange for almost no data — every cost, no benefit.

**Opt-out crash reporting.** On by default, disableable in Settings. This is the
option that actually yields data, and it was the strongest contender. Rejected
because it contradicts the data-egress summary as written and converts the
privacy posture from something Tomo states into something Tomo explains — a
permanent tax on every future privacy conversation, paid to diagnose a
single-developer MVP.

**Crash plus usage analytics.** Best product signal. Furthest from the stated
posture, and the PRD's no-tiers, no-unlocks commitment removes most of what
usage analytics would be *for*.

**Store everything and scrub on write.** Full exception text with a redaction
pass. This is what the architecture doc originally gestured at. Rejected: it is
a denylist, and a denylist cannot produce a guarantee.

**Allowlist plus curated exception messages.** Keep `.toString()` for types
judged content-free. More diagnostic value for modest risk. Rejected because the
curation list is permanent maintenance and a wrong judgement leaks silently,
with no signal that it happened.

**Accept blindness with no local diagnostics at all.** No file, no share row,
users report bugs in prose. Cheapest, and genuinely defensible at MVP scale.
Rejected because the errors it leaves undiagnosable are concentrated in the
reward engine and the focus cycle state machine — the two seams the architecture
doc already names as the load-bearing ones, where a silent fault costs user
trust in the economy itself.

**Documented convention plus the `avoid_print` lint.** Far less code than a
facade. Rejected: the guarantee degrades to discipline, and `debugPrint` passes
straight through `avoid_print` anyway.

**Scope the egress claim to Tomo and stay silent on OS-level reporting.**
Shorter, and arguably accurate since Apple's and Google's collection is the
user's own setting. Rejected because the one document whose job is to preempt
"but what about crash reports?" should not be the document that omits it.
