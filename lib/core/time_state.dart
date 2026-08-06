/// Resolves the current time-of-day quote category from a [DateTime].
/// Categories cover the full day so there is always exactly one match.
class TimeState {
  static String categoryFor(DateTime now) {
    final hour = now.hour;
    if (hour < 6) return 'DAWN';
    if (hour < 9) return 'MORNING';
    if (hour < 12) return 'LATE_MORNING';
    if (hour < 13) return 'NOON';
    if (hour < 18) return 'AFTERNOON';
    if (hour < 21) return 'EVENING';
    return 'NIGHT';
  }
}
