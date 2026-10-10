# Tomo — manual checks

The promises no test can keep. Run **all of them, on a real iPhone and a real
Android phone, before every store release**, not on every change. Each line
names the promise it keeps; the full promises list is in `Tomo_Build_Spec.md`
§16 and [Test inventory and coverage bar](https://github.com/heichan2000/Tomo/issues/52).

Tick each box on both phones, and note the phone and date at the bottom.

## Notifications (promise 35)

- [ ] Both Android channels show as **High** in system settings: *Focus block
      finished* and *Break finished*.
- [ ] On iPhone with a Focus mode on, a block-complete notification comes
      through as **Time Sensitive**.
- [ ] With the phone face down and dozing (Android: leave it 30+ minutes
      unplugged), the block-complete alert arrives **on time**.
- [ ] Restart the phone mid-block: the alert still arrives after the restart.
- [ ] Nothing is posted while Tomo is open; leaving Tomo schedules, coming back
      clears.
- [ ] The first block's notification is titled **Your egg**.

## Backup and restore (promise 36)

- [ ] iPhone: back up, restore onto a second phone (or erase and restore). The
      pet, its EXP, tasks and Stats come back.
- [ ] Android: same, through Google backup or phone-to-phone transfer.
- [ ] After the restore, the **first block asks for notification permission
      again**.
- [ ] The diagnostic log did **not** come across (About shows 0 entries).

## Screen reader (promise 37)

- [ ] VoiceOver and TalkBack can reach and use everything on all 9 routes:
      Onboarding, Home, Task picker, Focus, Work, Project, Task detail, Stats,
      Settings — and the hatch takeover.
- [ ] The pet reads as one item, e.g. "Geode, level 7. 480 of 600 EXP toward
      level 8. Stage 1 of 4.", and says nothing on its own between beats.
- [ ] The clock is never announced by itself; touching it reads rough minutes.
- [ ] A finished block's run is spoken once, facts first, then the pet's line.

## Look and feel (promise 38)

- [ ] At the phone's largest text setting (200% on Android), every screen
      scrolls rather than cuts text off, and it looks right.
- [ ] The reward tap fires on each beat, and the timer buzz fires when a block
      ends while you are on the Work tab.
- [ ] With reduce motion on, every celebration still shows its payload: EXP,
      the level plate, the new stage, still sparkles.
- [ ] The beats feel like rewards.

## Never online (promise 30)

- [ ] The **release APK's final permission list** (after manifest merging) has
      no `android.permission.INTERNET`:
      `aapt2 dump permissions build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.

## Build size ([Release build size](https://github.com/heichan2000/Tomo/issues/53))

- [ ] The **Android arm64 release APK is under 25 MB**
      (`flutter build apk --release --target-platform android-arm64 --split-per-abi`).
      If bigger, find out why before shipping (an un-subset font, a stray
      package, art bundled twice).

## Pixels on a real screen (first release, then when the kit changes)

- [ ] On a **2.625× Android phone**, text and the dither behind sheets start on
      whole dots: no grey dither, no soft text edges
      ([Pixel fonts](https://github.com/heichan2000/Tomo/issues/35),
      [Pixel interface kit](https://github.com/heichan2000/Tomo/issues/38)).
- [ ] The pet's pixels are all the same size and sharp at every spot (Home,
      Focus, setup tiles, hatch).
- [ ] Android haptics work without a manifest permission
      ([Sound & haptics spec](https://github.com/heichan2000/Tomo/issues/22)).

## Run log

| Date | Version | iPhone | Android | By |
|---|---|---|---|---|
| | | | | |
