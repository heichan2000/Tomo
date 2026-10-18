import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/new_task_project.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/tasks/task_status.dart';

import '../app/providers.dart';
import '../l10n/app_localizations.dart';
import '../ui/buttons.dart';
import '../ui/pixel_box.dart';
import '../ui/pixel_icon.dart';
import '../ui/rows.dart';
import '../ui/sharp_text.dart';
import '../ui/sheet.dart';
import '../ui/text_field.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';

/// A task picked for Focus's Ready, with the project it is in.
@immutable
final class PickedTask {
  const PickedTask(this.task, this.project);

  final Task task;
  final Project project;
}

/// Opens the task picker (spec §8.1), a sheet over the whole app, and gives
/// back the task picked, or null when it was dismissed. [current] is the
/// task already on Ready, shown with a check.
Future<PickedTask?> pickTask(BuildContext context, {Task? current}) =>
    showPixelSheet<PickedTask>(
      context,
      (_) => TaskPickerSheet(current: current),
    );

/// One flat list across every project: doing first, then to-do, the most
/// recently focused first, each with its project; never a done task. Above
/// it, *New task* adds a task and goes, into the last-used project shown as
/// a chip that changes it.
class TaskPickerSheet extends ConsumerStatefulWidget {
  const TaskPickerSheet({super.key, this.current});

  final Task? current;

  @override
  ConsumerState<TaskPickerSheet> createState() => _TaskPickerSheetState();
}

typedef _Choices = ({List<Task> tasks, List<Project> projects, Project? into});

class _TaskPickerSheetState extends ConsumerState<TaskPickerSheet> {
  final _title = TextEditingController();
  late final Future<_Choices> _choices = _read();

  /// Where *New task* goes, once the user has changed it with the chip.
  Project? _into;
  var _adding = false;
  var _failed = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<_Choices> _read() async {
    final tasks = ref.read(taskServiceProvider);
    final projects = await tasks.projects();
    return (
      tasks: await tasks.pickerTasks(),
      projects: projects,
      into: newTaskProject(
        projects,
        lastUsedId: await ref.read(settingsProvider).lastProjectId(),
      ),
    );
  }

  void _pick(Task task, Project project) =>
      Navigator.of(context).pop(PickedTask(task, project));

  Future<void> _chooseProject(List<Project> projects, Project into) async {
    final chosen = await showPixelSheet<Project>(
      context,
      (_) => _ProjectSheet(projects: projects, chosen: into),
    );
    if (chosen != null && mounted) setState(() => _into = chosen);
  }

  /// Adds the typed task and goes. With no project left at all, it goes
  /// into a new **My work**, as onboarding's skip makes (spec §17).
  Future<void> _add(Project? into) async {
    final title = _title.text.trim();
    if (title.isEmpty || _adding) return;
    setState(() => _adding = true);
    final tasks = ref.read(taskServiceProvider);
    final defaultName = AppLocalizations.of(context).defaultProject;
    T? made<T>(Result<T> result) => switch (result) {
      Success(:final value) => value,
      Failure() => null,
    };

    final project = into ?? made(await tasks.createProject(defaultName));
    final added = project == null
        ? null
        : made(await tasks.createTask(projectId: project.id, title: title));
    if (!mounted) return;
    if (added == null) {
      setState(() {
        _adding = false;
        _failed = true;
      });
      return;
    }
    await ref.read(settingsProvider).setLastProjectId(project!.id);
    if (mounted) _pick(added, project);
  }

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return FutureBuilder(
      future: _choices,
      builder: (context, snapshot) {
        final choices = snapshot.data;
        final into = _into ?? choices?.into;
        final names = {
          for (final p in choices?.projects ?? const <Project>[]) p.id: p,
        };
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PixelText(words.pickerTitle, step: TypeStep.title),
            if (choices != null) ...[
              SizedBox(height: u(5)),
              PixelTextField(
                controller: _title,
                hint: words.newTask,
                maxLines: 1,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(maxTaskTitleLength),
                ],
                onSubmitted: (_) => _add(into),
              ),
              if (into != null) ...[
                SizedBox(height: u(3)),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _ProjectChip(
                    project: into,
                    onPressed: () => _chooseProject(choices.projects, into),
                  ),
                ),
              ],
              if (_failed) ...[
                SizedBox(height: u(3)),
                PixelBox(
                  fill: colours.sunken,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: u(7),
                      vertical: u(5),
                    ),
                    child: PixelText(words.error),
                  ),
                ),
              ],
              for (final task in choices.tasks) ...[
                SizedBox(height: u(3)),
                _TaskRow(
                  task: task,
                  project: names[task.projectId]!,
                  current: task.id == widget.current?.id,
                  onPressed: () => _pick(task, names[task.projectId]!),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

/// A task to pick: its title, its project under it, *Doing* when it is
/// doing, and a check when it is already the one on Ready.
class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.project,
    required this.current,
    required this.onPressed,
  });

  final Task task;
  final Project project;
  final bool current;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final u = UiPixel.of(context);
    return PixelRow(
      title: task.title,
      subtitle: project.name,
      onTap: onPressed,
      selected: current,
      trailing: [
        if (task.status == TaskStatus.doing) PixelChip(words.statusDoing),
        if (current) const _Check() else SizedBox(width: u(4)),
      ],
    );
  }
}

/// The check on the chosen row, in a 48 pt square like the row's other ends.
class _Check extends StatelessWidget {
  const _Check();

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: UiPixel.of(context).target,
    child: const Center(child: PixelIcon(IconName.check)),
  );
}

/// The project *New task* goes into: a sunken chip, its target the full
/// 48 pt, that opens the list of projects.
class _ProjectChip extends StatelessWidget {
  const _ProjectChip({required this.project, required this.onPressed});

  final Project project;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: words.srNewTaskProject(project.name),
      builder: (context, pressed, ring) => ConstrainedBox(
        constraints: BoxConstraints(minHeight: u.target),
        child: Center(
          widthFactor: 1,
          child: PixelBox(
            fill: pressed ? colours.pressed(colours.sunken) : colours.sunken,
            ring: ring ? colours.accent : null,
            child: Padding(
              padding: EdgeInsets.fromLTRB(u(6), u(3), u(4), u(3)),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: PixelText(project.name, step: TypeStep.caption),
                    ),
                    SizedBox(width: u(2)),
                    PixelIcon(IconName.down, colour: colours.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Every project, the one *New task* goes into checked. Picking one gives
/// it back.
class _ProjectSheet extends StatelessWidget {
  const _ProjectSheet({required this.projects, required this.chosen});

  final List<Project> projects;
  final Project chosen;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final u = UiPixel.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixelText(words.chooseProject, step: TypeStep.title),
        for (final project in projects) ...[
          SizedBox(height: u(3)),
          PixelRow(
            title: project.name,
            onTap: () => Navigator.of(context).pop(project),
            selected: project.id == chosen.id,
            trailing: [if (project.id == chosen.id) const _Check()],
          ),
        ],
      ],
    );
  }
}
