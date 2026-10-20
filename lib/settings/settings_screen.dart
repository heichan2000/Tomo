import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/data/settings.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/pet_service.dart';
import 'package:tomo_core/result.dart';

import '../app/providers.dart';
import '../app/routes.dart';
import '../l10n/app_localizations.dart';
import '../platform/notifications.dart';
import '../ui/back_header.dart';
import '../ui/buttons.dart';
import '../ui/pixel_icon.dart';
import '../ui/rows.dart';
import '../ui/screen_body.dart';
import '../ui/segmented.dart';
import '../ui/sharp_text.dart';
import '../ui/switch.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import '../work/work_sheets.dart';
import 'licences_screen.dart';

/// Settings (spec §8.10), pushed from Home's gear. Five groups, each under a
/// muted label:
///
/// - **Pet**: *Rename pet* (once it has hatched) and the **Calm pet** switch.
/// - **Focus**: the **Auto-start** switch, the only timer setting.
/// - **Notifications**: whether they are on, and *Open system settings*.
/// - **Appearance**: *Match phone / Light / Dark*.
/// - **About**: the privacy lines, the version, *Licences* and
///   **Share diagnostics** with how many errors the log holds, turned off at
///   none.
///
/// Every choice takes effect and is kept at once; there is no save.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final Future<int> _entries = ref.read(diagnosticLogProvider).count();
  var _sharing = false;

  Future<WriteOutcome> _rename(String name) async {
    final renamed = await ref.read(petServiceProvider).rename(name);
    return renamed is Success ? WriteOutcome.done : WriteOutcome.failed;
  }

  Future<void> _share() async {
    if (_sharing) return;
    _sharing = true;
    try {
      final text = await ref.read(diagnosticLogProvider).exportText();
      await ref
          .read(shareSheetProvider)
          .shareTextFile(fileName: 'tomo-diagnostics.txt', text: text);
    } finally {
      _sharing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);

    final pet = ref.watch(petStandingProvider);
    final calmPet = ref.watch(calmPetProvider);
    final autoStart = ref.watch(autoStartProvider).value ?? false;
    final access = ref.watch(notificationAccessProvider).value;
    final appearance = ref.watch(appearanceProvider);
    final version = ref.watch(appVersionProvider).value;

    final hatched =
        pet?.lookAt(
          ref.read(databaseProvider).clock(),
          calmPet: calmPet,
          reduceMotion: false,
        )
        is HatchedLook;
    final petName = pet == null
        ? ''
        : pet.name ?? words.speciesName(pet.species.name);

    Widget group(String label, List<Widget> parts) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: ScreenBody.spaced(context, [
        Padding(
          padding: EdgeInsets.only(left: u(1)),
          child: Semantics(
            header: true,
            child: PixelText(
              label,
              step: TypeStep.caption,
              colour: colours.muted,
            ),
          ),
        ),
        ...parts,
      ], 3),
    );

    Widget icon(IconName name) => SizedBox.square(
      dimension: u.target,
      child: Center(child: PixelIcon(name, colour: colours.muted)),
    );

    Widget note(String words) => Padding(
      padding: EdgeInsets.symmetric(horizontal: u(1)),
      child: PixelText(words, step: TypeStep.caption, colour: colours.muted),
    );

    return ColoredBox(
      color: colours.ground,
      child: ScreenBody(
        content: [
          BackHeader(backLabel: words.back, title: words.settings),
          group(words.settingsPet, [
            if (hatched)
              PixelRow(
                title: words.renamePet,
                subtitle: petName,
                onTap: () => askName(
                  context,
                  title: words.renamePet,
                  button: words.renameSave,
                  label: words.petNameField,
                  maxLength: maxPetNameLength,
                  initial: petName,
                  save: _rename,
                ),
                trailing: [icon(IconName.next)],
              ),
            PixelSwitchRow(
              title: words.calmPet,
              subtitle: words.calmPetAbout,
              value: calmPet,
              onChanged: (value) =>
                  unawaited(ref.read(calmPetProvider.notifier).set(value)),
            ),
          ]),
          group(words.settingsFocus, [
            PixelSwitchRow(
              title: words.autoStart,
              subtitle: words.autoStartAbout,
              value: autoStart,
              onChanged: (value) =>
                  unawaited(ref.read(autoStartProvider.notifier).set(value)),
            ),
          ]),
          group(words.settingsNotifications, [
            if (access != null)
              PixelRow(
                title: words.openSystemSettings,
                subtitle: switch (access) {
                  NotificationAccess.granted => words.notifStatusOn,
                  NotificationAccess.denied => words.bellOff,
                  NotificationAccess.notDetermined => words.notifStatusNotAsked,
                },
                onTap: () => unawaited(
                  ref.read(notificationAccessProvider.notifier).openSettings(),
                ),
                trailing: [icon(IconName.external)],
              ),
          ]),
          group(words.settingsAppearance, [
            PixelSegmented<Appearance>(
              segments: [
                Segment(Appearance.system, words.appearanceSystem),
                Segment(Appearance.light, words.appearanceLight),
                Segment(Appearance.dark, words.appearanceDark),
              ],
              selected: appearance,
              onChanged: (value) =>
                  unawaited(ref.read(appearanceProvider.notifier).set(value)),
            ),
          ]),
          group(words.settingsAbout, [
            note(words.about),
            note(words.aboutOs),
            PixelRow(
              title: words.version,
              subtitle: version == null
                  ? null
                  : words.versionNumber(version.version, version.build),
            ),
            PixelRow(
              title: words.licences,
              onTap: () => pushInTab(context, (_) => const LicencesScreen()),
              trailing: [icon(IconName.next)],
            ),
            FutureBuilder(
              future: _entries,
              builder: (context, counted) {
                final count = counted.data ?? 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: ScreenBody.spaced(context, [
                    PixelButton(
                      label: words.shareDiagnostics,
                      kind: ButtonKind.secondary,
                      wide: true,
                      onPressed: count == 0 ? null : _share,
                    ),
                    note(words.diagEntries(count)),
                    note(words.shareDiag),
                  ], 3),
                );
              },
            ),
          ]),
        ],
      ),
    );
  }
}
