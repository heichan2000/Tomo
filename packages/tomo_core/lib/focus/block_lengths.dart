/// Block and break length (spec §4.7).
library;

const minFocusMinutes = 10;
const maxFocusMinutes = 120;

/// How far one tap of the Custom sheet's Focus stepper moves.
const focusMinutesStep = 5;

const minBreakMinutes = 1;
const maxBreakMinutes = 30;

/// Whether a focus block may be [minutes] long.
bool isValidFocusMinutes(int minutes) =>
    minutes >= minFocusMinutes && minutes <= maxFocusMinutes;

/// Whether a break may be [minutes] long.
bool isValidBreakMinutes(int minutes) =>
    minutes >= minBreakMinutes && minutes <= maxBreakMinutes;

/// [minutes] after one tap of the Focus stepper: the next multiple of five in
/// that direction, held within the limits.
int focusMinutesAfterStep(int minutes, {required bool up}) {
  final stepped = up
      ? (minutes ~/ focusMinutesStep + 1) * focusMinutesStep
      : ((minutes - 1) ~/ focusMinutesStep) * focusMinutesStep;
  return stepped.clamp(minFocusMinutes, maxFocusMinutes);
}

/// [minutes] after one tap of the Break stepper, held within the limits.
int breakMinutesAfterStep(int minutes, {required bool up}) =>
    (up ? minutes + 1 : minutes - 1).clamp(minBreakMinutes, maxBreakMinutes);

/// Which of Ready's three chips a pair of lengths is.
enum LengthChoice { preset25, preset50, custom }

/// A focus length and the break that goes with it.
final class BlockLengths {
  const BlockLengths({required this.focusMinutes, required this.breakMinutes});

  final int focusMinutes;
  final int breakMinutes;

  static const preset25 = BlockLengths(focusMinutes: 25, breakMinutes: 5);
  static const preset50 = BlockLengths(focusMinutes: 50, breakMinutes: 10);

  /// What onboarding starts with. It shows as Custom.
  static const firstEver = BlockLengths(focusMinutes: 15, breakMinutes: 5);

  /// A pair equal to a preset shows as that preset; anything else is Custom.
  LengthChoice get choice => switch (this) {
    preset25 => LengthChoice.preset25,
    preset50 => LengthChoice.preset50,
    _ => LengthChoice.custom,
  };

  @override
  bool operator ==(Object other) =>
      other is BlockLengths &&
      other.focusMinutes == focusMinutes &&
      other.breakMinutes == breakMinutes;

  @override
  int get hashCode => Object.hash(focusMinutes, breakMinutes);
}
