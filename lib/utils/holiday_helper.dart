class HolidayHelper {
  // Fixed official holidays in Turkey (month-day)
  static final Map<String, String> _fixedHolidays = {
    '01-01': 'Yılbaşı',
    '04-23': 'Ulusal Egemenlik ve Çocuk Bayramı',
    '05-01': 'Emek ve Dayanışma Günü',
    '05-19': 'Atatürk\'ü Anma, Gençlik ve Spor Bayramı',
    '07-15': 'Demokrasi ve Milli Birlik Günü',
    '08-30': 'Zafer Bayramı',
    '10-29': 'Cumhuriyet Bayramı',
  };

  // Variable / religious holidays (year-month-day)
  static final Map<String, String> _variableHolidays = {
    // 2025
    '2025-03-30': 'Ramazan Bayramı 1. Gün',
    '2025-03-31': 'Ramazan Bayramı 2. Gün',
    '2025-04-01': 'Ramazan Bayramı 3. Gün',
    '2025-06-06': 'Kurban Bayramı 1. Gün',
    '2025-06-07': 'Kurban Bayramı 2. Gün',
    '2025-06-08': 'Kurban Bayramı 3. Gün',
    '2025-06-09': 'Kurban Bayramı 4. Gün',
    // 2026
    '2026-03-20': 'Ramazan Bayramı 1. Gün',
    '2026-03-21': 'Ramazan Bayramı 2. Gün',
    '2026-03-22': 'Ramazan Bayramı 3. Gün',
    '2026-05-27': 'Kurban Bayramı 1. Gün',
    '2026-05-28': 'Kurban Bayramı 2. Gün',
    '2026-05-29': 'Kurban Bayramı 3. Gün',
    '2026-05-30': 'Kurban Bayramı 4. Gün',
    // 2027
    '2027-03-10': 'Ramazan Bayramı 1. Gün',
    '2027-03-11': 'Ramazan Bayramı 2. Gün',
    '2027-03-12': 'Ramazan Bayramı 3. Gün',
    '2027-05-16': 'Kurban Bayramı 1. Gün',
    '2027-05-17': 'Kurban Bayramı 2. Gün',
    '2027-05-18': 'Kurban Bayramı 3. Gün',
    '2027-05-19': 'Kurban Bayramı 4. Gün',
  };

  /// Checks if a date is an official Turkish public holiday
  static bool isOfficialHoliday(DateTime date) {
    final keyFixed = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (_fixedHolidays.containsKey(keyFixed)) return true;

    final keyVariable = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (_variableHolidays.containsKey(keyVariable)) return true;

    return false;
  }

  /// Gets the holiday name if the date is an official holiday, or null
  static String? getHolidayName(DateTime date) {
    final keyFixed = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (_fixedHolidays.containsKey(keyFixed)) return _fixedHolidays[keyFixed];

    final keyVariable = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (_variableHolidays.containsKey(keyVariable)) return _variableHolidays[keyVariable];

    return null;
  }

  /// Returns true if the date is Monday-Friday and NOT an official holiday
  static bool isOfficialWorkday(DateTime date) {
    if (date.weekday < DateTime.monday || date.weekday > DateTime.friday) {
      return false; // Weekend
    }
    return !isOfficialHoliday(date);
  }
}
