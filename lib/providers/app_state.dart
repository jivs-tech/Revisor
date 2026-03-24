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
  int get streak => _streak;
  int get points => _points;
  bool get isLoading => _isLoading;

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

  Future<void> addPoints(int earn) async {
    _points += earn;
    notifyListeners();
    await _storageService.saveStats({'streak': _streak, 'points': _points, 'intervals': _intervals.join(',')});
  }
}
