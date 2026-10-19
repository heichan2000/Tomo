import 'package:flutter/widgets.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_status.dart';

import '../l10n/app_localizations.dart';
import '../ui/buttons.dart';
import '../ui/pixel_icon.dart';
import '../ui/rows.dart';
import '../ui/tomo_theme.dart';
import 'work_words.dart';

/// A task in a project's list (spec §8.8): the status ring (a 48 pt
/// target), the title, its blocks in words, the *Doing* chip (the accent
/// *Focus* chip while its block runs), and ⋯. A done task's title is muted.
///
/// Tapping the ring marks it done, or reopens it; tapping the row opens the
/// task; a long press, or ⋯, opens the row menu.
class TaskListRow extends StatelessWidget {
  const TaskListRow({
    super.key,
    required this.task,
    required this.running,
    required this.onRing,
    required this.onOpen,
    required this.onMenu,
  });

  final Task task;

  /// Its block is running now.
  final bool running;

  final VoidCallback onRing;
  final VoidCallback onOpen;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final done = task.status == TaskStatus.done;
    return PixelRow(
      title: task.title,
      subtitle: taskMeta(words, task),
      mutedTitle: done,
      onTap: onOpen,
      onLongPress: onMenu,
      leading: PixelIconButton(
        icon: StatusGlyph(task.status),
        semanticLabel: done
            ? words.srRingReopen
            : words.srRingMarkDone(statusName(words, task.status)),
        onPressed: onRing,
      ),
      trailing: [
        if (running)
          PixelChip(words.chipFocus, tone: ChipTone.accent)
        else if (task.status == TaskStatus.doing)
          PixelChip(words.statusDoing),
        PixelIconButton(
          icon: PixelIcon(IconName.more, colour: colours.muted),
          semanticLabel: words.taskOptions,
          onPressed: onMenu,
        ),
      ],
    );
  }
}
