import 'package:test/test.dart';
import 'package:tomo_core/focus/commands.dart';
import 'package:tomo_core/focus/projection.dart';

/// Which command is legal in which state, and where it leads (spec §4.3).
void main() {
  const idle = FocusState.idle;
  const focusRunning = FocusState.focusRunning;
  const focusComplete = FocusState.focusComplete;
  const breakRunning = FocusState.breakRunning;
  const breakComplete = FocusState.breakComplete;

  // The spec's table, row by row. Null is an illegal pair.
  const table = <FocusState, Map<FocusCommand, FocusState?>>{
    idle: {
      FocusCommand.startBlock: focusRunning,
      FocusCommand.stopEarly: null,
      FocusCommand.takeBreak: null,
      FocusCommand.skipBreak: null,
      FocusCommand.leave: null,
    },
    focusRunning: {
      FocusCommand.startBlock: null,
      FocusCommand.stopEarly: idle,
      FocusCommand.takeBreak: null,
      FocusCommand.skipBreak: null,
      FocusCommand.leave: null,
    },
    focusComplete: {
      FocusCommand.startBlock: focusRunning,
      FocusCommand.stopEarly: null,
      FocusCommand.takeBreak: breakRunning,
      FocusCommand.skipBreak: null,
      FocusCommand.leave: idle,
    },
    breakRunning: {
      FocusCommand.startBlock: focusRunning,
      FocusCommand.stopEarly: null,
      FocusCommand.takeBreak: null,
      FocusCommand.skipBreak: breakComplete,
      FocusCommand.leave: idle,
    },
    breakComplete: {
      FocusCommand.startBlock: focusRunning,
      FocusCommand.stopEarly: null,
      FocusCommand.takeBreak: null,
      FocusCommand.skipBreak: null,
      FocusCommand.leave: idle,
    },
  };

  test('the table covers every state and every command', () {
    expect(table.keys, unorderedEquals(FocusState.values));
    for (final row in table.values) {
      expect(row.keys, unorderedEquals(FocusCommand.values));
    }
  });

  for (final MapEntry(key: state, value: row) in table.entries) {
    for (final MapEntry(key: command, value: target) in row.entries) {
      if (target != null) {
        test('${command.name} in ${state.name} leads to ${target.name}', () {
          expect(isLegal(state, command), isTrue);
          expect(stateAfter(state, command), target);
        });
      } else {
        test('${command.name} in ${state.name} is illegal: it fails loudly in '
            'debug and tests', () {
          expect(isLegal(state, command), isFalse);
          expect(
            () => stateAfter(state, command),
            throwsA(isA<AssertionError>()),
          );
        });
      }
    }
  }

  test('only a running block can be stopped early', () {
    expect(FocusState.values.where((s) => isLegal(s, FocusCommand.stopEarly)), [
      focusRunning,
    ]);
  });

  test('a block can start from anywhere except a running block', () {
    expect(
      FocusState.values.where((s) => !isLegal(s, FocusCommand.startBlock)),
      [focusRunning],
    );
  });
}
