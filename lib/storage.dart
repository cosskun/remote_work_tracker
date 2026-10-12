import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/work_model.dart';
import 'utils/holiday_helper.dart';

class WorkStorage {
  static const String _keyHourlyRate = 'hourly_rate';
  static const String _keyWorkLogs = 'work_logs';
  static const String _keyAutoAddOffice = 'auto_add_office_enabled';

  // Get saved hourly rate (defaults to 150.0 if not set)
  static Future<double> getHourlyRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyHourlyRate) ?? 150.0;
  }

  // Save hourly rate
  static Future<bool> setHourlyRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setDouble(_keyHourlyRate, rate);
  }

  // Check if auto-add office work is enabled (default: true)
  static Future<bool> isAutoAddOfficeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoAddOffice) ?? true;
  }

  // Set auto-add office work enabled
  static Future<bool> setAutoAddOfficeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_keyAutoAddOffice, enabled);
  }

  // Get all saved work logs
  static Future<List<WorkLog>> getWorkLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? logsJson = prefs.getString(_keyWorkLogs);
    if (logsJson == null || logsJson.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(logsJson) as List<dynamic>;
      return decoded
          .map((item) => WorkLog.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Save all work logs
  static Future<bool> saveWorkLogs(List<WorkLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> mapped = logs.map((log) => log.toJson()).toList();
    return prefs.setString(_keyWorkLogs, jsonEncode(mapped));
  }

  // Add a single log
  static Future<List<WorkLog>> addWorkLog(WorkLog log) async {
    final logs = await getWorkLogs();
    logs.add(log);
    logs.sort((a, b) => b.date.compareTo(a.date));
    await saveWorkLogs(logs);
    return logs;
  }

  // Delete a single log by id
  static Future<List<WorkLog>> deleteWorkLog(String id) async {
    final logs = await getWorkLogs();
    logs.removeWhere((item) => item.id == id);
    await saveWorkLogs(logs);
    return logs;
  }

  // Update a single log
  static Future<List<WorkLog>> updateWorkLog(WorkLog updatedLog) async {
    final logs = await getWorkLogs();
    final index = logs.indexWhere((item) => item.id == updatedLog.id);
    if (index != -1) {
      logs[index] = updatedLog;
      await saveWorkLogs(logs);
    }
    return logs;
  }

  // Auto-populate office logs for official business days in date range
  static Future<int> autoPopulateOfficialWorkdays({
    required DateTime startDate,
    required DateTime endDate,
    required double currentHourlyRate,
  }) async {
    final currentLogs = await getWorkLogs();
    final List<WorkLog> updatedLogs = List.from(currentLogs);
    int addedCount = 0;

    DateTime cur = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (!cur.isAfter(end)) {
      if (HolidayHelper.isOfficialWorkday(cur)) {
        final bool exists = updatedLogs.any((l) =>
            l.title == 'OFİSTEN ÇALIŞMA' &&
            l.date.year == cur.year &&
            l.date.month == cur.month &&
            l.date.day == cur.day);

        if (!exists) {
          // Historical rate logic: prior to 16.01.2026 was 600.0, thereafter is current rate (825.0)
          final double rate = cur.isBefore(DateTime(2026, 1, 16)) ? 600.0 : currentHourlyRate;
          updatedLogs.add(WorkLog(
            id: 'auto_office_${cur.year}_${cur.month}_${cur.day}',
            title: 'OFİSTEN ÇALIŞMA',
            date: cur,
            durationMinutes: 510, // 8.5 hours
            category: 'Ofis',
            hourlyRate: rate,
          ));
          addedCount++;
        }
      }
      cur = cur.add(const Duration(days: 1));
    }

    if (addedCount > 0) {
      updatedLogs.sort((a, b) => b.date.compareTo(a.date));
      await saveWorkLogs(updatedLogs);
    }
    return addedCount;
  }
}
