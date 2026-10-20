import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/tasks/task_status.dart';

import '../l10n/app_localizations.dart';
import '../ui/buttons.dart';
import '../ui/pixel_box.dart';
import '../ui/pixel_icon.dart';
import '../ui/rows.dart';
import '../ui/screen_body.dart';
import '../ui/segmented.dart';
import '../ui/sharp_text.dart';
import '../ui/sheet.dart';
import '../ui/text_field.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import 'work_words.dart';

// The Work screens' sheets (spec §8.1, §8.8): every dialog is a sheet over
// the dither, never a route.

/// How a write went, for a sheet that shows the outcome where it was asked
/// for: done, refused by the task lock, or failed.
enum WriteOutcome { done, locked, failed }

/// A project's name, asked for on a sheet: *New project* (*Create project*)
/// or *Rename project* (*Rename*). [save] writes it; the sheet closes once it
/// is [WriteOutcome.done], and shows the error line if it failed. The button
/// is off until something is typed.
Future<void> askProjectName(
  BuildContext context, {
  required String title,
  required String button,
  String initial = '',
  required Future<WriteOutcome> Function(String name) save,
}) => askName(
  context,
  title: title,
  button: button,
  label: AppLocalizations.of(context).projectName,
  maxLength: maxProjectNameLength,
  initial: initial,
  save: save,
);

/// A name, asked for on a sheet with one field, [maxLength] characters long
/// as a reader counts them: a project's, or the pet's (Settings → *Rename
/// pet*). [label] is what a screen reader calls the field. Behaves as
/// [askProjectName] says.
Future<void> askName(
  BuildContext context, {
  required String title,
  required String button,
  required String label,
  required int maxLength,
  String initial = '',
  required Future<WriteOutcome> Function(String name) save,
}) => showPixelSheet<void>(
  context,
  (_) => _NameSheet(
    title: title,
    button: button,
    label: label,
    maxLength: maxLength,
    initial: initial,
    save: save,
  ),
);

class _NameSheet extends StatefulWidget {
  const _NameSheet({
    required this.title,
    required this.button,
    required this.label,
    required this.maxLength,
    required this.initial,
    required this.save,
  });

  final String title;
  final String button;
  final String label;
  final int maxLength;
  final String initial;
  final Future<WriteOutcome> Function(String name) save;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final _name = TextEditingController(text: widget.initial);
  var _saving = false;
  var _failed = false;

  bool get _typed => _name.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_typed || _saving) return;
    setState(() => _saving = true);
    final outcome = await widget.save(_name.text);
    if (!mounted) return;
    if (outcome == WriteOutcome.done) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    return _SheetColumn(
      gap: 5,
      children: [
        PixelText(widget.title, step: TypeStep.title),
        PixelTextField(
          controller: _name,
          label: widget.label,
          autofocus: true,
          maxLines: 1,
          inputFormatters: [LengthLimitingTextInputFormatter(widget.maxLength)],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _save(),
        ),
        if (_failed) SunkenLine(words.error),
        PixelButton(
          label: widget.button,
          wide: true,
          onPressed: _typed ? _save : null,
        ),
      ],
    );
  }
}

/// What the row menu was closed with, beyond a status change, which it
/// makes itself.
enum RowMenuChoice { move, delete }

/// A task's row menu (spec §8.8), from ⋯ or a long press: the task's title,
/// the status control, *Move to another project* and *Delete task*.
///
/// A status chosen here is written at once through [setStatus], and the
/// sheet closes; a lock refusal shows under the status control instead.
/// *Delete task* while [locked] says so under it rather than asking.
Future<RowMenuChoice?> showRowMenu(
  BuildContext context, {
  required Task task,
  required Future<WriteOutcome> Function(TaskStatus status) setStatus,
  required bool Function() locked,
}) => showPixelSheet<RowMenuChoice>(
  context,
  (_) => _RowMenu(task: task, setStatus: setStatus, locked: locked),
);

class _RowMenu extends StatefulWidget {
  const _RowMenu({
    required this.task,
    required this.setStatus,
    required this.locked,
  });

  final Task task;
  final Future<WriteOutcome> Function(TaskStatus status) setStatus;
  final bool Function() locked;

  @override
  State<_RowMenu> createState() => _RowMenuState();
}

class _RowMenuState extends State<_RowMenu> {
  /// Where a refusal or failure shows: under the status control, or under
  /// *Delete task*.
  ({bool atStatus, WriteOutcome outcome})? _line;
  var _writing = false;

  Future<void> _status(TaskStatus status) async {
    if (status == widget.task.status || _writing) return;
    _writing = true;
    final outcome = await widget.setStatus(status);
    _writing = false;
    if (!mounted) return;
    if (outcome == WriteOutcome.done) {
      Navigator.of(context).pop();
    } else {
      setState(() => _line = (atStatus: true, outcome: outcome));
    }
  }

  void _delete() {
    if (widget.locked()) {
      setState(() => _line = (atStatus: false, outcome: WriteOutcome.locked));
    } else {
      Navigator.of(context).pop(RowMenuChoice.delete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final line = _line;
    Widget refusal(WriteOutcome outcome) => SunkenLine(
      outcome == WriteOutcome.locked ? words.lockTask : words.error,
    );
    return _SheetColumn(
      gap: 5,
      children: [
        PixelText(widget.task.title, step: TypeStep.title),
        _SheetColumn(
          gap: 3,
          children: [
            PixelSegmented<TaskStatus>(
              segments: [
                for (final status in TaskStatus.values)
                  Segment(status, statusName(words, status)),
              ],
              selected: widget.task.status,
              onChanged: _status,
            ),
            if (line != null && line.atStatus) refusal(line.outcome),
          ],
        ),
        _SheetColumn(
          gap: 3,
          children: [
            MenuRow(
              label: words.moveToAnotherProject,
              icon: IconName.external,
              chevron: true,
              onPressed: () => Navigator.of(context).pop(RowMenuChoice.move),
            ),
            MenuRow(
              label: words.deleteTask,
              icon: IconName.trash,
              colour: colours.destructive,
              onPressed: _delete,
            ),
            if (line != null && !line.atStatus) refusal(line.outcome),
          ],
        ),
      ],
    );
  }
}

/// What the project menu was closed with.
enum ProjectMenuChoice { rename, delete }

/// A project's menu (spec §8.8), from ⋯ in its header: *Rename project*
/// and *Delete project*. *Delete project* while [locked] says so under it
/// rather than asking.
Future<ProjectMenuChoice?> showProjectMenu(
  BuildContext context, {
  required String name,
  required bool Function() locked,
}) => showPixelSheet<ProjectMenuChoice>(
  context,
  (_) => _ProjectMenu(name: name, locked: locked),
);

class _ProjectMenu extends StatefulWidget {
  const _ProjectMenu({required this.name, required this.locked});

  final String name;
  final bool Function() locked;

  @override
  State<_ProjectMenu> createState() => _ProjectMenuState();
}

class _ProjectMenuState extends State<_ProjectMenu> {
  var _refused = false;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    return _SheetColumn(
      gap: 5,
      children: [
        PixelText(widget.name, step: TypeStep.title),
        _SheetColumn(
          gap: 3,
          children: [
            MenuRow(
              label: words.renameProject,
              onPressed: () =>
                  Navigator.of(context).pop(ProjectMenuChoice.rename),
            ),
            MenuRow(
              label: words.deleteProject,
              icon: IconName.trash,
              colour: colours.destructive,
              onPressed: () {
                if (widget.locked()) {
                  setState(() => _refused = true);
                } else {
                  Navigator.of(context).pop(ProjectMenuChoice.delete);
                }
              },
            ),
            if (_refused) SunkenLine(words.lockProject),
          ],
        ),
      ],
    );
  }
}

/// *Move to project* (spec §8.8): every project, the task's own checked.
/// Gives back the one picked, or null.
Future<Project?> chooseProjectToMove(
  BuildContext context, {
  required List<Project> projects,
  required int current,
}) => showPixelSheet<Project>(
  context,
  (context) => _SheetColumn(
    gap: 5,
    children: [
      PixelText(
        AppLocalizations.of(context).moveToProject,
        step: TypeStep.title,
      ),
      _SheetColumn(
        gap: 3,
        children: [
          for (final project in projects)
            PixelRow(
              title: project.name,
              onTap: () => Navigator.of(context).pop(project),
              selected: project.id == current,
              trailing: [
                if (project.id == current)
                  SizedBox.square(
                    dimension: UiPixel.of(context).target,
                    child: const Center(child: PixelIcon(IconName.check)),
                  ),
              ],
            ),
        ],
      ),
    ],
  ),
);

/// Asks before a delete (spec §8.8): what goes and what stays, then
/// *Cancel* (secondary) above the destructive [button], 8 UI pixels apart.
/// No undo. True once the user said delete.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String body,
  required String button,
}) async =>
    await showPixelSheet<bool>(
      context,
      (context) => _SheetColumn(
        gap: 5,
        children: [
          PixelText(title, step: TypeStep.title),
          PixelText(body),
          _SheetColumn(
            gap: 8,
            children: [
              PixelButton(
                label: AppLocalizations.of(context).cancel,
                kind: ButtonKind.secondary,
                wide: true,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              PixelButton(
                label: button,
                kind: ButtonKind.destructive,
                wide: true,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ],
      ),
    ) ??
    false;

/// A row in a menu sheet: an optional icon, the words, and a chevron when
/// it opens another sheet. No fill of its own; it shades while held.
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.colour,
    this.chevron = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconName? icon;

  /// The words' and icon's colour: ink, or the destructive colour.
  final Color? colour;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final ink = colour ?? colours.ink;
    return Pressable(
      onPressed: onPressed,
      builder: (context, pressed, ring) => PixelBox(
        fill: pressed ? colours.sunken : null,
        ring: ring ? colours.accent : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: u.target),
          child: Padding(
            padding: EdgeInsets.fromLTRB(u(1), u(3), u(2), u(3)),
            child: Row(
              children: [
                if (icon != null) ...[
                  PixelIcon(icon!, colour: ink),
                  SizedBox(width: u(4)),
                ],
                Expanded(child: PixelText(label, colour: ink)),
                if (chevron) ...[
                  SizedBox(width: u(4)),
                  PixelIcon(IconName.next, colour: colours.muted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A sheet's parts, top to bottom, [gap] UI pixels apart.
class _SheetColumn extends StatelessWidget {
  const _SheetColumn({required this.gap, required this.children});

  final num gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: ScreenBody.spaced(context, children, gap),
  );
}
