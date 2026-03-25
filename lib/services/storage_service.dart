import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/revision_item.dart';

class StorageService {
  static const String itemsKey = 'smart_revision_items_v2';
  static const String statsKey = 'smart_revision_stats_v2';
  static const String themeKey = 'smart_revision_theme_v2';
  static const String remindersKey = 'smart_revision_reminders_v2';

  Future<void> saveReminders(List<dynamic> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = reminders.map((r) => jsonEncode(r.toMap())).toList();
    await prefs.setStringList(remindersKey, jsonList);
  }

  Future<List<Map<String, dynamic>>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(remindersKey) ?? [];
    return jsonList.map((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>).toList();
  }

  Future<void> saveItems(List<RevisionItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((t) => jsonEncode(t.toMap())).toList();
    await prefs.setStringList(itemsKey, jsonList);
  }

  Future<List<RevisionItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(itemsKey) ?? [];
    return jsonList.map((jsonStr) => RevisionItem.fromMap(jsonDecode(jsonStr))).toList();
  }

  Future<void> saveTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(themeKey, isDarkMode);
  }

  Future<bool> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(themeKey) ?? true; // Default to dark mode
  }

  Future<void> saveStats(Map<String, dynamic> stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(statsKey, jsonEncode(stats));
  }

  Future<Map<String, dynamic>> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(statsKey);
    if (jsonStr != null) {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    }
    return {'streak': 0, 'points': 0, 'intervals': '1,3,7,14'};
  }
}
