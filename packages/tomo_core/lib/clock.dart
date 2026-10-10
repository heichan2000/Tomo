/// Tells the time. Injected everywhere a rule needs "now", so tests can set it.
typedef Clock = DateTime Function();

/// The phone's own clock.
DateTime systemClock() => DateTime.now();
