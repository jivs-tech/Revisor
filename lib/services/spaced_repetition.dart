class SpacedRepetition {
  static Map<String, dynamic> calculateNextRevision(int currentIntervalIndex, bool success, List<int> intervals) {
    int nextIndex = success ? currentIntervalIndex + 1 : 0;
    
    if (nextIndex >= intervals.length) {
      nextIndex = intervals.length - 1; 
    }
    
    final daysToAdd = intervals[nextIndex];
    final nextDate = DateTime.now().add(Duration(days: daysToAdd));
    
    return {
      'nextRevisionDate': nextDate,
      'intervalIndex': nextIndex
    };
  }

  static bool isDueToday(DateTime nextRevisionDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextRevisionDate.year, nextRevisionDate.month, nextRevisionDate.day);
    
    return today.compareTo(due) >= 0;
  }
}
