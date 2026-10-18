import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/focus/quiet_clock.dart';

import '../app/providers.dart';
import '../l10n/app_localizations.dart';
import '../ui/buttons.dart';
import '../ui/pixel_box.dart';
import '../ui/progress_line.dart';
import '../ui/sharp_text.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';

/// Focus's quiet clock and the line under it (spec §8.4, ADR-0010): "about
/// 19 min left" in muted text, then the 2-UI-pixel progress line.
///
/// A tap shows the exact `mm:ss` in ink for 5 s, then rough minutes again.
/// To a screen reader it is one button, read in rough minutes when touched
/// and never announced on its own (§12): its label changes quietly.
class QuietClock extends ConsumerStatefulWidget {
  const QuietClock({
    super.key,
    required this.start,
    required this.end,
    required this.task,
    this.rest = false,
  });

  /// When the block or the break began and when it runs out.
  final DateTime start;
  final DateTime end;

  /// The task's title, for the screen reader.
  final String task;

  /// A break: "of rest left", and the muted line.
  final bool rest;

  /// How long a tap shows the exact time.
  static const exactFor = Duration(seconds: 5);

  @override
  ConsumerState<QuietClock> createState() => _QuietClockState();
}

class _QuietClockState extends ConsumerState<QuietClock> {
  Timer? _wake;
  DateTime? _exactUntil;

  DateTime _now() => ref.read(databaseProvider).clock();

  @override
  void dispose() {
    _wake?.cancel();
    super.dispose();
  }

  void _showExact() =>
      setState(() => _exactUntil = _now().add(QuietClock.exactFor));

  /// Wakes when what shows next changes: each second of the exact time, or
  /// the next change of the rough minutes or the line, whichever is first.
  void _wakeAfter(DateTime now, int linePixels) {
    _wake?.cancel();
    final exactUntil = _exactUntil;
    final candidates = <DateTime>[
      if (exactUntil != null && now.isBefore(exactUntil))
        _nextWholeSecond(now)
      else if (exactUntil != null)
        now,
      ?nextRoughChange(now: now, end: widget.end),
      ?_nextLineStep(now, linePixels),
    ];
    if (candidates.isEmpty) return;
    final next = candidates.reduce((a, b) => a.isBefore(b) ? a : b);
    _wake = Timer(next.difference(now), () {
      if (!mounted) return;
      setState(() {
        final until = _exactUntil;
        if (until != null && !_now().isBefore(until)) _exactUntil = null;
      });
    });
  }

  /// The next instant the exact time reads a different second.
  DateTime _nextWholeSecond(DateTime now) {
    final left = widget.end.difference(now);
    final intoSecond = left.inMicroseconds % Duration.microsecondsPerSecond;
    return now.add(
      Duration(
        microseconds: intoSecond == 0
            ? Duration.microsecondsPerSecond
            : intoSecond,
      ),
    );
  }

  /// The next instant the line grows by a UI pixel, out of [pixels].
  DateTime? _nextLineStep(DateTime now, int pixels) {
    if (pixels <= 0 || !now.isBefore(widget.end)) return null;
    final whole = widget.end.difference(widget.start).inMicroseconds;
    final lit =
        (progressBetween(start: widget.start, end: widget.end, now: now) *
                    pixels +
                1e-9)
            .floor();
    if (lit >= pixels) return null;
    final at = widget.start.add(
      Duration(microseconds: ((lit + 1) * whole / pixels).ceil()),
    );
    return at.isAfter(now) ? at : now.add(const Duration(milliseconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final now = _now();
    final left = widget.end.difference(now);
    final rough = roughMinutes(left);
    final exactUntil = _exactUntil;
    final exact = exactUntil != null && now.isBefore(exactUntil);

    final shown = switch ((widget.rest, rough)) {
      (false, null) => words.clockUnderMinute,
      (false, final minutes?) => words.clockLeft(minutes),
      (true, null) => words.restUnderMinute,
      (true, final minutes?) => words.restLeft(minutes),
    };
    final spoken = switch ((widget.rest, rough)) {
      (false, null) => words.srClockUnderMinute(widget.task),
      (false, final minutes?) => words.srClock(minutes, widget.task),
      (true, null) => words.srRestUnderMinute,
      (true, final minutes?) => words.srRest(minutes),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        _wakeAfter(now, (constraints.maxWidth / u.pt + 1e-9).floor());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Pressable(
                onPressed: _showExact,
                semanticLabel: spoken,
                builder: (context, pressed, ring) => PixelBox(
                  fill: pressed ? colours.sunken : null,
                  ring: ring ? colours.accent : null,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: u.target,
                      minWidth: u.target,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: u(6)),
                      child: Center(
                        widthFactor: 1,
                        child: ExcludeSemantics(
                          child: exact
                              ? PixelText.number(
                                  exactTimeLeft(
                                    Duration(
                                      microseconds: math.max(
                                        0,
                                        left.inMicroseconds,
                                      ),
                                    ),
                                  ),
                                )
                              : PixelText(
                                  shown,
                                  colour: colours.muted,
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: u(6)),
            ProgressLine(
              progress: progressBetween(
                start: widget.start,
                end: widget.end,
                now: now,
              ),
              rest: widget.rest,
            ),
          ],
        );
      },
    );
  }
}
