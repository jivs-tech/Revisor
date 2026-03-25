import 'package:flutter/material.dart';
import '../models/revision_item.dart';
import '../models/reminder_item.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  List<RevisionItem> _items = [];
  List<ReminderItem> _reminders = [];
  List<int> _intervals = [1, 3, 7, 14, 30, 60, 90];
  int _streak = 0;
  int _points = 0;
  bool _isLoading = true;
  bool _isDarkMode = true;
  bool _hasIntroPlayed = false;

  List<RevisionItem> get items => _items;
  List<ReminderItem> get reminders => _reminders;
  List<int> get intervals => _intervals;
  bool get isLoading => _isLoading;
  int get points => _points;
  bool get isDarkMode => _isDarkMode;
  bool get hasIntroPlayed => _hasIntroPlayed;

  void setIntroPlayed() {
    _hasIntroPlayed = true;
    notifyListeners();
  }

  // Smart Bunches (Virtual views based on accuracy)
  List<RevisionItem> get needsRevisionItems => _items.where((item) {
    if (item.stats.attempts == 0) return false;
    double accuracy = (item.stats.successfulRecalls / item.stats.attempts) * 100;
    return accuracy < 40;
  }).toList();

  List<RevisionItem> get keepGoingItems => _items.where((item) {
    if (item.stats.attempts == 0) return false; 
    double accuracy = (item.stats.successfulRecalls / item.stats.attempts) * 100;
    return accuracy >= 40 && accuracy <= 90;
  }).toList();

  List<RevisionItem> get masteredItems => _items.where((item) {
    if (item.stats.attempts == 0) return false;
    double accuracy = (item.stats.successfulRecalls / item.stats.attempts) * 100;
    return accuracy > 90;
  }).toList();

  int get streak {
    if (_items.isEmpty) return 0;
    
    // Get all unique study dates (normalized to year-month-day)
    final studyDates = _items
        .expand((item) => item.revisionHistory)
        .map((d) => DateTime(d.date.year, d.date.month, d.date.day))
        .toSet()
        .toList();
    
    if (studyDates.isEmpty) return 0;
    
    studyDates.sort((a, b) => b.compareTo(a)); // Newest first
    
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    DateTime yesterday = today.subtract(const Duration(days: 1));
    
    // If they haven't studied today OR yesterday, the streak is broken (0).
    // Actually, if they haven't studied today yet, yesterday's streak might still be active.
    if (!studyDates.contains(today) && !studyDates.contains(yesterday)) {
      return 0;
    }
    
    int currentStreak = 0;
    DateTime checkDate = studyDates.contains(today) ? today : yesterday;
    
    while (studyDates.contains(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    return currentStreak;
  }

  AppState() {
    _loadData();
  }

  Future<void> _loadData() async {
    _items = await _storageService.loadItems();
    final stats = await _storageService.loadStats();
    _streak = stats['streak'] ?? 0;
    _points = stats['points'] ?? 0;
    _isDarkMode = await _storageService.loadTheme();
    
    final reminderData = await _storageService.loadReminders();
    _reminders = reminderData.map((m) => ReminderItem.fromMap(m)).toList();
    
    List<int> loadedIntervals = (stats['intervals'] as String?)?.split(',').where((e) => e.isNotEmpty).map((e) => int.parse(e)).toList() ?? [1, 3, 7, 14, 30, 60, 90];
    _intervals = loadedIntervals;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _storageService.saveTheme(_isDarkMode);
  }

  Future<void> updateIntervals(List<int> newIntervals) async {
    _intervals = newIntervals;
    notifyListeners();
    await _storageService.saveStats({'streak': _streak, 'points': _points, 'intervals': _intervals.join(',')});
  }

  Future<void> addItem(RevisionItem item) async {
    _items.add(item);
    notifyListeners();
    await _storageService.saveItems(_items);
    await _scheduleRevisionNotification(item);
  }

  Future<void> updateItem(RevisionItem updatedItem) async {
    final index = _items.indexWhere((t) => t.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      notifyListeners();
      await _storageService.saveItems(_items);
      await _scheduleRevisionNotification(updatedItem);
    }
  }

  Future<void> _scheduleRevisionNotification(RevisionItem item) async {
    if (item.nextRevisionDate.isAfter(DateTime.now())) {
      // Use a consistent hash-based ID for revision items to avoid collision with reminders (which use timestamps)
      final int notificationId = item.id.hashCode.abs();
      await NotificationService().scheduleNotification(
        notificationId,
        "Time to Revise: ${item.title}",
        "Keep your streak alive! Review this ${item.type} now.",
        item.nextRevisionDate,
      );
    }
  }

  Future<void> updateItems(List<RevisionItem> updatedItems) async {
    for (var updated in updatedItems) {
      final index = _items.indexWhere((t) => t.id == updated.id);
      if (index != -1) {
         _items[index] = updated;
      }
    }
    notifyListeners();
    await _storageService.saveItems(_items);
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((t) => t.id == id);
    notifyListeners();
    await _storageService.saveItems(_items);
    await NotificationService().cancelNotification(id.hashCode.abs());
  }

  Future<void> deleteItemsByFolder(String folderName) async {
    final toDelete = _items.where((t) => t.folder == folderName).toList();
    for (var item in toDelete) {
      await NotificationService().cancelNotification(item.id.hashCode.abs());
    }
    _items.removeWhere((t) => t.folder == folderName);
    notifyListeners();
    await _storageService.saveItems(_items);
  }

  Future<void> addPoints(int earn) async {
    _points += earn;
    notifyListeners();
    await _storageService.saveStats({'streak': _streak, 'points': _points, 'intervals': _intervals.join(',')});
  }

  // Reminder Management
  Future<void> addReminder(ReminderItem reminder) async {
    _reminders.add(reminder);
    notifyListeners();
    await _storageService.saveReminders(_reminders);
    
    // Schedule notification if dateTime is in the future
    if (reminder.dateTime != null && reminder.dateTime!.isAfter(DateTime.now())) {
      await NotificationService().scheduleNotification(
        int.tryParse(reminder.id) ?? 0,
        "Reminder: ${reminder.title}",
        "It's time for your scheduled task!",
        reminder.dateTime!,
      );
    }
  }

  Future<void> updateReminder(ReminderItem updated) async {
    final idx = _reminders.indexWhere((r) => r.id == updated.id);
    if (idx != -1) {
      _reminders[idx] = updated;
      notifyListeners();
      await _storageService.saveReminders(_reminders);
    }
  }

  Future<void> toggleReminder(String id) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reminders[idx].isCompleted = !_reminders[idx].isCompleted;
      notifyListeners();
      await _storageService.saveReminders(_reminders);
    }
  }

  Future<void> toggleImportance(String id) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reminders[idx].isImportant = !_reminders[idx].isImportant;
      notifyListeners();
      await _storageService.saveReminders(_reminders);
    }
  }

  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
    await _storageService.saveReminders(_reminders);
    await NotificationService().cancelNotification(int.tryParse(id) ?? 0);
  }

  double get reminderCompletionProgress {
    if (_reminders.isEmpty) return 0.0;
    int completed = _reminders.where((r) => r.isCompleted).length;
    return completed / _reminders.length;
  }

  // Returns all unique bunch names, including smart ones
  List<String> getUniqueBunches() {
    final userFolders = _items
        .map((i) => i.folder)
        .where((f) => f != null && f!.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    
    return [
      "All Flashcards",
      "Needs Revision",
      "Keep Going",
      "Already Mastered",
      ...userFolders,
    ];
  }
}
