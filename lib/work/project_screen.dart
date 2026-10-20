import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/focus/projection.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/tasks/task_status.dart';

import '../app/providers.dart';
import '../l10n/app_localizations.dart';
import '../ui/buttons.dart';
import '../ui/motion.dart';
import '../ui/pixel_icon.dart';
import '../ui/rows.dart';
import '../ui/screen_body.dart';
import '../ui/sharp_text.dart';
import '../ui/text_field.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import '../voice/pet_voice.dart';
import 'sliding_list.dart';
import 'task_detail_screen.dart';
import 'task_list_row.dart';
import 'work_lists.dart';
import 'work_screen.dart';
import 'work_sheets.dart';
import 'work_words.dart';

/// A project's screen, which is its task list (spec §8.8).
///
/// The header: back, the name, its tasks counted, and ⋯ for *Rename
/// project* and *Delete project*. Then its tasks, doing → to do → done, the
/// most recent first in each, done greyed at the bottom; *Add a task* at the
/// end of the open ones. When every task is done, a sunken line says so
/// above them; with no tasks, a card.
///
/// Marking done here is quiet: the ring fills at once, and after about
/// 450 ms the row slides to its new place. No sparkles, no EXP shown.
class ProjectScreen extends ConsumerStatefulWidget {
  const ProjectScreen({super.key, required this.projectId, required this.name});

  final int projectId;

  /// The name it was opened with, until the list says otherwise.
  final String name;

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
}

/// How long a ring tap holds the row in place before it moves.
const _holdBeforeMove = Duration(milliseconds: 450);

/// How long the row takes to slide to its new place.
const _slideTime = Duration(milliseconds: 240);

class _ProjectScreenState extends ConsumerState<ProjectScreen>
    with SingleTickerProviderStateMixin {
  late final _slide = AnimationController(vsync: this, duration: _slideTime);
  final _newTask = TextEditingController();
  final _newTaskFocus = FocusNode();

  /// The list as it stood when a ring was tapped, and the tasks changed
  /// since: each row keeps its place, showing its new status, until it
  /// moves.
  ({List<Task> before, Map<int, Task> changed})? _held;

  /// The list as the database last gave it.
  List<Task>? _live;
  Timer? _move;
  SlideArm? _arm;

  /// A refusal or a failure, under the row it happened on (spec §8.8). It
  /// goes at the next touch or scroll.
  ({int taskId, String text})? _rowLine;

  /// A write on the project itself that failed or was refused.
  String? _projectLine;
  var _addFailed = false;
  var _adding = false;
  var _gone = false;

  /// The project has been seen in the list of projects.
  var _listed = false;
  Timer? _wake;

  @override
  void dispose() {
    _move?.cancel();
    _wake?.cancel();
    _slide.dispose();
    _newTask.dispose();
    _newTaskFocus.dispose();
    super.dispose();
  }

  TaskService get _tasks => ref.read(taskServiceProvider);

  DateTime _now() => ref.read(databaseProvider).clock();

  /// The task a block is running on now, if any. Only while it runs does
  /// the task lock hold (ADR-0024).
  int? _runningTaskId() {
    final cycle = ref.read(petStandingProvider)?.cycle;
    return project(cycle, _now()).state == FocusState.focusRunning
        ? cycle!.taskId
        : null;
  }

  /// Looks again when the running block ends, so its *Focus* chip goes.
  void _wakeAtBlockEnd() {
    _wake?.cancel();
    final cycle = ref.read(petStandingProvider)?.cycle;
    if (cycle == null || _runningTaskId() == null) return;
    _wake = Timer(cycle.endAt.difference(_now()), () {
      if (mounted) setState(() {});
    });
  }

  WriteOutcome _outcome(WriteError error) =>
      error is BlockRunning ? WriteOutcome.locked : WriteOutcome.failed;

  String _lineFor(WriteOutcome outcome) {
    final words = AppLocalizations.of(context);
    return outcome == WriteOutcome.locked ? words.lockTask : words.error;
  }

  /// Changes [task]'s status. Done, the row shows it at once where it is,
  /// then moves after [_holdBeforeMove].
  Future<WriteOutcome> _setStatus(Task task, TaskStatus status) async {
    final written = await _tasks.updateTask(task.id, TaskPatch(status: status));
    switch (written) {
      case Failure(:final error):
        return _outcome(error);
      case Success(:final value):
        if (!mounted) return WriteOutcome.done;
        final held = _held;
        setState(() {
          _held = (
            before: held?.before ?? _live ?? const [],
            changed: {...?held?.changed, value.id: value},
          );
          _rowLine = null;
        });
        _move?.cancel();
        _move = Timer(_holdBeforeMove, () {
          if (!mounted) return;
          setState(() {
            _held = null;
            if (!reduceMotion(context)) {
              _slide.value = 0;
              _arm = SlideArm(value.id);
            }
          });
        });
        return WriteOutcome.done;
    }
  }

  void _slideHome(double distance) {
    if (!mounted) return;
    if (distance == 0) {
      setState(() => _arm = null);
      return;
    }
    unawaited(
      _slide.forward(from: 0).whenComplete(() {
        if (mounted) setState(() => _arm = null);
      }),
    );
  }

  /// One tap on the ring: done, or back from done (spec §5.4 note).
  Future<void> _ring(Task task) async {
    final status = task.status == TaskStatus.done
        ? task.reopensTo
        : TaskStatus.done;
    final outcome = await _setStatus(task, status);
    if (outcome != WriteOutcome.done && mounted) {
      setState(() => _rowLine = (taskId: task.id, text: _lineFor(outcome)));
    }
  }

  Future<void> _menu(Task task) async {
    final choice = await showRowMenu(
      context,
      task: task,
      setStatus: (status) => _setStatus(task, status),
      locked: () => _runningTaskId() == task.id,
    );
    if (!mounted) return;
    switch (choice) {
      case RowMenuChoice.move:
        await _moveTask(task);
      case RowMenuChoice.delete:
        await _deleteTask(task);
      case null:
        break;
    }
  }

  Future<void> _moveTask(Task task) async {
    final projects = await _tasks.projects();
    if (!mounted) return;
    final into = await chooseProjectToMove(
      context,
      projects: projects,
      current: task.projectId,
    );
    if (into == null || into.id == task.projectId) return;
    final moved = await _tasks.updateTask(
      task.id,
      TaskPatch(projectId: into.id),
    );
    if (moved case Failure(:final error) when mounted) {
      setState(
        () => _rowLine = (taskId: task.id, text: _lineFor(_outcome(error))),
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    final words = AppLocalizations.of(context);
    final sure = await confirmDelete(
      context,
      title: words.delTaskTitle,
      body: deleteTaskBody(
        words,
        task: task.title,
        minutes: task.cumulativeFocusMinutes,
      ),
      button: words.deleteTask,
    );
    if (!sure) return;
    final deleted = await _tasks.deleteTask(task.id);
    if (deleted case Failure(:final error) when mounted) {
      setState(
        () => _rowLine = (taskId: task.id, text: _lineFor(_outcome(error))),
      );
    }
  }

  Future<void> _projectMenu(String name, List<Task> tasks) async {
    final choice = await showProjectMenu(
      context,
      name: name,
      locked: () => tasks.any((task) => task.id == _runningTaskId()),
    );
    if (!mounted) return;
    switch (choice) {
      case ProjectMenuChoice.rename:
        await _rename(name);
      case ProjectMenuChoice.delete:
        await _deleteProject(name, tasks);
      case null:
        break;
    }
  }

  Future<void> _rename(String name) {
    final words = AppLocalizations.of(context);
    return askProjectName(
      context,
      title: words.renameProject,
      button: words.renameSave,
      initial: name,
      save: (name) async =>
          switch (await _tasks.renameProject(widget.projectId, name)) {
            Success() => WriteOutcome.done,
            Failure(:final error) => _outcome(error),
          },
    );
  }

  Future<void> _deleteProject(String name, List<Task> tasks) async {
    final words = AppLocalizations.of(context);
    final sure = await confirmDelete(
      context,
      title: words.delProjTitle(name),
      body: deleteProjectBody(
        words,
        tasks: tasks.length,
        minutes: tasks.fold(0, (sum, t) => sum + t.cumulativeFocusMinutes),
      ),
      button: words.deleteProject,
    );
    if (!sure) return;
    final deleted = await _tasks.deleteProject(widget.projectId);
    if (!mounted) return;
    switch (deleted) {
      case Success():
        _leave();
      case Failure(:final error):
        setState(
          () => _projectLine = _outcome(error) == WriteOutcome.locked
              ? words.lockProject
              : words.error,
        );
    }
  }

  /// Back to Work, once: the project is gone.
  void _leave() {
    if (_gone) return;
    _gone = true;
    Navigator.of(context).pop();
  }

  /// Enter adds the typed title as a to-do task and keeps the field ready
  /// for the next (spec §8.8).
  Future<void> _add() async {
    final title = _newTask.text.trim();
    if (title.isEmpty || _adding) return;
    _adding = true;
    final added = await _tasks.createTask(
      projectId: widget.projectId,
      title: title,
    );
    _adding = false;
    if (!mounted) return;
    setState(() {
      _addFailed = added is Failure;
      if (!_addFailed) _newTask.clear();
    });
  }

  void _clearLines() {
    if (_rowLine != null || _projectLine != null) {
      setState(() {
        _rowLine = null;
        _projectLine = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    ref.watch(petStandingProvider);
    _wakeAtBlockEnd();

    final summaries = ref.watch(projectSummariesProvider).value;
    final mine = summaries
        ?.where((s) => s.project.id == widget.projectId)
        .firstOrNull;
    if (mine != null) _listed = true;
    if (_listed && summaries != null && mine == null && !_gone) {
      // Deleted while open: there is nothing here any more. (A project just
      // made may not be listed yet; it has to be seen before it can go.)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _leave();
      });
    }
    final name = mine?.project.name ?? widget.name;
    final live = _live = ref
        .watch(projectTasksProvider(widget.projectId))
        .value;
    final held = _held;
    // While a row is held, the list keeps its old order and groups.
    final order = held?.before ?? live;
    Task shown(Task task) => held?.changed[task.id] ?? task;
    final tasks = order?.map(shown).toList();
    final running = _runningTaskId();

    final header = _ProjectHeader(
      name: name,
      counts: tasks == null
          ? ''
          : projectCounts(
              words,
              open: tasks.where((t) => t.status != TaskStatus.done).length,
              done: tasks.where((t) => t.status == TaskStatus.done).length,
            ),
      onMore: tasks == null ? null : () => _projectMenu(name, tasks),
    );

    final addField = SlidingItem(
      key: const ValueKey('add'),
      id: 'add',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PixelTextField(
            controller: _newTask,
            focusNode: _newTaskFocus,
            hint: words.addTask,
            restingIcon: IconName.plus,
            maxLines: 1,
            staysOpen: true,
            inputFormatters: [
              LengthLimitingTextInputFormatter(maxTaskTitleLength),
            ],
            onSubmitted: (_) => _add(),
          ),
          if (_addFailed) ...[SizedBox(height: u(3)), SunkenLine(words.error)],
        ],
      ),
    );

    Widget row(Task task) {
      final line = _rowLine;
      return SlidingItem(
        key: ValueKey(task.id),
        id: task.id,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TaskListRow(
              task: task,
              running: task.id == running,
              onRing: () => _ring(task),
              onOpen: () => openTaskDetail(context, task),
              onMenu: () => _menu(task),
            ),
            if (line != null && line.taskId == task.id) ...[
              SizedBox(height: u(3)),
              SunkenLine(line.text),
            ],
          ],
        ),
      );
    }

    // One list whatever the state, so the add field keeps its place, and
    // the keyboard, when the first task arrives.
    final open = [
      for (final t in order ?? const <Task>[])
        if (t.status != TaskStatus.done) shown(t),
    ];
    final done = [
      for (final t in order ?? const <Task>[])
        if (t.status == TaskStatus.done) shown(t),
    ];
    final list = SlidingColumn(
      gap: u(3),
      step: u(1),
      slide: _slide,
      armed: _arm,
      onArmed: _slideHome,
      children: [
        if (tasks != null && tasks.isEmpty)
          SlidingItem(
            key: const ValueKey('empty'),
            id: 'empty',
            child: EmptyCard(
              icon: IconName.todo,
              title: words.emptyProjectTitle(name),
              line: words.emptyProject,
            ),
          )
        else if (tasks != null && open.isEmpty)
          SlidingItem(
            key: const ValueKey('allDone'),
            id: 'allDone',
            child: SunkenLine(words.allDone(name), icon: IconName.done),
          ),
        for (final task in open) row(task),
        if (tasks != null) addField,
        for (final task in done) row(task),
      ],
    );

    return ColoredBox(
      color: colours.ground,
      child: Listener(
        onPointerDown: (_) => _clearLines(),
        child: NotificationListener<ScrollStartNotification>(
          onNotification: (_) {
            _clearLines();
            return false;
          },
          child: ScreenBody(
            content: [
              header,
              if (_projectLine != null) SunkenLine(_projectLine!),
              list,
            ],
          ),
        ),
      ),
    );
  }
}

/// Back, the project's name and its tasks counted, and ⋯. The icons' targets
/// reach into the screen's margins, so the icons line up with the rows.
class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({
    required this.name,
    required this.counts,
    required this.onMore,
  });

  final String name;
  final String counts;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => OverflowBox(
        fit: OverflowBoxFit.deferToChild,
        minWidth: constraints.maxWidth + u(12),
        maxWidth: constraints.maxWidth + u(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PixelIconButton(
              icon: PixelIcon(IconName.back, colour: colours.ink),
              semanticLabel: words.back,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            SizedBox(width: u(4)),
            Expanded(
              child: Padding(
                // The name's first line sits level with the icons.
                padding: EdgeInsets.only(top: u(2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PixelText(name, step: TypeStep.title),
                    PixelText(
                      counts,
                      step: TypeStep.caption,
                      colour: colours.muted,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: u(4)),
            PixelIconButton(
              icon: PixelIcon(IconName.more, colour: colours.ink),
              semanticLabel: words.projectOptions,
              onPressed: onMore,
            ),
          ],
        ),
      ),
    );
  }
}
