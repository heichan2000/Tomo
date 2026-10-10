# ADR-0028: The pet travels in the phone's own backup

- **Status:** Accepted
- **Date:** 2026-10-07
- **Decided in:** [#49 Data portability: does MVP ship export and import?](https://github.com/heichan2000/Tomo/issues/49)
- **Amended by:** [ADR-0029](0029-mvp-ships-without-ai-and-never-goes-online.md) — there is no key and no secure storage in the MVP, so the key exclusion and the Android secure-storage exclusion are moot, and the missing-key chat state is parked. The backed-up set (database and settings store) and the excluded set (device-only file, diagnostic log) stand. About's line now reads as in [#51](https://github.com/heichan2000/Tomo/issues/51).

Tomo's database and settings store are included in the phone's own backup on
both platforms: iCloud and computer backups on iOS, Google backup and
phone-to-phone transfer on Android. The API key, the diagnostic log and one
small device-only file are excluded. Tomo ships no export or import of its own.

A future reader will find this surprising, because the architecture doc and #24
both record "Android backup disabled" as a settled security requirement. That
requirement was set when Tomo had nothing worth restoring. Its job was to make
sure the key never left the device, and turning everything off was the simplest
way to do that. Once the schema existed, the cost became visible: **a new phone
was a lost pet.** Three months of use is 100 hours of focus and one character
the user has raised from an egg. Phone upgrades are much more common than lost
phones, so the cost would land on ordinary loyal users, not unlucky ones.

The security reason still holds, and is now met by exclusion instead of a blanket
off switch:

- **iOS:** the key is already written `unlocked_this_device`, which is never
  backed up. The device-only file and the log are marked excluded from backup.
- **Android:** `dataExtractionRules` includes only the database and the settings
  store for both cloud backup and device transfer. The secure-storage file must
  be **named and excluded**. A restored copy is encrypted with a Keystore key
  that stays on the old phone, so it could not be decrypted on the new one.

"No unbidden network calls" still holds. The backup is the phone's, and the user
turned it on. It sits beside #7's clause on OS-level crash reporting.

Two consequences follow:

- `notificationPermissionAsked` moves out of the settings store into the
  device-only file. If it came back as "already asked", the new phone would never
  ask for notification permission, and block alarms would silently never fire.
- A provider chosen with no key present is a distinct chat state: a plain-voice
  line saying the key stays on the old phone, and setup opened with the provider
  and model already filled in. Tomo never needs to detect that a restore
  happened.

## Considered options

- **Keep everything out of backup (the status quo).** Rejected: the pet is lost
  at every phone change.
- **An export/import file in Settings.** Not chosen for MVP. It is the only way
  across iPhone↔Android, but it protects only users who exported before the
  phone was gone, and it needs a format, shape checks, replace-or-merge rules
  (integer IDs, ADR-0023, make merging a renumbering job) and an import screen.
  Nothing here prevents adding it later.
- **Backup, but chat in a separate un-backed-up database.** Rejected. A pet that
  remembers everything except your conversations contradicts ADR-0002's "one
  continuous conversation", and it costs a second database file.
