/// Which of an egg's pictures shows during a running block (spec §7.2).
///
/// An egg has [pictures] drawings: whole (0), then one per crack step. They
/// share the block equally, so the last share shows the eyes peeking out.
/// The answer is worked out from the block's [elapsedMinutes] every time and
/// stored nowhere, which is why stopping early leaves the egg whole.
int eggPicture({
  required int pictures,
  required int focusMinutes,
  required int elapsedMinutes,
}) => (elapsedMinutes * pictures ~/ focusMinutes).clamp(0, pictures - 1);
