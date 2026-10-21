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
- [ ] The first block's notification is titled **Your stone egg** (or *paper*
      / *spotted*), and nothing in it names the pet.
- [ ] Tapping the alert with Focus minimised brings Focus forward.

Debug builds make these quick: kit gallery → *Notification check* (spec §17,
C100).

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
- [ ] The reward tap fires on each beat, the evolution plays one long buzz
      instead (C167), and the timer buzz fires when a block ends while you are
      on the Work tab.
- [ ] On Android the timer buzz feels like a real buzz, not a bump like the
      reward tap, and with the phone on silent it does not come
      ([#107](https://github.com/heichan2000/Tomo/issues/107), C157).
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

In a debug build, **long-press the Home tab** to open the **kit gallery**
(spec §17 C51): every part of the kit in every state, in either theme, any
accent and any text size. Its *Pixel check screen* button opens the **pixel check** (C48):
the type steps, every pet and egg at every spot, the dither and both haptics. A
screenshot from the phone (`adb exec-out screencap -p`) is at the phone's own
resolution, so its dots can be counted.

- [ ] On a **2.625× Android phone**, text and the dither behind sheets start on
      whole dots: no grey dither, no soft text edges
      ([Pixel fonts](https://github.com/heichan2000/Tomo/issues/35),
      [Pixel interface kit](https://github.com/heichan2000/Tomo/issues/38)).
- [ ] On the kit gallery, light and dark, 100% and 200% text, every box, line
      and corner starts and ends on whole dots: no faint seams, no grey edges.
      Every dot of a screenshot below the status bar is exactly one of the
      kit's colours ([Pixel kit](https://github.com/heichan2000/Tomo/issues/69),
      spec §17 C55).
- [ ] The pet's pixels are all the same size and sharp at every spot (Home,
      Focus, setup tiles, hatch).
- [ ] Android haptics work, and the only permission they need is `VIBRATE`,
      for the timer buzz; it is never asked of the user
      ([Sound & haptics spec](https://github.com/heichan2000/Tomo/issues/22),
      C157).

## App icon and splash ([App icon and splash screen](https://github.com/heichan2000/Tomo/issues/44))

- [ ] The home-screen icon is the Tomo egg on the warm grey, its pixels even
      and sharp.
- [ ] Android 13+: with themed icons on, the icon shows the one-colour egg,
      the eyes still readable through the cut-out crack.
- [ ] The splash is the egg in a grey circle, on cream in light and on black
      in dark, with no white flash before the first screen.

## Run log

| Date | Version | iPhone | Android | By |
|---|---|---|---|---|
| 2026-10-20 | 1.0.0+1 | not run (no Mac) | Galaxy S23 Ultra, Android 16, 2.8125×, plus the 2.625× emulator. Passed: notifications (High channels, on time after a restart, books on leave and clears on return, *Your stone egg*, tap opens Focus), 200% text, haptics (reward tap, evolution buzz, timer buzz, quiet on silent), reduced motion, never online, size (21.0 MB), pixels, icon and splash (themed icon on the emulator; One UI doesn't theme other apps' icons). **Backup and restore** passed on the emulator (Android 16, `bmgr` local transport: back up, uninstall, reinstall): pet, EXP, project, task, blocks and settings came back; the diagnostic log did not (0 errors); the first block asked for notifications again. **Not run:** doze (seen on time in [#72](https://github.com/heichan2000/Tomo/issues/72)), backup through Google or phone-to-phone, TalkBack (walked in [#121](https://github.com/heichan2000/Tomo/issues/121); the egg tiles and Length row changed since). [#122](https://github.com/heichan2000/Tomo/issues/122) | user and agent |
