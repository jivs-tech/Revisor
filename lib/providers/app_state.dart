import 'package:flutter/material.dart';
import '../models/revision_item.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  List<RevisionItem> _items = [];
  List<int> _intervals = [1, 3, 7, 14, 30, 60, 90];
  int _streak = 0;
  int _points = 0;
  bool _isLoading = true;

  List<RevisionItem> get items => _items;
  List<int> get intervals => _intervals;
  bool get isLoading => _isLoading;
  int get points => _points;

  int get streak {
    if (_items.isEmpty) return 0;
    
    // Get all unique study dates (normalized to year-month-day)
    final studyDates = _items
        .expand((item) => item.revisionHistory)
        .map((d) => DateTime(d.year, d.month, d.day))
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
    
    List<int> loadedIntervals = (stats['intervals'] as String?)?.split(',').where((e) => e.isNotEmpty).map((e) => int.parse(e)).toList() ?? [1, 3, 7, 14, 30, 60, 90];
    _intervals = loadedIntervals;

    _isLoading = false;
    notifyListeners();
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
  }

  Future<void> updateItem(RevisionItem updatedItem) async {
    final index = _items.indexWhere((t) => t.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      notifyListeners();
      await _storageService.saveItems(_items);
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
  }

  Future<void> deleteItemsByFolder(String folderName) async {
    _items.removeWhere((t) => t.folder == folderName);
    notifyListeners();
    await _storageService.saveItems(_items);
  }

  Future<void> addPoints(int earn) async {
    _points += earn;
    notifyListeners();
    await _storageService.saveStats({'streak': _streak, 'points': _points, 'intervals': _intervals.join(',')});
  }
}
