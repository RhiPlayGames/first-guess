class DailyFlashScheduleService {
  DailyFlashScheduleService._();

  static const int releaseHourUk = 16;

  /// Returns the Daily Flash content key currently active in the UK.
  ///
  /// A dated set becomes active at 16:00 Europe/London time and remains
  /// active until 15:59:59 on the following UK calendar day.
  static String activeDateKey({DateTime? nowUtc}) {
    final DateTime utcNow = (nowUtc ?? DateTime.now()).toUtc();
    final DateTime ukNow = _toUkTime(utcNow);

    DateTime activeDate = DateTime(
      ukNow.year,
      ukNow.month,
      ukNow.day,
    );

    if (ukNow.hour < releaseHourUk) {
      activeDate = activeDate.subtract(const Duration(days: 1));
    }

    return _dateKey(activeDate);
  }

  /// Time remaining until the next 16:00 Europe/London release.
  static Duration timeUntilNextRelease({DateTime? nowUtc}) {
    final DateTime utcNow = (nowUtc ?? DateTime.now()).toUtc();
    final DateTime ukNow = _toUkTime(utcNow);

    DateTime targetLocalDate = DateTime(
      ukNow.year,
      ukNow.month,
      ukNow.day,
    );

    if (ukNow.hour >= releaseHourUk) {
      targetLocalDate = targetLocalDate.add(const Duration(days: 1));
    }

    final DateTime targetUtc = _ukLocalFourPmToUtc(targetLocalDate);
    final Duration remaining = targetUtc.difference(utcNow);

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// The next Daily Flash release instant in UTC.
  static DateTime nextReleaseUtc({DateTime? nowUtc}) {
    final DateTime utcNow = (nowUtc ?? DateTime.now()).toUtc();
    final DateTime ukNow = _toUkTime(utcNow);

    DateTime targetLocalDate = DateTime(
      ukNow.year,
      ukNow.month,
      ukNow.day,
    );

    if (ukNow.hour >= releaseHourUk) {
      targetLocalDate = targetLocalDate.add(const Duration(days: 1));
    }

    return _ukLocalFourPmToUtc(targetLocalDate);
  }

  static DateTime _toUkTime(DateTime utc) {
    final bool bst = _isBritishSummerTimeUtc(utc);
    return utc.add(Duration(hours: bst ? 1 : 0));
  }

  static DateTime _ukLocalFourPmToUtc(DateTime localDate) {
    final bool bstAtFourPm = _isBstDateAtFourPm(localDate);
    return DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
      releaseHourUk - (bstAtFourPm ? 1 : 0),
    );
  }

  /// UK daylight saving starts at 01:00 UTC on the last Sunday in March
  /// and ends at 01:00 UTC on the last Sunday in October.
  static bool _isBritishSummerTimeUtc(DateTime utc) {
    final int year = utc.year;
    final DateTime start = DateTime.utc(
      year,
      3,
      _lastSundayOfMonth(year, 3),
      1,
    );
    final DateTime end = DateTime.utc(
      year,
      10,
      _lastSundayOfMonth(year, 10),
      1,
    );

    return !utc.isBefore(start) && utc.isBefore(end);
  }

  /// At 16:00 UK time, the DST transition on either changeover Sunday
  /// has already happened. March's last Sunday is therefore BST, while
  /// October's last Sunday is GMT.
  static bool _isBstDateAtFourPm(DateTime localDate) {
    final int year = localDate.year;
    final DateTime startDate = DateTime(
      year,
      3,
      _lastSundayOfMonth(year, 3),
    );
    final DateTime endDate = DateTime(
      year,
      10,
      _lastSundayOfMonth(year, 10),
    );
    final DateTime dateOnly = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );

    return !dateOnly.isBefore(startDate) && dateOnly.isBefore(endDate);
  }

  static int _lastSundayOfMonth(int year, int month) {
    final DateTime firstOfNextMonth = month == 12
        ? DateTime.utc(year + 1, 1, 1)
        : DateTime.utc(year, month + 1, 1);
    final DateTime lastDay = firstOfNextMonth.subtract(const Duration(days: 1));
    return lastDay.day - (lastDay.weekday % 7);
  }

  static String _dateKey(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
