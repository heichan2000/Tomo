# What Google Play asks of a new personal account and an offline timer app

**Research date: 2026-10-25.** For [What Play asks of a new personal account and an offline timer app](https://github.com/heichan2000/Tomo/issues/128).

> **Snapshot warning.** Play's rules move every few months. Most Play Console
> Help pages show no "last updated" date, only "©2026 Google". Where a page
> does show a date, it is given below. Everything here was read on 2026-10-25.
> Check the rule again in Play Console itself before acting on it. The repo facts
> (merged manifest, native libraries) come from the arm64 release APK built on
> 2026-10-20 (`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`,
> 21.0 MB), the last build before this note.

## Summary

| Question | Answer in one line |
|---|---|
| Testing before production | Yes, it applies: **12 testers, opted in without a break for 14 days**, on a closed test. Then a three-part "Apply for production" form, with review in about 7 days. |
| `USE_EXACT_ALARM` | Play's policy names **"an alarm or timer app"** as an accepted use. You fill in a declaration in Play Console. If Play refuses, the fallback needs a manifest change: today's `SCHEDULE_EXACT_ALARM` stops at Android 12. |
| Other permissions | `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` and `VIBRATE` need no Play declaration. The merged release manifest has **no foreground service, no full-screen intent, no `AD_ID`, no `INTERNET`**. |
| Data safety | Every app fills in the form. Tomo can answer **"No" to "collects or shares any user data"**, based on Google's own exceptions. One case is a judgement call (a log the user mails to the developer). |
| Privacy policy | **Required for every app**, even one that touches no personal data. It goes in the Play Console field, and a link **or the text** goes inside the app. |
| Target API level | New apps must target **API 36 (Android 16) since 2026-08-31**, or 2026-11-01 with an extension. Flutter 3.47.6 defaults to **36**, and the release manifest says 36. |
| 16 KB page size | It applies. It has been required for new apps since **2025-11-01**. Every `.so` in the arm64 APK is aligned to 16 KB or 64 KB, and stored on a 16 KB boundary. **Passes.** The x86_64 libraries in a future AAB are unchecked. |
| Bundle and signing | **AAB only** (new apps since August 2021). **Play App Signing is required.** The upload key is RSA of 2048 bits or more, valid past 2033-10-22 (aim for 25+ years). A lost upload key can be reset. Today's release build is signed with the **debug key, which Play refuses**. |
| Content rating, audience | The IARC questionnaire is free and gives one rating per region. The target audience form has age groups. Choosing any group under 13 brings in the **Families policy**. Teacher Approved is optional. |
| Title and developer name | Title **≤ 30 characters**. No emoji, no repeated symbols, no ALL CAPS unless it is the brand. No ranking, price or Play-programme words. Must not imitate another app. |
| Listing files | Icon 512×512 32-bit PNG, ≤ 1024 KB. Feature graphic 1024×500 JPEG or 24-bit PNG. **2–8 screenshots** per device type, 320–3840 px. **Tablet screenshots are optional.** |
| Account verification | **US$25** once. Government ID if the payments profile isn't verified. A **real Android phone (Android 10+)** checked through the Play Console app. **Legal name, country and developer email are shown publicly.** Package names must be registered for **Android developer verification** (automatic for most Play apps). |

## Why this exists

The release map has nine open tickets and four foggy steps (see the end). Each
needs to know what Play actually demands of *this* account (personal, made in
2026) and *this* app (free, offline, a timer, with the phone's own backup and a
user-shared diagnostic log). This note collects the rules from Google's own
pages, checks the repo against them, and ends with what each finding feeds.

---

## 1. Testing before production

**It applies to Tomo's account.** "Developers with personal accounts created
after November 13, 2023" must run a closed test with "a minimum of 12 testers
who have been opted in continuously for at least 14 days" before they can
publish to production ([App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465)).
Organisation accounts are not covered by this rule.

**The number changed once.** It was 20 testers at launch. On **2024-12-11**
Google changed it to "12 instead of 20 testers for personal developer
accounts" ([Android Developers Blog, update note](https://android-developers.googleblog.com/2023/11/ensuring-high-quality-apps-on-google-play.html)).
The 14 days have not changed.

**What "opted in" means**, from the same page and the
[testing-tracks page](https://support.google.com/googleplay/android-developer/answer/9845334):

- A tester needs a Google account, must be on the test's email list or Google
  Group, and must **opt in through the test's opt-in link**: "Each tester needs
  to opt in using the link." For a Google Group, "users must join the group
  before opting into your test."
- The link only appears once the test is published. It "can take several hours
  to become available to testers".
- "Testers who opt in, test for fewer than 14 days, and then opt out do not
  count toward the requirement." If a tester leaves and comes back, "the 14 days
  must be consecutive". Google tells developers to "Inform your testers that
  they need to remain opted in".
- Google's pages **do not say** that a tester must install the app, or open it,
  to count. The rule is worded only in terms of being opted in. Third-party
  guides claim the clock "resets" if the count dips below 12. Google's text says
  only that each tester's 14 days must be continuous.
- An internal test is "optional, but recommended". It does not replace the
  closed test.
- Before production, a closed-test app can't be found by searching Play.
  Testers need the opt-in link or the store URL
  ([testing tracks](https://support.google.com/googleplay/android-developer/answer/9845334)).
  Testers can give private feedback through Play, but cannot leave public
  reviews.

**Applying for production.** On the Dashboard, choose **Apply for production**.
The form has three parts
([same page](https://support.google.com/googleplay/android-developer/answer/14151465)):

1. **About your closed test:** how easy it was to recruit testers, how engaged
   they were, a summary of their feedback and how it was gathered.
2. **About your app:** the target audience ("Be as specific as possible"), the
   value it offers, and an estimate of first-year installs.
3. **About your production readiness:** what changed because of the test, and
   how you decided the app was ready.

"Review usually takes seven days or less, but can occasionally take longer." If
Google wants more testing, "you may need to continue running your closed test".
The page doesn't give the exact wording of each question, or a waiting period
after a refusal.

**Feeds:** "The closed-test testers: who they are and how they join", and the fog
steps "running the closed test" and "applying for production". The form's
questions are known now, so **notes from the test (feedback and what changed)
should be kept as it runs**. Part 3 asks for them.

## 2. `USE_EXACT_ALARM`

**What the manifest declares** (`android/app/src/main/AndroidManifest.xml`, and
the same in the merged release manifest):

```xml
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission
    android:name="android.permission.SCHEDULE_EXACT_ALARM"
    android:maxSdkVersion="32"/>
```

So Android 13+ phones use `USE_EXACT_ALARM`, which is granted at install. Android
12 (API 31–32) uses `SCHEDULE_EXACT_ALARM`. On Android 8–11 neither permission
exists, and exact alarms need none.

**A timer app is an accepted use.** Play's policy says the app "must use the
`USE_EXACT_ALARM` functionality only when your app's core, user facing
functionality requires precisely-timed actions, such as: The app is an alarm or
timer app. The app is a calendar app that shows event notifications"
([Permissions and APIs that Access Sensitive Information, "Exact Alarm Permission"](https://support.google.com/googleplay/android-developer/answer/16558241)).
"Apps that request this restricted permission are subject to review, and those
that do not meet the acceptable use case criteria will be disallowed from
publishing on Google Play." A Pomodoro timer that ends a block on time fits the
wording "an alarm or timer app". Whether a reviewer agrees is Play's call, and
no page promises it.

**The declaration.** The policy's "Key considerations" say: "Complete Play
Console declaration to indicate app functionality", and "Don't use this
permission for non-critical features". Android's docs add: "Apps will not be
able to publish a version of their app with this permission in the manifest
unless they qualify" ([Android 14 behaviour change, updated 2026-03-03](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms)).
**I could not find a Google page that shows the exact-alarm declaration's own
questions**, or says whether it asks for a video. The general permissions
declaration form (for SMS and Call Log) asks for use-case checkboxes and a
**required video**, and warns that review "may require up to several weeks"
([Declare permissions for your app](https://support.google.com/googleplay/android-developer/answer/9214102)).
That page does not name exact alarms, so treat it only as a hint. Expect the
form to ask which core feature needs exact alarms (timer). Have a short screen
recording ready in case it asks: start a block, leave the app, and the
notification arrives on time.

**If Play refuses.** The spec's fallback (§11.3) is `SCHEDULE_EXACT_ALARM`. As
the manifest stands, **that fallback does not cover Android 13+**, because the
permission stops at `maxSdkVersion="32"`. The fallback therefore means:

1. Remove `USE_EXACT_ALARM`, and remove `maxSdkVersion` from
   `SCHEDULE_EXACT_ALARM`. The never-online and manifest tests that list the
   permissions change too.
2. Accept that on Android 13+ it is "not pre-granted to fresh installs", and
   that a restore onto Android 14 leaves it "denied on the new device"
   ([Schedule alarms, updated 2026-10-21](https://developer.android.com/develop/background-work/services/alarms)).
   The user grants it under **Alarms & reminders**, and "Both the user and the
   system can revoke" it.
3. Tomo already falls back to `inexactAllowWhileIdle` when exact alarms are not
   allowed (§11.3), so nothing breaks. "Block done" may simply arrive late. If a
   way to ask the user is wanted, Android's route is an in-app explanation plus
   the `ACTION_REQUEST_SCHEDULE_EXACT_ALARM` intent ([same page](https://developer.android.com/develop/background-work/services/alarms)).
   Today the spec has no such screen or line.

`SCHEDULE_EXACT_ALARM` itself has no Play declaration. The policy points to it
as the option when `USE_EXACT_ALARM` doesn't fit.

**Feeds:** the fog step "applying for production and the review (incl.
USE_EXACT_ALARM refusal fallback)". The fallback is now specifiable: the
manifest change above, plus a decision on whether Tomo asks for Alarms &
reminders at all. **New small ticket suggested** (see the end).

## 3. Other permission declarations

From the **merged release manifest**
(`build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml`,
2026-10-20), the full permission list is: `POST_NOTIFICATIONS`,
`USE_EXACT_ALARM`, `SCHEDULE_EXACT_ALARM` (max 32), `RECEIVE_BOOT_COMPLETED`,
`VIBRATE`, and androidx's own signature-level
`…DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. Plugins add only receivers and
providers: `share_plus`'s file provider, androidx startup, and the profile
installer. The profile installer's receiver is *guarded* by `DUMP`, which is not
the same as asking for it. There is **no `<service>`, no
`FOREGROUND_SERVICE*`, no `USE_FULL_SCREEN_INTENT`, no `AD_ID`, and no
`INTERNET`**.

- **No declaration for these three.** The Permissions policy page has sections
  for exact alarms, full-screen intents, location, SMS, contacts, health and
  others. It has **no section** for notifications, boot or vibration
  ([policy page](https://support.google.com/googleplay/android-developer/answer/16558241)).
  I found no Google page that says outright "these need no declaration". This
  conclusion comes from their absence.
- **Foreground service declaration:** needed only "When your apps target
  Android 14 and above … [and] use" foreground service types
  ([Understanding foreground service and full-screen intent requirements](https://support.google.com/googleplay/android-developer/answer/13392821)).
  Tomo has none, so it is not asked.
- **Full-screen intent declaration:** only "If you use the
  USE_FULL_SCREEN_INTENT permission" ([same page](https://support.google.com/googleplay/android-developer/answer/13392821)).
  Not used.

Check the shipped bundle's own merged manifest the same way. The
`aapt2 dump permissions` line in `docs/manual-checks.md` already does this.

**Feeds:** "A release bundle Play accepts" (re-check on the AAB).

## 4. Data safety form

**Every app fills it in.** "All developers that have an app published on Google
Play must complete the Data safety form", including those that collect nothing.
Only **internal** testing tracks are exempt, so **the closed test needs it**. "A
privacy policy … is required to complete the Data safety form"
([Provide information for Google Play's Data safety section](https://support.google.com/googleplay/android-developer/answer/10787469),
latest change log entry 2023-12-05).

**Google's definitions** ([same page](https://support.google.com/googleplay/android-developer/answer/10787469)):

- **Collect:** "transmitting data from your app off a user's device". Not
  collection: "User data accessed by your app that is only processed locally
  on the user's device and not sent off device".
- **Share:** "transferring user data collected from your app to a third party".
  It *includes* "On-device transfer to another app", which must be disclosed
  "even if your app does not transmit the data off the user's device". It
  *excludes* a transfer "based on a specific user-initiated action, where the
  user reasonably expects the data to be shared".
- **The user's own cloud storage (FAQ):** "If the user chooses to upload their
  data directly to their own external drive or cloud storage account (such as
  Google Drive …) and this upload is governed by the … provider's terms of
  service and privacy policy and your app never collects or accesses the data
  in question then your app does not need to declare the collection of this
  data."

**Tomo's three data paths against those rules:**

| Path | What happens | Google's rule | Declare? |
|---|---|---|---|
| Database and settings | Stay on the phone; Tomo has no `INTERNET` permission. | "only processed locally … not sent off device" | **No** |
| Android Auto Backup (ADR-0028) | The OS copies `tomo.sqlite` and the prefs file to "a private folder in the user's Google Drive account". The backup is "end-to-end encrypted on devices running Android 9 or higher" with a screen lock, and "can't be read by the user or other apps" ([Auto Backup, updated 2026-10-23](https://developer.android.com/identity/data/autobackup)). Tomo never sees it. | The "own cloud storage" FAQ is the nearest match. **The Data safety page never names Auto Backup**, so this is a reading by analogy, not a quote. | **No** |
| Share diagnostics (§13, ADR-0004) | The user taps *Share diagnostics*, and the share sheet hands a `.txt` to the app the user picks. | An on-device transfer to another app is sharing, **unless** it is a "specific user-initiated action, where the user reasonably expects the data to be shared". A button named *Share diagnostics* that opens the share sheet is exactly that. | **No** (user-initiated) |

**The judgement call.** If a user sends the log to *the developer* (for
example by email), does the developer "collect" crash logs? Google's definition
says collection is transmission "from your app". Tomo itself transmits nothing,
because the mail app does. The Data safety page has **no FAQ on support emails or
user-sent bug reports**, so this cannot be settled from a primary source. The
honest choices are:

- **"No data collected" (recommended).** It matches Google's wording and Tomo's
  privacy claim. The privacy policy should still describe the log and the
  share button.
- **Belt and braces.** Declare *App info and performance → Crash logs* and
  *Diagnostics* as **collected, optional** (the user chooses), for *App
  functionality*. This is safer if a reviewer reads it strictly, but it makes
  the listing say Tomo collects data, which is not how Tomo thinks of itself.

**Question by question** (with "No" chosen):

1. *Does your app collect or share any of the required user data types?*
   **No.** The page's flow asks about encryption in transit and deletion only
   after a "Yes", so with "No" those two questions are skipped. The page
   implies this but doesn't state it outright.
2. The independent security review badge is optional and paid for by the
   developer, so skip it.
3. The form still needs the privacy policy URL (section 5).

**Other App content declarations** asked of every app (all apply to the closed
test as well):

- **Financial features:** "Even developers with apps that do not offer any
  financial features must complete this form"
  ([Financial features declaration](https://support.google.com/googleplay/android-developer/answer/13849271)).
- **Health apps:** the same rule; answer that there are no health features
  ([Health apps declaration](https://support.google.com/googleplay/android-developer/answer/14738291)).
- **Ads:** "You must declare whether or not your app contains ads" (No).
  **COVID-19 apps:** No. **App access:** everything works without a sign-in
  ([Prepare your app for review](https://support.google.com/googleplay/android-developer/answer/9859455)).
- **Advertising ID:** the merged manifest has no `AD_ID` permission. I could
  not find the Google page that describes Play Console's own advertising-ID
  question, so it is unconfirmed whether one is asked.

**Feeds:** "The privacy policy: what it says and where it lives" (the Data safety
answers and the policy must agree, and the policy must exist first). It also
feeds the fog step "running the closed test", because the form has to be done
before the closed test.

## 5. Privacy policy

**Required for every app.** "All apps must post a privacy policy link in the
designated field within Play Console and a privacy policy link or text within
the app itself." Also: "Apps that do not access any personal and sensitive user
data must still submit a privacy policy"
([User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311)).
(The older [Prepare your app for review](https://support.google.com/googleplay/android-developer/answer/9859455)
page still calls it conditional. The policy page owns the rule, and it says
every app.)

**Where it goes:**

1. The **Privacy policy** field in Play Console (App content).
2. Shown on the **store listing** from that field.
3. **Inside the app, as a link or as the text.** Tomo's Settings → About has two
   privacy *lines* (`about` in the ARB), not a policy. Tomo has no `INTERNET`
   permission and no `url_launcher`. A link would hand a URL to the browser
   (which needs no `INTERNET` in Tomo, but needs a launcher package or an
   intent). **Putting the policy's text in the app needs no new package.**

**What it must contain** ([User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311)):

- developer information and a privacy contact (or a way to send questions)
- what personal and sensitive data is accessed, collected, used and shared,
  and with whom
- secure handling
- retention and deletion
- a title that says it is a privacy policy
- the entity named in the store listing, or the app's name

**Format:** an active, public URL, not geofenced, not a PDF, and not editable by
others.

**Feeds:** "The privacy policy: what it says and where it lives". **The app
changes:** About must show the policy, by link or text.

## 6. Target API level

- **The rule now:** "New apps and app updates must target Android 16 (API level
  36) or higher to be submitted to Google Play", from **2026-08-31**, with "an
  extension to November 1, 2026" on request
  ([Target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878)).
  The previous floor was API 35 from 2025-08-31.
- **The next deadline:** the page names none (no API 37 date). The yearly pattern
  points to August 2027, but that is **not confirmed**.
- **Tomo:** `android/app/build.gradle.kts` sets `targetSdk = flutter.targetSdkVersion`.
  Flutter 3.47.6's `packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt`
  (in `C:\Users\shado\fvm\versions\3.47.6`) has `compileSdkVersion = 36`,
  `targetSdkVersion = 36`, `minSdkVersion = 24` and `ndkVersion = "28.2.13676358"`.
  The merged release manifest says `targetSdkVersion="36"`. **It meets the rule
  today.** A Flutter upgrade before August 2027 will probably move it to 37.

**Feeds:** "A release bundle Play accepts". Nothing to change.

## 7. 16 KB memory page size

- **The rule:** "Starting November 1st, 2025, all new apps and updates to
  existing apps submitted to Google Play and targeting Android 15+ devices must
  support 16 KB page sizes" ([Android Developers Blog, 2025-05-08](https://android-developers.googleblog.com/2025/05/prepare-play-apps-for-devices-with-16kb-page-size.html)).
  Android's guide says "all apps targeting Android 15 (API level 35) and higher
  must support 16 KB memory page sizes on 64-bit devices". It now gives
  **2027-02-01** as the date after which non-compliant *updates* can't be
  released ([Support 16 KB page sizes, updated 2026-10-16](https://developer.android.com/guide/practices/page-sizes)).
  Neither page explains how the two dates fit together. For a *new* app in
  October 2026, assume it is enforced now.
- **What's needed:** native libraries with every `LOAD` segment aligned to at
  least `2**14`, stored uncompressed on a 16 KB boundary in the APK. That means
  AGP 8.5.1+ and NDK r28+ ([same guide](https://developer.android.com/guide/practices/page-sizes)).
  Tomo uses **AGP 9.1.0** (`android/settings.gradle.kts`) and Flutter's **NDK
  28.2**.
- **Measured.** A short Python script read each `.so`'s ELF program headers
  and its zip offset in the arm64 release APK. `extractNativeLibs="false"` is
  set in the merged manifest.

| Library | `LOAD` p_align | Stored | Offset mod 16 384 |
|---|---|---|---|
| `libapp.so` (Dart code) | 0x10000 (64 KB) | uncompressed | 0 |
| `libflutter.so` | 0x10000 (64 KB) | uncompressed | 0 |
| `libsqlite3.so` (`sqlite3` package) | 0x4000 (16 KB) | uncompressed | 0 |
| `libdartjni.so` | 0x4000 (16 KB) | uncompressed | 0 |
| `libdatastore_shared_counter.so` (androidx DataStore) | 0x4000 (16 KB) | uncompressed | 0 |

**All pass.** 64 KB is a multiple of 16 KB. Two caveats:

1. The **AAB** will also carry `x86_64` and `armeabi-v7a` libraries.
   `flutter build appbundle` includes all three by default
   ([Flutter: Build and release an Android app, updated 2026-09-10](https://docs.flutter.dev/deployment/android)).
   x86_64 is 64-bit, so it is covered by the rule, and it was **not checked**
   (no AAB exists). Re-run the check on the bundle's APKs, or use Android's
   `zipalign -c -P 16 -v 4` and `llvm-objdump -p` checks from the guide.
2. Google's guide warns that `bundletool` builds can differ from local builds.
   The real test is the APKs Play makes from the AAB.

**Feeds:** "A release bundle Play accepts".

## 8. Bundle and signing

- **AAB is required:** "From August 2021, new apps are required to publish with
  the Android App Bundle on Google Play" ([About Android App Bundles, updated 2026-06-24](https://developer.android.com/guide/app-bundle)).
  Build with `flutter build appbundle`. It writes
  `build/app/outputs/bundle/release/app.aab`.
- **Play App Signing is required for new apps:** "When publishing your app to
  Google Play for the first time, you must also configure Play App Signing"
  ([Sign your app, updated 2026-03-06](https://developer.android.com/studio/publish/app-signing)).
  New apps are enrolled by default with a Google-generated key. That key is now
  "quantum-ready, hybrid signing", RSA 4096 plus ML-DSA-65, checked by
  Android 17+ ([Use Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)).
  Nothing to do for that. Flutter's guide says Play App Signing users "can wait
  for Google Play to give you the option".
- **The upload key:** "Stored in a Java keystore (`.jks` or `.keystore`)", "Must
  be an RSA key of 2048 bits or more" ([Use Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)).
  Validity: "should be valid for at least 25 years", and must end "after 22
  October 2033" ([Sign your app](https://developer.android.com/studio/publish/app-signing)).
  Flutter's own command uses `-keyalg RSA -keysize 2048 -validity 10000`
  (10,000 days, about 27 years), which fits. Keep the keystore and
  `key.properties` out of git.
- **A lost key is recoverable:** "If you lose your upload key or suspect that it
  was compromised, you are not locked out of your app". Make a new key, export
  its certificate as PEM, and ask for an upload key reset under *Manage Play app
  signing* ([Use Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)).
  Neither page says **how long a reset takes**.
- **Today's release build can't be uploaded.** `android/app/build.gradle.kts`
  signs `release` with `signingConfigs.getByName("debug")` (the template's
  TODO). "most app stores (including the Google Play Store) do not accept apps
  signed with a debug certificate" ([Sign your app](https://developer.android.com/studio/publish/app-signing)).
- **The first upload fixes the app id for good**, and the package name must
  also register for developer verification (section 12). The app id is the
  placeholder `io.github.heichan2000.tomo` (spec C14).

**Feeds:** "The release signing key: where it lives and how it's backed up",
"A release bundle Play accepts" and "The final app id".

## 9. Content rating, target audience, and children

- **Content rating (IARC).** Fill in the questionnaire for a new app: pick a
  category, answer every question, and give an email address for IARC's
  certificate. It gives "different ratings in different territories" (ESRB,
  PEGI, USK, ClassInd and IARC Generic among them). Do it again when "a change
  to your content or features … would affect the responses"
  ([Content rating requirements](https://support.google.com/googleplay/android-developer/answer/9859655)).
  No cost is mentioned. Tomo has no violence, no user-to-user contact, no
  purchases and no location, so it should land at the lowest rating, but the
  questionnaire decides.
- **Target audience and content.** The age groups are **5 and under, 6–8,
  9–12, 13–15, 16–17, 18 and over**. You may pick several, but only groups the
  app suits ([Manage target audience and app content settings](https://support.google.com/googleplay/android-developer/answer/9867159)).
- **Picking any group under 13** means Play treats the app as designed for
  children, and the **Families policy** applies
  ([Google Play Families Policies](https://support.google.com/googleplay/android-developer/answer/9893335)):
  - child privacy law (COPPA, GDPR)
  - content suitable for children
  - Families self-certified ad SDKs only (Tomo has no ads)
  - no AAID, IMEI or similar from children (Tomo sends nothing)
  - no location permission (none)
  - accurate answers in Play Console

  Tomo already meets the technical parts, because it has no network, no ads and
  no identifiers. The cost is mostly review attention and the legal duties.
  **Teacher Approved is optional**, an opt-in, and inclusion "is not guaranteed".
- **Not choosing children doesn't end it.** If an app "isn't primarily designed
  for under-13 children" but its listing has "youthful animation or young
  characters", Google Play may reject it, and Play "may conduct its own review"
  ([target audience page](https://support.google.com/googleplay/android-developer/answer/9867159);
  [Families policy](https://support.google.com/googleplay/android-developer/answer/9893335)).
  A cute pixel pet may draw that question. The answer should be decided on
  purpose, with the banner and screenshots in mind.

**Feeds:** "Who is Tomo for: which ages and which countries?" and "The store
listing".

## 10. App title and developer name

From the [Metadata policy](https://support.google.com/googleplay/android-developer/answer/9898842):

- "Your app title must be 30 characters or less." The app name field has the
  same 30-character limit; the short description has 80 and the full
  description 4,000. Full-width and half-width characters count the same
  ([Create and set up your app](https://support.google.com/googleplay/android-developer/answer/9859152)).
- In the title, icon **and developer name**: "Don't use emojis, emoticons, or
  repeated special characters", and "Avoid ALL CAPS unless it is part of your
  brand name".
- No text that suggests "store performance or ranking, price or promotional
  information, or … relations to existing Google Play programs". Google's
  examples: "App of the year", "#1", "Best of Play 20XX", "Popular", "10% off",
  "free for limited time only", "Editor's choice", "New".
- **Names don't have to be unique**, but they must not mislead. Not allowed:
  "App titles and icons that are so similar to those of existing products or
  services that users may be misled", or anything that implies a relationship
  that doesn't exist ([Impersonation](https://support.google.com/googleplay/android-developer/answer/9888374)).
  Search Play for other apps named "Tomo" before settling on the name.
- The **developer name** "can be different from your legal name" and "can be
  changed any time" ([Required information](https://support.google.com/googleplay/android-developer/answer/13628312)).
  See section 12 for what else is shown beside it.

**Feeds:** "The name on the store".

## 11. The listing's files

From [Add preview assets to showcase your app](https://support.google.com/googleplay/android-developer/answer/9866151):

| File | Required | Size | Format | File size |
|---|---|---|---|---|
| App icon | Yes | 512 × 512 px | 32-bit PNG (with alpha) | ≤ 1024 KB |
| Feature graphic | Yes | 1024 × 500 px | JPEG or 24-bit PNG, **no alpha** | not stated |
| Phone screenshots | Yes: "a minimum of two screenshots across different device types", up to 8 per type | 320–3840 px per side; the long side ≤ 2 × the short side | JPEG or 24-bit PNG, no alpha | not stated |
| Tablet / Chromebook screenshots | **Optional** ("you can add a minimum of 4") | 1080–7680 px, 16:9 or 9:16 | JPEG or 24-bit PNG | not stated |
| Video | Optional | YouTube URL, public or unlisted, no ads | — | — |

- **For recommendations (not required):** "at least four screenshots" at "9:16
  portrait (minimum 1080x1920)". Without them, an app may miss
  screenshot-based promotion slots.
- The icon must not use "Misleading symbols" (for example a fake notification
  dot), per the [Metadata policy](https://support.google.com/googleplay/android-developer/answer/9898842).
- The only MB limit on the page is 8 MB for Android XR screenshots. The often
  quoted "8 MB per screenshot / 15 MB feature graphic" are **not on Google's
  page**.
- Tomo is portrait-only and phone-shaped on tablets (§15.1), so four 1080×1920
  phone shots cover both the rule and the promotion advice.

**Feeds:** "The store listing: descriptions, banner and screenshots".

## 12. Developer account verification

- **Fee and age:** "a one-time US$25" registration fee, by credit or debit card
  (not prepaid). "You must be at least 18 years of age"
  ([Get started with Play Console](https://support.google.com/googleplay/android-developer/answer/6112435)).
  "If the information is judged invalid, the fee is not refunded."
- **What a personal account gives**
  ([Required information to create a Play Console developer account](https://support.google.com/googleplay/android-developer/answer/13628312)):
  - a developer name
  - your legal name and address (from the linked Google payments profile)
  - a contact email and contact phone for Google
  - a developer email for the public profile

  The three emails and phones are checked with a one-time password.
- **ID:** an "Official government identity document", but only if the payments
  profile isn't already verified, and it must match the profile exactly. The
  order is identity, then the Android device, then the phone
  ([Verify your developer identity information](https://support.google.com/googleplay/android-developer/answer/10841920)).
  **No page gives a time** for identity checks.
- **Android device:** new personal accounts must "verify that they have access
  to a real Android mobile device": "any non-rooted physical Android mobile
  device that runs at least the Android 10 operating system". Do it through
  the Play Console mobile app, with a QR code from the web console. It takes
  "less than a minute", and it must be done before the app can go on Play
  ([Device verification requirements](https://support.google.com/googleplay/android-developer/answer/14316361)).
  An emulator won't do. The Galaxy S23 Ultra will.
- **Shown publicly:** "Google will display your legal name, your country (as
  per your legal address), and developer email address on Google Play". The
  full address is shown only "If you decide to monetize". "In certain regions"
  more may be shown. The contact email and phone "are NOT shown to users"
  ([Required information](https://support.google.com/googleplay/android-developer/answer/13628312)).
  **So the owner's legal name is public**, whatever developer name is chosen.
  Tomo is free, so the address stays hidden.
- **Changed later:** the developer name, "any time". The legal name and address
  through the payments profile. The contact details must be kept current, and
  the developer email must keep working
  ([same page](https://support.google.com/googleplay/android-developer/answer/13628312)).
- **Android developer verification (2026).** This is Android's new
  developer-identity scheme. On **2026-09-30** installs began to be checked in
  Brazil, Indonesia, Singapore and Thailand, and "2027 and beyond" it spreads to
  all certified devices ([Android developer verification](https://developer.android.com/developer-verification)).
  For Play: "Effective September 30, 2026, all Play packages must be
  registered". Google "will attempt to auto-register both existing and new Play
  apps". A new package name is first-come, first-served while it has fewer than
  50 installs. If auto-registration fails, you add the key and upload a small
  signed APK with a snippet ([Registering Play package names](https://support.google.com/googleplay/android-developer/answer/16984799)).
  "If you use Play App Signing … Your eligible apps will be part of the
  automatic registration process" ([FAQ, page updated 2026-09-30](https://developer.android.com/developer-verification/guides/faq)).
  **ADB installs are untouched**: "you are free to install apps without
  verification with ADB". So *Tomo Dev* and `flutter run` keep working.

**Feeds:** "Make the Google Play developer account". The developer-verification
status of the final package name feeds "The final app id".

---

## Seen on the way

- **Staged rollout can't be used for the first launch:** "Staged rollouts can
  only be used for app updates, not when publishing an app for the first time"
  ([Release app updates with staged rollouts](https://support.google.com/googleplay/android-developer/answer/6346149)).
  This settles the fog step "the launch (staged rollout or not)" for 1.0. The
  first release goes to 100% of the chosen countries. A staged rollout is
  possible from the first update on.
- **Rules coming in 2027** ([Play Console technical quality requirements](https://support.google.com/googleplay/android-developer/answer/17492799),
  announced 2026-08-26):
  - From February 2027, a memory-use threshold for phones and tablets (no
    numbers on the page).
  - A "DEX code optimization" minimum, for DEX code over 10 MB. Tomo's
    `classes.dex` is **1.0 MB**, so it is not affected.
  - The page also lists crash-rate (1.09%) and ANR (0.47%) thresholds.
- **Cross-platform transfer (Android 16 QPR2+).** `data_extraction_rules.xml`
  can now hold a `<cross-platform-transfer platform="ios">` section. Google's
  page says that when a section is missing, "that mode is fully enabled for all
  content". However, the section also needs the iOS `bundleId` and `teamId` to
  match an app ([Auto Backup](https://developer.android.com/identity/data/autobackup)).
  Whether a missing section sends anything to iOS is **not stated**. This is
  not a Play rule, but it touches ADR-0028's "Switching between iPhone and
  Android brings nothing across".

## Could not confirm from a primary source

- The **exact questions** of Play Console's exact-alarm declaration, and whether
  it asks for a video.
- Whether a closed-test tester must **install** the app to count, or only opt in.
- How long an **identity check** or an **upload key reset** takes.
- The **API 37 deadline** (none is published yet).
- How the **2025-11-01** and **2027-02-01** 16 KB dates fit together.
- Whether Play Console asks an **advertising-ID** question of an app without
  `AD_ID`.
- Whether Google counts a log the user **mails to the developer** as
  "collection". Google's FAQ covers neither support email nor Auto Backup by
  name.
- **File size limits** for screenshots and the feature graphic.

---

## Changes the app

Things Play forces on the code or manifest.

1. **Release signing with an upload key**, not the debug key
   (`android/app/build.gradle.kts`, with `key.properties` and the keystore kept
   out of git). Feeds *The release signing key* and *A release bundle Play accepts*.
2. **Build an AAB** (`flutter build appbundle`), check its permissions with
   `aapt2`, and check its **x86_64** libraries for 16 KB alignment. Each upload
   needs a higher `versionCode` than the last. Feeds *A release bundle Play accepts*.
3. **The privacy policy inside the app**, as a link or the text, from Settings →
   About. Showing the text needs no new package. Feeds *The privacy policy*.
4. **The final application id**, before the first upload, because it can't
   change afterwards and it must register for developer verification. Feeds
   *The final app id* (already open).
5. **Only if Play refuses `USE_EXACT_ALARM`:** remove it, remove
   `maxSdkVersion="32"` from `SCHEDULE_EXACT_ALARM`, update the manifest tests,
   and decide whether Tomo sends the user to Alarms & reminders. Feeds the fog
   step *applying for production and the review*.

Nothing else is forced. Target SDK 36, 16 KB alignment on arm64, no foreground
service, no `INTERNET` and no `AD_ID` already meet the rules.

## Changes the map

- **New: "Run the closed test"** (from the fog). 12+ testers opted in for 14
  days in a row. Keep their feedback and what changed, because the production
  form asks for both.
- **New: "Apply for production"** (from the fog). The three-part form, about
  7 days of review, and the `USE_EXACT_ALARM` declaration. Have a screen
  recording of a block ending on time, in case it is asked for.
- **New: "If Play refuses USE_EXACT_ALARM"** (now specifiable, or a part of the
  ticket above). The manifest change, and whether Tomo asks for Alarms &
  reminders.
- **New: "Play's App content forms"** (or fold into *The privacy policy*). Data
  safety ("No", with the reasoning in section 4), financial features, health,
  ads and app access. All are needed **before the closed test**.
- *The privacy policy*: required for every app; add the in-app copy.
- *A release bundle Play accepts* and *The release signing key*: no debug
  signing; build an AAB; check x86_64 for 16 KB; upload key RSA 2048+, valid
  past 2033; a lost key can be reset. Target API 36 and arm64 16 KB already pass.
- *The final app id*: fixed at the first upload, and registered for developer
  verification.
- *Who is Tomo for*: picking under-13 brings the Families policy, and a cute
  listing may draw an "appeals to children" check either way.
- *The name on the store*: ≤ 30 characters, no emoji or caps, nothing that
  imitates another app. The developer name can change later.
- *Make the Google Play developer account*: US$25, ID, a real Android 10+
  phone. **The legal name and country are public.**
- *The store listing*: icon, feature graphic, 2–8 phone shots (four at
  1080×1920 advised). Tablet shots are optional.
- Fog, *the launch*: **settled for 1.0**. A staged rollout is impossible on a
  first release, so staged rollouts start with the first update.
- Fog, *the last phone checks*: run the permission and 16 KB checks **on the
  AAB**, plus the Google-cloud backup round trip.
- Not Play: the Android→iOS transfer section in the backup rules (seen on the
  way) is a small open question against ADR-0028.
