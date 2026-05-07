/// Abstraction around `DateTime.now()` so we can fake time in tests.
abstract class Clock {
  DateTime now();
  DateTime utcNow();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
  @override
  DateTime utcNow() => DateTime.now().toUtc();
}

class FakeClock implements Clock {
  FakeClock(this._now);
  DateTime _now;
  void advance(Duration d) => _now = _now.add(d);
  void setTo(DateTime t) => _now = t;
  @override
  DateTime now() => _now;
  @override
  DateTime utcNow() => _now.toUtc();
}
