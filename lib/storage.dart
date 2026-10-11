import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/work_model.dart';

class WorkStorage {
  static const String _keyHourlyRate = 'hourly_rate';
  static const String _keyWorkLogs = 'work_logs';

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
      // Return empty list if there's any corruption or formatting change
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
    // Sort logs by date descending so newer items come first
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
}
