import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/focus/live_cycle.dart';
import 'package:tomo_core/focus/projection.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/tasks/task_status.dart';

import '../app/providers.dart';
import '../app/routes.dart';
import '../focus/task_picker.dart';
import '../l10n/app_localizations.dart';
import '../ui/back_header.dart';
import '../ui/buttons.dart';
import '../ui/pixel_icon.dart';
import '../ui/rows.dart';
import '../ui/screen_body.dart';
import '../ui/segmented.dart';
import '../ui/sharp_text.dart';
import '../ui/stepper.dart';
import '../ui/text_field.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import '../voice/pet_voice.dart';
import 'work_lists.dart';
import 'work_sheets.dart';
import 'work_words.dart';

/// A task's own screen, which is where it is edited (spec §8.8).
///
/// Back; the title; the notes; the **Project** row, which opens *Move to
/// project*; **Status**; **Planned blocks**; **Focus so far**, which nobody
/// can edit; then *Start focusing* and *Delete task*. Every field saves as
/// you go: a typed field when you leave it, the rest at once.
///
/// A done task has the done-task line in place of *Start focusing*. While
/// its own block runs the button is *Back to focus*; while another task's
/// does, the button is off, with a line saying why. Refusals land where
/// they were tapped, as on the project screen.
class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.task});

  /// The task as it was when opened, until the database says otherwise.
  final Task task;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

/// Where a refusal or failure shows: under the part that was used.
enum _At { title, notes, project, status, plan, delete }

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late final _title = TextEditingController(text: widget.task.title);
  late final _notes = TextEditingController(text: widget.task.notes ?? '');
  final _titleFocus = FocusNode();
  final _notesFocus = FocusNode();

  /// The task as last read or written.
  late Task _task = widget.task;

  /// Held from the start, so the fields can still save as the screen goes.
  late final TaskService _tasks = ref.read(taskServiceProvider);

  ({_At at, String text})? _line;
  var _gone = false;
  Timer? _wake;

  @override
  void initState() {
    super.initState();
    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus) unawaited(_saveTitle());
    });
    _notesFocus.addListener(() {
      if (!_notesFocus.hasFocus) unawaited(_saveNotes());
    });
    ref.listenManual(workTaskProvider(widget.task.id), (_, next) {
      if (!next.hasValue) return;
      final task = next.value;
      if (task == null) {
        // Deleted, here or elsewhere: there is nothing to show.
        WidgetsBinding.instance.addPostFrameCallback((_) => _leave());
        return;
      }
      setState(() => _took(task));
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    // Left while typing: what was typed is kept.
    if (!_gone) {
      if (_titleFocus.hasFocus) unawaited(_saveTitle());
      if (_notesFocus.hasFocus) unawaited(_saveNotes());
    }
    _wake?.cancel();
    _title.dispose();
    _notes.dispose();
    _titleFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  /// Takes [task] as the latest, and shows its words in any field not
  /// being typed in.
  void _took(Task task) {
    _task = task;
    if (!_titleFocus.hasFocus && _title.text != task.title) {
      _title.text = task.title;
    }
    final notes = task.notes ?? '';
    if (!_notesFocus.hasFocus && _notes.text != notes) _notes.text = notes;
  }

  DateTime _now() => ref.read(databaseProvider).clock();

  /// Writes [patch], showing a refusal or failure at [at].
  Future<void> _write(TaskPatch patch, _At at) async {
    final written = await _tasks.updateTask(_task.id, patch);
    if (!mounted) return;
    switch (written) {
      case Success(:final value):
        setState(() {
          _took(value);
          if (_line?.at == at) _line = null;
        });
      case Failure(:final error):
        setState(() => _line = (at: at, text: _lineFor(error)));
    }
  }

  String _lineFor(WriteError error) {
    final words = AppLocalizations.of(context);
    return error is BlockRunning ? words.lockTask : words.error;
  }

  /// A title cleared away keeps the old one: a task always has a title.
  Future<void> _saveTitle() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      if (mounted) _title.text = _task.title;
      return;
    }
    if (title == _task.title) return;
    if (!mounted) {
      await _tasks.updateTask(_task.id, TaskPatch(title: title));
      return;
    }
    await _write(TaskPatch(title: title), _At.title);
  }

  Future<void> _saveNotes() async {
    final notes = _notes.text.trim();
    if (notes == (_task.notes ?? '')) return;
    if (!mounted) {
      await _tasks.updateTask(_task.id, TaskPatch(notes: Edit(notes)));
      return;
    }
    await _write(TaskPatch(notes: Edit(notes)), _At.notes);
  }

  Future<void> _move() async {
    final projects = await _tasks.projects();
    if (!mounted) return;
    final into = await chooseProjectToMove(
      context,
      projects: projects,
      current: _task.projectId,
    );
    if (into == null || into.id == _task.projectId) return;
    await _write(TaskPatch(projectId: into.id), _At.project);
  }

  Future<void> _setStatus(TaskStatus status) async {
    if (status == _task.status) return;
    await _write(TaskPatch(status: status), _At.status);
  }

  Future<void> _plan(int? planned) =>
      _write(TaskPatch(estimate: Edit(planned)), _At.plan);

  /// *Delete task*. While its block runs it is refused at once, with no
  /// sheet first (spec §17 C135).
  Future<void> _delete(bool locked) async {
    final words = AppLocalizations.of(context);
    if (locked) {
      setState(() => _line = (at: _At.delete, text: words.lockTask));
      return;
    }
    final sure = await confirmDelete(
      context,
      title: words.delTaskTitle,
      body: deleteTaskBody(
        words,
        task: _task.title,
        minutes: _task.cumulativeFocusMinutes,
      ),
      button: words.deleteTask,
    );
    if (!sure) return;
    final deleted = await _tasks.deleteTask(_task.id);
    if (!mounted) return;
    switch (deleted) {
      case Success():
        _leave();
      case Failure(:final error):
        setState(() => _line = (at: _At.delete, text: _lineFor(error)));
    }
  }

  /// Back to the project, once: the task is gone.
  void _leave() {
    if (_gone || !mounted) return;
    _gone = true;
    Navigator.of(context).pop();
  }

  /// Looks again when the running block ends, so the button comes back.
  void _wakeAtBlockEnd(LiveCycle? cycle, bool running) {
    _wake?.cancel();
    if (cycle == null || !running) return;
    _wake = Timer(cycle.endAt.difference(_now()), () {
      if (mounted) setState(() {});
    });
  }

  void _clearLine() {
    if (_line != null) setState(() => _line = null);
  }

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final task = _task;

    final cycle = ref.watch(petStandingProvider)?.cycle;
    final running = project(cycle, _now()).state == FocusState.focusRunning;
    _wakeAtBlockEnd(cycle, running);
    final mine = running && cycle!.taskId == task.id;
    final otherTask = running && !mine
        ? ref.watch(cycleTaskProvider)?.task.title
        : null;

    final summaries = ref.watch(projectSummariesProvider).value;
    final inProject = summaries
        ?.where((s) => s.project.id == task.projectId)
        .firstOrNull
        ?.project;

    final line = _line;
    List<Widget> lineAt(_At at) => [
      if (line != null && line.at == at) SunkenLine(line.text),
    ];

    // A group's label is a header, as on Settings, unless the part under it
    // already says it to a screen reader.
    Widget group(String label, List<Widget> parts, {bool spoken = true}) {
      final caption = Padding(
        padding: EdgeInsets.only(left: u(1)),
        child: PixelText(
          label,
          step: TypeStep.caption,
          colour: colours.muted,
          header: spoken,
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: ScreenBody.spaced(context, [
          spoken ? caption : ExcludeSemantics(child: caption),
          ...parts,
        ], 3),
      );
    }

    Widget field(Widget field, _At at) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: ScreenBody.spaced(context, [field, ...lineAt(at)], 3),
    );

    final planned = task.estimate;
    final blocks = task.actualPomodoros;

    final Widget action;
    if (task.status == TaskStatus.done) {
      action = PixelText(
        words.doneTask,
        colour: colours.muted,
        textAlign: TextAlign.center,
      );
    } else if (mine) {
      action = PixelButton(
        label: words.backToFocus,
        wide: true,
        onPressed: () => openFocus(context),
      );
    } else if (running) {
      action = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: ScreenBody.spaced(context, [
          PixelButton(label: words.startFocusing, wide: true, onPressed: null),
          PixelText(
            words.otherRunning(otherTask ?? ''),
            step: TypeStep.caption,
            colour: colours.muted,
            textAlign: TextAlign.center,
          ),
        ], 5),
      );
    } else {
      action = PixelButton(
        label: words.startFocusing,
        wide: true,
        onPressed: inProject == null
            ? null
            : () => openFocus(context, ready: PickedTask(task, inProject)),
      );
    }

    return ColoredBox(
      color: colours.ground,
      child: Listener(
        onPointerDown: (_) => _clearLine(),
        child: NotificationListener<ScrollStartNotification>(
          onNotification: (_) {
            _clearLine();
            return false;
          },
          child: ScreenBody(
            content: [
              BackHeader(backLabel: words.back),
              field(
                PixelTextField(
                  controller: _title,
                  focusNode: _titleFocus,
                  label: words.taskTitleField,
                  step: TypeStep.title,
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp('[\r\n]')),
                    LengthLimitingTextInputFormatter(maxTaskTitleLength),
                  ],
                ),
                _At.title,
              ),
              field(
                PixelTextField(
                  controller: _notes,
                  focusNode: _notesFocus,
                  hint: words.addNotes,
                  label: words.notesField,
                  minLines: 3,
                  textInputAction: TextInputAction.newline,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(maxNotesLength),
                  ],
                ),
                _At.notes,
              ),
              group(words.detailProject, [
                PixelRow(
                  title: inProject?.name ?? '',
                  onTap: _move,
                  trailing: [
                    SizedBox.square(
                      dimension: u.target,
                      child: Center(
                        child: PixelIcon(IconName.next, colour: colours.muted),
                      ),
                    ),
                  ],
                ),
                ...lineAt(_At.project),
              ]),
              group(words.detailStatus, [
                PixelSegmented<TaskStatus>(
                  segments: [
                    for (final status in TaskStatus.values)
                      Segment(status, statusName(words, status)),
                  ],
                  selected: task.status,
                  onChanged: _setStatus,
                ),
                ...lineAt(_At.status),
              ]),
              group(words.plannedBlocks, [
                PixelStepper(
                  label: words.plannedBlocks,
                  value: planned == null
                      ? words.noPlan
                      : words.taskBlocks(planned),
                  mutedValue: planned == null,
                  lessLabel: words.stepFewer,
                  moreLabel: words.stepMore,
                  // − from 1 is no plan; + from no plan is 1.
                  onLess: planned == null
                      ? null
                      : () => _plan(planned == 1 ? null : planned - 1),
                  onMore: planned == maxEstimate
                      ? null
                      : () => _plan((planned ?? 0) + 1),
                ),
                ...lineAt(_At.plan),
              ], spoken: false),
              group(words.focusSoFar, [
                Padding(
                  padding: EdgeInsets.only(left: u(1)),
                  child: PixelText(
                    blocks == 0
                        ? words.focusSoFarNone
                        : words.focusSoFarDone(
                            blocks,
                            focusTime(words, task.cumulativeFocusMinutes),
                          ),
                    colour: blocks == 0 ? colours.muted : colours.ink,
                  ),
                ),
              ]),
            ],
            bottom: [
              action,
              PixelButton(
                label: words.deleteTask,
                kind: ButtonKind.quietDestructive,
                wide: true,
                onPressed: () => _delete(mine),
              ),
              ...lineAt(_At.delete),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens a task's own screen, pushed in the Work tab.
void openTaskDetail(BuildContext context, Task task) =>
    pushInTab(context, (_) => TaskDetailScreen(task: task));
