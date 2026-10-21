import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task.dart';

import '../app/providers.dart';
import '../app/routes.dart';
import '../l10n/app_localizations.dart';
import '../ui/buttons.dart';
import '../ui/pixel_box.dart';
import '../ui/pixel_icon.dart';
import '../ui/rows.dart';
import '../ui/screen_body.dart';
import '../ui/sharp_text.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import 'project_screen.dart';
import 'work_lists.dart';
import 'work_sheets.dart';
import 'work_words.dart';

/// The Work tab (spec §8.8): "Work" and + for a new project, then every
/// project, the most recently active first, each with its tasks counted
/// and a chevron to open it. No progress bar. With no projects left, a card
/// that explains and offers *New project*.
class WorkScreen extends ConsumerWidget {
  const WorkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final summaries = ref.watch(projectSummariesProvider).value;

    final header = _RootHeader(
      title: words.workTitle,
      action: PixelIconButton(
        icon: PixelIcon(IconName.plus, colour: colours.ink),
        semanticLabel: words.newProject,
        onPressed: () => newProject(context, ref),
      ),
    );

    return ColoredBox(
      color: colours.ground,
      child: ScreenBody(
        content: [
          header,
          if (summaries == null)
            const SizedBox.shrink()
          else if (summaries.isEmpty)
            EmptyCard(
              icon: IconName.workClip,
              title: words.emptyProjectsTitle,
              line: words.emptyProjects,
              action: PixelButton(
                label: words.newProject,
                wide: true,
                onPressed: () => newProject(context, ref),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: ScreenBody.spaced(context, [
                for (final summary in summaries)
                  PixelRow(
                    title: summary.project.name,
                    subtitle: projectCounts(
                      words,
                      open: summary.open,
                      done: summary.done,
                    ),
                    onTap: () => openProject(context, summary.project),
                    trailing: [
                      SizedBox.square(
                        dimension: u.target,
                        child: Center(
                          child: PixelIcon(
                            IconName.next,
                            colour: colours.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
              ], 3),
            ),
        ],
      ),
    );
  }
}

/// *New project*: asks for a name on a sheet, makes the project and opens
/// it.
Future<void> newProject(BuildContext context, WidgetRef ref) {
  final words = AppLocalizations.of(context);
  return askProjectName(
    context,
    title: words.newProject,
    button: words.createProject,
    save: (name) async {
      final made = await ref.read(taskServiceProvider).createProject(name);
      switch (made) {
        case Success(:final value):
          if (context.mounted) openProject(context, value);
          return WriteOutcome.done;
        case Failure():
          return WriteOutcome.failed;
      }
    },
  );
}

/// Pushes [project]'s screen onto the Work tab's stack.
void openProject(BuildContext context, Project project) => pushInTab(
  context,
  (_) => ProjectScreen(projectId: project.id, name: project.name),
);

/// A tab root's header: its title, and one icon button at the right whose
/// target reaches into the screen's margin, so the icon lines up with the
/// edge of the rows below.
class _RootHeader extends StatelessWidget {
  const _RootHeader({required this.title, required this.action});

  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final u = UiPixel.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => OverflowBox(
        fit: OverflowBoxFit.deferToChild,
        alignment: AlignmentDirectional.centerStart,
        minWidth: constraints.maxWidth + u(6),
        maxWidth: constraints.maxWidth + u(6),
        child: Row(
          children: [
            Expanded(
              child: PixelText(title, step: TypeStep.title, header: true),
            ),
            SizedBox(width: u(4)),
            action,
          ],
        ),
      ),
    );
  }
}

/// An empty state (spec §8.8): a surface card with the 2× icon, a title,
/// one line and, when it has one, the one thing to do.
class EmptyCard extends StatelessWidget {
  const EmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.line,
    this.action,
  });

  final IconName icon;
  final String title;
  final String line;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return PixelBox(
      fill: colours.surface,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: u(10), vertical: u(14)),
        child: Column(
          children: ScreenBody.spaced(context, [
            PixelIcon(icon, colour: colours.muted, scale: 2),
            PixelText(
              title,
              step: TypeStep.title,
              header: true,
              textAlign: TextAlign.center,
            ),
            PixelText(line, colour: colours.muted, textAlign: TextAlign.center),
            if (action != null) SizedBox(width: double.infinity, child: action),
          ], 6),
        ),
      ),
    );
  }
}
